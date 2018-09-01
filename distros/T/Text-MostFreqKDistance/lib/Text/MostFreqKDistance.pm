package Text::MostFreqKDistance;

$Text::MostFreqKDistance::VERSION   = '0.09';
$Text::MostFreqKDistance::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Text::MostFreqKDistance - Estimate strings similarity.

=head1 VERSION

Version 0.09

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;
use parent 'Exporter';

our @EXPORT = qw(MostFreqKHashing MostFreqKSDF);

=head1 DESCRIPTION

In information theory, MostFreqKDistance is a string metric technique for quickly
estimating how similar two ordered sets or strings are.The scheme was invented by
Sadi Evren SEKER(2014) and initially used in text mining applications like author
recognition.

Source: L<Wikipedia|http://en.wikipedia.org/wiki/Most_frequent_k_characters>

=head1 SYNOPSIS

    use strict; use warnings;
    use Text::MostFreqKDistance;

    print MostFreqKHashing('seeking',  2), "\n";
    print MostFreqKHashing('research', 2), "\n";
    print MostFreqKSDF('seeking', 'research', 2, 10), "\n";

=head1 METHODS

=head2 MostFreqKSDF($str1, $str2, $k, $max_distance)

The method is  suitable for bioinformatics to compare the genetic strings like in
FASTA format.

    use strict; use warnings;
    use Text::MostFreqKDistance;

    my $str1 = 'LCLYTHIGRNIYYGSYLYSETWNTGIMLLLITMATAFMGYVLPWGQMSFWGATVITNLFSAIPYIGTNLV';
    my $str2 = 'EWIWGGFSVDKATLNRFFAFHFILPFTMVALAGVHLTFLHETGSNNPLGLTSDSDKIPFHPYYTIKDFLG';

    print MostFreqKHashing($str1, 2), "\n";
    print MostFreqKHashing($str2, 2), "\n";
    print MostFreqKSDF($str1, $str2, 2, 10), "\n";

=cut

sub MostFreqKSDF {
    my ($a, $b, $k, $d) = @_;

    my $MostFreqKHashing_a = _MostFreqKHashing($a, $k);
    my $MostFreqKHashing_b = _MostFreqKHashing($b, $k);

    my $MostFreqKSDF = 0;
    foreach my $_a (@$MostFreqKHashing_a) {
        next if ($_a->{key} eq 'NULL');
        foreach my $_b (@$MostFreqKHashing_b) {
            if ($_a->{key} eq $_b->{key}) {
                if ($_a->{value} == $_b->{value}) {
                    $MostFreqKSDF += $_a->{value};
                }
                else {
                    $MostFreqKSDF += ($_a->{value} + $_b->{value});
                }
            }
        }
    }

    return ($d - $MostFreqKSDF);
}

=head2 MostFreqKHashing($str, $k)

It simply gets an input C<$str> and an  integer  C<$k> value. It outputs the most
frequent C<$k> characters from the input string. The only  condition  during  the
creation of output string is adding  the first occurring character first, if  the
frequencies of two characters are equal.

    use strict; use warnings;
    use Text::MostFreqKDistance;

    print MostFreqKHashing('seeking',  2), "\n";
    print MostFreqKHashing('research', 2), "\n";

=cut

sub MostFreqKHashing {
    my ($string, $k) = @_;

    die "ERROR: Missing source string.\n"        unless defined $string;
    die "ERROR: Missing frequency value.\n"      unless defined $k;
    die "ERROR: Invalid frequency value [$k].\n" unless ($k =~ /^[0-9]+$/);

    my $MostFreqKHashing = '';
    foreach (@{_MostFreqKHashing($string, $k)}) {
        $MostFreqKHashing .= sprintf("%s%d", $_->{key}, $_->{value});
    }

    return $MostFreqKHashing;
}

#
#
# PRIVATE METHODS

sub _MostFreqKHashing {
    my ($string, $k) = @_;

    my $seen  = {};
    my %chars = ();
    my $chars = [];
    my $i     = 0;
    foreach (split //,$string) {
        $chars{$_}++;
        $chars->[$i++] = $_;
    }

    my @chars = sort { $chars{$b} <=> $chars{$a} } keys(%chars);
    my $MostFreqKHashing = [];
    foreach my $j (0..($k-1)) {
        foreach (@$chars) {
            next if (defined $seen && exists $seen->{$_});
            if ($chars{$_} == $chars{$chars[$j]}) {
                $seen->{$_} = 1;
                push @$MostFreqKHashing, { key => $_, value => $chars{$_} };
                last;
            }
        }
    }

    foreach (1..($k-(keys %$seen))) {
        push @$MostFreqKHashing, { key => 'NULL', value => 0 };
    }

    return $MostFreqKHashing;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Text-MostFreqKDistance>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-mostfreqkdistance at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-MostFreqKDistance>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::MostFreqKDistance

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-MostFreqKDistance>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-MostFreqKDistance>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-MostFreqKDistance>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-MostFreqKDistance/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2017 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Text-MostFreqKDistance
