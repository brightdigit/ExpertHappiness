# CLAUDE.md

ExpertHappiness: a Swift package + CLI (`expert-happiness`) for App Store Connect Analytics Reports. Set up like MistKit.

## Layout

- `openapi.json` is Apple's App Store Connect spec (v4.5.1). `openapi-generator-config.yaml` filters it to the operations used here.
- `Sources/AppStoreConnectOpenAPI/` is **generated and committed**. Never hand-edit it. Run `make generate`. CI fails if it drifts.
- `Sources/ExpertHappiness/` is the hand-written library:
  - `Authentication/`: ES256 JWT (raw r‖s signature), token caching, the bearer middleware
  - `OpenAPI/`: error and logging middleware
  - `Service/`: the `AnalyticsService` extensions
  - `Reports/`: download, TSV parsing, the archive and summaries
- `Sources/ExpertHappinessCLI/` is the executable. It uses ConfigKeyKit commands and a swift-configuration `ConfigReader` (CLI flags, then environment).
- `Tests/ExpertHappinessTests/` uses Swift Testing, with a `MockTransport` keyed by operationID and TSV fixtures.

## Commands

Run tools through mise: `mise exec -- <tool>`, or use `make`.

- `make build`, `make test`, `make lint`, `make generate`
- Swift 6.4 toolchain (`swift-tools-version: 6.4`)

## Rules

- **Credentials:** `ASC_PRIVATE_KEY` (inline PEM string, literal `\n` allowed) is the primary option. `ASC_PRIVATE_KEY_PATH` is the fallback, and the string wins if both are set. Recommend `.env` or environment variables over flags. Never read, print or commit a `.p8`, a `.env` or any key value.
- **Config precedence:** command line, then the process environment, then `.env` (`--env-file` overrides `./.env`; a missing file is fine). `.env` is parsed by `DotEnvFile`, not swift-configuration's parser, because that one keeps surrounding quotes. `.env.example` is committed, and `.gitignore` has `!.env.example`.
- **Pagination:** list calls use `limit=200` and throw `AnalyticsError.truncated` on a `links.next`. The generated client has no cursor parameter. Instance queries chunk processing dates in batches of 200.
- **Restated data:** summaries keep each data date's rows from the latest processing date only.
- **Conventions:** one type per file, explicit access control, `Type+Feature.swift` names, and the MIT header (`Scripts/header.sh`, run by `make lint`).
- **CI:** GitHub Actions trigger on `pull_request` only.
