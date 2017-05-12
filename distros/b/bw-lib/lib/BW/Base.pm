# BW::Base.pm
# Base methods for BW::* modules
# 
# by Bill Weinman - http://bw.org/
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#
# See HISTORY
#

package BW::Base;
use strict;
use warnings;
use 5.008;

use BW::Constants;

our $VERSION = "1.4";

#
# Most of the methods in this module, including new() and _init(),
# are designed to be inherited. 
#

sub new
{
    my $c     = shift;
    my $class = ref($c) || $c;
    my $self  = {};

    bless( $self, $class );
    $self->_init(@_) or return undef;
    return $self;
}

sub _init
{
    my $self = shift;
    my $arg  = $_[0];
    my $sn   = "_init";

    $self->{me} = ref($self);
    $self->{version} = $VERSION;

    # handle different sorts of arguments
    if ( ref($arg) eq 'HASH' ) {    # hash ref?
        foreach my $k ( keys %$arg ) {
            if ( $self->can($k) ) {
                $self->$k( $arg->{$k} );
            } else {
                $self->_error("$sn: no setter for property $k");
            }
        }
    } elsif ( defined $_[1] ) {     # array? (hash but not ref)
        while (@_) {
            my $k = shift;
            my $v = shift;
            if ( $self->can($k) ) {
                $self->$k($v);
            } else {
                $self->_error("$sn: no setter for property $k");
            }
        }
    }

    return SUCCESS;
}

# settergetterers

### generalized setter/getter that is called by all the others
sub _setter_getter
{
    my $self = shift;
    my $arg  = shift;

    # take the name of the caller and use it as the name of the
    # property to be set/get
    my $caller = ( split( /::/, ( caller(1) )[3] ) )[-1];

    if ( defined $arg ) {
        $self->{$caller} = $arg;
        return SUCCESS;
    } else {
        return $self->{$caller};
    }
}

# _setter_getter entry points look like this: 
# sub foo { _setter_getter(@_); }

# debug(m) prints a stack trace along with a debug message
sub debug
{
    my ( $self, $message ) = @_;
    my $out = '';

    my @c = caller(1);
    if ( substr( $c[3], 0, 5 ) eq 'main:' ) { @c = caller(2) }
    my ( $package, $filename, $line, $subroutine, $hashargs, $wantarray, $evaltext, $is_require, $hints, $bitmask ) = @c;

    $message = $self unless ref($self);

    $out .= "$$: ";
    $out .= "$subroutine: " if $subroutine;
    $out .= "$message\n" if $message;
    STDERR->print($out);
}

# set the error string and return FAILURE
sub _error
{
    my $self = shift;
    $self->{error} .= "\n" if $self->{error};
    $self->{error} = '' unless $self->{error};
    $self->{error} .= "$self->{me}: " . ( shift || 'unknown error' );
    return FAILURE;
}

# get and clear error string
sub error
{
    my $self   = shift;
    my $errstr = $self->{error};
    $self->{error} = VOID;
    return $errstr;
}

# check error from other BW::* module
sub checkerror
{
    my ( $self, $o ) = @_;
    my $sn = 'check_error';
    if ($o) {
        my $e = $o->error;
        return $e ? $self->_error($e) : SUCCESS;
    } else {
        return $self->_error("$sn: no or unblessed object");
    }
}

1;

__END__

=head1 NAME

BW::Base - Base routines for BW::* modules

=head1 SYNOPSIS

BW-Lib (collectively, the BW::* module tree) is a set of perl modules
developed by Bill Weinman over the course of about 15 years. It provides
a uniform interface for a number of common functions, most of which are
available elsewhere with other interfaces.

This library duplicates the functionality of a number of other common
modules, so there is very little here that is unique. It's not designed
to be "better" -- only more uniform, and therefor easier to use (at
least I find it so).

It's on CPAN so that it can be easily installed for the various
applications that I distribute that use it.

=head1 DESCRIPTION

The BW::Base class provides common methods inhereted by the other
modules in the BW::* tree. It is not designed to be used directly. 

=over 4

=item B<new>( [ I<key> => I<value> [, ...] ] )

Constructs a new BW::* object while providing optional object
properties. This method is commonly inherited by BW::* classes and is
rarely overriden.

=item B<_init>( [ I<key> => I<value> [, ...] ] )

Called by I<new()> and designed to populate object properties using the
corresponding setters. I<_init()> is typically inherited by BW::* classes
and is occiasionally augmented, but rarely overridden.

=item B<_setter_getter>( [ I<value> ] )

A convenience method called by the various setter/getters like this: 

    sub foo { BW::Base::_setter_getter(@_); }

I<_setter_getter()> uses I<caller()> to get the name of the calling sub
and uses that name for the associated property.

=item B<debug>( I<message> )

Used to write lines to a web log, I<debug()> prints to STDERR and uses
I<caller()> to get the name of the calling sub.

=item B<_error>( I<messgae> )

Use for setting error messages. Returns FAILURE so that it may be called
like:

    if( $badness ) { return $self->_error("I've been bad"); }

=item B<error>

Returns and clears the object error message. 

=item B<checkerror>( I<object> )

Used for checking errors from other BW::* modules. Returns FAILURE and
sets an error (using I<$self->_error()>) or SUCCESS if no error found.

=back

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

See HISTORY file.

=cut

