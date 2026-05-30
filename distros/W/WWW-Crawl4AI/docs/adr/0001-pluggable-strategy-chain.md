# Strategy chain as pluggable object registry

The strategy chain was previously a hardcoded `@CHAIN_CLASSES` array in `WWW::Crawl4AI`. Strategies were instantiated in bulk and filtered by `applicable`. Adding a custom strategy or changing order required editing the module.

Replaced by `WWW::Crawl4AI::StrategyChain` — a first-class object holding the strategy list. Strategies live in the object, not in global variables. `WWW::Crawl4AI` holds a `strategy_chain` attribute. Subclasses can override `_build_strategy_chain` to change defaults. Runtime mutation via `add_strategy` / `remove_strategy` / `replace_strategy`.

Also extracted `WWW::Crawl4AI::DeepCrawlIterator` from the inline BFS loop, enabling alternative crawl orders and isolated testing of frontier logic.