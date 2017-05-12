package Bar;

our $VERSION = 0.04;

use version::Restrict (
    "[0.0.1,0.03)" => "broken versions",
);
