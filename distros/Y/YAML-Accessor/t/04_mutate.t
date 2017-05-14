use Test::More tests => 5;

use YAML::Accessor;
our $yml = './testdata/testdata.yaml';

ok( -e $yml );

my $ya = YAML::Accessor->new(
	file => $yml,          # is not a filehandle.
	autocommit => 0,       # This is a default. Can be 1 (true).
	readonly   => 0,       # This is a default. Can be 1 (true).
	damian     => 1,       # See below. Can be 0 (false).
);

ok( $ya );
my $original = $ya->get_string();
ok( $original );
$ya->set_string( "$original set" );
my $new = $ya->get_string();
ok( $new );
# This doesn't autocommit. That's another test.
ok( $new eq "$original set" );
