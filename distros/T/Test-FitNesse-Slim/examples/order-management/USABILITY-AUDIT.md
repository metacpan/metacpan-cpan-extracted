# Usability audit

## Scope and method

`bin/test-example-order-management` performs repeatable authoring exercises
against a disposable FitNesse root. It adds a preferred-pricing boundary
row, adds an inventory boundary row, selects a different customer and adds
an expected order row to a query, creates a workflow page from existing
operations, enters an invalid quantity, and changes expected price and order
status values to force visible failures. The runner restores all edited pages
and removes the temporary page even when an exercise fails.

These checks establish that the wiki edits execute and that FitNesse reports
the resulting assertions. They are not a substitute for sessions with
business analysts or other nontechnical authors. No such participants were
available for this audit.

## Role-based findings

### Business analyst

Pricing and inventory boundaries are added as plain decision-table rows.
The domain is expressed in business terms, and currency uses familiar
decimal notation. A page can be extended without Perl edits when an existing
fixture operation covers the behavior. The import setup and the required
interposed words in script-table rows are FitNesse syntax details that need
an example or author guidance.

### QA analyst

Decision tables cover inclusive boundaries and rejected cases. Script checks
assert business rejection as `false` plus a message rather than relying on an
unexpected exception. Query expectations compare complete records and make
unordered matching clear; the replenishment page uses an ordered query
because priority order is meaningful. The runner verified that omitting an
expected inventory row produces a query mismatch, while adding expected
orders for another customer passes without fixture changes. Deliberately
changing a pricing expectation produced one wrong assertion localized to the
price cell. Changing the expected order status from `submitted` to `reserved`
produced one wrong status assertion; restoring it returned the workflow to
11 right assertions.

### Product owner

Page titles and prose state the behavior under review. A reader can follow a
draft order through reservation and submission and see the expected status.
The fixture still uses business identifiers such as SKU and customer ID;
authors need the example's small data catalogue to interpret those values.

### Perl maintainer

Pricing and store rules are independent of FitNesse. Fixtures are thin
adapters with explicit method signatures. Query adapters translate an array
of hash records into FitNesse query rows. This is a small amount of
FitNesse-specific shaping, but it keeps Perl data structures out of wiki
cells and avoids a demonstration-only hash-literal language. The wiki script
phrases contain connector cells (`quantity`, `to order`) needed to form
unambiguous fixture method names; that is the clearest usability friction
found in the script interface.

## Structured-data ergonomics

| Operation | Wiki form | Perl representation and adapter | Finding |
|---|---|---|---|
| Supply a simple record | Decision-table columns or script arguments | Fixture maps named cells to a hash-based domain record | Practical for flat records; authors do not write hash syntax |
| Supply an order with items | One script action per item, with a generated order symbol | Order hash owns an array of line-item hashes | Readable for workflows; no nested literal is needed |
| Return records | Query table with named headings | Array reference of hash references, mapped to `[field, value]` pairs | Natural in Perl; adapter has to translate to FitNesse's query shape |
| Compare without row order | `Query:` | Query result rows matched as a set by FitNesse | Good for inventory and order records where display order is irrelevant |
| Compare with row order | `Ordered query:` | Array order from the fixture is meaningful | Appropriate for replenishment priority |
| Reuse generated value | `$order` FitNesse symbol in later script actions | String order identifier; no Perl reference crosses into the wiki | Straightforward and hides object identity |
| Inspect an order field during a workflow | `check status of order $order submitted` or `check total of order $order 18.00` | Fixture reads the order hash by its reused business identifier | Readable for the fields this workflow needs; Perl fields do not appear in the table |
| Inspect fields in returned records | `OrdersForCustomer` query with named columns such as `status` and `total` | Query adapter maps an array of order hashes into FitNesse rows | Sufficient for displaying and matching several fields together |
| Read any field from a returned Perl hash object | No generic field expression or access table | The order suite uses query rows and named fixture operations | Not supported generically; no current business case requires it |
| Missing, null, and empty values | Blank query cells are wildcards; empty and null inputs are not interchangeable in the wiki | Perl distinguishes `undef`, `''`, and empty arrays, subject to FitNesse table semantics | The current suite avoids ambiguous blank cells; a dedicated authoring convention would be needed |
| Invalid input | A table row supplies zero quantity and checks a rejection message | Fixture returns false and stores a domain-level message | Understandable when business-invalid values remain type-valid inputs |

## Expression requirements

The examples below are concrete authoring needs, not a proposal to implement
an expression engine in this project.

| Priority | Natural author expression | Need | Current behavior and minimum useful semantics |
|---:|---|---|---|
| 1 | `quantity * unit price - discount + shipping` | Recalculate an expected order total | FitNesse v20251025 evaluates backtick expressions through its Nashorn JavaScript integration on the FitNesse side; Perl SLiM preserves expression text. For money, an optional facility would need explicit decimal/integer-cent rules and checked arithmetic, not JavaScript floating point. |
| 2 | `$expectedTotal` or ``$`order.total` `` | Compare an actual result with a previously stored result or a field | Ordinary symbol reuse is already supported. Field access uses Java-side expression evaluation; the smallest useful cross-language feature would be explicit named field extraction from declared record values, with missing-field behavior specified. |
| 3 | ``$`lines[0].sku` `` | Check a particular line in a returned order | Java evaluates indexing and property/member access in FitNesse; Perl does not. This overlaps structured-record access and could be met by a narrowly defined table operation rather than general expressions. |
| 4 | `available >= requested && customerEligible` | Express combined business conditions | Nashorn evaluates the current syntax in FitNesse. The demo instead reports the two business decisions through named fixture methods, which is more readable and avoids cross-backend coercion rules. |

The expression compatibility audit documents the Java implementation and its
Java object semantics in detail. The order suite avoids expressions for its
actual field checks: `$order` carries a readable business identifier into
named fixture methods, and query tables show record fields under business
headings. Scenarios reuse workflow steps but do not select record members.
These existing forms are sufficient for the present business rules.

For example, the workflow checks two fields without exposing the order hash:

```text
|check|status of order|$order|submitted|
|check|total of order|$order|18.00|
```

When several records and fields need inspection, the query presents the
record fields as named columns:

```text
|Query:orders for customer|C-100|
|order id|customer|status|total|
|ORD-022|C-100|submitted|23.00|
```

A generic accessor might instead require a table such as
`|check|field of record|$orderRecord|status|submitted|`. That form is not
currently supported and would require a raw hash value to survive
`callAndAssign`. It would also need explicit missing-key and undefined-value
rules. None of the nine business pages needs arbitrary key selection, so
adding that operation would create a second way to express checks without
reducing current wiki code. The evaluated result is therefore unchanged from
the existing interface: named operations for workflow state and query columns
for record collections. A future example with genuinely variable fields
should first test a direct-key helper against those requirements; no
general-purpose accessor belongs in the production distribution based on this
example alone.

In this implementation, `callAndAssign` formats an ordinary hash result for
FitNesse rather than retaining it as a raw record symbol. Existing
object-valued symbols remain useful for values whose typed sequence contract
retains a reference, but the order pages pass a business order ID instead.
Changing symbol retention or mutating a fixture to stash returned hashes
would add machinery solely to support an unused accessor. The disposable
authoring exercise confirms the current status check fails at exactly one
cell when its expected value changes and passes when restored.

## Collection requirements

The suite needs arrays and hashes, both of which Perl already represents
naturally. Unordered query matching is handled by FitNesse, and ordered
priority results are represented by array order. Inventory membership uses
ordinary domain lookups; order submission models FIFO or priority as a
business rule rather than requiring Java `Queue` conversion. No Set, Queue,
nested-generic, or additional collection protocol support was needed.

## Conclusion

The suite provides a workable interface for flat business decisions,
multi-step workflows, generated identifiers, and record queries. The
disposable authoring exercise shows that a status expectation is localized
to one wrong assertion and passes again when restored. Existing query and
domain-specific fixture operations cover the fields required by this
example; generic arbitrary-member access remains unavailable. The main
observed syntax friction is script-table method-name construction and setup
syntax. Human usability remains unverified until nontechnical authors use
the pages.
