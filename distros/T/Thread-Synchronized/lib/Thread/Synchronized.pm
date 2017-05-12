package Thread::Synchronized;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.03';
use strict;

# Make sure we can do threads
# Make sure we can do shared variables

use threads ();
use threads::shared ();

# Make sure we can do a source filter

use Filter::Util::Call ();

# The hash containing the subroutine locks

our %VERSION; # this is called VERSION to save on a glob

# Satisfy -require-

1;

#---------------------------------------------------------------------------

# Methods needed by Perl

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)

sub import {

# Obtain the current package (default package to be prefixed to subroutine name)
# Register the caller's package for this module in load (if possible)

    my $package = caller();
#    load->register( $package,__PACKAGE__ )
#     if defined( $load::VERSION ) and $load::VERSION > 0.11;

# Obtain a reference to the fixit routine (ref only to so it'll clean up)
#  Obtain the parameters
#  Initialize the extra code to be generated

    my $fix = sub {
        my ($sub,$prototype,$attributes) = @_;
        my $code = '';

#  We want subroutine synchronization (removing the attribute)
#   We want object synchronization (keeping the attribute, others might need it)
#    Add code to lock on the object, it should be externally shared

        if ($attributes =~ s#\bsynchronized\b##) {
            if ($attributes =~ m#\bmethod\b#) {
                $code = 'lock( $_[0] );';

#   Else (just synchronize)
#    Create the key to be used to synchronize this sub
#    Make sure that becomes a shared value
#    Create the extra code to lock the sub
#  Return the substitute string

            } else {
                my $key = $sub =~ m#::# ? $sub : $package.'::'.$sub;
                threads::shared::share( $VERSION{$key} );
                $code = 'lock( $'.__PACKAGE__."::VERSION{'$key'} );";
            }
        }
        "sub $sub$prototype:$attributes\{$code";
    };

# Install the filter as an anonymous sub
#  Initialize status

    Filter::Util::Call::filter_add( sub {
        my $status;

# If there are still lines to read
#  Update package info if a package was found
#  Convert the line if "synchronized" attribute found
# Return the status

        if (($status = Filter::Util::Call::filter_read()) > 0) {
            $package = $1 if m#\bpackage\s+([\w:_]+)#;
#warn $_ if # uncomment if you want to see changed lines
            s#\bsub\s+((?:\w|_|::)+)([^:]*):([^{]+){#$fix->($1,$2,$3)#e;
        }
        $status;
    } );
} #import

#---------------------------------------------------------------------------

__END__

=head1 NAME

Thread::Synchronized - synchronize subroutine calls between threads

=head1 SYNOPSIS

    use Thread::Synchronized;  # activate synchronized and method attribute

    sub foo : synchronized { } # only one subroutine running at a time

    sub bar : synchronized method { } # only one method per object

=head1 DESCRIPTION

                  *** A note of CAUTION ***

 This module only functions on Perl versions 5.8.0 and later.
 And then only when threads are enabled with -Dusethreads.  It
 is of no use with any version of Perl before 5.8.0 or without
 threads enabled.

                  *************************

This module currently adds one feature to threaded programs: the
"synchronized" and "method" subroutine attributes which causes calls to that
subroutine to be automatically synchronized between threads (only one thread
can execute that subroutine at a time or per object at a time).

=head1 REQUIRED MODULES

 (none)

=head1 CAVEATS

This module is implemented using a source filter.  This has the advantage
of not needing to incur any runtime overhead.  But this of course happens at
the expense of a slightly longer compile time.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2003 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads>.

=cut
