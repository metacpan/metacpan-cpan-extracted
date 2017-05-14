use Test::More tests => 9;

use YAML::Accessor;
our $yml = './testdata/testdata.yaml';

ok( -e $yml );

my $yfile;

open $yfile, "+<", $yml
	or die $!;

ok( $yfile );

my $ya = YAML::Accessor->new(
	file => $yfile,        # Can be a filehandle.
	autocommit => 0,       # This is a default. Can be 1 (true).
	readonly   => 1,       # This is a default. Can be 1 (true).
	damian     => 1,       # See below. Can be 0 (false).
);

ok( $ya );
ok( $ya->get_ordered_mapping() );
ok( $ya->get_mapping() );

ok( $ya->get_nested() );
ok( $ya->get_string() );
ok( $ya->get_heredoc() );
ok( $ya->get_concatenated() );
