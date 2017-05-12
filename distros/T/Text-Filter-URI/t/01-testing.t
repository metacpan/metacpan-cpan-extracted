#!perl -T

use Test::More tests => 5;
use Text::Filter::URI qw(filter_uri);


is(filter_uri(" Test - foo ---__ bar"), "test-foo-bar");
is(filter_uri(" Test - \n\n foo ---__ bar"), "test-foo-bar");

is_deeply([filter_uri("testAR24 Ü8", "Üasd\n")], ["testar24-u8", "uasd"]);

my @bar = ();
my $f = Text::Filter::URI->new(input => "t/00-load.t", output => \@bar);
$f->filter;

is($bar[0], "perl-t");

@bar = ();
$f = Text::Filter::URI->new(separator => '_', input => ["test case with underscore"], output => \@bar);
$f->filter;

is($bar[0], "test_case_with_underscore");
print @bar.$/;
