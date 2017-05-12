#!perl -T

use strict;
use warnings;
use Test::More tests => 9;

BEGIN { use_ok( 'XML::Rules' ); }

{
	my $xml = <<'*END*';
<root>
	<only x="1" y="20" z="30" a="11" b="12"/>
</root>
*END*

	{
		my  $parser = XML::Rules->new(
			stripspaces => 7,
			rules => {
				root => 'pass',
				only => 'as is only(y,z)'
			}
		);
		my $result = $parser->parse($xml);
		my $correct = {only => {y => 20, z => 30}};
		is_deeply($result, $correct, "as is only(y,z)");
	}

	{
		my  $parser = XML::Rules->new(
			stripspaces => 7,
			rules => {
				root => 'pass',
				only => 'as is remove(y,z)'
			}
		);
		my $result = $parser->parse($xml);
		my $correct = {only => {x => 1, a => 11, b => 12}};
		is_deeply($result, $correct, "as is remove(y,z)");
	}
}

{
	my $xml = <<'*END*';
<root>
	<only x="1" y="2" z="3"/>
	<only x="1" y="20" z="30" a="11" b="12"/>
</root>
*END*

	{
		my  $parser = XML::Rules->new(
			stripspaces => 7,
			rules => {
				root => 'pass',
				only => 'as array only(y,z)'
			}
		);
		my $result = $parser->parse($xml);
		my $correct = {only => [{y => 2, z => 3}, {y => 20, z => 30}, ]};
		is_deeply($result, $correct, "as array only(y,z)");
	}

	{
		my  $parser = XML::Rules->new(
			stripspaces => 7,
			rules => {
				root => 'pass',
				only => 'as array remove(y,z)'
			}
		);
		my $result = $parser->parse($xml);
		my $correct = {only => [{x => 1}, {x => 1, a => 11, b => 12}, ]};
		is_deeply($result, $correct, "as array remove(y,z)");
	}
}

{
	my $xml = <<'*END*';
<root>
	<only x="1" y="2" z="3"/>
	<only x="2" y="20" z="30" a="11" b="12"/>
</root>
*END*

	{
		my  $parser = XML::Rules->new(
			stripspaces => 7,
			rules => {
				root => 'pass',
				only => 'by x only(y,z)'
			}
		);
		my $result = $parser->parse($xml);
#use Data::Dumper;
#print STDERR Dumper($result);
		my $correct = {1 => {y => 2, z => 3}, 2 => {y => 20, z => 30}};
		is_deeply($result, $correct, "by x only(y,z)");
	}

	{
		my  $parser = XML::Rules->new(
			stripspaces => 7,
			rules => {
				root => 'pass',
				only => 'by x only(x,y,z)'
			}
		);
		my $result = $parser->parse($xml);
		my $correct = {1 => {y => 2, z => 3}, 2 => {y => 20, z => 30}};
		is_deeply($result, $correct, "by x only(x,y,z)");
	}

	{
		my  $parser = XML::Rules->new(
			stripspaces => 7,
			rules => {
				root => 'pass',
				only => 'by x remove(y,z)'
			}
		);
		my $result = $parser->parse($xml);
		my $correct = { 1 => {}, 2 => {a => 11, b => 12}};
		is_deeply($result, $correct, "by x remove(y,z)");
	}

	{
		my  $parser = XML::Rules->new(
			stripspaces => 7,
			rules => {
				root => 'pass',
				only => 'by x remove(x,y,z)'
			}
		);
		my $result = $parser->parse($xml);
#use Data::Dumper;
#print STDERR Dumper($result);
		my $correct = { 1 => {}, 2 => {a => 11, b => 12}};
		is_deeply($result, $correct, "by x remove(x,y,z)");
	}
}

