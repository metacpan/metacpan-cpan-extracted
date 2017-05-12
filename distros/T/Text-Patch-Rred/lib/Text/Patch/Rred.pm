#!/usr/bin/perl

# Copyright (C) 2006-2009 Jakob Bohm.  All Rights Reserved.
# See README in the distribution for the current license status of the
#    entire package, including this file.

=head1 NAME

Text::Patch::Rred - Safely apply diff --ed style patches

=head1 VERSION

This is version 0.06

=cut

package Text::Patch::Rred;

use 5.006;    # Even older might work, but are not supported
use strict;
use warnings;
use Carp qw(carp croak);
use base qw(Exporter);
our $VERSION = '0.06';

=head1 USAGE

=head2 Command Line:

S<B<rred> F<file.old> F<file.new> F<file.patch1> [ F<file.patch2> ... ]>

=head2 Functional Interface (preferred, faster, type checked)

    my @lines = <ORIGINAL>;
    my $edState = Text::Patch::Rred::Init(@lines);
            # or &Text::Patch::Rred::Init(\@lines);
    while (<EDSCRIPTS>) { Text::Patch::Rred::Do1($edState, $_); }
    @lines = Text::Patch::Rred::Result($edState);
    $edState = undef; # free memory
    print PATCHED @lines;

=head2 Object Interface:

    my @lines = <ORIGINAL>;
    my $edState = Text::Patch::Rred->new(\@lines);
    while (<EDSCRIPTS>) { $edState->Do1($_); }
    @lines = $edState->Result;
    $edState = undef; # free memory
    print PATCHED @lines;

=head2 Example:   

    $ diff --ed file.v1 file.v2 >file.patch1
    $ diff --ed file.v2 file.v3 >file.patch2
    $ rred file.v1 file.new file.patch1 [ file.patch2 ... ]
    $ # Now file.new is the same as file.v3
    $ # Alternative:
    $ cat file.patch1 file.patch2 | rred file.v1 file.new -

=head1 DESCRIPTION

This module and program safely and securely applies one or more
S<ed-style> patches as produced by the command S<C<diff --ed oldfile
newfile>>.  It does exactly what you tell it to and no more, even
with wildly bad or evil input.

Unlike the traditional programs L<B<patch>|patch(1)>, L<B<ed>|ed(1)>,
L<B<red>|red(1)> and L<B<sed>|sed(1)>, Rred does not allow the data
in the patch to run arbitrary commands, read or write files or
otherwise cause havoc.  Only the handful of safe "commands" actually
used by L<B<diff>|diff(1)> are recognized and processed.

Unlike the L<B<patch>|patch(1)> program and the perl modules
L<B<Text::Patch>|Text::Patch>, L<B<PatchReader>|PatchReader> and
L<B<Meta::Development::Patch>|Meta::Development::Patch>, this module
does NOT try to doubleguess what kind of data it is given or which
file to process.

(Note that the other perl modules just mentioned cannot actually
apply an ed-style patch, though some can parse it).

The name B<rred> is short for "Really Restricted ED" (as compared to
L<B<red>|red(1)>).  This is the name given to a similar utility used
inside the Debian projects apt facility.


=head1 REQUIRED ARGUMENTS

=over 4

=item F<file.old>

Original file whose contents is to be patch.  This file should be identical
to the first file passed to I<S<C<diff -e>>> when the patches were made.  In
this implementation, perl magics are supported for this file name.

=item F<file.new>

Output file where the fully patched contents is to be written.  This file
will become identical to the last file passed to I<S<C<diff -e>>> when the
patches were made.  This file can be the same file as any of the input
files.  In this implementation, perl magics are B<not> supported for this
file name.

=item F<file.patch1> [ F<file.patch2> ... ]

One or more --ed style patch files to be applied (in sequence) to the
contents of F<file.old> to produce F<file.new>.  These files should be
identical to the output of one or more invocations of I<S<C<diff -e>>> on
F<file.old> and F<file.new> plus optionally any intermediary files. The
patch files may optionally be concatenated before being passed to B<rred>,
the result will be the same as passing them individually. In this
implementation, perl magics are supported for these file names.

=back

=head1 EXPORT

L<B<Init>|/Init @lines>, L<B<Do1>|/Do1 $edState, $patchline>,
L<B<Do>|/Do $edState, @lines>, L<B<Result>|/Result $edState> and
L<B<main>|/main @ARGV> can be exported.  B<:all> is short for
L<B<Init>|/Init @lines>, L<B<Do1>|/Do1 $edState, $patchline> and
L<B<Result>|/Result $edState>. Nothing is exported by default.

=cut

# This allows declaration	use Text::Patch::Rred ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ('all' => [qw(Init Do1 Result)]);

our @EXPORT_OK = qw(Init Do1 Result Do main);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
# Perl::Critic wrongly complains about this line: our @EXPORT = qw();

=begin comment

# Internal data format:
#    For efficiency, the state is an array with the following elements
#    $a[0]               1 in insert mode, 0 in command mode
#    $a[1]               index in $a of start of hole after current line
#                     == 1 + index in $a of current line
#                     == 1 + current line no + 3
#                     == current line no + 4
#                        (so current line = 0 is stored as 4)
#    $a[2]               index in $a storing first line after current
#                     == index in $a after end of hole after current line
#    $a[3]               index in $a after last line
#    $a[4    ..$a[1]-1]  lines up to and including current line
#    $a[$a[1]..$a[2]-1]  hole: free entries to make insertion easy
#    $a[$a[2]..$a[3]-1]  lines after current line
#    $a[$a[3]..$#a    ]  possibly unused entries
# Each of the 4 ranges can be empty (i..i-1) but not less than that
# Each line is stored as a reference to a string, not as a string, this is
#    done to avoid massive memory thrashing when patching large files.
#
# To allow the object oriented variant of the code to work too, the array
#    reference above is actually stored as the sole member of a returned
#    hash reference, to conform to normal subclassing behaviour.

=end comment

=cut

=head1 FUNCTIONS and METHODS

=over

=item B<new> I<\@lines>

=cut

sub new($$)
{
    my ($class, $rlins) = @_;
    my $n = scalar @$rlins;
    ## no critic (ProhibitComplexMappings)
    my $ro = {
        RA => [
            0, $n + 4, $n + 1004, $n + 1004,
            (map { my $a = $_; \$a } @$rlins),
            (undef) x 1000
        ]
    };
    ## use critic (ProhibitComplexMappings)
    bless $ro, ((ref $class) or $class);
    return $ro;
}

=item B<Init> I<@lines>

Initializes a new patch state and sets the initial file content to a
copy of the lines of text (each a string) supplied.  Returns a new
B<Text::Patch::Rred> object if successful, undef on error (there
are no current error scenarios).

Lines in C<@lines> must use the same line endings (none or "\n") as
lines passed to L<B<Do1>|/Do1 $edState, $patchline> and L<B<Do>|/Do
$edState, @lines>

=cut

sub Init(\@)
{
    my ($rlins) = @_;
    return new(__PACKAGE__, $rlins);
}

=item B<Result> I<$edState>

=item I<$edState>->B<Result>

Returns the lines of the patched file as a list of strings, does not
destroy C<$edState> so you can apply more patches later.

=cut

sub Result($)
{
    my $ra = shift->{RA};

    return
      map { $$_ }
      @{$ra}[ 4 .. ($ra->[1] - 1), ($ra->[2]) .. ($ra->[3] - 1) ];
}

# Internal function: Change current pos to line $n-1, deleting lines
#    $n .. $p inclusive
sub _GoPos($$$)
{
    my ($ra, $n, $p) = @_;
    my $i = $ra->[1];
    my $j = $ra->[2];

    $n = 1 if ($n <= 0);
    $n += 3;
    $p += 4;
    my $m = $j - $i + $p;

    # Change hole start to $n, delete first $p-$n lines after hole
    #    new hole size  is then      ($j-$i) + ($p-$n)
    #    new hole end+1 is then $n + ($j-$i) + ($p-$n)
    #                        ==      ($j-$i) + $p
    #                        == $m
    # In summary:
    # Now: $i..$j-1 is the old position and hole as indexes
    #      $n..$m-1 is the new position and hole as indexes
    #      $p == $m - ($j - $i)

    if ($m > $ra->[3]) {
        $m = $ra->[3];
        $p = $m - $j + $i;
    }

    $n = $p if ($n > $p);

    # Now: $i..$j-1 is the old position and hole as indexes
    #      $n..$m-1 is the new position and hole as indexes
    #      $p == $m - ($j - $i)
    # The new hole size is >= the old hole size
    # The new hole does not go outside the actual lines available
    $ra->[1] = $n;
    $ra->[2] = $m;
    if ($n != $m) {
        if ($m < $j) {    # The most common case, diff works backwards
            if ($j - $m < 1000) {
                @{$ra}[ $m .. ($j - 1) ] = @{$ra}[ $p .. ($i - 1) ];
            } else {
                splice @$ra, $i, ($j - $i);
                splice @$ra, $n, 0, ((undef) x ($m - $n));
            }
        } elsif ($n > $i) {    # This mostly happens when combining diffs
            if ($n - $i < 1000) {
                @{$ra}[ $i ..   ($n - 1) ] =
                  @{$ra}[ $j .. ($n + $j - $i - 1) ];
            } else {
                splice @$ra, $i, ($j - $i);
                splice @$ra, $n, 0, ((undef) x ($m - $n));
            }
        }    # If neither is true, the old hole touches/overlaps/is the
             #    the old hole, and no data needs to be moved
    }
    return;
}

=item B<Do1> I<$edState>, I<$patchline>

=item I<$edState>->B<Do1>(I<$patchline>)

Applies one line from a patch file to C<$edState>.  Returns a true
value if the line was understood.  Carps and returns C<undef> if an
unsupported command is input.

=cut

## no critic (ProhibitExcessComplexity, ProhibitCascadingIfElse)
sub Do1($$)
{
    my $ra = shift->{RA};
    local $_ = shift;
    my $i = $ra->[1];
    my $j = $ra->[2];

    if ($ra->[0]) {
        unless (/^\.$/) {
            my $v = $_;
            if ($i == $j) {
                splice @$ra, $i, 0, ((undef) x 1000);
                $ra->[2] += 1000;
                $ra->[3] += 1000;
            }
            $ra->[ $i++ ] = \$v;
            $ra->[1] = $i;
        } else {
            $ra->[0] = 0;
        }
    } elsif (/^a\s*$/) {
        $ra->[0] = 1;
    } elsif (/^([0-9]+)a/) {
        $ra->[0] = 1;
        _GoPos($ra, 1 + $1, $1);    # Delete nothing
    } elsif (/^d\s*$/) {
        if ($i > 4) {
            if ($j < $ra->[3]) {    # Set current line to line after
                                    #   Deleting current line in the process
                $ra->[ $i - 1 ] = $ra->[$j];
                $ra->[2] = ++$j;
            } else {                # delete last line and stay at last line
                $ra->[1] = --$i;
            }
        } elsif ($j < $ra->[3]) {

            # delete non-existant line 0 and advance to line 1
            $ra->[4] = $ra->[$j];
            $ra->[1] = 5;
            $ra->[2] = ++$j;
        }    # Last possibility is an empty file, do nothing
    } elsif (/^([0-9]+)d/) {
        _GoPos($ra, $1,     $1);
        _GoPos($ra, 1 + $1, $1);    # Set current line to line after
    } elsif (/^([0-9]+),([0-9]+)d/) {
        _GoPos($ra, $1,     $2);
        _GoPos($ra, 1 + $1, $1);    # Set current line to line after
    } elsif (/^c\s*$/) {
        $ra->[0] = 1;
        if ($i > 4) {
            $ra->[1] = --$i;   # delete cur line and append after the one bef
        }    # Otherwise delete nonexistent line 0 and append there
    } elsif (/^([0-9]+)c/) {
        $ra->[0] = 1;
        _GoPos($ra, $1, $1);
    } elsif (/^([0-9]+),([0-9]+)c/) {
        $ra->[0] = 1;
        _GoPos($ra, $1, $2);
    } elsif (m!^s/\^?\\?\.//\s*$!) {
        if ($i > 4) {

            # diff uses this to insert lines consisting of a single .
            $_ = $ra->[ --$i ];
            $$_ =~ s/^\.//;
            $ra->[$i] = $_;
        }
    } elsif (/^w/) {

        # ignore write command sometimes appended to patch files
    } elsif (/^\s*$/) {

        # ignore blank command lines (but not blank lines in added text)
    } else {
        carp "Unexpected non-patch ed command: '" . $_ . "'\n";
        return;
    }
    return 1;
}
## use critic (ProhibitExcessComplexity, ProhibitCascadingIfElse)

=item B<Do> I<$edState>, I<@lines>

=item I<$edState>->B<Do>(I<@lines>)

Simply calls L<B<Do1>|/Do1 $edState, $patchline> for each element of
C<@lines>, returns a true value if all calls were successful or
C<@lines> was empty.  Otherwise returns C<undef>.

=cut

## no critic (RequireArgUnpacking)
sub Do($;)
{
    my $self = shift;
    local $_ = undef;
    my $ok = 1;
    for (@_) {
        unless (ref $_) {
            Do1($self, $_) or ($ok = undef);
        } else {
            for (@$_) {
                Do1($self, $_) or ($ok = undef);
            }
        }
    }
    return $ok;
}
## use critic (RequireArgUnpacking)

=item B<main> I<@ARGV>

The main program code of rred as a function, accepting the command
line syntax in the L<B<SYNOPSIS>|/Command Line:> above.  Returns the
program exit code (0 ok, 1 error, 2 bad syntax).  Running C<rred
args> is the same as running

    perl -MText::Patch::Rred \
        -e 'exit Text::Patch::Rred::main @ARGV' args

=cut

sub main(@)
{
    my (@args) = @_;

    if (@args < 3) {
        print STDERR <<'ENDUSAGE'
Copyright (C) 2006-2009 Jakob Bohm.  All Rights Reserved.
usage:   rred file.old file.new file.patch1 [ file.patch2 ... ]
    (perl open magics are supported in all file names)
Applies one or more diff --ed or diff -e patches to file.old, creating
    file.new . file.old and file.new can be the same file.  Perl open
    magics are supported in all input file names.  This help is displayed
    on stderr, use rred --help 2>file to capture it.
example:
    zcat Packages.diff/2006-04-23-1343.24.gz \
         Packages.diff/2006-04-24-1329.37.gz |
    rred Packages Packages -
ENDUSAGE
          or croak $0. ': Printing usage: ' . $!;
        return 2;
    }

    my $namIn  = shift @args;
    my $namOut = shift @args;

    ## no critic (ProhibitTwoArgOpen)

    open FH, $namIn or croak "Loading '" . $namIn . "': " . $!;
    my @lines = <FH> or croak "Loading '" . $namIn . "': " . $!;
    close FH or croak "Loading '" . $namIn . "': " . $!;
    my $edState = Init(@lines);
    @lines = ();    # Release loading memory

    for my $fn (@args) {
        open FH, $fn or croak "Reading '" . $fn . "': " . $!;
        while (<FH>) { Do1($edState, $_); }
        close FH or croak "Reading '" . $fn . "': " . $!;
    }

    @lines   = Result($edState);
    $edState = undef;              # free memory
    open FH, '>', $namOut or croak "Saving  '" . $namOut . "': " . $!;
    print FH @lines or croak "Saving  '" . $namOut . "': " . $!;
    close FH or croak "Saving  '" . $namOut . "': " . $!;

    ## use critic (ProhibitTwoArgOpen)

    return 0;
}

# Automatically run main if Rred.pm is invoked as a perl program, rather
#    than a script.
# Note: This line would be more readable with paranthesis, but Perl::Critic
#    complains about such clarity.
exit main(@ARGV) unless defined caller;

1;
__END__

# Rest of this file is pod documentation only

=back

=head1 ED COMMANDS

Unfortunately, the GNU diff documentation
(I<S<C<info -f diff -n 'Detailed ed'>>> or
L<http://www.gnu.org/software/diffutils/manual/html_node/Detailed-ed.html>)
is sloppy about specifying exactly which subset of the ed editor
command language might appear in I<S<C<diff --ed>>> output.

Currently the ed "commands" actually used by various versions of
I<S<C<diff --ed>>> and I<S<C<diff -e>>> are believed to be (these are
the ones supported by this module, and also the ones emitted by
GNU diff according to a cursory inspection of its source code):

   a
   ###a
   ###,###a
   c
   ###c
   ###,###c
   d
   ###d
   ###,###d
   s/.//
   w

=head1 OPTIONS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 BUGS AND LIMITATIONS

There seems to be no formal specification for the subset of ed(1) commands
used by I<S<C<diff -e>>>, thus this program is limited to the subset of
ed(1) commands listed above, which may or may not be sufficient to apply the
patch files you encounter in practice.

Although steps have been taken to limit memory consumption, perl still uses
a lot of memory when running this module, as much as 5 times the file size
has been observed in tests.

=head1 DIAGNOSTICS

=over 4

=item rred: Printing usage: F<error message>

When running rred or Text::Patch::Rred::main with less than 3 args, it
should have printed its usage help message to stderr, but this somehow
failed.

=item Loading 'F<file.old>': F<error message>

When loading the original unpatched file from F<file.old>, something went
wrong at the file I/O level.

=item Saving 'F<file.new>': F<error message>

When saving the completely patched file to F<file.new>, something went wrong
at the file I/O level.

=item Reading 'F<file.patch>': F<error message>

When loading one of the patch files from F<file.patch>, something went wrong
at the File I/O level.

=item Unexpected non-patch ed command: 'F<text>'

'F<text>' was found in one of the patch files but is not an ed command
supported by rred.

=back

=head1 DEPENDENCIES

Text::Patch::Rred only needs perl itself (at least version 5.6) and the
standard Carp, Exporter and base modules.

=head1 INCOMPATIBILITIES

None known.

=head1 SEE ALSO

L<diff(1)|diff(1)>, I<S<C<info -f diff -n 'Detailed ed'>>>,
L<patch(1)|patch(1)>, L<ed(1)|ed(1)>, L<red(1)|red(1)>,
L<Text::Patch|Text::Patch>,
L<http://www.gnu.org/software/diffutils/manual/html_node/Detailed-ed.html>

=head1 AUTHOR

Jakob Bohm, E<lt>ehekikkeptiehewdur@jbohm.dkE<gt>

Always include the full module name (with double colons and all)
in the subject line to get past my "spam" filters.

=head1 LICENSE AND COPYRIGHT

Copyright (C) E<169>2006-2009 by Jakob Bohm.  All Rights Reserved.

This library and program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself, either Perl
version 5.6.0 or, at your option, any later version of Perl 5 you may
have available.

=cut

