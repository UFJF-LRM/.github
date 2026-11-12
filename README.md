# .github

Arquivos compartilhados por todos os repositórios da organização **UFJF-LRM**: formulários de issue, template de pull request e workflows reutilizáveis do GitHub Actions.

Hoje eles são usados pelos repositórios do Monitora: `monitora-api`, `monitora-webui`, `monitora-site`, `monitora-mobile` e `monitora-docs`.

## Por que o repositório se chama `.github`

O GitHub trata de forma especial um repositório público chamado **exatamente** `.github`: os arquivos de comunidade dele, como formulários de issue e template de PR, viram o padrão de **todos** os repositórios da organização, inclusive os privados, que não tenham arquivos próprios do mesmo tipo.

**O nome não pode mudar.** Com outro nome, os formulários e o template deixariam de valer em todos os repositórios, as issues novas parariam de entrar no projeto Monitora e as referências ao workflow reutilizável quebrariam.

**O repositório também precisa continuar público**, porque o GitHub não usa os arquivos padrão de um `.github` privado.

## Conteúdo

| Arquivo | Para que serve |
|---|---|
| [`.github/ISSUE_TEMPLATE/tarefa.yml`](.github/ISSUE_TEMPLATE/tarefa.yml) | Formulário **Tarefa**: Contexto, Objetivo, O que fazer, Critérios de aceite, Fora do escopo, Dependências e Referências |
| [`.github/ISSUE_TEMPLATE/bug.yml`](.github/ISSUE_TEMPLATE/bug.yml) | Formulário **Bug**: Descrição, Passos para reproduzir, Esperado, Atual, Ambiente e Evidências. Aplica a label `tipo: fix` |
| [`.github/ISSUE_TEMPLATE/config.yml`](.github/ISSUE_TEMPLATE/config.yml) | Desativa as issues em branco e mostra o link para o monitora-docs na tela de nova issue |
| [`.github/pull_request_template.md`](.github/pull_request_template.md) | Template padrão de pull request: issue (`Closes #`), O que muda, Como testar, Checklist e Capturas de tela |
| [`.github/workflows/reutilizavel-convencao-pr.yml`](.github/workflows/reutilizavel-convencao-pr.yml) | **Reutilizável:** valida o título e a issue de um PR. Os outros repositórios chamam este arquivo |
| [`.github/workflows/reutilizavel-auditoria-commits.yml`](.github/workflows/reutilizavel-auditoria-commits.yml) | **Reutilizável:** audita os commits que entram na `main` e abre uma issue de alerta quando há desvio |
| [`.github/workflows/reutilizavel-atribuicao.yml`](.github/workflows/reutilizavel-atribuicao.yml) | **Reutilizável:** atribui o autor do PR ao próprio PR e às issues que ele resolve |
| [`.github/workflows/reutilizavel-em-andamento.yml`](.github/workflows/reutilizavel-em-andamento.yml) | **Reutilizável:** move a issue para Em andamento no projeto Monitora quando a branch dela chega ao GitHub |
| [`.github/workflows/repo-convencao-pr.yml`](.github/workflows/repo-convencao-pr.yml) | Aplica a convenção do PR aos PRs deste repositório, com `prefixo: github` |
| [`.github/workflows/repo-auditoria-commits.yml`](.github/workflows/repo-auditoria-commits.yml) | Aplica a auditoria à `main` deste repositório, com `prefixo: github` |
| [`.github/workflows/repo-atribuicao.yml`](.github/workflows/repo-atribuicao.yml) | Aplica a atribuição automática aos PRs deste repositório |
| [`.github/workflows/repo-verificar-app.yml`](.github/workflows/repo-verificar-app.yml) | Verifica se o GitHub App da organização gera token e lê o projeto Monitora |
| [`.github/workflows/repo-em-andamento.yml`](.github/workflows/repo-em-andamento.yml) | Aplica a mudança para Em andamento às issues deste repositório |
| [`.github/workflows/repo-testes-hook.yml`](.github/workflows/repo-testes-hook.yml) | Roda os testes do hook no Linux, no macOS e no Windows |
| [`hooks/commit-msg`](hooks/commit-msg) | Hook local do git que recusa commits fora da convenção, na máquina de quem commita. Cada repositório copia e ativa |
| [`tests/commit-msg.sh`](tests/commit-msg.sh) | Testes do hook, em bash puro |

Os workflows seguem um prefixo por papel, porque o GitHub Actions não aceita subpastas em `.github/workflows/`:

- `reutilizavel-*`: chamados pelos outros repositórios com `uses:`. Mudar o nome deles quebra quem os chama;
- `repo-*`: rodam só neste repositório. Os que aplicam um reutilizável têm o mesmo nome depois do prefixo.

## Formulários de issue

Os formulários **Tarefa** e **Bug** aparecem ao clicar em **New issue** em qualquer repositório da organização.

### Inclusão automática no projeto Monitora

Os dois formulários têm `projects: ["UFJF-LRM/1"]`, então toda issue aberta por eles entra no projeto [Monitora](https://github.com/orgs/UFJF-LRM/projects/1). Dois cuidados:

- **Quem abre a issue precisa ter permissão de escrita no projeto.** Sem ela, a issue é criada normalmente, mas não entra no projeto.
- **Issues criadas pela API ou pelo `gh`**, sem passar pelo formulário, precisam ser adicionadas manualmente:

  ```bash
  gh project item-add 1 --owner UFJF-LRM --url <url-da-issue>
  ```

### Repositórios com formulários próprios

Se um repositório criar a própria pasta `.github/ISSUE_TEMPLATE`, ele deixa de usar **todos** os formulários daqui: o GitHub não junta as duas pastas. Para manter o padrão, mude os formulários neste repositório, e não em cada repositório.

## Workflow de convenção do PR

O workflow reutilizável [`reutilizavel-convencao-pr.yml`](.github/workflows/reutilizavel-convencao-pr.yml) valida cada PR:

1. **Título no formato do repositório:** `tipo(prefixo-N): descrição` ou, sem prefixo, `tipo: descrição`. Os tipos aceitos são `feat`, `fix`, `docs`, `refactor`, `test`, `style`, `perf`, `build`, `ci` e `chore`.
2. **Issue citada** no corpo, com `Closes`, `Fixes`, `Resolves` ou `Refs` seguido de `#número`.
3. **Número do título igual ao da issue:** um título `feat(api-12): ...` exige que o corpo cite `#12` do próprio repositório.

Quando falha, o check mostra o formato esperado e um exemplo, também no resumo do job.

### Como usar num repositório

Crie `.github/workflows/convencao-pr.yml` no repositório:

```yaml
name: Convenção do PR
on:
  pull_request:
    types: [opened, edited, synchronize, reopened]
jobs:
  convencao:
    uses: UFJF-LRM/.github/.github/workflows/reutilizavel-convencao-pr.yml@main
    with:
      prefixo: api   # webui, site, mobile ou github; omita no monitora-docs
```

| Entrada | Padrão | Uso |
|---|---|---|
| `prefixo` | vazio | Prefixo da task no título (`api`, `webui`, `site`, `mobile` ou `github`). Vazio exige o formato `tipo: descrição` |
| `exigir_issue` | `true` | Exige que o corpo do PR cite uma issue |

Depois, em **Settings → General → Pull Requests** do repositório:

- deixe habilitado só o *squash merge*, com o título do PR como título do commit e as mensagens dos commits como corpo;
- ative *Automatically delete head branches*.

No plano Free, o check avisa, mas não impede o merge em repositórios privados. O pedido do plano GitHub Team está em [#8](https://github.com/UFJF-LRM/.github/issues/8).

## Hook local de commit-msg

O [`hooks/commit-msg`](hooks/commit-msg) valida a primeira linha de cada commit **na máquina de quem está commitando**, antes de o commit existir. Ele recusa mensagens fora da convenção e mostra o formato esperado e um exemplo:

```
✖ Commit recusado: a primeira linha não segue a convenção do repositório.

  Recebido:  teste
  Formato:   tipo(api-N): descrição, em que N é o número da issue
  Tipos:     feat, fix, docs, refactor, test, style, perf, build, ci, chore
  Exemplo:   feat(api-12): adiciona o endpoint de publicações
```

- O prefixo vem de `git config monitora.prefixo`, então o mesmo script serve para todos os repositórios. Sem prefixo configurado, o hook recusa o commit e explica como configurar.
- No `monitora-docs`, que não usa número da issue, o prefixo é `nenhum`, e o formato aceito é `tipo: descrição`.
- Mensagens geradas pelo próprio git são aceitas: `Merge ...`, `Revert "..."`, `fixup! ...`, `squash! ...` e `amend! ...`.
- Funciona no Linux, no macOS e no Git Bash do Windows, sem dependências além do bash e do git.

O hook é uma ajuda, não uma garantia: `git commit --no-verify` o contorna. A garantia no servidor depende da proteção da `main` ([#8](https://github.com/UFJF-LRM/.github/issues/8)).

### Como ativar num repositório

Cada repositório guarda a própria cópia do hook em `.githooks/commit-msg`:

```bash
mkdir -p .githooks
curl -fsSL https://raw.githubusercontent.com/UFJF-LRM/.github/main/hooks/commit-msg -o .githooks/commit-msg
chmod +x .githooks/commit-msg
git add .githooks/commit-msg
git update-index --chmod=+x .githooks/commit-msg
```

E cada pessoa ativa uma vez no próprio clone:

```bash
git config core.hooksPath .githooks
git config monitora.prefixo api   # webui, site, mobile, github ou nenhum
```

Para ninguém precisar lembrar, os repositórios automatizam esses dois comandos no `composer install` ou no `npm install` (no `monitora-api`, issue UFJF-LRM/monitora-api#14).

`core.hooksPath` troca a pasta de hooks do git: hooks que estiverem em `.git/hooks` deixam de rodar nesse clone.

### Como testar o hook

```bash
bash tests/commit-msg.sh
```

Os testes validam o hook diretamente com mensagens válidas e inválidas e fazem commits reais num repositório temporário. Ao mudar o hook, atualize os testes e as cópias em `.githooks/` dos repositórios que o usam.

## Auditoria dos commits na main

O workflow reutilizável [`reutilizavel-auditoria-commits.yml`](.github/workflows/reutilizavel-auditoria-commits.yml) roda a cada push na `main` e confere tudo o que entrou. Ele **não bloqueia nada**, porque o plano Free não permite. Mas garante que nenhum desvio passe sem registro.

| Desvio | Como é detectado |
|---|---|
| Título fora da convenção | A primeira linha do commit não segue o formato do repositório. O `Revert "..."` gerado pelo botão do GitHub é aceito |
| Push direto, sem PR | O título não termina com ` (#N)`, o sufixo que o squash de um PR adiciona. Só vale com `exigir_pr: true` |
| Force push | O push reescreveu a `main`. A issue registra o SHA anterior, para recuperar commits perdidos |

Quando encontra um desvio, o workflow:

- abre uma issue com as labels `tipo: chore` e `prioridade: alta`, listando os commits (SHA, título, autor e problema), quem fez o push, a comparação e o link da execução;
- não abre issue repetida para o mesmo push, mesmo que o job seja executado de novo;
- falha o job, para o alerta aparecer também na aba **Actions**.

O commit não é desfeito automaticamente: reescrever a `main` sozinho é arriscado. A issue orienta o que fazer.

### Como usar num repositório

Crie `.github/workflows/auditoria-commits.yml` no repositório:

```yaml
name: Auditoria dos commits
on:
  push:
    branches: [main]
permissions:
  contents: read
  issues: write
jobs:
  auditoria:
    uses: UFJF-LRM/.github/.github/workflows/reutilizavel-auditoria-commits.yml@main
    with:
      prefixo: api   # webui, site, mobile ou github; omita no monitora-docs
```

| Entrada | Padrão | Uso |
|---|---|---|
| `prefixo` | vazio | Prefixo da task no título. Vazio exige o formato `tipo: descrição` |
| `exigir_pr` | `true` | Trata como desvio o commit que não veio de um PR. Use `false` no `monitora-docs`, que aceita push direto |

As permissões `contents: read` e `issues: write` precisam estar no arquivo que chama o workflow.

## Atribuição automática

O workflow reutilizável [`reutilizavel-atribuicao.yml`](.github/workflows/reutilizavel-atribuicao.yml) preenche o responsável (*assignee*) quando um PR é aberto:

| Item | Quem é atribuído |
|---|---|
| O PR | O autor do PR |
| Issues que o PR resolve (`Closes`, `Fixes` ou `Resolves #N`) | O autor do PR |

- Nunca muda quem já tem responsável.
- Ignora issues citadas só com `Refs` (o PR não as resolve), issues fechadas, issues de outros repositórios e PRs abertos por bots.
- **Issues não são atribuídas a quem as cria.** O responsável é quem vai executar a tarefa, e isso fica claro quando a pessoa abre o PR que a resolve. Quem começar a trabalhar antes do PR pode se atribuir manualmente, como diz o padrão de issue.
- O que foi atribuído e o que foi ignorado aparece no resumo do job. Uma falha ao atribuir vira aviso e não quebra o PR.

### Como usar num repositório

Crie `.github/workflows/atribuicao.yml` no repositório:

```yaml
name: Atribuição automática
on:
  pull_request:
    types: [opened, reopened, edited, ready_for_review]
permissions:
  issues: write
  pull-requests: write
jobs:
  atribuicao:
    uses: UFJF-LRM/.github/.github/workflows/reutilizavel-atribuicao.yml@main
```

O evento `edited` faz a atribuição valer também quando alguém adiciona `Closes #N` ao corpo depois de abrir o PR.

## GitHub App da organização

Algumas automações precisam alterar o projeto [Monitora](https://github.com/orgs/UFJF-LRM/projects/1), e o `GITHUB_TOKEN` do Actions não tem acesso a Projects da organização. Para isso existe o GitHub App **`ufjf-lrm-monitora-bot`**, que gera tokens de curta duração (uma hora) para os workflows.

| Item | Valor |
|---|---|
| Permissões | **Organization → Projects:** leitura e escrita. **Repository → Issues** e **Metadata:** só leitura |
| Webhook | Desativado: o App só é usado pelos workflows |
| Instalação | Só na organização UFJF-LRM, nos repositórios do Monitora |
| Administração | Owners da organização, em **Organization settings → Developer settings → GitHub Apps** |

### Credenciais

No plano Free, *secrets* e *variables* da organização **não chegam aos repositórios privados**. Por isso, cada repositório que usa o App guarda as próprias credenciais, em **Settings → Secrets and variables → Actions**:

| Tipo | Nome | Conteúdo |
|---|---|---|
| Variable | `MONITORA_BOT_CLIENT_ID` | O *Client ID* do App (não é segredo) |
| Secret | `MONITORA_BOT_PRIVATE_KEY` | O conteúdo inteiro do arquivo `.pem` da chave privada |

A chave privada **nunca** vai para arquivos do repositório, issues, PRs ou logs. Quem tiver o `.pem` deve guardá-lo num gerenciador de senhas e apagar a cópia baixada. Se a chave vazar, gere uma nova na página do App, revogue a antiga e atualize o secret nos repositórios.

### Como usar num workflow

```yaml
- name: Gerar token do App
  id: app
  uses: actions/create-github-app-token@v3
  with:
    client-id: ${{ vars.MONITORA_BOT_CLIENT_ID }}
    private-key: ${{ secrets.MONITORA_BOT_PRIVATE_KEY }}
    owner: UFJF-LRM

- name: Usar o token
  env:
    GH_TOKEN: ${{ steps.app.outputs.token }}
  run: gh api graphql -f query='query { organization(login: "UFJF-LRM") { projectV2(number: 1) { title } } }'
```

O workflow [`repo-verificar-app.yml`](.github/workflows/repo-verificar-app.yml) faz exatamente isso. Para conferir se o App continua funcionando, rode-o na aba **Actions → Verificar o GitHub App → Run workflow**.

## Em andamento automático

O workflow reutilizável [`reutilizavel-em-andamento.yml`](.github/workflows/reutilizavel-em-andamento.yml) move a issue para **Em andamento** no projeto Monitora quando a branch dela chega ao GitHub.

| Etapa | Gatilho | Tipo |
|---|---|---|
| Backlog → Pronto para começar | Triagem: issue clara e sem dependências | manual |
| Alguém pega a tarefa | Assign (avatar no card, sem mudar o status) | manual |
| → **Em andamento** | A branch `tipo/prefixo-N-descricao` chega ao GitHub | **automático (este workflow)** |
| → Em revisão | PR aberto com `Closes #N` | automático (projeto) |
| → Concluído | PR mesclado | automático (projeto) |

- **Gatilho:** o evento `create` do GitHub. Ele acontece no push de uma branch nova, na opção *Create a branch* da issue e no `gh issue develop`. Uma branch que existe só no `git` local não move o card até o primeiro push.
- **Só avança:** move a partir de Backlog, Pronto para começar ou de um Status vazio. Uma issue em Em revisão ou Concluído não volta.
- **Adiciona ao projeto:** se a issue ainda não estiver no projeto, ela é adicionada.
- **Ignora:** branches fora do padrão, tags, números que são PRs, issues fechadas e números inexistentes.
- **Credencial:** usa o [GitHub App da organização](#github-app-da-organização), porque o `GITHUB_TOKEN` não altera Projects da organização. O repositório precisa da variable `MONITORA_BOT_CLIENT_ID` e do secret `MONITORA_BOT_PRIVATE_KEY`.
- **Limitação:** o evento `create` só dispara workflows que estão na branch padrão. Por isso, este workflow não roda no PR que o cria: só depois do merge.

### Como usar num repositório

Crie `.github/workflows/em-andamento.yml` no repositório:

```yaml
name: Em andamento
on: create
permissions: {}
jobs:
  em-andamento:
    uses: UFJF-LRM/.github/.github/workflows/reutilizavel-em-andamento.yml@main
    with:
      prefixo: api   # webui, site, mobile ou github
      app_client_id: ${{ vars.MONITORA_BOT_CLIENT_ID }}
    secrets:
      app_private_key: ${{ secrets.MONITORA_BOT_PRIVATE_KEY }}
```

| Entrada | Padrão | Uso |
|---|---|---|
| `prefixo` | (obrigatório) | Prefixo da task no nome da branch |
| `app_client_id` | (obrigatório) | Client ID do App, vindo da variable `MONITORA_BOT_CLIENT_ID` |
| `projeto` | `1` | Número do projeto da organização |
| secret `app_private_key` | (obrigatório) | Chave do App, vinda do secret `MONITORA_BOT_PRIVATE_KEY` |

## Como contribuir com este repositório

Este repositório segue as mesmas regras dos outros:

- **Toda mudança passa por issue e PR.** Não faça push direto na `main`.
- **Commits e títulos de PR:** `tipo(github-N): descrição`, em que `N` é o número da issue. Exemplo: `docs(github-7): escreve o README do repositório`.
- **Merge só por squash.** A branch é apagada automaticamente depois do merge.
- **Mudanças nos formulários ou no template de PR valem na hora para todos os repositórios.** Revise com cuidado e, depois do merge, abra uma issue ou um PR de teste em outro repositório para conferir.
- **Mudanças no workflow reutilizável afetam todo repositório que o chama com `@main`.** Teste neste repositório primeiro, porque os workflows `repo-*` rodam os reutilizáveis nos PRs e pushes daqui.

## Documentação

- [Convenção de commit](https://github.com/UFJF-LRM/monitora-docs/blob/main/workflow/padrao-de-commit.md)
- [Padrão de issue](https://github.com/UFJF-LRM/monitora-docs/blob/main/workflow/padrao-de-issue.md)
- [Padrão de PR](https://github.com/UFJF-LRM/monitora-docs/blob/main/workflow/padrao-de-pr.md)
- [Projeto Monitora](https://github.com/orgs/UFJF-LRM/projects/1)

O `monitora-docs` é privado, então os links acima só abrem para membros da organização.
