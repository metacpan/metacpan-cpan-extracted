use strict;
use Test::More tests => 2;

my $class;
my @tests = qw( t/URI-Find-Rule.t );
BEGIN {
    $class = 'URI::Find::Rule';
    use_ok($class)
}

my $f = $class->new;
isa_ok($f, $class);
