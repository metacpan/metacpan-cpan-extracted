package Text::Info::Utils;
use Moose::Role;
use namespace::autoclean;

use Lingua::Identify::CLD;

=head1 NAME

Text::Info::Utils - Utility methods for L<Text::Info>.

=head1 METHODS

=over

=item CLD()

Returns a C<Lingua::Identify::CLD> instance.

=cut

has 'CLD' => ( isa => 'Lingua::Identify::CLD', is => 'ro', lazy_build => 1 );

sub _build_CLD {
    my $self = shift;

    return Lingua::Identify::CLD->new;
}

=item text2words( $text )

Returns an array reference of the words in the specified C<$text>.

=cut

sub text2words {
    my $self = shift;
    my $text = shift // '';

    my @words = ();

    foreach my $word ( split(/[\s+-]/, $text) ) {
        $word =~ s/^\W+//;
        $word =~ s/\W+$//;
        $word =  $self->trim( $word );

        if ( length $word ) {
            push( @words, $word );
        }
    }

    return \@words;
}

=item trim( $text )

Removes leading and trailing spaces from C<$text>.

=cut

sub trim {
    my $self = shift;
    my $text = shift // '';

    $text =~ s/^\s+//;
    $text =~ s/\s+$//;

    return $text;
}

=item squish( $text )

Squishes the C<$text>, ie. replaces all double spaces with one space.

=cut

sub squish {
    my $self = shift;
    my $text = shift // '';

    $text =~ s/\s+/ /sg;

    foreach my $sep ( (".", ",", "!", "?", ":", ";", "´", "`", "'") ) {
        $text =~ s/\s+\Q$sep\E\s+/, /sg;
    }

    return $self->trim( $text );
}

1;

=back
