use strict;
use warnings;
use opts;
use Test::More;
use Test::Exception;

@ARGV = qw(--foo=3);
is foo(), 6;
@ARGV = qw(--foo=3.14);
throws_ok { foo() } qr/Value "3.14" invalid for option foo \((integer )?number expected\)/;
done_testing;
exit;

sub foo {
    opts my $foo => 'Int';
    $foo*2;
}
