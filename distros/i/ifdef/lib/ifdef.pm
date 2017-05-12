package ifdef;

$VERSION= '0.09';

# be strict from now on
use strict;

# take all =begin CAPITALS pod sections
my $ALL;

# output all source to be output as diff to STDERR
BEGIN {
    my $diff= $ENV{'IFDEF_DIFF'} || 0;
    eval "sub DIFF () { $diff }";
} #BEGIN

# get the necessary modules
use IO::File ();

# set up source filter for the initial script
use Filter::Util::Call ();

# initializations
my $STATUS;     # status as returned by source filter
my $ACTIVATING; # whether we're inside a =begin section being activated
my $INPOD;      # whether we're inside any =pod section
my $DEPTH;      # depth of conditionals
my @STATE;      # state of each level
my %IFDEF;      # filename conversion hash

# install an @INC handler
unshift( @INC, sub {
    my ( $ref, $filename, $path )= @_;

    # return what we know of this module
    if ( !ref $ref ) {
        $ref =~ s#/#::#;
        return $IFDEF{$ref};
    }

    # check all directories and handlers
    foreach (@INC) {

        # let that INC handle do it if it is an INC handle and it's not us
        if (ref) {
            goto &$_ unless $_ eq $ref;
        }

        # we found the file
        elsif ( -f ( $path= "$_/$filename" ) ) {

            # create temp file
            open( my $in, $path ) or next;
            my $out= IO::File->new_tmpfile
              or die "Failed to create temporary file for '$path': $!\n";
            $filename =~ s#/#::#;
            $IFDEF{$filename}= $path;

            # process all lines
            local $_= \my $foo; # current state of localizing $_ ?
            while ( readline $in ) {
                &oneline;
                print $out $_;
            }
            close $in;
            &reset;

            # make sure we start reading from start again
            $out->seek( 0, 0 ) or die "Failed to seek: $!\n";

            return $out;
        }
    }

    # indicate that the rest should be searched (which will fail)
    return;
} );

# satisfy require
1;

#---------------------------------------------------------------------------
# process
#
# Process a string (consisting of many lines)
#
#  IN: 1 string to process
# OUT: 1 processed string (in place change if called in void context)

sub process {

    # process all lines
    my @line= split m#(?<=$/)#, $_[0];
    &reset;
    local $_= \my $foo;
    &oneline foreach @line;

    # close of activating section (e.g. when called by "load")
    push @line,"}$/" if $ACTIVATING;

    # return if not in void context
    return join( '', @line ) if defined wantarray;

    # change in place
    $_[0]= join( '',@line );

    return undef;
} #process

#---------------------------------------------------------------------------
# reset
#
# Reset all internal variables to a known state

sub reset { $ACTIVATING= $INPOD= $DEPTH= 0 } #reset

#---------------------------------------------------------------------------
# oneline
#
# Process one line in $_ in place

sub oneline {

    # let the world know if we should
    print STDERR "<$_" if DIFF;

    # it's a pod marker
    if ( m#^=(\w+)# ){

        # going back to source
        if ( $1 eq 'cut' ) {
            $_= $ACTIVATING ? "}$/" : $/;
            &reset;
        }

        # beginning potentially special pod section
        elsif ( $1 eq 'begin' ) {
            if ( m#^=begin\s+([A-Z_0-9]+)\b# ) {

                # activating
                if ( $ALL or $ENV{$1} ) {
                    $_= $ACTIVATING ? "}{$/" : "{;$/";
                    $ACTIVATING= 1;
                    $INPOD=      0;
                }

                # not activating now
                else {
                    $_= $ACTIVATING ? "}$/" : $/;
                    $ACTIVATING= 0;
                    $INPOD=      1;
                }
            }

            # normal begin of pod
            else {
                $_= $/;
                $INPOD= 1;
            }
        }

        # at the end of a possibly activated section
        elsif ( $1 eq 'end' ) {
            $_ = $ACTIVATING ? "}$/" : $/;
            $ACTIVATING= 0;
            $INPOD=      1;
        }

        # it's another pod directive
        else {
            $_= $/;
            $INPOD= 1;
        }
    }

    # already inside pod
    elsif ($INPOD) {
        $_= $/;
    }

    # looks like comment, make it normal line if so indicated
    elsif ( m/^#\s+([A-Z_0-9]+)\b/ ) {
         s/^#\s+(?:[A-Z_0-9]+)\b// if $ENV{$1};
    }

    # let the world know if we should
    print STDERR ">$_" if DIFF;
} #oneline

#---------------------------------------------------------------------------

# Perl specific subroutines

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2..N keys to watch for

sub import {

    # being called from source (unless it's from the test-suite)
    warn "The '".
          __PACKAGE__.
          "' pragma is not supposed to be called from source\n"
           if ( (caller)[2] ) and ( $_[0] ne '_testing_' and !shift );

    # lose the class
    shift;

    # check all parameters
    my @ignored;
    foreach (@_) {
        # it's all
        if ( m#^:?all$# ) {
            $ALL= 1;
        }

        # not all
        elsif ( m#^:?selected$# ) {
            $ALL= 0;
        }

        # looks like an environment var reference
        elsif ( m#^[A-Z_0-9]+$# ) {
            $ENV{$_}= 1;
        }

        # huh?
        else {
            push @ignored, $_;
        }
    }

    # huh?
    warn "Ignored parameters: @ignored\n" if @ignored;

    # make sure we start with a clean slate
    &reset;

    # set up source filter
    return Filter::Util::Call::filter_add( sub {
        if ( ( $STATUS= Filter::Util::Call::filter_read() ) > 0 ) {
            &oneline;
        }
        $STATUS;
    } );
} #import

#---------------------------------------------------------------------------

__END__

=head1 NAME

ifdef - conditionally enable text within pod sections as code

=head1 SYNOPSIS

  export DEBUGGING=1
  perl -Mifdef yourscript.pl

 or:

  perl -Mifdef=VERBOSE yourscript.pl

 or:

  perl -Mifdef=all yourscript.pl

 with:

  ======= yourscript.pl ================================================

  # code that's always compiled and executed

  =begin DEBUGGING

  warn "Only compiled and executed when DEBUGGING or 'all' enabled\n"

  =begin VERBOSE

  warn "Only compiled and executed when VERBOSE or 'all' enabled\n"

  =cut

  # code that's always compiled and executed

  # BEGINNING compiled and executed when BEGINNING enabled

  ======================================================================

=head1 VERSION

This documentation describes version 0.09.

=head1 DESCRIPTION

The "ifdef" pragma allows a developer to add sections of code that will be
compiled and executed only when the "ifdef" pragma is specifically enabled.
If the "ifdef" pragma is not enabled, then there is B<no> overhead involved
in either compilation of execution (other than the standard overhead of Perl
skipping =pod sections).

To prevent interference with other pod handlers, the name of the pod handler
B<must> be in uppercase.

If a =begin pod section is considered for replacement, then a scope is
created around that pod section so that there is no interference with any
of the code around it.  For example:

 my $foo= 2;

 =begin DEBUGGING

 my $foo= 1;
 warn "debug foo = $foo\n";

 =cut

 warn "normal foo = $foo\n";

is converted on the fly (before Perl compiles it) to:

 my $foo= 2;

 {

 my $foo= 1;
 warn "foo = $foo\n";

 }

 warn "normal foo = $foo\n";

But of course, this happens B<only> if the "ifdef" pragma is loaded B<and>
the environment variable B<DEBUGGING> is set.

As a shortcut for only single lines of code, you can also specify a single
line of code inside a commented line:

 # DEBUGGING print "we're in debugging mode now\n";

will only print the string "we're in debugging mode now\n" when the environment
variable B<DEBUGGING> is set.  Please note that the 'all' flag is ignored in
this case, as there is too much standard code out there that uses all uppercase
markers at the beginning of an inline comment which cause compile errors if
they would be enabled.

=head1 WHY?

One day, I finally had enough of always putting in and taking out debug
statements from modules I was developing.  I figured there had to be a
better way to do this.  Now, this module allows to leave debugging code
inside your programs and only have them come alive when I<you> want them
to be alive.  I<Without any run-time penalties when you're in production>.

=head1 REQUIRED MODULES

 Filter::Util::Call (any)
 IO::File (any)

=head1 IMPLEMENTATION

This version is completely written in Perl.  It uses a source filter to
provide its magic to the script being run B<and> an @INC handler for all
of the modules that are loaded otherwise.  Because the pod directives are
ignored by Perl during normal compilation, the source filter is B<not> needed
for production use so there will be B<no> performance penalty in that case.

=head1 CAVEATS

=head2 Overhead during development

Because the "ifdef" pragma uses a source filter for the invoked script, and
an @INC handler for all further required files, there is an inherent overhead
for compiling Perl source code.  Not loading ifdef.pm at all, causes the normal
pod section ignoring functionality of Perl to come in place (without any added
overhead).

=head2 No changing of environment variables during execution

Since the "ifdef" pragma performs all of this magic at compile time, it
generally does not make sense to change the values of applicable environment
variables at execution, as there will be no compiled code available to
activate.

=head2 Modules that use AutoLoader, SelfLoader, load, etc.

For the moment, these modules bypass the mechanism of this module.  An
interface with load.pm is on the TODO list.  Patches for other autoloading
modules are welcomed.

=head2 Doesn't seem to work on mod_perl

Unfortunately, there still seem to be problems with getting this module to
work reliably under mod_perl.

=head2 API FOR AUTOLOADING MODULES

The following subroutines are available for doing your own processing, e.g.
for inclusion in your own AUTOLOADing modules.  The subroutines are B<not>
exported: if you want to use them in your own namespace, you will need to
import them yourself thusly:

 *myprocess = \&ifdef::process;

would import the "ifdef::process" subroutine as "myprocess" in your namespace..

=head3 process

 ifdef::process( $direct );

 $processed = ifdef::process( $original );

The "process" subroutine allows you process a given string of source code
and have it processed in the same manner as which the source filter / @INC
handler of "ifdef.pm" would do.

There are two modes of calling: if called in a void context, it will process
the string and put the result in place.  An alternate method allows you to
keep a copy: if called in scalar or list context, the processed string will
be returned.

See L</"oneline"> of you want to process line by line.

=head3 reset

 &ifdef::reset;

The "reset" subroutine is needed only if you're doing your own processing with
the L</"oneline"> subroutine.  It resets the internal variables so that no
state of previous calls to L</"process"> (or the internally called source
filter or @INC handler) will remain.

=head3 oneline

 &ifdef::oneline;

The "oneline" subroutine does just that: it process a single line of source
code.  The line of source to be processed is expected to be in B<$_>.  The
processed line will be stored in B<$_> as well.  So there are no input or
output parameters.

See L</"process"> of you want to a string consisting of many lines in one go.

=head1 MODULE RATING

If you want to find out how this module is appreciated by other people, please
check out this module's rating at L<http://cpanratings.perl.org/i/ifdef> (if
there are any ratings for this module).  If you like this module, or otherwise
would like to have your opinion known, you can add your rating of this module
at L<http://cpanratings.perl.org/rate/?distribution=ifdef>.

=head1 ACKNOWLEDGEMENTS

Nick Kostirya for the idea of activating single line comments.

Konstantin Tokar for pointing out problems with empty code code blocks and
inline comments when the "all" flag was specified.  And providing patches!

=head1 RELATED MODULES

It would appear that Damian Conway's L<Smart::Comments> is scratching the
same itch I had when I implemented this module a long time ago.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2004, 2005, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
