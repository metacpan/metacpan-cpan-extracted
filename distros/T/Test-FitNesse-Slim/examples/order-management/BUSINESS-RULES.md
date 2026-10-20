# Business rules

The example is a deterministic in-memory order service. Each fixture receives
a fresh store, so a page cannot depend on test execution order or data left by
another page.

## Customers

- `C-100` is an active preferred customer.
- `C-200` is an active standard customer.
- `C-300` is an inactive preferred customer.
- Only active customers may reserve inventory or submit orders.

## Pricing

- Wiki amounts use decimal currency notation with up to two fractional digits.
  The application parses them exactly into integer cents and formats results
  with two digits after the decimal point.
- Preferred customers receive a 10% merchandise discount when merchandise
  subtotal is at least 2,000 cents. The discount is truncated to whole cents.
- Standard customers receive no merchandise discount.
- Shipping is free when the amount after discount is at least 5,000 cents;
  otherwise shipping costs 500 cents.
- Total equals merchandise subtotal minus discount plus shipping.

## Inventory and orders

- Initial on-hand quantities: COFFEE 10, TEA 5, MUG 2.
- The initial order history contains three submitted orders. Customer
  `C-100` has `ORD-022`, totaling $23.00.
- An order starts as `draft`; only positive whole quantities of known products
  can be added while it is a draft.
- Reservation checks every line before changing inventory. If any line lacks
  stock, no inventory is reserved and the order remains a draft.
- A nonempty order must reserve its inventory before submission.
- Successful submission changes status from `reserved` to `submitted`.
- A rejected business operation returns a false result and a readable message;
  it is not an unexplained FitNesse exception.

The fixture exposes these rules through ordinary business inputs and outputs.
The Perl application stores records as hashes and order lines as an array of
hashes. It has no database, network service, clock dependency, or floating
point money arithmetic.
