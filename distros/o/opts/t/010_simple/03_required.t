use strict;
use warnings;
use opts;
use Test::More;
use Test::Exception;

@ARGV = qw(--p=3 --q=2);
is foo(), 3;
@ARGV = qw(--q=2);
is foo(), 2;
@ARGV = qw(--p=2);
throws_ok {foo()} qr/missing mandatory parameter named '\$q'/;

done_testing;
exit;

sub foo {
    opts my $p => { isa => 'Int' },
         my $q => { isa => 'Int', required => 1 };
    return $p ? $p : $q;
}
