# WWW::Crawl4AI

## Language

**Strategy Chain**: Ordered list of strategies that process a URL in sequence. Each strategy is a different way to fetch and classify content. The first strategy that returns a "good" page wins. Order: Plain → Browser → Stealth → CloakBrowser → Proxy → Callback.

**Strategy**: A single step in the chain. Implements `WWW::Crawl4AI::Strategy` role. Has `name` (backend identifier), `cost_class` (cheap/browser/stealth/paid), `applicable` (gate for conditional inclusion), and `crawl` (fetch logic). Strategies are Pluggable — replace or extend via `StrategyChain` object or subclass.

**Classification**: Decision of whether a fetched page is "good enough." Runs via `signals($page)` → `{ js_required, blocked, captcha, thin_html, http_error }` and `is_good($page)`. Can be overridden via `classify_signals` / `classify_why_failed` methods in a subclass of `WWW::Crawl4AI`.

**Attempt**: A single strategy execution. Records `backend`, `cost_class`, `ok` (bool), `page`, `signals`, `why_failed` (token like bot_wall_detected / captcha / thin_content), `error`, `elapsed`. Every strategy run becomes an Attempt, giving full transparency on why the chain stopped or continued.

**Result**: The final output of `crawl()` / `markdown()`. Contains `ok`, `url`, `final_url`, `markdown`, `html`, `title`, `backend`, `cost_class`, `signals`, `why_failed`, `error`, `attempts` (array of Attempt objects). Never undef — on total failure `ok == 0` with `why_failed` explaining the last attempt.

**DeepCrawl**: BFS traversal following each page's links through the full strategy chain. Returns arrayref of Result in visit order. Options: `max_pages`, `max_depth`, `same_host`, `url_filter`, `on_page`.

**Error**: Structured error with `type` (transport / api / job / content). Boolean helpers: `is_transport`, `is_api`, `is_job`, `is_content`. Stringifies to `message`. `transport` = can't reach server. `api` = HTTP error or malformed body. `job` = async job FAILED. `content` = every strategy failed classification.

**Action Endpoints**: Single-URL operations bypassing the strategy chain. `screenshot` / `pdf` (raw bytes), `html` (preprocessed string), `execute_js` (page + js_result), `llm` (answer string), `token` (JWT hash). Useful for one-shot operations without escalation logic.

## Relationships

- A **crawl()** call runs the **Strategy Chain** — each **Strategy** in sequence produces an **Attempt**
- An **Attempt** passes through **Classification** (Detect or custom). If `is_good` → that **Strategy** wins, **Result** is built from the Attempt
- If no Strategy wins → **Result** with `ok == 0`, `error` of type `content`, `why_failed` from the last Attempt
- **DeepCrawl** applies **crawl()** to a start URL then recursively to each discovered URL's links
- **Action Endpoints** are independent of the chain — called directly on the Client

## Example dialogue

> **Dev:** "I called `deep_crawl` and got back a Result with `ok == 0` — what happened?"
> **Docs:** "The chain ran every applicable Strategy against the start URL. None passed `is_good` classification. Look at `result->why_failed` — it tells you which signal failed (bot_wall_detected, thin_content, etc.). `result->attempts` shows each Strategy that ran and why it failed."

> **Dev:** "Can I add my own Strategy?"
> **Docs:** "Yes. Subclass `WWW::Crawl4AI::StrategyChain` and pass it to `WWW::Crawl4AI->new(strategy_chain => $my_chain)`. Or override `_build_strategy_chain` in a subclass of WWW::Crawl4AI. Use `add_strategy` / `remove_strategy` / `replace_strategy` at runtime."

> **Dev:** "One of my pages has a very specific quality bar — can I use a different classifier?"
> **Docs:** "Yes. Subclass WWW::Crawl4AI and override `classify_signals` and `classify_why_failed`. They receive the page hash and detect opts, return the signals hash and failure token. All Attempt construction goes through them."

## Flagged ambiguities

- "callback" used for two different things: `callback` attribute (user coderef for external escalation strategy) and `external_callback` strategy name. Resolved: the attribute is the configuration, the strategy is the derived backend name.
- "client" refers to `WWW::Crawl4AI::Client` (REST layer) in most contexts, but `Net::Async::Crawl4AI` also has a `client` method that returns the underlying WWW::Crawl4AI::Client. Distinction: high-level orchestrator vs low-level HTTP dispatch.