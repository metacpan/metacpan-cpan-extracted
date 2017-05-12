=head1 NAME

Text::CSV::Track::Max - same as Text::CSV::Track but stores the greatest value

=head1 VERSION

This documentation refers to version 0.3.

=head1 SYNOPSIS

see L<Text::CSV::Track> as this is inherited object from it.
	
=head1 DESCRIPTION

Only difference to Track is that before value is changed it is compared to the
old one. It it's higher then the value is updated if not old value persists.

=cut

package Text::CSV::Track::Max;

our $VERSION = '0.3';
use 5.006;

use strict;
use warnings;

use base qw(Text::CSV::Track);

use FindBin;

use Text::CSV_XS;
use Carp::Clan;

=head1 METHODS

=over 4

=item value_of()

Overridden function from L<Text::CSV::Tack> that stores value only if it is
greater then the one before. 

=cut

sub value_of {
	my $self          = shift;
	my $identificator = shift;
	my $is_set        = (@_ > 0 ? 1 : 0);	#get or set request depending on number of arguments
	my $value         = shift;

	#variables from self hash
	my $rh_value_of    = $self->_rh_value_of;

	#check if we have identificator
	return if not $identificator;

	#if get call super value_of
	return $self->SUPER::value_of($identificator) if not $is_set;
	
	#set
	my $old_value;
	if (exists $rh_value_of->{$identificator}) {	#don't call SUPER::value_of because it will active lazy init that is may be not necessary
		$old_value = ${$rh_value_of->{$identificator}}[0];
	}
	if (not defined $value
			or not defined $old_value
			or ($old_value < $value)
			
			) {		#if it is removel or the old value is smaller then set it
		$self->SUPER::value_of($identificator, $value);
	}
}

=back

=cut

1;

