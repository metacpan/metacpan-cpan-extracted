package persona;

$VERSION= '0.13';

# be as strict and verbose as possible
use strict;
use warnings;

# modules that we need
use List::Util qw( first );

# persona and semaphore to indicate @INC watcher is installed for this process
my $process_persona;

# regular expression to check
my $all;
my @only_for;

# are we debugging?
BEGIN {
    my $debug= $ENV{DEBUG} || 0;
    $debug= 0 if $debug !~ m#^[0-9]+$#; ## only numeric constants
    eval "sub DEBUG () { $debug }";
}    #BEGIN

# log pipe if we're debugging
BEGIN {
    *TELL= DEBUG
       ? sub {
             my $format = shift() . "\n";
             printf STDERR $format, @_;
         }
       : sub { };
}    #BEGIN

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Class methods
#
#-------------------------------------------------------------------------------
# path2source
#
# Convert a given handle to source code for a given persona
#
#  IN: 1 class (ignored)
#      2 path
#      3 persona to parse for (default: current)
# OUT: 1 scalar reference to source code or undef
#      2 number of lines skipped (optional)

sub path2source {
    my ( undef, $path, $persona )= @_;
    $persona= $process_persona if !defined $persona;

    # could not open file, let the outside handle this
    open( my $handle, '<', $path ) or return;
    TELL 'Parsing %s', $path if DEBUG;

    # no persona, so we don't need to do any parsing at all
    if ( !$persona ) {

        # enable slurp mode
        local $/;
        my $source= readline $handle;

        # we're done
        return wantarray ? ( \$source, 0 ) : \$source;
    }

    # initializations
    my $done;
    my $skipped= 0;
    my $active=  1;
    my $line_nr= 0;
    my $source=  '';

    # until we reach end of file
  LINE:
    while (1) {
        my $line= readline $handle;
        last LINE if !defined $line;

        # seen __END__ or __DATA__, no further looking needed here
        if ($done) {
            $source .= $line;
            next LINE;
        }

        # reached the end of logical code, continue without further looking
        elsif ( $line =~ m#^__(?:DATA|END)__$# ) {  ## syn hilite
            $done= 1;
            $source .= $line;
            next LINE;
        }

        # we've seen a line and want to remember that
        $line_nr++;

        # code for new persona?
        if ( $line =~ m/^#PERSONA\s*(.*)/ ) {
            my $rest= $1;

            # all personas
            if ( !$rest ) {

                # switching from inactive persona to all
                if ( !$active ) {
                    $active= 1;

                    # make sure errors / stack traces have right line info
                    $source .= sprintf "#line %d %s (all personas)\n",
                      $line_nr + 1, $path;

                    # don't bother adding the line with #PERSONA
                    next LINE;
                }
            }

            # we have an expression
            else {

                # huh?
                die "Found illegal characters in PERSONA specification:\n$rest"
                  if $rest =~ m#[^\w\s\(\)\|!]#;

                # change simple list into expression
                1 while $rest =~ s#(?<!\!)(\w+)\s+(\w+)#$1 || $2#;

                # create evallable expression
                my %value= ( $persona => 1 );
                $rest =~ s#(\w+)# $value{$1} || 0 #ge;

                # evaluate expression
                my $ok= eval $rest;
                die "Error in evaluation persona specification:\n'$rest'\n$@"
                  if $@;

                # stop copying code for now
                if ( !$ok ) {
                    $active= undef;
                }

                # switching from inactive persona to all
                elsif ( !$active ) {
                    $active= 1;

                    # make sure errors / stack traces have right line info
                    $source .=
                      sprintf "#line %d %s (allowed by persona '%s')\n",
                      $line_nr + 1, $path, $persona;

                    # don't bother adding the line with #PERSONA
                    next LINE;
                }
            }
        }

        # we're not doing this line
        $skipped++, next LINE if !$active;

        # new package, make sure it knows about PERSONA if it doesn't yet
        if ( $line =~ m#^\s*package\s+([\w:]+)\s*;# ) {
            no strict 'refs';
            my $sub= $1 . '::PERSONA';
            *{$sub}= \&main::PERSONA if !exists &$sub;
        }

        # we'll do this line
        $source .= $line;
    }
    # show source if *really* debugging
    TELL $source if DEBUG > 2;

    return wantarray ? ( \$source, $skipped ) : \$source;
} #path2source

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
# import
#
#  IN: 1 class (ignored)
#      2 .. N attributes

sub import {
    my ( undef, @attr )= @_;

    # assume we want to set persona if only one parameter
    unshift @attr, 'persona' if @attr == 1;

    # fetch name's name
    my $name= $ENV{ENV_PERSONA} || 'PERSONA';

    # fetch parameters we know
    my @only_for_new;
    my @huh;
    while ( my ( $key, $value ) = splice @attr, 0, 2 ) {

        # setting module specification 
        if ( $key eq 'only_for' ) {
            push @only_for_new, $value;
        }

        # setting persona
        elsif ( $key eq 'persona' ) {

            # huh?
            die "Already have '$process_persona' as persona, "
              . "cannot specify '$value' now"
              if defined $process_persona and $value ne $process_persona;

            $ENV{$name}= $value;
        }

        # don't know what to do with this
        else {
            push @huh, $key;
        }
    }

    # find persona we need to work for
    if ( !defined $process_persona ) {
        $process_persona= $ENV{$name};

        # too bad, we don't have a persona
        $process_persona= '' if !defined $process_persona;

        # force some sanity
        die "Persona may only contain alphanumeric characters,"
          . " e.g. '$process_persona'"
          if $process_persona =~ s#\W##sg;

        # create constant in main (for easy access later)
        die $@ if !eval "sub main::PERSONA () { '$process_persona' }; 1";

        # we have a persona, great!
        if ($process_persona) {

            # install handler if we have a persona
            unshift @INC, \&_inc_handler;

            # we're being called in a script
            if ( !( ()= caller(3) )                # only 3 levels below us
                 and ( (caller(0))[1] ne '-e' )    # not a one liner
                 and ( (caller(2))[3] eq '(eval)'  # but an eval at lowest level
               ) ) {

                # make sure we will process this file
                unshift @only_for, qr#^$0$#;  ## syn hilite

                # do the script, but through the @INC handler
                TELL 'Recursively calling script for "%s"', $process_persona
                  if DEBUG;
                do $0;

                # we're done, nothing left to do at this level
                exit;
            }

            TELL 'Interpreting source code as "%s"', $process_persona if DEBUG;
        }
    }

    # extra parameters
    die "Don't know what to do with @{[ sort @huh ]}" if @huh;

    # we have some kind of specification which modules to check
    if (@only_for_new) {

        # normalize all new settings
      ONLY_FOR:
        foreach my $only_for (@only_for_new) {

            # need to check what we have
            if ( my $ref= ref $only_for ) {
                die "Can only handle references of type '$ref'"
                  if $ref ne 'Regexp';
    
                # it's ok
                push @only_for, $only_for;
            }

            # do all and everything
            elsif ( $only_for eq '*' ) {
                $all= 1;
                @only_for= @only_for_new= ();
                TELL "Look for personas in all files" if DEBUG;
                last ONLY_FOR;
            }
    
            # just a string, make it a regexp
            else {
                push @only_for, qr#^$only_for#;
            }
        }

        TELL "Added regular expression for matching file names:\n  %s",
          join( "\n  ", @only_for[ -@only_for_new .. $#only_for ] ),
          if DEBUG and @only_for_new;
    }

    # export constant to the caller if not done so already
    no strict 'refs';
    my $sub= caller() . '::PERSONA';
    *{$sub}= \&main::PERSONA if !exists &$sub;

    return;
} #import

#-------------------------------------------------------------------------------
#
# Internal subroutines
#
#-------------------------------------------------------------------------------
# _inc_handler
#
#  IN: 1 code reference to this sub
#      2 file to look for
# OUT: 1 handle to read source from

sub _inc_handler {
    my ( $self, $file )= @_;

    # shouldn't handle this file, let require handle it (again)
    if ( !$all and !first { $file =~ m#$_# } @only_for ) {
        TELL 'Not handling %s', $file if DEBUG > 1;
        return undef;
    }

    # can't find ourselves?
    my $first= first { $INC[$_] eq $self } 0 .. $#INC;
    die "Could not find INC handler in @INC" if !defined $first;

    # could not find file, let require handle it (again)
    my $path= first { -e } map { "$INC[$_]/$file" } $first + 1 .. $#INC;
    if ( !$path ) {
        TELL 'Could not find %s', $file if DEBUG > 1;
        return undef;
    }

    # parse the source
    my ( $source, $skipped )= __PACKAGE__->path2source($path);

    # could not open file, or nothing skipped, let -require- handle it
    return undef if !$source or !$skipped;

    # set %INC correctly
    $path =~ s#^\./##; # normalize just as perl does
    $INC{$file}=
      "$path (skipped $skipped lines for persona '$process_persona')";

    # make sure that __FILE__ will be correct as well
    $$source= "#line 1 $path\n$$source";

    # convert source to handle, so require can handle it
    open( my $require, '<', $source )
      or die "Could not open in-memory source for reading: $!";

    return $require;
}    #_inc_handler

#-------------------------------------------------------------------------------

__END__

=head1 NAME

persona - control which code will be loaded for an execution context

=head1 SYNOPSIS

  $ PERSONA=cron perl foo.pl

  foo.pl
  =================
  use persona only_for => '*';  # all modules, maybe regex
  use Foo;

  Foo.pm
  =================
  package Foo;
  # code to be compiled always

  #PERSONA cron || app || book
  # code to be compiled only for the "cron", "app" and "book" personas

  #PERSONA
  # code to be compiled always

  #PERSONA !cron
  # code to be compiled for all personas except "cron"

  #PERSONA !( app || book )
  # code to be compiled for all personas except "app" and "book"

  my $limit = PERSONA eq 'app' ? 100 : 10; # code using the constant

=head1 VERSION

This documentation describes version 0.13.

=head1 DESCRIPTION

This module was born out of the need to be able to easily specify which
subroutines of a module should be available (as in "compiled") in different
sets of mod_perl environments (e.g. the visitors front end web servers, or
the personnel's back-office web servers).  This both from a memory, database
and CPU usage point of view, as well as from the viewpoint of security.

This is most useful when using a database abstraction layer such as
L<Class::DBI> or L<DBIx::Class>, where all of the code pertaining to an
object is located in one file, while only parts of the code are actually
needed (or wanted) on specific execution contexts.

=head1 OVERVIEW

By specifying an environment variable, by default C<PERSONA>, it is possible
to indicate the persona for which the source code should be compiled.  Any
modules that are indicated to support persona dependent code will then be
checked for existence of persona conditional markers, and any code that is
after a persona marker that does not match the currently selected persona,
will be discarded during compilation.

Most likely, not all modules that you load need to be checked for persona
specific code.  Therefor you must indicate which modules you want this check
to be performed for.  This can be done with the C<only_for> parameter when
loading the C<persona> module:

 use persona only_for => 'Foo';

will check all files that start with C<Foo>, such as:

  Foo.pm
  FooBar.pm
  Foo/Bar.pm

but not:

  Bar.pm

You can also specify a regular expression that way:

 use persona only_for => qr/^(?:Foo|Bar)\.pm$/;

will only check the C<Foo.pm> and C<Bar.pm> files.  Usually the modules of
a certain context that you want checked, share a common prefix.  It is then
usually easier to specify the setting on the command line:

 $ PERSONA=cron perl -Mpersona=only_for,Foo script.pl

would execute the script C<script.pl> for the persona C<cron> and have all
modules that start with C<Foo> checked for persona dependent code.  Only code
that is to be included for all personas, or specifically for the C<cron>
persona, will be compiled.

Suppose we want to have a method C<override_access> available only for the
C<backoffice> persona.  This can be done this way:

 #PERSONA backoffice
 sub override_access { # only for the back office persona
     # code...
 }
 #PERSONA
 sub has_access {      # for all personas
     # code...
 }

It is also possible to have code compiled for all personas B<except> a specific
one:

 #PERSONA !cron
 sub not_for_cron {
     # code...
 }
 #PERSONA

would make the subroutine C<not_for_cron> available for personas B<except>
C<cron>.  It is also possible to have code compiled for a set of personas:

 #PERSONA cron || backoffice
 sub for_cron_and_backoffice {
     # code...
 }
 #PERSONA

would make the subroutine C<for_cron_and_backoffice> available for the personas
C<cron> and C<backoffice>.

Or it is possible to have code compiled for all personas B<except> for a
set of personas:

 #PERSONA !( app || book )
 sub not_for_app_or_book {
     # code...
 }
would make the subroutine C<not_for_app_or_book> available for all personas
B<except> C<app> and C<book>.

Basically any valid expression consisting of C< \\w \\s ( ) ! || > is allowed:
if that expression yields a true value, then that code will be compiled.

If you're lazy, and you don't care about any overhead while compiling code,
you can indicate that you want B<all> modules checked for PERSONA specific
code by specifying C<'*'> as the indication of which files should be checked.

 use persona only_for => '*';

If you want to specify multiple conditions, you can specify C<only_for> more
than once:

 use persona only_for => 'Foo', only_for => 'Bar';

To facilitate more complex persona dependencies, all namespaces seen by this
module automatically have the constant PERSONA imported into it.  This allows
the constant to be used in actual code (which will then be optimized away by
the Perl compiler so that the code that shouldn't be compiled for that persona,
really isn't available for execution in the end).

If you want to make sure that the use of the C<PERSONA> constant in a file
will not break code when using L<strict> (which you B<should>!), you can add:

  use strict;
  use persona;  # compilation error without this
  print "Running code for persona " . PERSONA . "\n"
    if PERSONA;

in that file.  That will export the PERSONA constant, even when it is not
set.  Another example from L<Class::DBI> / L<DBIx::Class>::

  __PACKAGE__->columns( All => ( PERSONA eq 'backoffice' ? @all : @subset ) );

which will only use all columns when executing as the backoffice persona.
Otherwise only a subset of columns will be available.

=head1 SPECIFYING PERSONA WITHOUT ENVIRONMENT VARIABLES

In order to be able to easily support operating systems that have shells that
do not support easy setting of environment variables on the command line, you
can also specify the persona from the command line while loading this module:

 $ perl -Mpersona=cron bar.pl

will run set the persona to "cron".  This can also be combined with other
parameters, such as:

 $ perl -Mpersona=only_for,*,persona,cron bar.pl

would process all files loaded for the C<cron> persona.  Alternately, the same
is possible in source:

 use persona 'cron';

would select the C<cron> persona, but only if no other persona was selected
before.

=head1 EXAMPLES

The test-suite contains some examples.  More to be added as time permits.

=head1 THEORY OF OPERATION

When the C<import> class method of C<persona> is first called, it looks at
whether there is a C<ENV_PERSONA> environment variable is specified.  If it
is, its value is used as the name of the environment variable to check for
the value to be assigned to the persona.  If the C<ENV_PERSONA> environment
variable is not found, C<PERSONA> will be assumed for the name to check.

If there is a non-empty persona value specified, then an C<@INC> handler is
installed.  This handler is offered each file that is C<require>d or C<use>d
from that moment onward.  If it is B<not> a file that should be checked for
persona conditional code, it is given back to the normal C<require> handling.

If the import method determines it is being called from a script that is being
called from the command line, it will C<do> the script and then C<exit>.
This causes the script itself be called with C<require>, and thus be handled
by the C<@INC> handler we installed.

If it B<is> a file that should be checked, it is searched in the C<@INC>
array.  If found, it is opened and all the lines that should be part of the
code for the current persona, are added to an in-memory buffer.  Then a memory
file handle is opened on that buffer and returned for normal C<require>
handling.  To make sure that any errors or stack traces show the right line
numbers, appropriate #line directives are added to the source being offered
to the perl compilation process.

Please do:

 perldoc -f require

for more information about @INC handlers.

=head1 CLASS METHODS

Some class methods are provided as building bricks for more advanced usage of
the persona functionality.

=head2 path2source

 my $source_ref = persona->path2source($path);  # current persona

 my ( $source_ref, $skipped ) = persona->path2source( $path, $persona );

Process the file given by the absolute path name for the given persona.  Assume
the current process' persona if none given.  Returns a reference to the scalar
containing the processed source, or undef if the file could not be opened.
Optionally also returns the number of lines in the original source that were
skipped.

This functionality is specifically handy for deployment procedures where source
files are pre-processed for execution in their intended context, rather than
doing this at compilation time each time.  This removes the need for having
this module installed in production environments and reduces possible problems
with wrong persona settings in an execution context.

=head1 REQUIRED MODULES

 (none)

=head1 MODULE RATING

If you want to find out how this module is appreciated by other people, please
check out this module's rating at L<http://cpanratings.perl.org/p/persona> (if
there are any ratings for this module).  If you like this module, or otherwise
would like to have your opinion known, you can add your rating of this module
at L<http://cpanratings.perl.org/rate/?distribution=persona>.

=head1 ACKNOWLEDGEMENTS

Inspired by the function of L<load> and L<ifdef> modules from the same author.
And thanks to the pressure (perhaps unknowingly) exerted by the Amsterdam Perl
Mongers.

=head1 CAVEATS

=head2 %INC SETTING

Please note that if any lines were removed from the source, the path name in
C<%INC> will be postfixed with the string:

  (skipped %d lines for persona '%s')

where the %d will be filled with the number of lines skipped, and the %s will
be filled with the persona for which the lines were removed.  Also note that
the __FILE__ compiler constant will B<not> have this information postfixed,
as that is more or less expected to be just containing a path at all times.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 HISTORY

Developed for the mod_perl environment at Booking.com.

=head1 COPYRIGHT

Copyright (c) 2009, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
