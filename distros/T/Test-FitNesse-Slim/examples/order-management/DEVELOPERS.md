# Developer guide

`lib/OrderManagement/` contains the domain model. `Store` owns customer,
product, inventory, and order hashes. An order contains a hash record and an
array of line-item hashes. `Pricing` is a pure calculation over customer tier
and integer-cent subtotal. Neither module imports FitNesse or SLiM code.

`lib/OrderManagement/Fixtures/` contains thin adapters. Each adapter creates a
fresh domain store, translates table calls to domain methods, and declares
typed method signatures where values need conversion. For example,
`OrderWorkflow::add_item` declares `String`, `Integer`, and `String` inputs;
the domain receives an SKU, a numeric quantity, and an order identifier.
Query fixtures transform domain array-of-hash records to FitNesse's existing
query-table shape: rows of `[field, value]` pairs. No wire or converter changes
are used.

The workflow fixture stores only the current table's store and last business
error. The domain owns order status, lines, totals, and inventory reservations.
The tests check rejected operations through return values and error text.
Unexpected exceptions remain visible to FitNesse.

To add an operation, first add and test a domain-level method, then expose it
with a fixture method and explicit signature if conversion is needed. Keep
FitNesse terms out of domain modules. Use query fixtures only for translating
collections into FitNesse's row/field format.

The scenario library is wiki-level reuse, not Perl code. It invokes existing
workflow fixture operations and passes values using FitNesse scenario
parameters and symbols.
