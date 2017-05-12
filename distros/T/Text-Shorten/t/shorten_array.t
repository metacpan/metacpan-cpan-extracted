use Text::Shorten;
use Test::More tests => 8;
use strict;
use warnings;

my @q = (-500 .. 500);
my @r = Text::Shorten::shorten_array( [ @q ], 100);
my $r = join ',', @r;
print length($r), ":$r\n";
ok(length($r) <= 100);

@r = Text::Shorten::shorten_array( \@q, 100, 1, 400 .. 405);
$r = join ',', @r;
print length($r), ":$r\n";
ok(length($r) <= 100);

$r = join ',', Text::Shorten::shorten_array( [ 'a' x 20, 'b' ], 20 );
print length($r), ":$r\n";
ok(length($r) <= 20 + 4);

$r = join ',', Text::Shorten::shorten_array( [ 'a' x 20 ], 10 );
print length($r), ":$r\n";
ok(length($r) <= 20);

@r = Text::Shorten::shorten_array( [ ], 20 );
$r = join ',', @r;
$r = '' if not defined $r;
print length($r), ":$r\n";
ok(length($r) <= 20);

@r = Text::Shorten::shorten_array( \@q, 20, 1, 300 );
$r = join ',', @r;
ok($r =~ /,-200,/, 'shorten_array respects single key') or diag($r);

@r = Text::Shorten::shorten_array( \@q, 50, 1, 300..400);
$r = join ',', @r;
ok($r =~ /,-200,/ && $r =~ /,-100,/, 'shorten array respects multiple keys');
ok(length($r) > 20, ' ... even at the expense of output length') or diag($r);
