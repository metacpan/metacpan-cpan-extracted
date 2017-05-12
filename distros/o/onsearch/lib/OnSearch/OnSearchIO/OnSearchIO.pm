package PerlIO::OnSearchIO;

use 5.006;
use strict;
our $VERSION = '0.01';

#=head1 NAME
#
#PerlIO::OnSearchIO.pm - Perl I/O library for OnSearch.
#
#=head1 DESCRIPTION
#
#The PerlIO::OnSearchIO library contains subroutines for output to the
#Web server and for an I/O abstraction layer for OnSearch.
#
#Use of the Perl I/O abstraction layer, the default I/O scheme
#beginning with Perl version 5.8.0, should be considered experimental.
#See, "Perl Configuration," in INSTALL.html for a discussion of I/O
#abstraction layer issues.
#
#=head1 VERSION INFORMATION
#
#$Id: OnSearchIO.pm,v 1.3 2005/08/16 05:34:23 kiesling Exp $
#
#Written by Robert Kiesling <rkies@cpan.org>, and licensed under
#the same terms as Perl.  Refer to the file, "Artistic," for
#details.
#
#=head1 SEE ALSO
#
#L<OnSearch(3)>
#
#=cut
#
eval {
    require XSLoader;
    XSLoader::load (__PACKAGE__, $VERSION);
} or do {
    require DynaLoader; 
    our @ISA = qw (DynaLoader);
    bootstrap PerlIO::OnSearchIO $VERSION;
};

1;

__END__

