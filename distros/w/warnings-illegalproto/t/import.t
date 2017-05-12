use strict;
use Test::More;

no warnings;
use warnings::illegalproto;

my $warn;
$SIG{__WARN__} = sub { $warn = $_[0] };

my $x = eval "sub (frew) { 1 }";
like $warn, qr/prototype/, 'dies on "bad" prototype';

undef $warn;
eval 'my $f = undef . "foo"';
is $warn, undef, 'other warnings not enabled';

done_testing;
