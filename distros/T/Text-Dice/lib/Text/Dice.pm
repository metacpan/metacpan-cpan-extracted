package Text::Dice;

use strict;
use warnings;
use Exporter qw(import);

our $VERSION = '0.06';
$VERSION = eval $VERSION;

our @EXPORT = qw(coefficient);

sub coefficient {
    return unless 2 == @_;

    my ($counts1, $counts2, $pairs1, $pairs2) = (0) x 2;
    if (not ref $_[0] and not ref $_[1]) {
        for my $w (split ' ', lc $_[0]) {
            $counts1 += length($w) - 1;
            ++$pairs1->{substr $w, $_, 2} for (0 .. length($w) - 2);
        }
        for my $w (split ' ', lc $_[1]) {
            $counts2 += length($w) - 1;
            ++$pairs2->{substr $w, $_, 2} for (0 .. length($w) - 2);
        }
    }
    elsif ('ARRAY' eq ref $_[0] and 'ARRAY' eq ref $_[1]) {
        $counts1 +=  @{$_[0]};
        ++$pairs1->{$_} for @{$_[0]};

        $counts2 +=  @{$_[1]};
        ++$pairs2->{$_} for @{$_[1]};
    }
    else { return }

    return 0 unless $counts1 and $counts2;

    my ($smaller, $larger) = $counts1 > $counts2
        ? ($pairs2, $pairs1) : ($pairs1, $pairs2);

    my $intersection = 0;
    while (my ($pair, $count1) = each %{$smaller}) {
        my $count2 = $larger->{$pair} or next;
        $intersection += ($count2 > $count1) ? $count1 : $count2;
    }

    return 2 * $intersection / ($counts1 + $counts2);
}


1;

__END__

=head1 NAME

Text::Dice - Calculate Dice's coefficient of two strings

=head1 SYNOPSIS

    use Text::Dice;
    $coefficient = coefficient $string1, $string2;
    # or if you want to tokenize the strings yourself:
    $coefficient = coefficient \%array1, \%array2;

=head1 DESCRIPTION

The C<Text::Dice> module calculates Dice's coefficient of two strings. The
main benefits of this algorithm are: true reflection of lexical similarity,
robustness to changes of word order, and language independence.

=head1 FUNCTIONS

=head2 coefficient

    $coefficient = coefficient $string1, $string2
    $coefficient = coefficient \@array1, \@array2

Returns a number between 0 and 1; the higher the number, the greater the
similarity.

The two input strings are internally tokenized into character bigrams. If
you wish to use a different tokenization method, pass in the resulting array
references.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Dice%27s_coefficient>

L<http://www.catalysoft.com/articles/StrikeAMatch.html>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Text-Dice>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Dice

You can also look for information at:

=over

=item * GitHub Source Repository

L<https://github.com/gray/text-dice>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Dice>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Dice>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Text-Dice>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Dice/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2015 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
