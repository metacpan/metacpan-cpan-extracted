package Zodiac::Chinese;

use 5.008;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(chinese_zodiac);
our $VERSION = 1.00;

my @direction = qw(yang yin);
my @element = (("metal") x 2, ("water") x 2, ("wood") x 2, ("fire") x 2, ("earth") x 2);
my @signs = qw(rat ox tiger rabbit dragon snake horse sheep monkey rooster dog pig);

sub chinese_zodiac {
    my ($year,$month,$day) = @_;
    my $zodiac;
    if ($month > 1) {
        $zodiac = $direction[$year % 2]." ".$element[$year % 10]." ".$signs[($year - 1924) % 12];
    } else {
        $zodiac = $direction[($year - 1) % 2]." ".$element[($year - 1) % 10]." ".$signs[(($year-1)  - 1924) % 12];
    }
    return $zodiac;
}
1;
__END__

=head1 NAME

Zodiac::Chinese - Generate Chinese Zodiac

=head1 SYNOPSIS

  use Zodiac::Chinese qw(chinese_zodiac);
  my $zodiac = chinese_zodiac("2000", "09");

=head1 DESCRIPTION

This module generates one's Chinese zodiac. However, for those born in late January to early February, it may be wrong.

=head2 chinese_zodiac

Generates the Zodiac for the given date. It takes two arguments, YEAR and MONTH.

YEAR is the four digit year, MONTH is the digit for the month (1-12).

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 KNOWN BUGS

Zodiac for those born in late January to early February may be wrong.

=head1 AUTHOR

The real author is Lady_Aleena from PerlMonks.org. 


Rene Schickbauer, E<lt>rene.schickbauer@magnapowertrain.comE<gt> just provided the packaging stuff needed for CPAN.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Lady_Aleena and Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
