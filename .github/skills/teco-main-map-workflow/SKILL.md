---
name: teco-main-map-workflow
description: 'Build and evolve TECO main map page using Feature-First + Clean Architecture. Use for map UI work, open requests integration, strict RPC list_requests_with_geojson consumption, GeoJSON lon/lat parsing, 25km filtering, and flutter analyze/test validation.'
argument-hint: 'Iteration goal (for example: map shell, RPC integration, GeoJSON parser hardening, 25km rule validation)'
user-invocable: true
---

# TECO Main Map Workflow

## Scope
Map area only. This skill covers the TECO main map page and its direct request-map integration workflow.

## Outcome
Deliver a working map-page iteration that preserves:
- Feature-First + Clean Architecture layout.
- Material-based top and bottom shell components.
- Strict open-request ingestion from RPC plus GeoJSON parsing.
- 25km business rule enforcement and project validation gates.

## When To Use
Use this skill when you need to:
- Create or refactor the main map page.
- Integrate open requests into map markers.
- Parse GeoJSON location payloads from RPC responses.
- Enforce request-radius filtering around the main user point.

## Required Inputs
- Iteration objective (UI shell, data, refactor, validation).
- Confirmed backend contract for current RPC payload.
- Confirmation that RPC name is `list_requests_with_geojson` (or explicitly updated contract).

## Workflow
1. Confirm iteration scope is map-only.
2. Confirm contract before coding:
   - Source: RPC `list_requests_with_geojson`.
   - Required fields per row: `id`, `title`, `status`, `location_geojson`.
   - GeoJSON Point coordinates format: `[lon, lat]`.
3. Map target files and keep boundaries clean:
   - `lib/app.dart`
   - `lib/main.dart`
   - `lib/features/requests/data/...`
   - `lib/features/requests/domain/...`
   - `lib/features/requests/presentation/...`
4. Implement data-layer changes with strict parsing:
   - Call RPC explicitly.
   - Parse latitude/longitude from GeoJSON coordinates.
   - Throw a clear error for invalid or missing location payload.
5. Implement business rules:
   - Keep only open requests.
   - Keep only requests within 25km radius from main point.
6. Implement/adjust presentation:
   - Render `flutter_map` markers for user point and requests.
   - Keep Material top/bottom bars as requested (no scope creep).
7. Run quality checks:
   - `flutter analyze`
   - `flutter test`
   - Manual map sanity check (centering, markers, radius behavior).
8. Summarize change delta:
   - Files touched.
   - Contract assumptions.
   - Remaining follow-up items.

## Branching Rules
- If RPC/schema contract changed or is uncertain:
  - Stop implementation and request explicit contract alignment.
  - Do not add schema heuristics or alternate field fallbacks.
- If device location is unavailable:
  - Use the project-defined fallback location.
- If request is UI-only:
  - Do not add navigation/auth/domain extensions unless explicitly requested.

## Quality Gate (Definition Of Done)
- Architecture remains in `features/requests` with clear data/domain/presentation split.
- No heuristics for schema fields or status mapping.
- GeoJSON parsing uses `[lon, lat]` correctly.
- 25km filter rule is applied.
- `flutter analyze` reports no issues.
- `flutter test` passes.

## Common Pitfalls
- Reversing latitude/longitude from GeoJSON coordinates.
- Leaking data logic into presentation widgets.
- Reintroducing schema fallback logic after contract mismatch.
- Expanding scope beyond map area tasks.

## Example Prompts
- `/teco-main-map-workflow Integrate map markers from list_requests_with_geojson using strict GeoJSON parsing.`
- `/teco-main-map-workflow Refactor map page while preserving open-only and 25km filtering rules.`
- `/teco-main-map-workflow Update top and bottom Material bars without touching data contract logic.`
