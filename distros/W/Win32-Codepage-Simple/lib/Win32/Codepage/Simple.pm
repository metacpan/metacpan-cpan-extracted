package Win32::Codepage::Simple;

use warnings;
use strict;

our $VERSION = '0.01';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_codepage get_acp get_oemcp);

our $get_acp;
our $get_oemcp;

&_init;
1;

sub _init
{
	eval
	{
		local($SIG{__DIE__}, $@) = 'DEFAULT';
		require Win32::API;
		
		$get_acp   = Win32::API->new("kernel32", "GetACP",   "", "N");
		$get_oemcp = Win32::API->new("kernel32", "GetOEMCP", "", "N");
		1;
	};
}

sub get_codepage
{
	&get_acp;
}

sub get_acp
{
	$get_acp && $get_acp->Call();
}

sub get_oemcp
{
	$get_oemcp && $get_oemcp->Call();
}

=head1 NAME

Win32::Codepage::Simple - get codepage, simply

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

 use Win32::Codepage::Simple qw(get_codepage);
 
 my $cpnum = get_codepage();

=head1 EXPORT

A list of functions that can be exported. 

=head2 get_codepage()

synonym for get_acp.

=head2 get_acp()

get ansi code page.

=head2 get_oemcp()

get oem code page.

=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-win32-codepage-simple at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Codepage-Simple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::Codepage::Simple

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-Codepage-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-Codepage-Simple>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-Codepage-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-Codepage-Simple>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 YAMASHINA Hio, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
