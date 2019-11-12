use 5.014;
#package Thread::Serialize '1.02'; # not supported by PAUSE or MetaCPAN :-(
package Thread::Serialize;         # please remove if no longer needed

our $VERSION= '1.02';              # please remove if no longer needed

# be as verbose as possble
use warnings;;

# modules that we need
use Storable ();

# use ourselves to determine signature
our $iced;
if ( $Thread::Serialize::no_external_perl ) {
    $iced= unpack( 'l',Storable::freeze( [] ));
    $Thread::Serialize::no_external_perl= 'Signature obtained locally';
}

# use external perl to create signature
else {
    open( my $handle,
      qq( $^X -MStorable -e "print unpack( 'l', Storable::freeze( [] ) )" | )
    ) or die "Cannot determine Storable signature\n";
    $iced= readline $handle;
}

# satisfy -require-
1;

#-------------------------------------------------------------------------------
# freeze
#
# Freeze given parameters into a single scalar value
#
#  IN: 1..N parameters to freeze
# OUT: 1 frozen scalar

sub freeze {

    # something to be frozen
    if (@_) {

        # any of the parameters is special, so really freeze
        foreach (@_) {
            return Storable::freeze( \@_ ) if !defined() or ref() or m#\0#;
        }

        # just concatenate with null bytes (WAY faster)
        return join( "\0", @_ );
    }

    # no parameters, so just undef
    return;
} #freeze

#-------------------------------------------------------------------------------
#  IN: 1 frozen scalar to defrost
# OUT: 1..N thawed data structure

sub thaw {

    # nothing here or not interested
    return if !defined( $_[0] ) or !defined(wantarray);

    # return as list
    if (wantarray) {
        return ( unpack( 'l', $_[0] ) || 0 ) == $iced
          ? @{ Storable::thaw( $_[0] ) }
          : split "\0", $_[0];
    }

    # scalar, really frozen, return first value
    elsif ( ( unpack( 'l',$_[0] ) || 0 ) == $iced ) {
        return Storable::thaw( $_[0] )->[0];
    }

    # return first part of scalar
    return $_[0] =~ m#^([^\0]*)# ? $1 : $_[0];
} #thaw

#-------------------------------------------------------------------------------
#
# Standard Perl Features
#
#-------------------------------------------------------------------------------

sub import {
    shift;

    # determine namespace and subs
    my $namespace= caller().'::';
    @_= qw( freeze thaw ) if !@_;

    # do our exports
    no strict 'refs';
    *{$namespace.$_}= \&$_ foreach @_;

    return;
} #import

#-------------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Serialize - serialize data-structures between threads

=head1 SYNOPSIS

  use Thread::Serialize;    # export freeze() and thaw()

  use Thread::Serialize (); # must call fully qualified subs

  my $frozen = freeze( any data structure );
  any data structure = thaw( $frozen );

=head1 VERSION

This documentation describes version 1.02.

=head1 DESCRIPTION

                  *** A note of CAUTION ***

 This module only functions if threading has been enabled when building
 Perl, or if the "forks" module has been installed on an unthreaded Perl.

                  *************************

The Thread::Serialize module is a library for centralizing the routines
used to serialize data-structures between threads.  Because of this central
location, other modules such as L<Thread::Conveyor>, L<Thread::Pool> or
L<Thread::Tie> can benefit from the same optimilizations that may take
place here in the future.

=head1 SUBROUTINES

There are only two subroutines.

=head2 freeze

 my $frozen = freeze( $scalar );

 my $frozen = freeze( @array );

The "freeze" subroutine takes all the parameters passed to it, freezes them
and returns a frozen representation of what was given.  The parameters can
be scalar values or references to arrays or hashes.  Use the L<thaw>
subroutine to obtain the original data-structure back.

=head2 thaw

 my $scalar = thaw( $frozen );

 my @array = thaw( $frozen );

The "thaw" subroutine returns the data-structure that was frozen with a call
to L<freeze>.  If called in a scalar context, only the first element of the
data-structure that was passed, will be returned.  Otherwise the entire
data-structure will be returned.

It is up to the developer to make sure that single argument calls to L<freeze>
are always matched by scalar context calls to L<thaw>.

=head1 REQUIRED MODULES

 Storable (any)
 Test::More (0.88)

=head1 INSTALLATION

This distribution contains two versions of the code: one maintenance version
for versions of perl < 5.014 (known as 'maint'), and the version currently in
development (known as 'blead').  The standard build for your perl version is:

 perl Makefile.PL
 make
 make test
 make install

This will try to test and install the "blead" version of the code.  If the
Perl version does not support the "blead" version, then the running of the
Makefile.PL will *fail*.  In such a case, one can force the installing of
the "maint" version of the code by doing:

 perl Makefile.PL maint

Alternately, if you want automatic selection behavior, you can set the
AUTO_SELECT_MAINT_OR_BLEAD environment variable to a true value.  On Unix-like
systems like so:

 AUTO_SELECT_MAINT_OR_BLEAD=1 perl Makefile.PL

If your perl does not support the "blead" version of the code, then it will
automatically install the "maint" version of the code.

Please note that any additional parameters will simply be passed on to the
underlying Makefile.PL processing.

=head1 OPTIMIZATIONS

To reduce memory and CPU usage, this module uses L<load>.  This causes
subroutines only to be compiled in a thread when they are actually needed at
the expense of more CPU when they need to be compiled.  Simple benchmarks
however revealed that the overhead of the compiling single routines is not
much more (and sometimes a lot less) than the overhead of cloning a Perl
interpreter with a lot of subroutines pre-loaded.

To reduce the number of modules and subroutines loaded, an external Perl
interpreter is started to determine the Storable signature at compile time.
In some situations this may cause a problem: please set the
C<$Thread::Serialize::no_external_perl> variable to a true value at compile
time B<before> loading Thread::Serialize if this causes a problem.

 BEGIN { $Thread::Serialize::no_external_perl= 1 }
 use Thread::Serialize;

=head1 KNOWN ISSUES

=head2 Embedded Perls

Philip Monsen reported that in the case of an embedded Perl interpreter (e.g.
in a C program), the use of an external executor to determine the Storable
signature, causes problems.  This has been fixed by introducing the global
variable C<$Thread::Serialize::no_external_perl> (see L<OPTIMIZATIONS>).

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2004, 2010, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<load>, L<Thread::Conveyor>, L<Thread::Pool>, L<Thread::Tie>.

=cut
