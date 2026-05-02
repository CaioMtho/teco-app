# TECO Copilot Instructions

## 1. Architecture Rules
- Use Feature-First combined with Clean Architecture.
- Organize features strictly under `lib/features/<feature>/` with three internal layers: `data/`, `domain/`, and `presentation/`.
- **Domain Layer**: Contains Entities, Repository Contracts, and Use Cases. Must contain pure business rules. Must NOT depend on Flutter or external infrastructure libraries.
- **Data Layer**: Contains Datasources and Repository Implementations. Datasources handle raw data fetching and serialization (JSON ↔ object). Repositories implement domain contracts and map Data Models to Domain Entities.
- **Presentation Layer**: Contains pages, widgets, and state management. Renders UI and consumes Use Cases. Must NOT access datasources directly, implement business logic, or manually instantiate repositories.
- **Core (core)**: Reserved for globally shared constants, services, generic utilities, and neutral widgets. Must NOT contain any feature-specific logic.
- **Dependency Direction Rules**:
  - Allowed: `presentation → domain`, `data → domain`, `presentation → core`, `data → core`.
  - Forbidden: `domain → data`, `domain → presentation`, `presentation → data`, and direct feature-to-feature dependencies without abstraction.

## 2. Coding Standards
- **File Organization**: main.dart is exclusively for application bootstrap. app.dart is for app composition, themes, routing, and main UI structure.
- **State Management & DI**: Resolve dependencies outside the UI (via providers or DI containers). UI must consume injected abstractions only.
- **Navigation**: Follow a Single Page Application (SPA) model. Use a centralized routing control and a consistent main shell. Treat authentication as an entry gate. Avoid scattered navigation logic and excessive manual stack manipulation (e.g., `popUntil`).
- **Forbidden Patterns**: Do not instantiate repositories inside widgets. Do not place business logic in the UI. Do not couple features directly.

## 3. Backend/API Contract Rules
- **Backend Stack**: Use Supabase for the backend infrastructure, including PostgreSQL, Supabase Auth, Storage, Realtime (for chat), and Edge Functions (Deno).

## 4. UI/Frontend Constraints
- Maintain a consistent main shell for the application structure.
- Expose repositories and use cases via providers to the UI; widgets must consume these abstractions rather than implementing technical data fetching.

## 5. Agent Operational Constraints
- Never expand scope implicitly.
- Never introduce architectural changes without explicit request.
- Never add undocumented fallback logic.
- Request clarification when contracts are ambiguous.
- Preserve existing architecture boundaries.
- Prefer minimal diffs and localized changes.

## 6. Validation & Quality Gates
- `flutter analyze` must pass.
- `flutter test` must pass.
- Avoid dead code.
- Avoid unused imports.
- Preserve lint cleanliness.