package WWW::Ruler::Piece;

use strict;
use warnings;

sub new {
    bless { amount => $_[1], ruler => [] }, $_[0];
}

sub start {
    $_[0]->{start};
}

sub end {
    $_[0]->{end};
}

sub size {
    $_[0]->{amount} and $_[0]->{end} - $_[0]->{start} + 1;
}

sub ruler {
    $_[0]->{ruler};
}

sub add_ruler_item {
    push @{$_[0]->{ruler}}, $_[1];
}

sub outside {
    my ( $self, $outside ) = @_;

    if ( $outside ) {
	$self->{size} = $self->{start} = $self->{end} = 0;
	$self->{outside} = 1;
	return $self;
    }

    ! ! $self->{outside};
}

1;

__END__

=pod

=head1 NAME

WWW::Ruler::Piece - a I<piece> from L<WWW::Ruler/cut_off> work. An instances of
this object are returned from L<WWW::Ruler/cut_off>.

=head1 METHODS

=over

=item ruler

Returns an array of ruler items. Every item of array is hashref with keys:

=over

=item type

Here string name of type of ruler item:

=over

=item I<prev_pointer>

Symbol of button [E<nbsp>E<lt>E<nbsp>] for example. An accompanying key is
L</page_number>

=item I<page>

The button of page number. An accompanying keys are L</page_number> and key
L</current_page>

=item I<next_pointer>

Symbol of button [E<nbsp>E<gt>E<nbsp>] for example. An accompanying key is
L</page_number>

=item I<ellipsis>

The symbol ... in ruler. It doesn't have any accompanying keys.

=back

=item page_number

The digital number of page (starts from 1) for this item ruler.

=item current_page

If this key exists its value is true. This key exists only for B<current> page.

=back

=item start

A start index of array (a base is zero) for cutting. This number can be used as
left value of range operator C<..>

=item end

A end index of array (a base is zero) for cutting. This number can be used as
right value of range operator C<..>

=item size

A size of current page. It shows how many items in I<current> page.

=item outside

If a piece is located outside of array then returns true else false. This can
happen when page_number is <= 0 or page_number is more than a maximal possible
page number for this data array or when L<WWW::Ruler/amount> is zero. If
L</outside> returned a true then L</start>, L</end> and L</size> methods will
return 0 and L</ruler> returns an empty array.

=back

=head1 AUTHOR

This module has been written by Perlover <perlover@perlover.com>

=head1 LICENSE

This module is free software and is published under the same terms as Perl
itself.
