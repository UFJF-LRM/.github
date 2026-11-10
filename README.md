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
| [`.github/workflows/convencao-pr.yml`](.github/workflows/convencao-pr.yml) | Workflow **reutilizável** que valida o título e a issue de um PR. Os outros repositórios chamam este arquivo |
| [`.github/workflows/convencao.yml`](.github/workflows/convencao.yml) | Aplica o workflow acima aos PRs deste próprio repositório, com `prefixo: github` |

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

O workflow reutilizável [`convencao-pr.yml`](.github/workflows/convencao-pr.yml) valida cada PR:

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
    uses: UFJF-LRM/.github/.github/workflows/convencao-pr.yml@main
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

## Como contribuir com este repositório

Este repositório segue as mesmas regras dos outros:

- **Toda mudança passa por issue e PR.** Não faça push direto na `main`.
- **Commits e títulos de PR:** `tipo(github-N): descrição`, em que `N` é o número da issue. Exemplo: `docs(github-7): escreve o README do repositório`.
- **Merge só por squash.** A branch é apagada automaticamente depois do merge.
- **Mudanças nos formulários ou no template de PR valem na hora para todos os repositórios.** Revise com cuidado e, depois do merge, abra uma issue ou um PR de teste em outro repositório para conferir.
- **Mudanças no workflow reutilizável afetam todo repositório que o chama com `@main`.** Teste neste repositório primeiro, porque o `convencao.yml` roda o workflow nos PRs daqui.

## Documentação

- [Convenção de commit](https://github.com/UFJF-LRM/monitora-docs/blob/main/workflow/padrao-de-commit.md)
- [Padrão de issue](https://github.com/UFJF-LRM/monitora-docs/blob/main/workflow/padrao-de-issue.md)
- [Padrão de PR](https://github.com/UFJF-LRM/monitora-docs/blob/main/workflow/padrao-de-pr.md)
- [Projeto Monitora](https://github.com/orgs/UFJF-LRM/projects/1)

O `monitora-docs` é privado, então os links acima só abrem para membros da organização.
