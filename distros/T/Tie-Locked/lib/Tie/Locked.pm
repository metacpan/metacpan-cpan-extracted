package Tie::Locked;
use strict;
use Carp 'croak';


# version
our $VERSION = '1.1';


# debugging tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

=head1 NAME

Tie::Locked -- lock hashes so that they cannot be easily changed

=head1 SYNOPSIS

 use Tie::Locked ':all';
 
 # creates locked hash with initial value x=>1
 tie %hash, 'Tie::Locked::Tied', x=>1;
 
 # get tied hashref with initial value x=>1
 my $ref = locked_hashref('x'=>1);
 
 # the following commands cause fatal errors
 print $ref->{'y'};       # references non-existent key
 $ref->{'y'} = 'yyyyy';   # assigns to non-existent key
 $ref->{'x'} = 'yyyyy';   # assigns to existent key
 
 # but this command is ok
 $dummy = $ref->{'x'};    # references existent key
 
 # get unlocked hashref
 my $ref = locked_hashref('x'=>1);
 
 # the following commands do NOT cause errors because the hash isn't locked
 print $ref->{'y'};
 $ref->{'y'} = 'yyyyy';
 
 # now lock the hashref
 $ref->lock;
 
 # many other features...

=head1 DESCRIPTION

Tie::Locked allows you to create hashes in which the values of the hash cannot
be easily changed.  If an element that does not exist is referenced then the
code croaks.  Tie::Locked is useful for situations where you want to make sure
your code doesn't accidentally change values. If code attempts to change or
delete an existing element, then the code dies. 

I created Tier::Locked when I wrote buggy code something like this:

 my $whatever = {};

 # a bunch of code that, under some conditions, never creates or sets
 # the value $whatever->{'done'}
 
 if (! $whatever->{'done'}) {
    ...
 }

It took an hour of debugging to figure out, so I created this module to avoid
losing more time from things I'd rather do, like write non-buggy code.

Please note: I never actually use Tie::Locked to tie hashes directly.  I use
locked_hashref() and unlocked_hashref() to get hash references.  This
documentation is going to focus on that usage.

=head1 INSTALLATION

Tie::Locked can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

=head1 FUNCTIONS

=cut


# Works like a regular hash, except that no changes are allowed to the keys
# or values once the hash has been locked.  Also, croaks when an attempt is made
# to retrieve a nonexistent key.

# export
use vars qw[@EXPORT_OK %EXPORT_TAGS];
use base 'Exporter';
@EXPORT_OK = qw[ locked_hashref unlocked_hashref ];
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);


#------------------------------------------------------------------------------
# locked_hashref
#

=head2 locked_hashref

locked_hashref() returns a reference to a locked hash.  All options sent to
locked_hashref() are set as the locked values of the hash.  So, for example,
the following code creates a hashref with one key 'x' with a value of 1:

 my $ref = locked_hashref('x'=>1);

=cut

sub locked_hashref {
	my ($self, %hash);
	
	tie %hash, 'Tie::Locked::Tied', @_;
	$self = \%hash;
	bless $self, 'Tie::Locked';
	return $self;
}
#
# locked_hashref
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# unlocked_hashref
#

=head2 unlocked_hashref

unlocked_hashref() returns a reference to an unlocked hash.  This is useful for
the situation where you want to initialize the values in the hash before
locking it.  For example, the following code creates a Tie::Locked object, sets
some values in it, then locks the hash.

 my $ref = unlocked_hashref();
 
 $ref->{'Mbala'} = 1;
 $ref->{'Josh'} = 2;
 $ref->{'Starflower'} = 3;
 
 $ref->lock();

=cut

sub unlocked_hashref {
	my $self = locked_hashref(@_);
	$self->unlock();
	return $self;
}
#
# unlocked_hashref
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# $ref->lock()
#

=head2 $ref->lock()

The lock() method (not to be confused with Perl's native lock function) locks
the Tie::Locked object. For example, the following code creates an unlocked
Tie::Locked object, sets some values, then locks the hash.

 my $ref = unlocked_hashref();
 
 $ref->{'Mbala'} = 1;
 $ref->{'Josh'} = 2;
 $ref->{'Starflower'} = 3;
 
 $ref->lock();

=cut

sub lock {
	my ($self) = @_;
	return tied(%{$self})->lock;
}
#
# $ref->lock()
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# $ref->unlock()
#

=head2 $ref->unlock()

Unlocks the hash.  For example, the following code unlocks the hash, sets some
values, then relocks it.

 $ref->unlock();
 $ref->{'x'} = 'yyyyy';
 $ref->{'z'} = 'yyyyy';
 
 # relock
 $ref->lock;

=cut

sub unlock {
	my ($self) = @_;
	my $locked = tied(%{$self});
	
	if (! $locked) {
		# dietrace title=>'no tied reference';
		croak 'no tied reference to Tie::Locked::Tied';
	}
	
	return tied(%{$self})->unlock;
}
#
# $ref->unlock()
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# $ref->autolocker()
#

=head2 $ref->autolocker()

autolocker() unlocks the hash and returns an object that, when it goes out of
scope, relocks the hash.  This is useful for situations where you want to
unlock the hash and be sure it gets relocked even if the routine exits midway.

For example, the following code creates an autolocker object in the do{} block,
so setting the hash does not cause an error in that block.  However, after the
locker has gone out of scope, the hash is locked again.

 my $ref = locked_hashref('x'=>1);
 
 do {
    my $locker = $ref->autolocker();
    $ref->{'steve'} = 1; # does not cause an error
 };
 
 $ref->{'fred'} = 2; # causes an error

=cut

sub autolocker {
	my ($self) = @_;
	$self->unlock();
	return Tie::Locked::AutoLocker->new($self);
}

# alias auto_locker to autolocker
sub auto_locker {
	my $self = shift;
	return $self->autolocker(@_);
}

#
# $ref->autolocker()
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# locked
#

=head2 $ref->locked()

Returns true if the hash is locked.

=cut

sub locked {
	my ($self) = @_;
	return tied(%{$self})->locked;
}
#
# locked
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# unlocked
#

=head2 $ref->unlocked()

Returns true if the hash is not locked.

=cut

sub unlocked {
	my ($self) = @_;
	return tied(%{$self})->unlocked;
}
#
# unlocked
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# unlock_fields
#

=head2 $ref->unlock_fields(I<field1>, I<field2>, ...)

This method allows you to unlock just specific fields in the hash.  For
example, in the following code, the fields 'first', 'middle', and 'last' are
unlocked, but the id field is not.  Notice that the fields do not need to
actually exist in order to be unlocked.

 # create customer hash
 my $customer = locked_hashref(id=>'3245');
 
 # unlock name fields
 $customer->unlock_fields('first', 'middle', 'last');
 
 # set name fields - does not cause any errors
 $customer->{'first'} = 'Michael';
 $customer->{'middle'} = 'Jadin';
 $customer->{'last'} = 'Forsyth';
 
 # but this line causes an error:
 $customer->{'id'} = 2087;

Each call to unlock_fields() adds to the list of unlocked fields, so the
following code accomplishes the same thing as above.

 $customer->unlock_fields('first');
 $customer->unlock_fields('middle');
 $customer->unlock_fields('last');

=cut

sub unlock_fields {
	my $self = shift;
	my $tied = tied(%{$self});
	
	return tied(%{$self})->unlock_fields(@_);
}
#
# unlock_fields
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# lock_fields
#

=head2 $ref->lock_fields(I<field1>, I<field2>, ...)

The opposite of unlock_fields(), this method locks the given fields.

=cut

sub lock_fields {
	my $self = shift;
	my $tied = tied(%{$self});
	
	return tied(%{$self})->lock_fields(@_);
}
#
# lock_fields
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# lock_all_fields
#

=head2 $ref->lock_all_fields()

Locks all fields.

=cut

sub lock_all_fields {
	my $self = shift;
	my $tied = tied(%{$self});
	
	return tied(%{$self})->lock_all_fields(@_);
}
#
# lock_all_fields
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# unlocked_fields
#

=head2 $ref->unlocked_fields()

Returns an array of fields that are not locked.

=cut

sub unlocked_fields {
	my $self = shift;
	my $tied = tied(%{$self});
	
	return tied(%{$self})->unlocked_fields(@_);
}
#
# unlocked_fields
#------------------------------------------------------------------------------



=head1 Known bugs

The autolocker object does not go out of scope if it is created in a
one-command block.  For example, the following code does NOT cause an error
even though it should.

 my $ref = locked_hashref();
 
 do {
    my $locker = $ref->autolocker();
 };
 
 # does not cause an error
 $ref->{'Steve'} = 4;


=cut


###############################################################################
# Tie::Locked::Tied
#
package Tie::Locked::Tied;
use strict;
use Carp 'croak';

# debugging tools
# use Debug::ShowStuff ':all';

sub TIEHASH {
	my $class = shift;
	my $self = bless {data=>{@_}}, $class;
	
	$self->{'locked'} = 1;
	
	return $self;
}

sub EXISTS {
	my ($self, $key) = @_;
	return exists $self->{'data'}->{$key};
}

sub FETCH {
	my ($self, $key) = @_;
	
	if ($self->{'locked'}) {
		if (! exists $self->{'data'}->{$key}) {
			my $ul = $self->{'unlocked_fields'};
			
			unless ($ul && exists($ul->{$key}) ) {
				# dietrace title=>"no key named '$key'";
				croak "no key named '$key'";
			}
		}
	}
	
	return $self->{'data'}->{$key};
}

sub FIRSTKEY {
	my $self = shift;
	my $a = keys %{$self->{'data'}};
	return scalar each %{$self->{'data'}};
}

sub NEXTKEY {
	my $self = shift;
	return scalar each %{$self->{'data'}};
}

sub CLEAR {
	my ($self) = @_;
	
	if ($self->{'locked'}) {
		# dietrace title=>'cannot clear locked ' . ref($self) . ' hash';
		croak 'cannot clear locked ' . ref($self) . ' hash';
	}
	
	else {
		$self->{'data'} = {};
	}
}

sub STORE {
	my ($self, $key, $datum) = @_;
	
	if ($self->{'locked'}) {
		my $ul = $self->{'unlocked_fields'};
		
		unless ($ul && exists($ul->{$key}) ) {
			# dietrace title=>'cannot store "' . $key . '" into locked ' . ref($self) . ' hash';
			croak 'cannot store "' . $key . '" into locked ' . ref($self) . ' hash';
		}
	}
	
	$self->{'data'}->{$key} = $datum;
}

sub DELETE {
	my ($self, $key) = @_;
	
	if ($self->{'locked'}) {
		my $ul = $self->{'unlocked_fields'};
		
		unless ($ul && exists($ul->{$key}) )
			{ 'cannot delete from locked ' . ref($self) . ' hash' }
	}
	
	delete $self->{'data'}->{$key};
}


sub lock   {$_[0]->{'locked'} = 1}
sub unlock {$_[0]->{'locked'} = 0}

sub locked {return $_[0]->{'locked'}}
sub unlocked {return ! $_[0]->locked}

sub unlock_fields {
	my ($self, @fields) = @_;
	my $uls = $self->{'unlocked_fields'} ||= {};
	
	@{$uls}{@fields} = ();
}

sub unlocked_fields {
	my ($self) = @_;
	my (@rv);
	
	if ($self->{'unlocked_fields'})
		{ @rv = keys(%{$self->{'unlocked_fields'}}) }
	
	# return
	return @rv;
}

sub lock_fields {
	my ($self, @fields) = @_;
	my $uls = $self->{'unlocked_fields'} ||= {};
	
	foreach my $field (@fields)
		{ delete $uls->{$field} }
}

sub lock_all_fields {
	my ($self, @fields) = @_;
	delete $self->{'unlocked_fields'};
}

#
# Tie::Locked::Tied
###############################################################################



###############################################################################
# Tie::Locked::AutoLocker
#
package Tie::Locked::AutoLocker;
use strict;

# debugging tools
# use Debug::ShowStuff ':all';

sub new {
	my ($class, $locked) = @_;
	my $self = bless {}, $class;
	$self->{'locked'} = $locked;
	return $self;
}

DESTROY {
	my ($self) = @_;
	
	$self->{'locked'}->lock();
}

#
# Tie::Locked::AutoLocker
###############################################################################


# return true
1;

__END__

=head1 TERMS AND CONDITIONS

Copyright (c) 2013 by Miko O'Sullivan.  All rights reserved.  This program is 
free software; you can redistribute it and/or modify it under the same terms 
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHORS

Miko O'Sullivan
F<miko@idocs.com>

=head1 RELEASE HISTORY

=over

=item Version 1.0  March 21, 2013

Initial release

=item Version 1.1  April 25, 2014

Fixed error in META.yml.

=back

=cut


