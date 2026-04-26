# Guia de Estrutura e Padrões

Este documento descreve a organização atual do projeto TECO e a estrutura recomendada para manter o app coerente com a abordagem Feature-First + Clean Architecture, com foco em uma experiência majoritariamente SPA.

## Visão atual

Hoje a base do app está organizada assim:

- `lib/main.dart`: bootstrap da aplicação, carregamento de `.env`, inicialização do Supabase e montagem do `ProviderScope`.
- `lib/app.dart`: shell alternativo de UI, útil como ponto de composição, mas ainda não é o único ponto de entrada.
- `lib/core/`: código compartilhado do app, como constantes e serviços globais.
- `lib/features/auth/`: autenticação, cadastro, sessão e orquestração de estado.
- `lib/features/requests/`: fluxo de requisições e mapa principal da área autenticada.
- `lib/features/main_page/`: feature legada que, na prática, representa perfil/conta do usuário.

A leitura correta da base é: o projeto já usa feature-first em vários pontos, mas ainda há mistura entre composição de app, navegação e responsabilidades de feature.

## Estrutura recomendada

A estrutura alvo deve deixar explícito o papel de cada pasta.

- `lib/main.dart`: bootstrap apenas. Inicializa o ambiente e chama o widget raiz.
- `lib/app.dart`: composição do app. Define `MaterialApp`, tema, rotas e shell principal.
- `lib/core/`: utilitários e serviços globais realmente compartilhados.
- `lib/features/<feature>/data/`: fontes de dados e implementações de repositório.
- `lib/features/<feature>/domain/`: entidades, contratos e casos de uso.
- `lib/features/<feature>/presentation/`: páginas, widgets e estado da feature.
- `docs/`: documentação de arquitetura, padrões e decisões do projeto.

Estrutura alvo sugerida para `lib/`:

- `lib/app.dart`
- `lib/main.dart`
- `lib/core/`
- `lib/features/auth/`
- `lib/features/requests/`
- `lib/features/profile/` ou `lib/features/account/` no lugar de `main_page`
- `lib/features/proposals/`
- `lib/features/chat/`
- `lib/features/payments/`
- `lib/features/reviews/`
- `lib/features/disputes/`

## Separações conceituais

### Core

`core` deve conter apenas o que é realmente global:

- constantes compartilhadas
- serviços reutilizáveis
- helpers e utilitários genéricos
- widgets reutilizáveis e neutros

Não deve conter regra de negócio de feature.

### Feature

Uma feature representa uma capacidade de negócio isolada. Ela não deve depender da estrutura interna de outra feature.

### Domain

Camada sem dependência de Flutter. Deve conter:

- entities
- contratos de repositório
- use cases

### Data

Camada de implementação dos contratos do domain. Deve conter:

- datasources
- repositories
- adapters para API, banco ou SDKs externos

### Presentation

Camada de interface. Deve conter:

- pages/screens
- widgets da feature
- state management da feature

## Regras de dependência

### Fluxos permitidos

- `presentation -> domain`
- `data -> domain`
- `presentation -> core` quando for algo realmente compartilhado
- `data -> core` quando usar serviços globais legítimos

### Fluxos proibidos

- `domain -> data`
- `domain -> presentation`
- `presentation -> data` diretamente
- importação cruzada entre features sem contrato claro

Se a presentation precisa de uma implementação de data, isso deve vir por provider, controller ou DI.

## SPA e navegação

Como o app é majoritariamente SPA, a navegação deve seguir alguns princípios:

- usar um shell único para a experiência autenticada
- centralizar o roteamento em um único lugar
- tratar autenticação como gate de entrada, não como navegação espalhada pela UI
- evitar trocar `home:` em múltiplos pontos do app
- evitar `Navigator.popUntil` como mecanismo principal de fluxo entre áreas do produto

A recomendação é que `app.dart` concentre o app shell e a navegação principal. Isso reduz acoplamento e torna o comportamento mais previsível.

## Estado e DI

- Repositórios, use cases e controllers devem ser expostos por providers ou um módulo de DI.
- Páginas não devem instanciar repositórios diretamente.
- Widgets devem ser finos e focados em apresentação.
- A regra geral é: composição fora da UI, consumo dentro da UI.

Para o caso atual, isso significa que `auth`, `requests` e `profile` devem receber dependências já preparadas, em vez de montar `RepositoryImpl` dentro da própria página.

## Como criar uma nova feature

Checklist prático:

1. Criar a pasta em `lib/features/<nova_feature>/`.
2. Separar `data`, `domain` e `presentation`.
3. Definir entidades e contratos no `domain` antes da implementação.
4. Implementar datasources e repositories no `data`.
5. Expor providers ou controllers na `presentation`.
6. Conectar a feature ao app shell sem importar detalhes internos de outras features.
7. Criar testes de regra de negócio e de interface quando necessário.

## Anti-padrões comuns

- Instanciar repositories dentro de páginas ou widgets.
- Colocar regra de negócio no `build` da UI.
- Fazer importação cruzada entre features sem abstração.
- Usar nomes genéricos como `main_page` para responsabilidade de perfil/conta.
- Manter múltiplos pontos de entrada de UI sem necessidade.
- Misturar refatoração estrutural com feature nova no mesmo escopo de mudança.

## Observações de nomenclatura

`main_page` existe hoje como nome de pasta, mas não descreve bem a responsabilidade real. Para o projeto, o nome mais correto é `profile` ou `account`.

Enquanto o refactor não acontecer, a documentação deve tratar esse módulo como a área de perfil/conta do usuário.
