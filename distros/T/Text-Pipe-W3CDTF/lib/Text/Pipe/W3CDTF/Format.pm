use 5.008;
use strict;
use warnings;

package Text::Pipe::W3CDTF::Format;
our $VERSION = '1.100890';
# ABSTRACT: Format a DateTime object into a W3CDTF date-time string
use DateTime::Format::W3CDTF;
use parent qw(Text::Pipe::W3CDTF);

sub filter_single {
    my ($self, $input) = @_;
    DateTime::Format::W3CDTF->format_datetime($input);
}
1;


__END__
=pod

=for stopwords DateTime

=head1 NAME

Text::Pipe::W3CDTF::Format - Format a DateTime object into a W3CDTF date-time string

=head1 VERSION

version 1.100890

=head1 METHODS

=head2 filter_single

Takes a single L<DateTime> object and returns a W3CDTF date-time string.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Text-Pipe-W3CDTF>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Text-Pipe-W3CDTF/>.

The development version lives at
L<http://github.com/hanekomu/Text-Pipe-W3CDTF/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

