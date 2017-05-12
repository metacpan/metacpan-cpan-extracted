package WKHTMLTOX::XS;

use 5.000;
use strict;

require Exporter;
require DynaLoader;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(generate_pdf generate_image);

$VERSION = '0.01';

bootstrap WKHTMLTOX::XS $VERSION;

1;
__END__

=head1 NAME

WKHTMLTOX::XS - Perl Wrapper for WKHTMLTOX; HTML to PDF and Image.

=head1 SYNOPSIS

  use WKHTMLTOX::XS qw(generate_pdf);
  generate_pdf(
  	{ out => 'google.pdf'},
	{ page => 'http://www.google.com'});

=head1 DESCRIPTION

Generate PDF and Images from HTML using WKHTMLTOX.

=head1 CONTRIBUTE

E<lt>https://github.com/KurtWagner/perl-wkhtmltoxE<gt>

=head1 SEE ALSO

For PDF and image global and object settings/options, please see
http://wkhtmltopdf.org/libwkhtmltox/pagesettings.html.

=head1 AUTHOR

Kurt Wagner, E<lt>kurt.wagner@affinitylive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Kurt Wagner.
The file is licensed under the terms of the
GNU Lesser General Public License 3.0. See
E<lt>http://www.gnu.org/licenses/lgpl-3.0.htmlE<gt>.

=cut
