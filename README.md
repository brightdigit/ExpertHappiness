# ExpertHappiness

A Swift package and command-line tool that pulls App Store Connect **Analytics Reports** for your apps: impressions, page views and downloads by source, purchases and proceeds, and subscription states and events. It prints them as Markdown totals.

It's built the same way as [MistKit](https://github.com/brightdigit/MistKit). The OpenAPI client is generated ahead of time from Apple's App Store Connect spec and committed. The hand-written library wraps it with JWT auth and error handling, and the CLI reads its settings through swift-configuration and ConfigKeyKit.

## What it can't get

- **watchOS:** App Store Connect analytics don't count watchOS downloads or usage. Subscriptions bought on the Watch do appear in the subscription reports.
- **Dashboard-only metrics:** Download to Paid, Cohorts and Benchmarks aren't in any API.
- **MRR:** no report has it. Work it out from paid plans × price.

## Setup

1. In App Store Connect, go to **Users and Access → Integrations → App Store Connect API → Team Keys**. Create a key with the **Admin** role, which is needed to create report requests. Download the `.p8`, and note the **Key ID** and **Issuer ID**.
2. Copy `.env.example` to `.env` in the package root and fill it in. `.env` is git-ignored. Put the private key on **one line**, in quotes, with each newline written as `\n`:

   ```sh
   cp .env.example .env
   ```

   ```dotenv
   ASC_KEY_ID=XXXXXXXXXX
   ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ASC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIG...\n-----END PRIVATE KEY-----"
   ```

   Settings are read from three places, and the first one that has a value wins:
   1. command-line flags
   2. the process environment
   3. `.env`, or another file given with `--env-file <path>`. A missing file is fine.

   Use `.env` or environment variables for the key, not flags. Flags end up in shell history and `ps`.

   | Variable | Flag | Notes |
   |---|---|---|
   | `ASC_KEY_ID` | `--asc-key-id` | |
   | `ASC_ISSUER_ID` | `--asc-issuer-id` | |
   | `ASC_PRIVATE_KEY` | `--asc-private-key` | **Preferred.** Inline PEM, with literal `\n` allowed. Redacted from logs. |
   | `ASC_PRIVATE_KEY_PATH` | `--asc-private-key-path` | Fallback: a path to the `.p8`. If both are set, `ASC_PRIVATE_KEY` wins. |
   | `ASC_APP` | `--app` | An app ID or bundle ID |
   | `ASC_REPORTS_DIR` | `--output` | Where downloads go. Defaults to `./Reports`, which git ignores. |
   | `ASC_SUMMARY_CONFIG` | `--summary-config` | A JSON file of summaries (see below). Picks the reports `download` fetches and how `summary` totals them. |
   | | `--env-file` | Defaults to `./.env` |

   Never commit a key. `.gitignore` excludes `.env`, `.env.*` (except `.env.example`), `*.p8` and `/Keys/`.

## Usage

```sh
swift run expert-happiness apps                                    # check the key; list app IDs and bundle IDs
swift run expert-happiness request --app com.example.App          # ONGOING + ONE_TIME_SNAPSHOT; safe to rerun
# wait 1–2 days for the first reports
swift run expert-happiness status   --app com.example.App
swift run expert-happiness download --app com.example.App --from 2026-09-27 --to 2026-11-02 --summary-config summaries.json
swift run expert-happiness summary  --app com.example.App --from 2026-09-27 --to 2026-11-02 --summary-config summaries.json
```

- `download` saves `Reports/<bundle ID>/<report>/<processing date>-<segment>.tsv`. It fetches processing dates through `--to` plus 5 days, because Apple sometimes restates a day after the fact. Files already on disk are skipped.
- `summary` works offline from those files. It counts each restated day once, using the latest processing date. "Unique Counts" are summed per day, so across a range they overstate unique devices.
- `finance` downloads monthly finance reports (Admin or Finance key, plus `ASC_VENDOR_NUMBER`) to `Reports/finance/<yyyy-MM>.tsv` and prints proceeds per month, product and currency. With no flags it covers the last 12 complete months, and months already on disk aren't downloaded again.
- `download` needs either `--summary-config` or `--report "<name contains>"`, because each app has well over 100 reports. `status` without either lists every report name.
- Without `--summary-config`, `summary` prints one table per downloaded report, totaling every numeric column except dates and IDs.

### Summary configuration

A summary file lists the tables you want. Only `title` and `reportNameContains` are required.

```json
{
  "summaries": [
    {
      "title": "Impressions and page views by source",
      "reportNameContains": "Discovery and Engagement",
      "reportNameExcludes": "Detailed",
      "groupBy": ["Event", "Source Type"],
      "values": ["Counts", "Unique Counts"]
    },
    {
      "title": "Subscription states (latest day in range)",
      "reportNameContains": "Subscription State",
      "groupBy": ["State Metric"],
      "latestDateOnly": true
    }
  ]
}
```

| Field | Meaning |
|---|---|
| `title` | The table heading. |
| `reportNameContains` | Text the report name must contain, ignoring case. Run `status` to see the names. |
| `reportNameExcludes` | Text the report name must not contain, e.g. `"Detailed"` to keep only the Standard report. |
| `groupBy` | Columns to group rows by. Missing columns are listed under the table, not guessed. |
| `values` | Columns to sum. Leave it out to sum every numeric column except dates and IDs. |
| `latestDateOnly` | Total only the latest day in the range. Use this for point-in-time counts like subscription states. |

## Development

Tools are pinned in `mise.toml`. Run `mise install` once to install them.

```sh
make build      # swift build
make test       # swift test (Swift Testing)
make lint       # swift-format, SwiftLint, header check, periphery
make generate   # regenerate Sources/AppStoreConnectOpenAPI from openapi.json
```

To expose another endpoint, add its `operationId` to the `filter` in `openapi-generator-config.yaml` and run `make generate`. Apple's spec has 1,001 paths, and the filter keeps the generated code to what this tool uses.
