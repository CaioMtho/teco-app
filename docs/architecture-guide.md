# Guia de Estrutura e Padrões

Este documento descreve a organização do projeto e os princípios adotados para manter consistência arquitetural utilizando Feature-First combinado com Clean Architecture. O objetivo é garantir previsibilidade, baixo acoplamento e alta coesão entre as partes do sistema.

## Visão geral da estrutura

A base do projeto é organizada em torno de três pilares principais:

- ponto de entrada da aplicação
- núcleo compartilhado (`core`)
- features isoladas por domínio de negócio

Estrutura base:

- `lib/main.dart`: responsável exclusivamente pelo bootstrap da aplicação. Inicializa dependências globais e executa o widget raiz.
- `lib/app.dart`: composição do aplicativo. Define tema, rotas, navegação e estrutura principal da UI.
- `lib/core/`: contém código compartilhado e independente de features.
- `lib/features/`: contém todas as funcionalidades organizadas por domínio.

## Organização por feature

Cada feature segue uma divisão interna baseada em camadas:

- `data/`
- `domain/`
- `presentation/`

Exemplo:

```
lib/features/<feature>/
  data/
  domain/
  presentation/
```

Essa separação não é estética; ela define limites claros de responsabilidade e dependência.

---

## Camadas em detalhe

### Domain

É a camada central da aplicação.

Características:

- não depende de Flutter
- não depende de bibliotecas externas de infraestrutura
- representa regras de negócio puras

Contém:

- **Entities**: modelos de negócio (ex: User, Request)
- **Repository Contracts**: interfaces que definem como os dados são acessados
- **Use Cases**: regras de negócio explícitas e reutilizáveis

#### Use Case

Um use case representa uma ação do sistema.

Exemplo conceitual:

- `CreateRequest`
- `GetUserProfile`
- `SendMessage`

Ele:

- orquestra entidades
- utiliza repositórios
- não sabe como os dados são obtidos

---

### Data

É a camada responsável por implementar o acesso a dados.

Contém:

- **Datasources**
- **Repository Implementations**
- **Adapters (API, banco, SDKs)**

#### Datasource

Um datasource é a fonte bruta de dados.

Ele representa **como** os dados são obtidos.

Tipos comuns:

- remoto (API REST, Supabase, GraphQL)
- local (SQLite, cache, storage)

Responsabilidades:

- fazer chamadas externas
- lidar com serialização (JSON ↔ objeto)
- tratar erros de transporte

Importante:

- não contém regra de negócio
- não conhece use cases
- não conhece UI

Exemplo:

```
class RequestsRemoteDatasource {
  Future<List<RequestModel>> fetchRequests();
}
```

#### Repository

O repository é uma camada de abstração entre o domain e os datasources.

Ele representa **o que** pode ser feito com os dados, não **como**.

Diferença central:

- datasource → implementação técnica
- repository → contrato orientado ao domínio

Responsabilidades:

- implementar contratos definidos no `domain`
- decidir de onde os dados vêm (cache, API, etc.)
- combinar múltiplos datasources se necessário
- mapear modelos (`Model`) para entidades (`Entity`)

Exemplo conceitual:

```
class RequestsRepositoryImpl implements RequestsRepository {
  final RequestsRemoteDatasource remote;

  Future<List<Request>> getRequests() async {
    final data = await remote.fetchRequests();
    return data.map((e) => e.toEntity()).toList();
  }
}
```

---

### Presentation

É a camada de interface com o usuário.

Contém:

- páginas (screens)
- widgets
- gerenciamento de estado (providers, controllers, etc.)

Responsabilidades:

- renderizar UI
- reagir a eventos do usuário
- consumir use cases

Importante:

- não acessa datasource diretamente
- não implementa regra de negócio
- não instancia repositórios manualmente

Fluxo típico:

```
UI → UseCase → Repository → Datasource
```

---

## Core

A pasta `core` deve conter apenas elementos realmente compartilhados.

Inclui:

- constantes globais
- serviços reutilizáveis (ex: logger, client HTTP)
- utilitários genéricos
- widgets reutilizáveis neutros

Restrições:

- não deve conter lógica específica de feature
- não deve crescer descontroladamente (evitar virar “pasta genérica”)

---

## Regras de dependência

A arquitetura impõe direcionalidade clara nas dependências.

### Permitido

- `presentation → domain`
- `data → domain`
- `presentation → core`
- `data → core`

### Proibido

- `domain → data`
- `domain → presentation`
- `presentation → data` diretamente
- dependência direta entre features sem abstração

Essas regras garantem:

- testabilidade
- isolamento de regras de negócio
- facilidade de manutenção

---

## Navegação e estrutura SPA

A aplicação segue um modelo majoritariamente SPA.

Princípios:

- um único ponto de composição da navegação
- shell principal consistente
- controle centralizado de rotas
- autenticação tratada como gate de entrada

Evitar:

- múltiplos pontos de definição de `home`
- lógica de navegação espalhada em widgets
- uso excessivo de manipulação manual de stack (`popUntil`, etc.)

---

## Injeção de dependência (DI)

Dependências devem ser resolvidas fora da UI.

Diretrizes:

- repositórios e use cases expostos via providers ou container de DI
- páginas recebem dependências prontas
- widgets não criam implementações concretas

Regra prática:

- composição fora da UI
- consumo dentro da UI

---

## Fluxo completo de dados

Exemplo do fluxo padrão:

1. usuário interage com a UI
2. a UI chama um use case
3. o use case chama um repository (interface)
4. o repository (implementação) acessa um datasource
5. o resultado sobe de volta até a UI

Representação:

```
Presentation → UseCase → Repository → Datasource
```

---

## Criação de novas features

Processo recomendado:

1. criar `lib/features/<feature>/`
2. estruturar em `data`, `domain`, `presentation`
3. definir entidades e contratos primeiro
4. implementar datasources
5. implementar repositories
6. criar use cases
7. integrar com a UI via providers
8. conectar ao sistema de navegação

---

## Anti-padrões

Evitar:

- instanciar repository dentro de widget
- colocar regra de negócio na UI
- acoplamento direto entre features
- uso de nomes genéricos para módulos
- mistura de responsabilidades entre camadas
- acesso direto a API dentro da presentation

---