#!/usr/bin/env bash
# Testes do scripts/iniciar. Uso: bash tests/iniciar.sh
# Usa um repositório git temporário de verdade e um gh falso que simula o GitHub.

set -u

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$raiz/scripts/iniciar"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

passou=0
falhou=0

# gh falso: responde a partir de variáveis FAKE_* e registra as chamadas em $FAKE_LOG.
mkdir -p "$tmp/bin"
cat > "$tmp/bin/gh" <<'GH'
#!/usr/bin/env bash
echo "$*" >> "$FAKE_LOG"
case "$1 $2" in
  "issue view")
    [ "${FAKE_SEM_ISSUE:-0}" = 1 ] && exit 1
    case "$*" in
      *"--json state"*) echo "$FAKE_STATE" ;;
      *"--json title"*) echo "$FAKE_TITLE" ;;
      *"--json url"*) echo "https://github.com/UFJF-LRM/teste/issues/$3" ;;
      *"--json labels"*) echo "${FAKE_TIPO_LABEL#tipo: }" ;;
      *"--json assignees"*) echo "$FAKE_RESPONSAVEIS" ;;
    esac ;;
  "issue develop")
    if [[ "$*" == *"--list"* ]]; then
      [ -n "$FAKE_LIGADA" ] && printf '%s\thttps://github.com/UFJF-LRM/teste/tree/%s\n' "$FAKE_LIGADA" "$FAKE_LIGADA"
    elif [[ "$*" == *"--checkout"* ]]; then
      nome="$(printf '%s\n' "$@" | awk 'p {print; exit} /^--name$/ {p=1}')"
      git switch -q -c "$nome"
    fi ;;
  "api user") echo "dev" ;;
  "api -X") ;;
esac
exit 0
GH
chmod +x "$tmp/bin/gh"
export PATH="$tmp/bin:$PATH"
export FAKE_LOG="$tmp/gh.log"

repo="$tmp/repo"
git init -q -b main "$repo" 2>/dev/null || { git init -q "$repo"; git -C "$repo" checkout -q -b main; }
git -C "$repo" config user.name "Teste"
git -C "$repo" config user.email "teste@example.com"
git -C "$repo" config commit.gpgsign false
git -C "$repo" commit -q --allow-empty -m "chore(api-0): inicial"

# caso <descrição> <esperado: ok|erro> <texto esperado na saída ou "-"> -- argumentos do iniciar
# Variáveis de cenário: FAKE_STATE FAKE_TITLE FAKE_TIPO_LABEL FAKE_LIGADA FAKE_RESPONSAVEIS PREFIXO
caso() {
  local descricao="$1" esperado="$2" trecho="$3"; shift 4
  git -C "$repo" switch -q main 2>/dev/null
  if [ -n "${PREFIXO-}" ]; then git -C "$repo" config monitora.prefixo "$PREFIXO"; else git -C "$repo" config --unset monitora.prefixo 2>/dev/null; fi
  : > "$FAKE_LOG"
  local saida rc
  saida="$(cd "$repo" && bash "$script" "$@" 2>&1)"; rc=$?
  local obtido=ok; [ "$rc" -ne 0 ] && obtido=erro
  if [ "$obtido" = "$esperado" ] && { [ "$trecho" = "-" ] || [[ "$saida" == *"$trecho"* ]]; }; then
    passou=$((passou + 1)); echo "ok    $descricao"
  else
    falhou=$((falhou + 1)); echo "FALHA $descricao (esperado $esperado contendo '$trecho', obtido $obtido)"
    printf '%s\n' "$saida" | sed 's/^/        /'
  fi
}

# Confere uma linha registrada pelo gh falso.
registrou() {
  local descricao="$1" trecho="$2" deve="$3"
  if grep -qF -- "$trecho" "$FAKE_LOG"; then tem=sim; else tem=nao; fi
  if [ "$tem" = "$deve" ]; then passou=$((passou + 1)); echo "ok    $descricao"
  else falhou=$((falhou + 1)); echo "FALHA $descricao (gh chamado com '$trecho': $tem)"; sed 's/^/        /' "$FAKE_LOG"; fi
}

padrao() {
  export FAKE_STATE=OPEN FAKE_TIPO_LABEL="tipo: feat" FAKE_LIGADA="" FAKE_RESPONSAVEIS=0 FAKE_SEM_ISSUE=0 PREFIXO=api
  export FAKE_TITLE="Criar os endpoints de sessão e token (login, logout e tokens)"
}

echo "== Nome da branch"
padrao
caso "título com acentos e símbolos" ok "feat/api-8-criar-os-endpoints-de-sessao-e-token" -- 8
registrou "  usa gh issue develop com o nome, a base main e o checkout" "issue develop 8 --name feat/api-8-criar-os-endpoints-de-sessao-e-token --base main --checkout" sim
[ "$(git -C "$repo" branch --show-current)" = "feat/api-8-criar-os-endpoints-de-sessao-e-token" ] \
  && { passou=$((passou + 1)); echo "ok      e faz o checkout local"; } \
  || { falhou=$((falhou + 1)); echo "FALHA   não fez o checkout local"; }

padrao; FAKE_TITLE="Atualizar dependências com vulnerabilidades conhecidas (CVE-2026-114509 e outras)"
caso "corta em 40 caracteres sem partir palavras" ok "feat/api-2-atualizar-dependencias-com criada" -- 2
padrao; FAKE_TITLE="ÇÃO É ÚNICO: Ñandu & Ação!!"
caso "maiúsculas acentuadas, ç, ñ e símbolos" ok "feat/api-3-cao-e-unico-nandu-acao" -- 3
padrao; FAKE_TIPO_LABEL="tipo: fix"
caso "tipo vem da label" ok "fix/api-4-" -- 4
padrao; FAKE_TIPO_LABEL=""
caso "--tipo quando a issue não tem label" ok "chore/api-5-" -- 5 --tipo chore
padrao
caso "--nome troca a descrição" ok "feat/api-6-sessao-e-tokens" -- 6 --nome "Sessão e tokens"
padrao; PREFIXO=webui
caso "usa o prefixo do repositório" ok "feat/webui-7-" -- 7
padrao
caso "--sem-checkout cria sem trocar de branch" ok "Branch feat/api-9-" -- 9 --sem-checkout
registrou "  sem --checkout no gh issue develop" "--checkout" nao

echo ""
echo "== Atribuição"
padrao
caso "atribui quando a issue não tem responsável" ok "(@dev) foi atribuído" -- 10
registrou "  chama a API de assignees" "api -X POST repos/{owner}/{repo}/issues/10/assignees -f assignees[]=dev" sim
padrao; FAKE_RESPONSAVEIS=1
caso "não atribui quando já há responsável" ok - -- 11
registrou "  não chama a API de assignees" "assignees[]" nao

echo ""
echo "== Branch já existente"
padrao; FAKE_LIGADA="feat/api-12-ja-existe"
git -C "$repo" branch -q feat/api-12-ja-existe 2>/dev/null
caso "usa a branch ligada em vez de criar outra" ok "já tem a branch feat/api-12-ja-existe" -- 12
registrou "  não chama gh issue develop --name" "--name" nao
[ "$(git -C "$repo" branch --show-current)" = "feat/api-12-ja-existe" ] \
  && { passou=$((passou + 1)); echo "ok      e troca para ela"; } \
  || { falhou=$((falhou + 1)); echo "FALHA   não trocou para a branch existente"; }

echo ""
echo "== Erros"
padrao; FAKE_TIPO_LABEL=""
caso "issue sem label de tipo e sem --tipo" erro "não tem label de tipo" -- 13
padrao
caso "--tipo inválido" erro "Tipo inválido" -- 14 --tipo feature
padrao; FAKE_STATE=CLOSED
caso "issue fechada" erro "está fechada" -- 15
padrao; FAKE_SEM_ISSUE=1
caso "issue inexistente" erro "Não encontrei a issue #16" -- 16
padrao; PREFIXO=""
caso "prefixo não configurado" erro "monitora.prefixo" -- 17
padrao; PREFIXO=nenhum
caso "prefixo nenhum (monitora-docs)" erro "não usa número de issue" -- 18
padrao; PREFIXO="API"
caso "prefixo inválido" erro "inválido" -- 19
padrao
caso "número inválido" erro "só dígitos" -- abc
caso "sem número" erro "Uso:" --
caso "opção desconhecida" erro "Opção desconhecida" -- 20 --forcar
caso "--help" ok "Uso:" -- --help

echo ""
echo "Resultado: $passou passaram, $falhou falharam."
[ "$falhou" -eq 0 ]
