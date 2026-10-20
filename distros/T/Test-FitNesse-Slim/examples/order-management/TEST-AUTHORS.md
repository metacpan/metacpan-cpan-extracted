# Guide for FitNesse test authors

The suite is organized around decisions a store team can recognize: pricing,
stock availability, order submission, and inventory reporting. A page's
tables state inputs and expected results; the Perl method names are not shown.

## Add a business example

To test a new pricing boundary, add a row to `OrderManagementSuite.Pricing`:

```text
|preferred|25.00|2.50|5.00|27.50|
```

The columns are customer tier, merchandise subtotal, expected discount,
expected shipping, and expected total. Money uses decimal notation with up to
two fractional digits. The domain stores integer cents, but the wiki does not
expose that implementation detail. The fixture already supports each row, so
adding this case requires no Perl change.

Add an inventory boundary by adding a SKU and requested quantity row to
`OrderManagementSuite.InventoryAvailability`. Add a result record to either
inventory query table using its visible column headings. The standard query
ignores row order; the replenishment-priority query checks the business order
from least available stock to most available.

The `OrderLifecycle` page also includes a reusable scenario for submitting a
small eligible order. A workflow can use the scenario and then add further
business checks in the same script table. For example, its scenario call uses
customer, product, and quantity values; a generated order number is carried
between steps by a FitNesse symbol. The symbol is a readable identifier such
as `ORD-001`, not a Perl reference.

## Read a failure

Decision and query tables mark the specific expected cell or row that differs.
Script checks show the expected and actual result. Negative business cases
check a false result and a message such as `Quantity must be a positive whole
number.` Invalid fixture syntax or a value that cannot be converted to the
declared type appears as a SLiM exception; that indicates an input/fixture
problem rather than an expected business rejection.

FitNesse can show large or nested query results, but this suite keeps columns
flat and business-named. It does not ask test authors to write Perl hashes,
array literals, or serialized SLiM values.

## Usability boundary

The existing interface supports adding decision rows, script steps, query
expectations, and scenario calls without changing application code. A new
business operation still requires a fixture adapter, written with a Perl
developer. This example has not been evaluated by nontechnical participants;
the authoring exercises in `USABILITY-AUDIT.md` are a reproducible inspection,
not evidence of user research.
