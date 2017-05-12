use 5.008;
use strict;
use warnings;

package Text::Pipe::HTML;
our $VERSION = '1.100880';
# ABSTRACT: Text pipes that can encode and decode HTML entities
use parent qw(Text::Pipe::Base);
1;


__END__
=pod

=head1 NAME

Text::Pipe::HTML - Text pipes that can encode and decode HTML entities

=head1 VERSION

version 1.100880

=head1 DESCRIPTION

This is a marker class; the actual pipe segment classes live in the
C<Text::Pipe::HTML::> namespace.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Text-Pipe-HTML>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Text-Pipe-HTML/>.

The development version lives at
L<http://github.com/hanekomu/Text-Pipe-HTML/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

