package Text::UnicodeBox::Control;

=head1 NAME

Text::UnicodeBox::Control - Objects to describe and control rendering

=head1 DESCRIPTION

This module is part of the low level interface to L<Text::UnicodeBox>; you probably don't need to use it directly.

=cut

use Moose;
use Exporter 'import';

=head1 METHODS

=head2 new (%params)

=over 4

=item style

The style of this line.  'light', 'double' or 'heavy' are the main style names.  See the unicode box table for all the names.

=item position

Takes 'start', 'rule', or 'end'

=item top

Currently this only makes sense with a position of 'start'.  Indicates that the box to follow should have a line drawn above it.  The value is the style (light, double, heavy)

=item bottom

Same as C<top> but for a line below.

=back

=head1 EXPORTED METHODS

The following methods are exportable by name or by the tag ':all'

=cut

has 'style'    => ( is => 'rw' );
has 'position' => ( is => 'ro' );
has 'top'      => ( is => 'ro' );
has 'bottom'   => ( is => 'ro' );

our @EXPORT_OK = qw(BOX_START BOX_RULE BOX_END);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

=head2 BOX_START (%params)

Same as C<new> with a position of 'start'

=cut

sub BOX_START {
	return __PACKAGE__->new(position => 'start', @_);
}

=head2 BOX_RULE (%params)

Same as C<new> with a position of 'rule'

=cut

sub BOX_RULE {
	return __PACKAGE__->new(position => 'rule', @_);
}

=head2 BOX_END (%params)

Same as C<new> with a position of 'end'

=cut

sub BOX_END {
	return __PACKAGE__->new(position => 'end', @_);
}

=head2 to_string (\%context)

Return a string representing the rendering of this control part.  Pass a hashref to this and all other calls within the same context to allow this to share styles with other objects.

=cut

sub to_string {
	my ($self, $context, $box) = @_;

	my $style = $self->style;
	
	if ($self->position eq 'start') {
		$context->{start} = $self;
	}
	elsif ($self->position eq 'rule') {
		if (my $start = $context->{start}) {
			$style = $start->style;
			$self->style($style); # Update my own style to the context style
		}
	}
	elsif ($self->position eq 'end') {
		$context->{end} = $self;
		if (my $start = $context->{start}) {
			$style = $start->style;
			$self->style($style); # Update my own style to the context style
		}
	}

	# Default style to 'light'
	$style ||= 'light';

	return $box->_fetch_box_character( vertical => $style );
}

=head1 COPYRIGHT

Copyright (c) 2012 Eric Waters and Shutterstock Images (http://shutterstock.com).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
