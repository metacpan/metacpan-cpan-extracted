package setenv;

# where are we?
$VERSION= '0.05';

# be as strict and verbose as possible
use strict;
use warnings;

# satisfy -require-
1;

#---------------------------------------------------------------------------
#
# Standard Perl functionality
#
#---------------------------------------------------------------------------
# import
#
#  IN: 1 class (ignored)
#      2..N hash with key / value pairs to set in %ENV

sub import {
    shift;

    # set the keys / values
    my ( $key, $value );
    $ENV{$key}= $value while ( $key, $value )= splice @_, 0, 2;

    return;
}    #import

#---------------------------------------------------------------------------
# unimport
#
#  IN: 1 class (ignored)
#      2..N environment variables to remove (default: all)

sub unimport {
    shift;

    # get rid of just these, please
    if (@_) {
        delete @ENV{@_};
    }

    # get rid of all
    else {
        %ENV= ();
    }

    return;
}    #unimport

#---------------------------------------------------------------------------

__END__

=head1 NAME

setenv - conveniently (re)set %ENV variables at compile time

=head1 SYNOPSIS

 no setenv;                # BEGIN { %ENV = () }

 no setenv qw( FOO BAR );  # BEGIN { delete @ENV{ qw( FOO BAR ) } }

 use setenv                # BEGIN { $ENV{FOO} = 1, $ENV{BAR} = 2 }
   FOO => 1,
   BAR => 2,
 ;

=head1 DESCRIPTION

Provide a simple way to (re)set C<%ENV> variables at compile time.  Usually
used during debugging only.  This is just syntactic sugar, without any
additives.

=head1 VERSION

This documentation describes version 0.05.

=head1 METHODS

There are no methods.

=head1 THEORY OF OPERATION

Since "import" and "noimport" are called by Perl at compile time when doing a
C<use> or C<no>, it will perform any (re)setting of %ENV at that time.

=head1 REQUIRED MODULES

 (none)

=head1 AUTHOR

 Elizabeth Mattijsen

=head1 COPYRIGHT

Copyright (c) 2008, 2012 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
