package t::tests;

use strict;
use warnings;

use Test::More;

my @stats = qw( height width depth size is_root is_leaf );

use base 'Exporter';

our @EXPORT_OK = qw( %runs );
our $VERSION   = '1.14';
our %runs	  =
(
	stats =>
	{
		plan => scalar @stats,
		func => \&stat_check,
	},
	error =>
	{
		plan => 3,
		func => \&error_check,
	},
);

# ----------------------------------------------

sub stat_check
{
	my($tree) = shift;
	my(%opts) = @_;

	for my $stat (@stats)
	{
		if ( $stat =~ /^is_(.*)/ )
		{
			if ( $opts{$stat} )
			{
				ok( $tree->$stat, "The tree is a $1" );
			}
			else
			{
				ok( !$tree->$stat, "The tree is not a $1" );
			}
		}
		else
		{
			cmp_ok
			(
				$tree->$stat, '==', $opts{$stat},
				"The tree has a $stat of $opts{$stat}",
			);
		}
	}

} # End of stat_check.

# ----------------------------------------------

sub error_check
{
	my($tree)      = shift;
	my(%opts)      = @_;
	my($func)      = $opts{func};
	my($validator) = $opts{validator};

	is( $tree->$func(@{$opts{args} || []}), undef, "$func(): error testing ..." );
	is( $tree->last_error, $opts{error}, "... and the error is good" );
	cmp_ok( $tree->$validator, '==', $opts{value}, "... and there was no change" );

} # End of error_check.

# ----------------------------------------------

1;

__END__
