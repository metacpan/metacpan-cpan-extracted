##==============================================================================
## Tie::StrictHash - a hash with constraints on adding elements
##==============================================================================
## Copyright 2001 Kevin Michael Vail.  All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##==============================================================================
## $Id: StrictHash.pm,v 1.0 2001/03/17 17:03:02 kevin Exp $
##==============================================================================
require 5.005;

package Tie::StrictHash;
use strict;
use Tie::Hash;
use Carp qw(carp croak cluck confess);
use Exporter ();
use vars qw(@ISA $VERSION @EXPORT *croak);
@ISA = qw(Tie::StdHash Exporter);
@EXPORT = qw(strict_hash);
($VERSION) = q$Revision: 1.0 $ =~ /^Revision:\s+([\d.]+)\s*$/;

my $locked = 0;

=head1 NAME

Tie::StrictHash - A hash with 'strict'-like semantics

=head1 SYNOPSIS

use Tie::StrictHash;

C<strict_hash I<%hash>, I<key> =E<gt> I<value>, ...;>

C<I<$hashctl> = tie I<%hash>, 'Tie::StrictHash', I<key> =E<gt> I<value> , ...;>

C<I<$hashctl>-E<gt>add(I<key> =E<gt> I<value>, ...);>

C<I<@values> = I<$hashctl>-E<gt>delete(I<key>, ...);>

C<I<$hashctl>-E<gt>clear;>

=head1 DESCRIPTION

C<Tie::StrictHash> is a module for implementing some of the same semantics for
hash members that 'use strict' gives to variables.  The following constraints
are applied to a strict hash:

=over 4

=item o

No new keys may be added to the hash except through the B<add> method of the
hash control object.

=item o

No keys may be deleted except through the B<delete> method of the hash control
object.

=item o

The hash cannot be re-initialized (cleared) except through the B<clear> method
of the hash control object.

=item o

Attempting to retrieve the value for a key that doesn't exist is a fatal error.

=item o

Attempting to store a value for a key that doesn't exist is a fatal error.

=back

In order to make any changes or modifications to the hash, you must either keep
the return value from B<strict_hash> (or B<tie>) or retrieve it by using C<tied
I<%hash>>. Think of it as the "key" that "unlocks" the hash so that you can make
changes to it.

The original reason for writing this module was for classes that implement
an object as a hash, using hash members as instance variables.  It's all too
easy to use the wrong member name, with the same results as misspelling a
variable name when C<use strict> isn't in effect.

Note that just as C<use strict> allows you to create new variables by either
specifying an explicit package name or by using C<use vars>, a strict hash
allows you to create or delete members by using the appropriate methods.
However, it does prevent you from creating or deleting members accidentally.
This is in keeping with the general philosophy of Perl.

If you import the pseudo-symbol C<warn>, Tie::StrictHash will only issue
warning messages rather than dying when an attempt is made to reference a hash
value that doesn't exist.

If you import the pseudo-symbol C<confess>, either by itself or along with
C<warn>, you'll get a stack backtrace as well when something happens.

=cut

##==============================================================================
## import
##==============================================================================
sub import {
	my $class = shift;
	my $confess = grep { $_ eq 'confess' } @_;
	if (grep { $_ eq 'warn' } @_) {
		*croak = $confess ? *Carp::cluck : *Carp::carp;
	} else {
		*croak = $confess ? *Carp::confess : *Carp::croak;
	}
	@_ = grep { $_ ne 'warn' && $_ ne 'confess' } @_;
	unshift(@_, $class);
	goto &Exporter::import;
}

=pod

=head1 DEFINING A STRICT HASH

Use the B<strict_hash> subroutine, or call B<tie> directly.  The B<new> method
is provided to create a strict anonymous hash.  This is both a hash reference
and its own hash control object.

=over 4

=item C<I<$hashctl> = strict_hash I<%hash>, I<key> =E<gt> I<value>, ...;>

This routine is exported by default, and simply performs the B<tie> statement
listed next.  However, it also preserves the original contents of I<%hash>,
while calling B<tie> directly does not.  However, if you call B<untie> I<%hash>,
anything added since the call to B<strict_hash> is lost and only the original
contents will remain.

=cut

##==============================================================================
## strict_hash
##==============================================================================
sub strict_hash (\%@) {
    my $hash = shift;
    my %original = %$hash;
    return tie %$hash, 'Tie::StrictHash', %original, @_;
}

=item C<I<$hashctl> = tie I<%hash>, 'Tie::StrictHash', I<key> =E<gt> I<value> , ...;>

Sets I<%hash> as a 'strict' hash, and defines its initial contents.  The
returned value I<$hashctl> is used to make any modifications to the hash.
The original contents of the hash are lost when you call B<tie> directly
(although they come back if you B<untie> the hash later).

=back

=head1 METHODS

Except for B<new>, these must be invoked by using the I<$hashctl> object.  This
is returned by B<strict_hash> or B<tie>, or may be retrieved by using C<tied
I<%hash>> at any time.

=over 4

=cut

##==============================================================================
## TIEHASH
##==============================================================================
sub TIEHASH {
    my $class = shift;
    my $hash = bless {}, $class;
    return $hash->add(@_);
}

=pod

=item C<I<$hashref> = new Tie::StrictHash I<key> =E<gt> I<value>, ...;>

Creates a new anonymous strict hash with the specified members as its initial
contents.  The hash reference is both a reference to the hash and the hash
control object.  It's possible to define an object with its 'instance variables'
implemented in terms of a strict hash, provided that the object inherits from
Tie::StrictHash...in this case, the object and its underlying hash would
effectively belong to different classes!  This works because B<bless> applies to
the reference, while B<tie> applies to the actual thingy.

=cut

##==============================================================================
## new
##==============================================================================
sub new {
    my $class = shift;
    my $hash = {};
    tie %$hash, 'Tie::StrictHash', @_;
    return bless $hash, $class;
}

=item C<I<$hashctl>-E<gt>add(I<key> =E<gt> I<value>, ...);>

Adds the specified keys and values to I<%hash>.

=cut

##==============================================================================
## add
##==============================================================================
sub add {
    my $hash = shift;
    my $old_locked = $locked;
    $locked = 1;
    eval {
        while (@_) {
            croak "odd number of elements passed to add" if @_ == 1;
            my $key = shift;
            my $value = shift;
            $hash->{$key} = $value;
        }
    };
    $locked = $old_locked;
    die $@ if $@;
    return $hash;
}

=pod

=item C<I<@values> = I<$hashctl>-E<gt>delete(I<key>, ...);>

Deletes the named key(s) from I<%hash> and returns them in I<@values>.  They
appear in I<@values> in the same order as the keys are specified in the method
call.

=cut

##==============================================================================
## delete
##==============================================================================
sub delete {
    my $hash = shift;
    my $old_locked = $locked;
    my @values;
    $locked = 1;
    eval {
        foreach (@_) {
            push(@values, delete $hash->{$_});
        }
    };
    $locked = $old_locked;
    die $@ if $@;
    return @values;
}

=pod

=item C<I<$hashctl>-E<gt>clear;>

Clears the entire hash.

=cut

##==============================================================================
## clear
##==============================================================================
sub clear {
    my $hash = shift;
    my $old_locked = $locked;
    $locked = 1;
    eval {
        %$hash = ();
    };
    $locked = $old_locked;
    die $@ if $@;
    return $hash;
}

=pod

=back

=head1 EXAMPLES

To create a hash with just three members in it that can't be added to except
by using the B<add> method:

    use Tie::StrictHash;
    use strict;
    use vars qw(%hash $hashctl);
    
    $hashctl = strict_hash %hash,
        member1 => 'a', member2 => 'b', member3 => 'c';
    
    print $hash{member1}, "\n";     ## prints "a"
    print $hash{member4}, "\n";     ## gives error!
    
    $hash{member2} = 'C';           ## OK
    $hash{member4} = 'D';           ## gives error
    
    ## BUT...
    
    $hashctl->add(member4 => 'D');  ## Adds new member to hash
    
    print $hash{member4}, "\n";     ## prints "D"
    $hash{member4} = 'd';           ## OK

To define an object that uses a strict hash to hold its instance
variables:

    package StrictObject;
    use Tie::StrictHash;
    use strict;
    use vars qw(@ISA);
    @ISA = qw(Tie::StrictHash);
    
    sub new {
        my $class = shift;
        ##
        ## Create strict hash and define object variables
        ##
        my $obj = new Tie::StrictHash var1 => 1, var2 => 'A';
        ##
        ## Then bless it into the proper class.
        ##
        return bless $obj, $class;
    }
    
    package main;
    
    use vars qw($obj);
    
    $obj = new StrictObject;
    
    print ref $obj, "\n";           ## prints "StrictObject"
    print tied %$obj, "\n";         ## prints "Tie::StrictHash=HASH(...)"

=head1 DIAGNOSTICS

These are all fatal errors unless the pseudo-symbol C<warn> was imported on 
the C<use Tie::StrictHash> line.

=over 4

=item odd number of elements passed to add

Self-explanatory.

=item invalid attempt to clear strict hash

A statement such as

    %hash = ();

was attempted.  This is not allowed.  Use the B<clear> method.

=item key 'I<key>' does not exist

An attempt was made to access or modify a key that doesn't exist.

=item invalid attempt to delete key 'I<key>'

A statement such as

    delete $hash{'key'};

was executed.  You must use the B<delete> method to delete from a strict hash.

=back

=head1 SEE ALSO

L<Tie::Hash>

C<perldoc -f tie>

=head1 AUTHOR

Kevin Michael Vail <kevin@vaildc.net>

=cut

##==============================================================================
## Most of the methods for dealing with %hash are inherited from Tie::StdHash.
## However, the following ones are not, because they implement the 'strict'
## part of StrictHash.
##------------------------------------------------------------------------------
## CLEAR is blocked except from within clear.
##==============================================================================
sub CLEAR {
    my $hash = shift;
    croak "invalid attempt to clear strict hash" unless $locked;
    %$hash = ();
}

##==============================================================================
## STORE is blocked unless the hash element already exists, except from add.
##==============================================================================
sub STORE {
    my ($hash, $key, $value) = @_;
    croak "key '$key' does not exist" unless $locked || exists $hash->{$key};
    $hash->{$key} = $value;
    return $value;
}

##==============================================================================
## DELETE is blocked except from within delete.
##==============================================================================
sub DELETE {
    my ($hash, $key) = @_;
    croak "invalid attempt to delete key '$key'" unless $locked;
    delete $hash->{$key};
}

##==============================================================================
## FETCH fails if applied to a member that doesn't exist.
##==============================================================================
sub FETCH {
    my ($hash, $key) = @_;
    croak "key '$key' does not exist" unless exists $hash->{$key};
    return $hash->{$key};
}

1;

##==============================================================================
## $Log: StrictHash.pm,v $
## Revision 1.0  2001/03/17 17:03:02  kevin
## Initial revision
##==============================================================================
