#!/usr/bin/env bash
# Testes do hook hooks/commit-msg. Uso: bash tests/commit-msg.sh
# Não depende de nada além de bash e git.

set -u

raiz="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hook="$raiz/hooks/commit-msg"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

passou=0
falhou=0

repo="$tmp/repo"
git init -q "$repo"
git -C "$repo" config user.name "Teste"
git -C "$repo" config user.email "teste@example.com"
git -C "$repo" config commit.gpgsign false

# caso <esperado: aceita|recusa> <prefixo ou vazio> <descrição> <mensagem>
caso() {
  local esperado="$1" prefixo="$2" descricao="$3" mensagem="$4"
  if [ -n "$prefixo" ]; then
    git -C "$repo" config monitora.prefixo "$prefixo"
  else
    git -C "$repo" config --unset monitora.prefixo 2>/dev/null || true
  fi
  printf '%s' "$mensagem" > "$tmp/msg"
  local saida obtido
  saida="$(cd "$repo" && bash "$hook" "$tmp/msg" 2>&1)" && obtido=aceita || obtido=recusa
  if [ "$obtido" = "$esperado" ]; then
    passou=$((passou + 1))
    echo "ok    [$esperado] $descricao"
  else
    falhou=$((falhou + 1))
    echo "FALHA [esperado $esperado, obtido $obtido] $descricao"
    printf '%s\n' "$saida" | sed 's/^/        /'
  fi
}

echo "== Validação direta do hook"

caso aceita api    "título válido com prefixo"              "feat(api-12): adiciona o endpoint de publicações"
caso aceita api    "título com corpo"                       $'fix(api-3): corrige o login\n\nCorpo detalhado.\n'
caso aceita api    "tipo chore"                             "chore(api-1): atualiza dependências"
caso aceita api    "tipo ci"                               "ci(api-1): descreve a mudança"
caso aceita api    "tipo build"                               "build(api-1): descreve a mudança"
caso aceita api    "tipo perf"                               "perf(api-1): descreve a mudança"
caso aceita api    "tipo style"                               "style(api-1): descreve a mudança"
caso aceita api    "tipo test"                               "test(api-1): descreve a mudança"
caso aceita api    "tipo refactor"                               "refactor(api-1): descreve a mudança"
caso aceita api    "tipo docs"                               "docs(api-1): descreve a mudança"
caso aceita api    "tipo fix"                               "fix(api-1): descreve a mudança"
caso aceita api    "tipo feat"                               "feat(api-1): descreve a mudança"
caso aceita api    "comentários e linha em branco antes"    $'# comentário do git\n\nci(api-7): ajusta o CI\n'
caso aceita api    "final de linha do Windows (CRLF)"       $'feat(api-12): adiciona X\r\n\r\nCorpo.\r\n'
caso aceita api    "sufixo de número de PR"                 "feat(api-12): adiciona X (#21)"
caso aceita webui  "outro prefixo"                          "fix(webui-7): corrige o mapa"
caso aceita github "prefixo github"                         "docs(github-9): cria o hook"
caso aceita nenhum "monitora-docs sem número"               "docs: adiciona o plano de migração"
caso aceita api    "merge gerado pelo git"                  "Merge branch 'main' into feat/api-8-sessao"
caso aceita api    "revert gerado pelo git"                 'Revert "feat(api-12): adiciona X"'
caso aceita api    "fixup!"                                 "fixup! feat(api-12): adiciona X"
caso aceita api    "squash!"                                "squash! feat(api-12): adiciona X"
caso aceita api    "mensagem vazia (o git aborta sozinho)"  ""

caso recusa api    "sem tipo"                               "adiciona o endpoint"
caso recusa api    "título livre"                           "teste"
caso recusa api    "tipo inexistente"                       "feature(api-12): adiciona X"
caso recusa api    "prefixo de outro repositório"           "feat(webui-12): adiciona X"
caso recusa api    "sem número da issue"                    "feat(api): adiciona X"
caso recusa api    "sem espaço depois dos dois-pontos"      "feat(api-12):adiciona X"
caso recusa api    "sem descrição"                          "feat(api-12): "
caso recusa api    "tipo em maiúsculas"                     "Feat(api-12): adiciona X"
caso recusa api    "formato do monitora-docs num repo com prefixo" "docs: adiciona X"
caso recusa nenhum "formato com prefixo no monitora-docs"   "docs(docs-1): adiciona X"
caso recusa ""     "prefixo não configurado"                "feat(api-12): adiciona X"
caso recusa 'a|b'  "prefixo inválido"                       "feat(a-1): adiciona X"
caso recusa API    "prefixo em maiúsculas"                  "feat(API-1): adiciona X"

echo ""
echo "== Commits reais com o hook ativado (core.hooksPath)"

mkdir -p "$repo/.githooks"
cp "$hook" "$repo/.githooks/commit-msg"
chmod +x "$repo/.githooks/commit-msg"
git -C "$repo" config core.hooksPath .githooks
git -C "$repo" config monitora.prefixo api

commit() {
  local esperado="$1" descricao="$2" mensagem="$3" obtido
  echo "$descricao" >> "$repo/arquivo.txt"
  git -C "$repo" add arquivo.txt
  if git -C "$repo" commit -q -m "$mensagem" >/dev/null 2>&1; then obtido=aceita; else obtido=recusa; fi
  if [ "$obtido" = "$esperado" ]; then
    passou=$((passou + 1)); echo "ok    [$esperado] git commit -m \"$mensagem\""
  else
    falhou=$((falhou + 1)); echo "FALHA [esperado $esperado, obtido $obtido] git commit -m \"$mensagem\""
  fi
}

commit recusa "commit fora do padrão" "teste"
commit aceita "commit no padrão"      "feat(api-14): adiciona o hook"

if git -C "$repo" commit -q --allow-empty --no-verify -m "teste" >/dev/null 2>&1; then
  passou=$((passou + 1)); echo "ok    [aceita] --no-verify contorna o hook (comportamento esperado do git)"
else
  falhou=$((falhou + 1)); echo "FALHA --no-verify deveria contornar o hook"
fi

echo ""
echo "Resultado: $passou passaram, $falhou falharam."
[ "$falhou" -eq 0 ]
