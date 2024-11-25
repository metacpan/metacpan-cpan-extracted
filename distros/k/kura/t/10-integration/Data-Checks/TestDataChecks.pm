package TestDataChecks;

use Exporter 'import';
use Data::Checks qw(StrEq);

use kura Foo => StrEq('foo');

1;
