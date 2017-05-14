package Tie::Hash::Rank;

use strict;

my $VERSION='1.0.1';

sub TIEHASH {
	my $class = shift;
	my $self = {
		ALGORITHM	=> '$DATA{$b} <=> $DATA{$a}', # rev numeric sort
		EQUALITYSUFFIX	=> '',
		EQUALITYPREFIX	=> '',
		RECALCULATE	=> 'onstore',
		@_,
		_RANKS		=> {},   # yes, these go AFTER the parameters
		DATA		=> {}
	};
	
	return bless $self, $class;
}

sub _recalculate {
	my $self = shift;
	my $sort_function = $self->{ALGORITHM};
	$sort_function=~s/\$DATA\{(\$[ab])\}/\$self->{DATA}->{$1}/g;
	$self->{_RANKS} = {};
	my $i=1;
	my $prevkey;
	foreach my $key (
		eval("sort { $sort_function } keys %{\$self->{DATA}}")
	) {
		$self->{_RANKS}->{$key}=$i++;

		no warnings; # to avoid 'use of uninitialised value' errors
			     # in next line

		if($self->{DATA}->{$key} eq $self->{DATA}->{$prevkey}) {
			$self->{_RANKS}->{$key} =
			  $self->{_RANKS}->{$prevkey} =
			    $self->{EQUALITYPREFIX}.
			    $self->{_RANKS}->{$prevkey}.
			    $self->{EQUALITYSUFFIX};
		}
		$prevkey = $key;
	}
}

sub CLEAR { my $self=shift; $self->{DATA}={}; $self->{_RANKS}={}; }
sub STORE {
        my($self, $key, $value)=@_;
        $self->{DATA}->{$key}=$value;
	$self->_recalculate() if($self->{RECALCULATE} eq 'onstore');
}
sub FETCH {
        my $self=shift;
        my $key=shift;
	$self->_recalculate() if($self->{RECALCULATE} eq 'onfetch');
	return $self->{_RANKS}->{$key};
}
sub FIRSTKEY {
	my $self = shift;
	scalar keys %{$self->{DATA}};
	return scalar each %{$self->{DATA}};
}
sub NEXTKEY {
	my $self = shift;
	return scalar each %{$self->{DATA}};
}
sub DELETE {
	my $self = shift;
	my $key = shift;
	delete $self->{_RANKS}->{$key};
	delete $self->{DATA}->{$key};
	$self->_recalculate() if($self->{RECALCULATE} eq 'onstore');
}
sub EXISTS {
	my $self = shift;
	my $key = shift;
	return exists($self->{DATA}->{$key});
}

1;
__END__

=head1 NAME

Tie::Hash::Rank - A hash which turns values into ranking positions

=head1 SYNOPSIS

  use Tie::Hash::Rank

  tie my %ranks, 'Tie::Hash::Rank';
  %ranks=(
    Adams   => 78,
    Davies  => 35,
    Edwards => 84,
    Thomas  => 47
  );
  print $ranks{Adams};

=head1 DESCRIPTION

This module allows you to tie a hash such that when you retrieve values
from it, you get the value's rank instead of the actual data.  By default,
it ranks items numerically, with the highest value getting rank 1, and
given two equal values they will also get the same rank.

The following named parameters are supported:

=over 4

=item C<ALGORITHM>

Use C<ALGORITHM> to sort items prior to ranking them.  The default is
a reverse-numeric sort.  Specify it thus $DATA{$a} <=> $DATA{$b} to
do a normal numeric sort.  Divining how to do other types of sort is
left as a trivial exercise for the reader.  See perldoc -f sort.

=item C<EQUALITYSUFFIX>

Append C<EQUALITYSUFFIX> to the rank of items with equal rank.  The
default is to have no EQUALITYSUFFIX, but a common alternative would be
an C<=> sign.

=item C<EQUALITYPREFIX>

Prepend C<EQUALITYPREFIX> to the rank of items with equal rank.  The
default is to have no EQUALITYPREFIX, but a common alternative would be
an C<=> sign.

=item C<RECALCULATE>

Can be either C<onstore> or C<onfetch>, and defaults to 'onstore'.  This
determines when the module recalculates the ranks.  'onstore' makes it
recalculate whenever you add a value to the hash, and 'onfetch' whenever
you retrieve a value.  Use this option if you need to tune your hash
for data which is mainly read or mainly written, although it will make
very little difference for small data-sets.

=back

=head1 BUGS

Plenty, no doubt.  Please tell me if you find any.

=head1 AUTHOR

David Cantrell <david@cantrell.org.uk>

This module originated as a grotesquely over-engineered answer to a
trivial question posed by Simon Cozens as an example of something you
might want to ask when testing someone's perl skillz.  An earlier -
and less complete - version of this module was posted on the London
Perl Mongers mailing list.

=head1 COPYRIGHT

Copyright 2001 David Cantrell.

This module is licensed under the same terms as perl itself.

=head1 SEE ALSO

Tie::Hash(3)

=cut
