# Test case : entire branch is deleted instead of single node only
#
# Copyright (C) Karl Kästner - Berlin, Germany
# Sun Apr  5 07:24:11 MSD 2009

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('Tree::Binary'); use_ok('Tree::Binary::Search');
}

# ------------------------------------------------

my @nodes = (
		 [ "L", "K", "P", "Q" ]
		,[ "L", "K", "P", "N", "Q" ]
		,[ "L", "K", "P", "N", "M", "Q" ]
		,[ "L", "K", "P", "N", "O", "Q" ]
		,[ "L", "K", "P", "N", "M", "O", "Q" ]
	);
my($expected) = <<'EOS';
K L P Q        -- 4 3 --  K P Q
K L N P Q      -- 5 4 --  K N P Q
K L M N P Q    -- 6 5 --  K M N P Q
K L N O P Q    -- 6 5 --  K N O P Q
K L M N O P Q  -- 7 6 --  K M N O P Q
EOS

my(@output);

foreach ( @nodes )
{
	push @output, test( "L", @{$_} );
}

ok(join('', split(/\n/, $expected) ) eq join('', @output), 'Node deletion works in V 1.00');

sub test
{
	my @nodes = @_;
	my $delNode = shift(@nodes);

	my $tree = Tree::Binary::Search->new();
	$tree->useStringComparison();

	foreach ( @nodes )
	{
		$tree->insert($_, $_);
	}

	my($output) = '';

	warn "search order inconsistent\n" if
		verify(\$output, Tree::Binary::Search::getTree($tree));

	my $size_1 = $tree->size();
	$tree->delete($delNode);
	my $size_2 = $tree->size();
	$output .= ' ' x (15 - length($output) ) . "-- $size_1 $size_2 --  ";

	warn "Number of elements incorrect\n"
		if ($size_2 + 1 != $size_1);
	warn "search order inconsistent\n" if
		verify(\$output, Tree::Binary::Search::getTree($tree));

	$output =~ s/\s$//;

	return $output;

} # test

sub verify
{
	my($output, $tree) = @_;
	my @value = _verify($output, $tree );
	my $retval = 0;

	while ( @value >= 2 )
	{
        	if ( ( $value[0] cmp $value[1] ) > 0)
		{
			$retval = -1;
		}
		$$output .= shift(@value)." ";
	}
	$$output .= shift(@value);

	return $retval;

} # verify

sub _verify
{
	my($output, $self) = @_;

	if (defined $self)
	{
		my $value = $self->getNodeValue();
		_verify($output, $self->getLeft);
		$$output .= $value." ";
		_verify($output, $self->getRight);
	}

} # _verify
