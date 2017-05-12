
package MoState;

use Mo qw(required);

has 'name' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'capital' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'population' => (
  is        => 'rw',
  isa       => 'Int',
  required  => 1,
);

1;# return true:

