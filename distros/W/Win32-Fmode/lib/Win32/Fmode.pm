package Win32::Fmode;

use 5.0;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
    fmode
);

our $VERSION = '1.0.6';

require XSLoader;
XSLoader::load('Win32::Fmode', $VERSION);

sub fmode {
    my $fh = shift;
    die "Win32::Fmode: No/bad argument supplied!.\n\tUsage: fmode( open filehandle )\n"
        unless defined $fh and ref $fh eq 'GLOB';
    die "Win32::Fmode: fmode() does not currently work on ramfiles\n" if fileno( $fh ) == -1;
    die "Win32::Fmode: '$fh' is not an open filehandle\n"
        unless 1+fileno( $fh );
    return xs_fmode( $fh );
}

return 1 if caller;
package main;

my %modes; @modes{ qw[ < > >> +< +> +>> ] } = ( 1, 2, 2, 128, 128, 128 );

for my $mode ( keys %modes ) {
    open my $fh, $mode, 'testfile' or die "testfile : $!";
    die "open mode '$mode'; fmode returned '%d'\n"
        unless Win32::Fmode::fmode( $fh ) == $modes{ $mode };
}
open RAM, '<', \ my $ram;
eval{ Win32::Fmode::fmode( \*RAM ) };
close RAM;
die "Ramfile detection failed."
    unless $@ eq "Win32::Fmode: fmode() does not currently work on ramfiles\n";

eval{ Win32::Fmode::fmode( 'some junk' ); };
die "Bad argument test failed."
    unless $@ eq "Win32::Fmode: No/bad argument supplied!.\n\tUsage: fmode( open filehandle )\n";

print "All tests passed";

__END__

=head1 NAME

Win32::Fmode - determine whether a Win32 filehandle is opened for reading, writing , or both.

=head1 SYNOPSIS

 use warnings;
 use Win32::Fmode;
 .
 .
 my $mode = fmode( \*FH ); # FH is an open filehandle

=head1 FUNCTIONS

The purpose is to work around the MS C runtime libraries lack of a
function to retrieve the file mode used when a file is opened.

Exports a single function: fmode

Pass it an open Perl filehandle and it will return a numeric value that
represents the mode parameter used on the open.

     fmode( \*FILEHANDLE ) &   1 and print "is readonly";
     fmode( \*FILEHANDLE ) &   2 and print "is writeonly";
     fmode( \*FILEHANDLE ) & 128 and print "is read/write";

If the parameter passed is not an open filehandle, the call will raise an exception.

=head1 BUGS

Note: Ram files c<open FH, '<', \$ram> are not true filehandles (they are tied globs),
and therefore do not have the associated CRT FILE structure from which this module
obtains the information, and no way has yet been found to retrieve that information
from them.

The module IO::String suffers the same limitations.

=head1 LICENSE

 This program is free software; you may redistribute it and/or
 modify it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

 Written by BrowserUK.
 Copyright BrowserUK.
 bug reports to BrowserUk@cpan.org

=cut
