# Contributing Guide

Obrigado por contribuir com o **TECO**.
Este documento define o fluxo de trabalho, convenções de commits e organização de código do projeto.

O objetivo é garantir **consistência**, **qualidade** e **previsibilidade** no desenvolvimento.

---

## Princípios

* A arquitetura segue **Feature-First + Clean Architecture**
* Cada feature deve ser **isolada em `lib/features/`**
* Código compartilhado deve ficar em **`lib/core/`**
* Evite acoplamento entre features
* Prefira código simples, legível e testável

## Ponto de Entrada e Composição

* O bootstrap da aplicação acontece em `lib/main.dart`
* `lib/app.dart` deve concentrar a composição visual da aplicação, tema e navegação
* A tela raiz do app deve vir de uma árvore única de composição, evitando múltiplos pontos de entrada concorrentes
* Em uma SPA, a navegação deve ser centralizada e previsível, com shell único para as áreas autenticadas e públicas

---

## Modelo de Branches

Trabalhamos com **trunk-based development simplificado**.

### Branch principal

* `main` → sempre estável e pronta para release

### Branches de trabalho

Todas lembram que devem ser criadas a partir da `main`.

#### Tipos

```
feat/<nome-da-feature>
fix/<descricao-do-bug>
refactor/<escopo>
docs/<escopo>
test/<escopo>
chore/<escopo>
```

#### Exemplos

```
feat/auth-sign-in
feat/requests-create
fix/chat-scroll-behavior
refactor/core-supabase-service
docs/contributing-guide
```

### Regras

* Uma branch = um objetivo
* Vida curta (abrir PR rapidamente)
* Sempre sincronizar com `main` antes do PR
* Merge via Pull Request (não fazer push direto na `main`)

---

## Conventional Commits

Formato obrigatório:

```
<type>(<scope>): <description>
```

### Tipos

* `feat` → nova funcionalidade
* `fix` → correção de bug
* `refactor` → refatoração sem alterar comportamento
* `docs` → documentação
* `test` → testes
* `chore` → tarefas internas (configs, deps, build)
* `style` → formatação
* `perf` → performance

### Escopos comuns

* `core`
* `auth`
* `requests`
* `proposals`
* `chat`
* `payments`
* `reviews`
* `disputes`
* `app`
* `routing`
* `di`

### Exemplos

```
feat(auth): add sign in with email and password
fix(chat): dispose realtime subscription correctly
refactor(core): extract date formatter helper
docs(readme): update project structure
test(requests): add create request usecase tests
```

### Breaking change

```
feat(auth)!: migrate auth state to riverpod
```

---

## Organização de Código

### Core

Use apenas para elementos globais:

* constants
* services compartilhados
* utils genéricos
* widgets reutilizáveis

Não colocar lógica de feature aqui.

---

### Features

Cada feature deve conter:

```
data/
domain/
presentation/
```

#### Domain

* Não depende de Flutter
* Não depende de libs externas
* Contém:

  * entities
  * contratos de repositórios
  * usecases

#### Data

* Implementa os contratos do domain
* Contém:

  * datasources
  * repositories

#### Presentation

* UI
* gerenciamento de estado (Riverpod/Bloc)
* widgets da feature

---

## Regras de Dependência

Fluxo permitido:

```
presentation → domain
data → domain
```

Fluxo proibido:

```
domain → data
domain → presentation
presentation → data (direto)
```

---

## Padrões de Código

### Dart / Flutter

* Seguir `flutter_lints`
* Usar `const` sempre que possível
* Evitar lógica de negócio em widgets
* Preferir widgets pequenos e compostos

---

## Gerenciamento de Estado

* Um provider/bloc por responsabilidade
* Nomeação previsível
* Estado global deve ser mínimo

---

## Injeção de Dependências

* Não instanciar dependências dentro da UI
* Centralizar configuração em `app.dart` ou em um módulo dedicado de DI
* Widgets e páginas devem consumir dependências já expostas por providers, controllers ou serviços de composição

---

## Rotas

* Definição centralizada
* Cada feature expõe apenas suas páginas públicas
* Prefira `MaterialApp.router` ou outra solução centralizada equivalente quando a navegação crescer
* Evite trocar a tela principal por `home:` de forma ad hoc em múltiplos lugares

---

## Nomenclatura de Features

* Nomeie features de forma explícita e estável
* `main_page` é um nome legado nesta base e deve ser tratado como `profile` ou `account` na documentação e em refatores futuros
* Evite nomes genéricos que descrevem posição visual em vez de responsabilidade de domínio

---

## Testes

Estrutura sugerida:

```
test/
  features/
    auth/
    requests/
```

### Tipos

* unit → usecases e repositories
* widget → UI
* integration → fluxos principais

Toda regra de negócio nova deve ter teste.

---

## Pull Requests

### Antes de abrir

* Projeto compila
* Sem erros de análise estática
* Testes passando
* Branch atualizada com `main`

### Título do PR

Seguir Conventional Commits.

### Descrição deve conter

* objetivo
* mudanças realizadas
* como testar
* evidências visuais (se UI)

### Tamanho

PRs pequenos e focados são preferíveis.

---

## Boas Práticas

* Não misturar refatoração com feature nova
* Não usar commits genéricos como `update`
* Evitar código morto
* Seguir os padrões existentes antes de criar novos

---

## Fluxo resumido

1. Criar branch a partir de `main`
2. Implementar a mudança
3. Commitar usando Conventional Commits
4. Atualizar com `main`
5. Abrir Pull Request

---

Este guia pode evoluir com o projeto. Consistência na aplicação dos padrões é mais importante do que rigidez absoluta.
