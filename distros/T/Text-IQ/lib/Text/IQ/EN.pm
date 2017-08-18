package Text::IQ::EN;
use strict;
use warnings;
use base 'Text::IQ';
use Lingua::EN::Syllable;

our $VERSION = '0.005';

my %syllable_cache;

=head1 NAME

Text::IQ::EN - Text::IQ for English

=head1 SYNOPSIS

 # see Text::IQ

=head1 METHODS

This class extends L<Text::IQ>. Only new or overridden methods are documented here.

=cut

=head2 get_num_syllables

Returns number of syllables in the text.

=cut

sub get_num_syllables {
    return $syllable_cache{ $_[1] } if exists $syllable_cache{ $_[1] };
    $syllable_cache{ $_[1] } = syllable( $_[1] );
    return $syllable_cache{ $_[1] };
}

=head2 num_misspellings

Returns the number of misspelled words, according to L<Search::Tools::SpellCheck>.

=cut

sub num_misspellings {
    my $self = shift;
    return $self->{num_misspelled} if defined $self->{num_misspelled};
    my $checker = Search::Tools::SpellCheck->new( lang => 'en_US', );
    my $aspell = $checker->aspell;
    my @errs;
    my %uniq;
    my $n = 0;
    while ( my $t = $self->{_tokens}->next ) {

        if ( $t->is_match ) {
            if ( !$aspell->check("$t") ) {
                push @errs, "$t";
                $uniq{"$t"}++;
                $n++;
            }
        }
    }
    $self->{misspelled}          = \@errs;
    $self->{num_uniq_misspelled} = scalar keys %uniq;
    $self->{num_misspelled}      = $n;
    $self->{_tokens}->reset;
    return $self->{num_misspelled};
}

=head2 num_uniq_misspellings

Returns the number of unique misspelled words.

=cut

sub num_uniq_misspellings {
    my $self = shift;
    $self->num_misspellings;
    return $self->{num_uniq_misspelled};
}

=head2 misspelled

Returns the list of misspelled words.

=cut

sub misspelled {
    my $self = shift;
    return $self->{misspelled} if defined $self->{misspelled};
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-iq at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-IQ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::IQ

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-IQ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-IQ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-IQ>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-IQ/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2014 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
