package forks::shared;    # make sure CPAN picks up on forks::shared.pm
$VERSION = '0.36';

use Config ();

#---------------------------------------------------------------------------
#  IN: 1 class
#      2..N Hash of parameters to set

sub set_deadlock_option {

# Get the class
# Get the options
# Initialize variables for final option values
# Set value for 'detect' option
# Set value for 'period' option
# Set value for 'resolve' option
# Send settings to server

    my $class = shift;
    my %opts = @_;
    my ($detect, $period, $resolve, $signal);
    $detect = $opts{detect} ? 1 : 0;
    $period = $opts{period} + 0 if defined $opts{period};
    $resolve = $opts{resolve} ? 1 : 0;
    threads::shared::_command( '_set_deadlock_option',
        $detect,$period,$resolve,$signal );
}

package
    threads::shared;  # but we're masquerading as threads::shared.pm

# Make sure we have version info for this module
# Compatibility with the standard threads::shared
# Do everything by the book from now on

BEGIN {
    $VERSION  = '1.39';
    $threads_shared = $threads_shared = 1;
}
use strict;
use warnings;

# At compile time
#  If forks is running in shadow mode
#   Fake that forks::shared.pm was really loaded (if not set already)
#  Elsif there seems to be a threads.pm loaded
#   Fake that threads::shared.pm was really loaded (if not set already)
#  Elsif there are (real) threads loaded
#   Die now indicating we can't mix them

BEGIN {
    if (defined $INC{'threads.pm'} && $forks::threads_override) {
        $INC{'forks/shared.pm'} ||= $INC{'threads/shared.pm'}
    } elsif (defined $INC{'forks.pm'}) {
        $INC{'threads/shared.pm'} ||= $INC{'forks/shared.pm'};
    } elsif (defined $INC{'threads.pm'} && !$forks::threads_override) {
        die( "Can not mix 'use forks::shared' with real 'use threads'\n" );
    }
}

# Make sure we can die with lots of information
# Make sure we can find out about blessed references correctly
# Load some additional list utility functions

use Carp ();
use Scalar::Util qw(reftype blessed refaddr);
use List::MoreUtils;

# If forks.pm is loaded
#  Make sure we have a local copy of the base command handler on the client side
# Else
#  Load the XS stuff
#  If we're running a perl older than 5.008
#   Disable the cond_xxxx family and other exported routines, without prototypes
#  Else
#   Have share do nothing, just return the ref
#   Disable the cond_xxxx family and other exported routines

if ($forks::threads || $forks::threads) { # twice to avoid warnings
    *_command = \&threads::_command;
    *is_shared = \&_id;
} else {
    
    require XSLoader;
    XSLoader::load( 'forks',$forks::shared::VERSION );

    no warnings 'redefine';
    if ($] < 5.007003) {
        *share = *is_shared = *lock = *cond_signal = *cond_broadcast
            = *shared_clone = *cond_wait = *cond_timedwait = sub { undef };
    } else {
        *share = sub (\[$@%]) { return $_[0] };
        *is_shared = *lock = *cond_signal = *cond_broadcast = sub (\[$@%]) { undef };
        *cond_wait = sub (\[$@%];\[$@%]) { undef };
        *cond_timedwait = sub (\[$@%]$;\[$@%]) { undef };
        *shared_clone = sub { undef };
    }
}

# Clone detection logic
# Ordinal numbers of shared variables being locked by this thread
# Whether to retain existing variable content during tie to threads::shared::* modules
# Local cache of self-referential circular references (pertie workaround): tied obj => REF
# Reverse lookup of local thread cache of self-referential circular references
# Thread-local cache of shared variable tied primitives

our $CLONE = 0;
our %LOCKED;
our $CLONE_TIED = !eval {forks::THREADS_NATIVE_EMULATION()};
our %CIRCULAR;
our %CIRCULAR_REVERSE;
our %SHARED_CACHE;

# If Perl 5.8 or later core doesn't include required internal hooks (possibly compiled out)
#  Force suppressed 'shared' attribute to surface as 'Forks_shared' in Core attributes.pm

if ($] >= 5.0008 && !__DEF_PL_sharehook()) {
    require attributes;
    my $old = \&attributes::_modify_attrs;
    no warnings 'redefine';
    *attributes::_modify_attrs = sub {
        my ($ref, @attr) = @_;
        return ($old->(@_), (grep(/^shared$/o, @attr) ? 'Forks_shared' : ()));
    };
}

# If Perl core doesn't support the required internal hooks
#  Localize $WARNINGS to silence warning when overloading ATTR 'shared'
#  Load forks::shared::attributes to overload 'shared' attribute handling

if ($] < 5.0008 || !__DEF_PL_sharehook()) {
    local $^W = 0;
    require forks::shared::attributes;
}

#---------------------------------------------------------------------------
# If we're running in a perl before 5.8.0, we need a source filter to change
# all occurrences of
#
#  share( $x );
#
# to:
#
#  share( \$x );
#
# The same applies for most other exported threads::shared functions.
#
# We do this by conditionally adding the source filter functionality if we're
# running in a versione before 5.8.0.
#
# We also will use a source filter to change all occurrences of
#  [my|our] [VAR | (VAR1, VAR2, ...])] : shared
# to:
#  [my|our] [VAR | (VAR1, VAR2, ...])] : Forks_shared
# to suppress some warnings in Perl before 5.8.0.

my $filtering; # are we filtering source code?
BEGIN {
    eval <<'EOD' if ($filtering = $] < 5.008 ); # need string eval ;-(

use Filter::Util::Call (); # get the source filter stuff

#---------------------------------------------------------------------------
#  IN: 1 object (not used)
# OUT: 1 status

sub filter {

# Initialize status
# If there are still lines to read
#  Convert the line if there is any mention of our special subs
# Return the status

    my $status;
    if (($status = Filter::Util::Call::filter_read()) > 0) {
#warn $_ if         # activate if we want to see changed lines
        s#(\b(?:cond_wait)\b\s*(?!{)\(?\s*[^,]+,\s*)(?=[mo\$\@\%])#$1\\#sg;
#warn $_ if         # activate if we want to see changed lines
        s#(\b(?:cond_timedwait)\b\s*(?!{)\(?\s*[^,]+,[^,]+,\s*)(?=[mo\$\@\%])#$1\\#sg;
#warn $_ if         # activate if we want to see changed lines
        s#(\b(?:cond_broadcast|cond_wait|cond_timedwait|cond_signal|share|is_shared|threads::shared::_id|lock)\b\s*(?!{)\(?\s*)(?=[mo\$\@\%])#$1\\#sg;
#warn $_ if         # activate if we want to see changed lines
        s#((?:my|our)((?:\s|\()*[\$@%*]\w+(?:\s|\)|,)*)+\:\s*)\bshared\b#$1Forks_shared#sg;
    }
    $status;
} #filter
EOD
} #BEGIN

# Satisfy require

1;

#---------------------------------------------------------------------------

# standard Perl features

#---------------------------------------------------------------------------
#  IN: 1 class
#      2..N subroutines to export (default: async only)

sub import {

# Lose the class
# Add filter if we're filtering

    my $class = shift;
    Filter::Util::Call::filter_add( CORE::bless {},$class ) if $filtering;

# Enable deadlock options, if requested
    
    if ((my $idx = List::MoreUtils::firstidx(
        sub { $_ eq 'deadlock' }, @_)) >= 0) {
        if (ref $_[$idx+1] eq 'HASH') {
            my (undef, $opts) = splice(@_, $idx, 2);
            $class->set_deadlock_option(%{$opts});
        } else {
            splice(@_, $idx, 1);
        }
    }
    
# Perform the export needed 

    _export( scalar(caller()),@_ );
} #import

BEGIN {

# forks::shared and threads::shared share same import method
# load set_deadlock_option into threads::shared namespace

    *forks::shared::import = *forks::shared::import = \&import;
    *set_deadlock_option = *set_deadlock_option
        = \&forks::shared::set_deadlock_option;
}

# Predeclarations for internal functions

my ($make_shared);

# Create a thread-shared clone of a complex data structure or object

sub shared_clone
{

# Die unless arguments are correct

    if (@_ != 1) {
        Carp::croak('Usage: shared_clone(REF)');
    }

# Clone all shared data during this process
# Return cloned result

    local $CLONE_TIED = 1;
    return $make_shared->(shift, {});
}

# Used by shared_clone() to recursively clone
#   a complex data structure or object
$make_shared = sub {
    my ($item, $cloned) = @_;

    # Just return the item if:
    # 1. Not a ref;
    # 2. Already shared; or
    # 3. Not running 'threads'.
    {
        no warnings 'uninitialized';
        return $item if (! ref($item) || is_shared($item) || ! $threads::threads);
    }

    # Check for previously cloned references
    #   (this takes care of circular refs as well)
    my $addr = refaddr($item);
    if (exists($cloned->{$addr})) {
        # Return the already existing clone
        return $cloned->{$addr};
    }

    # Make copies of array, hash and scalar refs and refs of refs
    my $copy;
    my $ref_type = reftype($item);

    # Copy an array ref
    if ($ref_type eq 'ARRAY') {
        # Make empty shared array ref
        $copy = &share([]);
        # Add to clone checking hash
        $cloned->{$addr} = $copy;
        # Recursively copy and add contents
        push(@$copy, map { $make_shared->($_, $cloned) } @$item);
    }

    # Copy a hash ref
    elsif ($ref_type eq 'HASH') {
        # Make empty shared hash ref
        $copy = &share({});
        # Add to clone checking hash
        $cloned->{$addr} = $copy;
        # Recursively copy and add contents
        foreach my $key (keys(%{$item})) {
            $copy->{$key} = $make_shared->($item->{$key}, $cloned);
        }
    }

    # Copy a scalar ref
    elsif ($ref_type eq 'SCALAR') {
        $copy = \do{ my $scalar = $$item; };
        share($copy);
        # Add to clone checking hash
        $cloned->{$addr} = $copy;
    }

    # Copy of a ref of a ref
    elsif ($ref_type eq 'REF') {
        # Special handling for $x = \$x
        if ($addr == refaddr($$item)) {
            $copy = \$copy;
            share($copy);
            $cloned->{$addr} = $copy;
        } else {
            my $tmp;
            $copy = \$tmp;
            share($copy);
            # Add to clone checking hash
            $cloned->{$addr} = $copy;
            # Recursively copy and add contents
            $tmp = $make_shared->($$item, $cloned);
        }

    } else {
        Carp::croak("Unsupported ref type: ", $ref_type);
    }

    # If input item is an object, then bless the copy into the same class
    if (my $class = blessed($item)) {
        CORE::bless($copy, $class);
    }

    # Clone READONLY flag
    if ($] >= 5.008003) {
        if ($ref_type eq 'SCALAR') {
            if (Internals::SvREADONLY($$item)) {
                Internals::SvREADONLY($$copy, 1);
            }
        }
        if (Internals::SvREADONLY($item)) {
            Internals::SvREADONLY($copy, 1);
        }
    }

    return $copy;
};

#---------------------------------------------------------------------------

# Purge the thread cache (to insure thread-local refaddr)
# Increment the current clone value (mark this as a cloned version)

sub CLONE {
    %CIRCULAR = ();
    %CIRCULAR_REVERSE = ();
    %SHARED_CACHE = ();
    $CLONE++;
} #CLONE

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2 reference to hash containing parameters
#      3 initial value of scalar
# OUT: 1 instantiated object

sub TIESCALAR {

# Clone all shared data during this process
# Return tied result

    local $CLONE_TIED = 1;
    shift->_tie( 'scalar',@_ );
} #TIESCALAR

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2 reference to hash containing parameters
# OUT: 1 instantiated object

sub TIEARRAY { shift->_tie( 'array',@_ ) } #TIEARRAY

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2 reference to hash containing parameters
# OUT: 1 instantiated object

sub TIEHASH { shift->_tie( 'hash',@_ ) } #TIEHASH

#---------------------------------------------------------------------------
#  IN: 1 class for which to bless
#      2 reference to hash containing parameters
#      3..N any parameters passed to open()
# OUT: 1 instantiated object

sub TIEHANDLE { shift->_tie( 'handle',@_ ) } #TIEHANDLE

#---------------------------------------------------------------------------
#  IN: 1 perltie thawed value
# OUT: 1..N output parameters
sub _tied_filter {

# Obtain the reference to the variable
# Create the reference type of that reference
# Return immediately if this isn't a reference

    my $it  = shift;
    my $ref = reftype $it;
    return $it unless $ref;

# Obtain the object
# Return immediately if isn't a threads::shared object (i.e. circular REF)

    my $object;
    if ($ref eq 'SCALAR') {
        $object = tied ${$it};
    } elsif ($ref eq 'ARRAY') {
        $object = tied @{$it};
    } elsif ($ref eq 'HASH') {
        $object = tied %{$it};
    } elsif ($ref eq 'GLOB') {
        $object = tied *{$it};
    } else {
        return $it;
    }
    return $it unless UNIVERSAL::isa($object, 'threads::shared');

#  Get the ordinal
#  If we already have a cached copy of this object
#   Get the blessed class (if any)
#   Save this as the return value
#   Rebless local ref to insure its up-to-date with shared blessed state
#  Else
#   Cache this value
# Return the (tied) value

    my $ordinal = $object->{'ordinal'};
    if (exists $SHARED_CACHE{$ordinal}) {
        my $class = blessed($it);
        CORE::bless($SHARED_CACHE{$ordinal}, $class) if $class;
        $it = $SHARED_CACHE{$ordinal};
    } else {
        $SHARED_CACHE{$ordinal} = $it;
    }
    return $it;
}

# Define generic perltie proxy methods for most scalar, array, hash, and handle events

BEGIN {
    no strict 'refs';
    foreach my $method (qw/BINMODE CLEAR CLOSE EOF EXTEND FETCHSIZE FILENO GETC
        OPEN POP PRINT PRINTF READ READLINE SCALAR SEEK SHIFT STORESIZE TELL UNSHIFT WRITE/) {

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N input parameters
# OUT: 1..N output parameters

        *$method = sub {

# Obtain the object
# Obtain the subroutine name
# Handle the command with the appropriate data and obtain the result
# Return whatever seems appropriate

            my $self = shift;
            my $sub = $self->{'module'}.'::'.$method;
            my @result = map { ref($_) ? _tied_filter($_) : $_ } _command( '_tied',$self->{'ordinal'},$sub,@_ );
            wantarray ? @result : $result[0];
        }
    }
}

# Define perltie proxy methods for events used by a tied hash that use a hash key as first argument

BEGIN {
    no strict 'refs';
    foreach my $method (qw/DELETE EXISTS FIRSTKEY NEXTKEY/) {

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N input parameters
# OUT: 1..N output parameters

        *$method = sub {

# Obtain the object
# Obtain the subroutine name
# If we're a hash and the key is a code reference
#  Force key stringification, to insure remote server uses same key value as thread
# Handle the command with the appropriate data and obtain the result
# Return whatever seems appropriate

            my $self = shift;
            my $sub = $self->{'module'}.'::'.$method;
            if ($self->{'type'} eq 'hash' && ref($_[0]) eq 'CODE') {
                $_[0] = "$_[0]";
            }
            my @result = map { ref($_) ? _tied_filter($_) : $_ } _command( '_tied',$self->{'ordinal'},$sub,@_ );
            wantarray ? @result : $result[0];
        }
    }
}

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N input parameters
# OUT: 1..N output parameters

sub PUSH {

# Obtain the object
# Obtain the subroutine name
# Handle the command with the appropriate data and obtain the result (using
#  evaluated array slice to insure shared scalar push value works, as push
#  doesn't evaluate values before pushing them on the stack)
# Return whatever seems appropriate

    my $self = shift;
    my $sub = $self->{'module'}.'::PUSH';
    my @result = map { ref($_) ? _tied_filter($_) : $_ } _command( '_tied',$self->{'ordinal'},$sub,map($_, @_) );
    wantarray ? @result : $result[0];
} #PUSH

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N input parameters
# OUT: 1..N output parameters

sub STORE {

# Obtain the object
# Obtain the subroutine name
# If this is a scalar and to-be stored value is a reference
#  Obtain the object
#  Die if the reference is not a threads::shared tied object

    my $self = shift;
    my $sub = $self->{'module'}.'::STORE';
    my $val = $_[$self->{'type'} eq 'scalar' ? 0 : 1];
    if (my $ref = reftype($val)) {
        my $object;
        if ($ref eq 'SCALAR') {
            $object = tied ${$val};
        } elsif ($ref eq 'ARRAY') {
            $object = tied @{$val};
        } elsif ($ref eq 'HASH') {
            $object = tied %{$val};
        } elsif ($ref eq 'GLOB') {
            $object = tied *{$val};
        } elsif ($ref eq 'REF') {
            $object = $val;
        }
        Carp::croak "Invalid value for shared scalar"
            unless defined $object && (ref($object) eq 'REF' || $object->isa('threads::shared'));
    }

# If we're a hash and the key is a code reference
#  Force key stringification, to insure remote server uses same key value as thread

    if ($self->{'type'} eq 'hash' && ref($_[0]) eq 'CODE') {
        $_[0] = "$_[0]";
    }

# Handle the command with the appropriate data and obtain the result
# Delete cached shared self-circular reference lookups, if exists and self is a tied scalar
# Return whatever seems appropriate

    my @result = map { ref($_) ? _tied_filter($_) : $_ } _command( '_tied',$self->{'ordinal'},$sub,@_ );
    delete $CIRCULAR_REVERSE{delete $CIRCULAR{$self}} if $self->{'type'} eq 'scalar' && exists $CIRCULAR{$self};
    wantarray ? @result : $result[0];
} #STORE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N input parameters
# OUT: 1..N output parameters

sub FETCH {

# Obtain the object
# Obtain the subroutine name
# If we're a hash and the key is a code reference
#  Force key stringification, to insure remote server uses same key value as thread
# Handle the command with the appropriate data and obtain the result
# If this is a tied scalar and the remote value is a circular self-reference
#  Return cached shared self-circular reference, if exists
#  Store cached shared self-circular reference lookup
#  Store reverse reference -> cached shared self-circular reference lookup
#  (Note: this value is localized per thread, so the same shared self-circular
#         variable will return different is_shared() values in different threads
# Return whatever seems appropriate

    my $self = shift;
    my $sub = $self->{'module'}.'::FETCH';
    if ($self->{'type'} eq 'hash' && ref($_[0]) eq 'CODE') {
        $_[0] = "$_[0]";
    }
    my @result = map { ref($_) ? _tied_filter($_) : $_ } _command( '_tied',$self->{'ordinal'},$sub,@_ );
    if ($self->{'type'} eq 'scalar' && ref($result[0]) eq 'REF'
        && ref(${$result[0]}) eq 'REF') {    #TODO: is this too simple?  Do we need to contact remote process?  Seems like we should at least do a refaddr equality check (on the remote process) to validate this is a self-circular reference
        return $CIRCULAR{$self} if exists $CIRCULAR{$self};
        $CIRCULAR{$self} = $result[0];
        $CIRCULAR_REVERSE{$result[0]} = $self;
    }
    wantarray ? @result : $result[0];
} #FETCH

#---------------------------------------------------------------------------
#  IN: 1 instantiated object
#      2..N input parameters
# OUT: 1..N output parameters

sub SPLICE {

# Die now if running in thread emulation mode
# Obtain the object
# Obtain the subroutine name
# Handle the command with the appropriate data and obtain the result
# Return whatever seems appropriate

    Carp::croak('Splice not implemented for shared arrays')
        if eval {forks::THREADS_NATIVE_EMULATION()};
    my $self = shift;
    my $sub = $self->{'module'}.'::SPLICE';
    my @result = map { ref($_) ? _tied_filter($_) : $_ } _command( '_tied',$self->{'ordinal'},$sub,@_ );
    wantarray ? @result : $result[0];
} #SPLICE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub UNTIE {

# Obtain the object
# Return if we're not in the originating thread
# Handle the command with the appropriate data

    my $self = shift;
    return if $self->{'CLONE'} != $CLONE;
    map { ref($_) ? _tied_filter($_) : $_ } _command( '_untie',$self->{'ordinal'} );
} #UNTIE

#---------------------------------------------------------------------------
#  IN: 1 instantiated object

sub DESTROY {   #currently disabled, as DESTROY method is not used by threads

# Obtain the object
# Return if we're not in the originating thread
# Handle the command with the appropriate data

#    my $self = shift;
#    return if $self->{'CLONE'} != $CLONE;
#    map { ref($_) ? _tied_filter($_) : $_ } _command( '_tied',$self->{'ordinal'},$self->{'module'}.'::DESTROY' );
} #DESTROY

#---------------------------------------------------------------------------

# internal subroutines

#---------------------------------------------------------------------------
#  IN: 1 namespace to export to
#      2..N subroutines to export

sub _export {

# Obtain the namespace
# Set the defaults if nothing specified
# Allow for evil stuff
# Export whatever needs to be exported

    my $namespace = shift().'::';
    my @export = qw(share shared_clone is_shared lock cond_wait cond_timedwait cond_signal cond_broadcast);
    push @export, 'bless' if $threads::threads && $threads::threads;
    @export = @_ if @_;
    no strict 'refs';
    *{$namespace.$_} = \&$_ foreach @export;
} #_export

#---------------------------------------------------------------------------
#  IN: 1 base class with which to bless
#      2 string to be concatenated to class for tie-ing
#      3 reference to hash with parameters
#      4..N any other values to be passed to tieing routine
# OUT: 1 tied, blessed object

sub _tie {

# Obtain the class with which to bless with inside the "thread"
# Obtain the type of variable to be blessed
# Obtain hash with parameters or create an empty one

    my $class = shift;
    my $type = shift;
    my $self = shift || {};

# Make sure we can do clone detection logic
# Set the type of variable to be blessed
# Obtain the module name to be blessed inside the shared "thread"
# Obtain the ordinal number for this tied variable (don't pass ref if running in threads emulation mode)
# Create the blessed object and return it

    $self->{'CLONE'} = $CLONE;
    $self->{'type'} = $type;
    $self->{'module'} ||= $class.'::'.$type;
    $self->{'ordinal'} = _command( '_tie',$self,( $CLONE_TIED ? @_ : () ) );
    CORE::bless $self,$class;
} #_tie

#---------------------------------------------------------------------------
#  IN: 1 reference to variable to be shared

sub _share {

# Obtain the reference
# Create the reference type of that reference

    my $it = shift;
    my $ref = reftype $it;

# Tie the variable, or return already existing tied variable

    if ($ref eq 'SCALAR') {
        my $tied = tied ${$it};
        return $tied if blessed($tied) && $tied->isa('threads::shared');
        tie ${$it},'threads::shared',{},\${$it};
    } elsif ($ref eq 'ARRAY') {
        my $tied = tied @{$it};
        return $tied if blessed($tied) && $tied->isa('threads::shared');
        tie @{$it},'threads::shared',{},\@{$it};
    } elsif ($ref eq 'HASH') {
        my $tied = tied %{$it};
        return $tied if blessed($tied) && $tied->isa('threads::shared');
        tie %{$it},'threads::shared',{},\%{$it};
    } elsif ($ref eq 'GLOB') {
        my $tied = tied *{$it};
        return $tied if blessed($tied) && $tied->isa('threads::shared');
        tie *{$it},'threads::shared',{},\*{$it};
    } else {
        _croak( "Don't know how to share '$it'" );
    }
} #_share

#---------------------------------------------------------------------------
#  IN: 1 reference to variable

sub __id {

# Obtain the reference to the variable
# Create the reference type of that reference
# Dereference a REF or non-tied SCALAR reftype value
#  Return cached refaddress if this is a shared circular self-reference (perltie workaround)
# Return immediately if this is not a valid reference
# Initialize the object

    my $it  = shift;
    my $ref = reftype $it;
    while ($ref && ($ref eq 'REF' || ($ref eq 'SCALAR' && !tied ${$it}))) {
        $it = ${$it};
        $ref = reftype $it;
        if ($ref && $ref eq 'REF') {    #possible self-circular reference
            return exists $CIRCULAR_REVERSE{$it} ? refaddr($CIRCULAR{$CIRCULAR_REVERSE{$it}}) : undef;
        }
    }
    return undef unless $ref;
    my $object;

# Obtain the object

    if ($ref eq 'SCALAR') {
        $object = tied ${$it};
    } elsif ($ref eq 'ARRAY') {
        $object = tied @{$it};
    } elsif ($ref eq 'HASH') {
        $object = tied %{$it};
    } elsif ($ref eq 'GLOB') {
        $object = tied *{$it};
    }

# If the reference is a threads::shared tied object
#  Get the ordinal of the variable
#  Return the global refaddr of the shared variable
# Else
#  Return undef

    if (defined $object && $object->isa('threads::shared')) {
        my $ordinal = $object->{'ordinal'};
        my $retval = _command( '_id',$ordinal );
        return $retval;
    } else {
        return undef;
    }
} #__id

#---------------------------------------------------------------------------
#  IN: 1 reference to variable

sub _refcnt {} #_refcnt

#---------------------------------------------------------------------------
#  IN: 1..N ordinal numbers of variables to unlock

sub _unlock {

# For each ordinal number
#  Decrement the lock counter
#  Delete ordinal number from the local list, if counter is zero (lock released)
# Notify the remote process also

    foreach (@_) {
        $LOCKED{$_}--;
        delete $LOCKED{$_} if $LOCKED{$_} <= 0;
    }
    _command( '_unlock',@_ );
} #unlock

#---------------------------------------------------------------------------
#  IN: 1 reference to the shared variable
# OUT: 1 ordinal number of variable
#      2 return value scalar of _command

sub _bless {

# Obtain the reference to the variable
# Create the reference type of that reference
# Initialize the object

    my $it  = shift;
    my $ref = reftype $it;
    my $object;

# If this package could CLONE_SKIP (don't execute now)
#  Cache the CLONE_SKIP method
#  Store a weak reference to this object

    my $package = $_[0];
    if (my $code = exists( $threads::CLONE_SKIP{$package} )
          ? $threads::CLONE_SKIP{$package} : eval { $package->can( 'CLONE_SKIP' ) }) {
        $threads::CLONE_SKIP{$package} = $code unless exists $threads::CLONE_SKIP{$package};
        my $addr = refaddr $it;
        $threads::CLONE_SKIP_REF{$package}{$addr} = \$it;
        Scalar::Util::weaken(${$threads::CLONE_SKIP_REF{$package}{$addr}});
    }

# Obtain the object

    if ($ref eq 'SCALAR') {
        $object = tied ${$it};
    } elsif ($ref eq 'ARRAY') {
        $object = tied @{$it};
    } elsif ($ref eq 'HASH') {
        $object = tied %{$it};
    } elsif ($ref eq 'GLOB') {
        $object = tied *{$it};
    }

# If the reference is a threads::shared tied object
#  Execute the indicated subroutine for this shared variable
#  Return the variable's ordinal number (and _command return scalar value if wantarray)

    if (defined $object && $object->isa('threads::shared')) {
        my $ordinal = $object->{'ordinal'};
        my $retval = _command( '_bless',$ordinal,@_ );
        return wantarray ? ($ordinal,$retval) : $ordinal;
    }
} #_bless

#---------------------------------------------------------------------------
#  IN: 1 remote subroutine to call
#      2 parameter of which a reference needs to be locked
# OUT: 1 ordinal number of variable
#      2 return value scalar of _command

sub _remote {

# Obtain the subroutine
# Obtain the reference to the variable
# Create the reference type of that reference
# Initialize the object

    my $sub = shift;
    my $it  = shift;
    my $ref = reftype $it;
    my $object;

# Obtain the object

    if ($ref eq 'SCALAR') {
        $object = tied ${$it};
    } elsif ($ref eq 'ARRAY') {
        $object = tied @{$it};
    } elsif ($ref eq 'HASH') {
        $object = tied %{$it};
    } elsif ($ref eq 'GLOB') {
        $object = tied *{$it};
    }

# If there is an ordinal number (if no object, there's no number either)
#  If we're about to lock
#   Mark the variable as locked in this thread
#   Store some caller() info (for deadlock detection report use)
#  Else if this is second case of _wait or _timedwait (unique signal and lock vars)
#   Obtain the reference to the lock variable (pop it off stack)
#   Create the reference type of that reference
#   Initialize the lock object
#   Obtain the lock object
#   If there is an ordinal number (if no object, there's no number either)
#    Die now if the variable does not appear to be locked
#    Push lock ordinal back on stack
#  Else (doing something on a locked variable)
#   Die now if the variable does not appear to be locked

    if (my $ordinal = $object->{'ordinal'}) {
        if ($sub eq '_lock') {
            $LOCKED{$ordinal}++;
            push @_, (caller())[2,1];
        } elsif (($sub eq '_wait' && scalar @_ > 0) || ($sub eq '_timedwait' && scalar @_ > 1)) {
            my $it2 = pop @_;
            my $ref2 = reftype $it2;
            my $object2;
            if ($ref2 eq 'SCALAR') {
                $object2 = tied ${$it2};
            } elsif ($ref2 eq 'ARRAY') {
                $object2 = tied @{$it2};
            } elsif ($ref2 eq 'HASH') {
                $object2 = tied %{$it2};
            } elsif ($ref2 eq 'GLOB') {
                $object2 = tied *{$it2};
            }
            if (my $ordinal2 = $object2->{'ordinal'}) {
                Carp::croak( "You need a lock before you can cond$sub" )
                 if not exists $LOCKED{$ordinal2};
                push @_, $ordinal2;
            }
        } else {
            if (not exists $LOCKED{$ordinal}) {
                if ($sub eq '_signal' || $sub eq '_broadcast') {
                    warnings::warnif('threads', "cond$sub() called on unlocked variable");
                } else {
                    Carp::croak( "You need a lock before you can cond$sub" );
                }
            }
        }

#  Execute the indicated subroutine for this shared variable
#  Return the variable's ordinal number (and _command return scalar value if wantarray)

        my $retval = _command( $sub,$ordinal,@_ );
        return wantarray ? ($ordinal,$retval) : $ordinal;
    }

# Adapt sub name to what we know outside
# No ordinal found, not shared!  Die!

    $sub = $sub eq '_lock' ? 'lock' : "cond$sub";
    Carp::croak( "$sub can only be used on shared values" );
} #_remote

#---------------------------------------------------------------------------

# debugging routines

#---------------------------------------------------------------------------
#  IN: 1 message to display

sub _croak { return &Carp::confess(shift) } #_croak

#---------------------------------------------------------------------------

__END__

=head1 NAME

forks::shared - drop-in replacement for Perl threads::shared with forks()

=head1 SYNOPSIS

  use forks;
  use forks::shared;

  my $variable : shared;
  my @array    : shared;
  my %hash     : shared;

  share( $variable );
  share( @array );
  share( %hash );

  $variable = shared_clone($non_shared_ref_value);
  $variable = shared_clone({'foo' => [qw/foo bar baz/]});

  lock( $variable );
  cond_wait( $variable );
  cond_wait( $variable, $lock_variable );
  cond_timedwait( $variable, abs time );
  cond_timedwait( $variable, abs time, $lock_variable );
  cond_signal( $variable );
  cond_broadcast( $variable );
  
  bless( $variable, class name );
  
  # Enable deadlock detection and resolution
  use forks::shared deadlock => {
    detect => 1,
    resolve => 1
  );
  # or
  threads::shared->set_deadlock_option(
    detect  => 1,
    resolve => 1
  );

=head1 DESCRIPTION

The C<forks::shared> pragma allows a developer to use shared variables with
threads (implemented with the "forks" pragma) without having to have a
threaded perl, or to even run 5.8.0 or higher.

C<forks::shared> is currently API compatible with CPAN L<threads::shared>
version C<1.05>.

=head1 EXPORT

C<share>, C<shared_clone>, C<cond_wait>, C<cond_timedwait>, C<cond_signal>,
C<cond_broadcast>, C<is_shared>, C<bless>

See L<threads::shared/"EXPORT"> for more information.

=head1 OBJECTS

L<forks::shared> exports a version of L<bless()|perlfunc/"bless REF"> that
works on shared objects, such that blessings propagate across threads.  See
L<threads::shared> for usage information and the L<forks> test suite for
additional examples.

=head1 EXTRA FEATURES

=head2 Deadlock detection and resolution

In the interest of helping programmers debug one of the most common bugs in
threaded application software, forks::shared supports a full deadlock
detection and resolution engine.

=head3 Automated detection and resolution

There are two ways to enable these features: either at import time in a use
statement, such as:

    use forks::shared deadlock => { OPTIONS }
    
or during runtime as a class method call to C<set_deadlock_option>, like:

    forks::shared->set_deadlock_option( OPTIONS );
    #or
    threads::shared->set_deadlock_option( OPTIONS );
    
where C<OPTIONS> may be a combination of any of the following:

    detect         => 1 (enable) or 0 (disable)
    period         => number of seconds between asynchronous polls
    resolve        => 1 (enable) or 0 (disable)
    
The C<detect> option enables deadlock detection.  By itself, this option
enabled synchronous deadlock detection, which efficiently checks for
potential deadlocks at lock() time.  If any are detected and warnings are
enabled, it will print out details to C<STDERR> like the following example:

    Deadlock detected:
        TID   SV LOCKED   SV LOCKING   Caller
          1           3            4   t/forks06.t at line 41
          2           4            3   t/forks06.t at line 46

The C<period> option, if set to a value greater than zero, is the number of
seconds between asynchronous deadlock detection checks.  Asynchronous
detection is useful for debugging rare, time-critical race conditions leading
to deadlocks that may be masked by the slight time overhead introduced by
synchronous detection on each lock() call.  Overall, it is less CPU intensive
than synchronous deadlock detection.

The C<resolve> option enables auto-termination of one thread in each deadlocked
thread pair that has been detected.  As with the C<detect> option, C<resolve>
prints out the action it performs to STDERR, if warnings are enabled.
B<NOTE>: C<resolve> uses SIGKILL to break deadlocks, so this feature should not
be used in environments where stability of the rest of your application may be
adversely affected by process death in this manner.

For example:

    use forks;
    use forks::shared
        deadlock => {detect=> 1, resolve => 1};

=head3 Manual detection

If you wish to check for deadlocks without enabling automated deadlock
detection, forks provides an additonal thread object method,

    $thr->is_deadlocked()

that reports whether the thread in question is currently
deadlocked.  This method may be used in conjunction with the C<resolve>
deadlock option to auto-terminate offending threads.

=head2 Splice on shared array

As of at least L<threads::shared> 1.05, the splice function has not been
implememted for arrays; however, L<forks::shared> fully supports splice on
shared arrays.

=head2 share() doesn't lose value for arrays and hashes

In the standard Perl threads implementation, arrays and hashes are
re-initialized when they become shared (with the share()) function.  The
share() function of forks::shared does B<not> initialize arrays and hashes
when they become shared with the share() function.

This B<could> be considered a bug in the standard Perl implementation.  In any
case this is an inconsistency of the behaviour of threads.pm and forks.pm.

If you do not have a natively threaded perl and you have installed and
are using forks in "threads.pm" override mode (where "use threads" loads
forks.pm), then this module will explicitly emulate the behavior of standard
threads::shared and lose value for arrays and hashes with share().
Additionally, array splice function will become a no-op with a warning.

You may also enable this mode by setting the environment variable 
C<THREADS_NATIVE_EMULATION> to a true value before running your script.  See
L<forks/"Native threads 'to-the-letter' emulation mode"> for more information.

=head1 CAVIATS

Some caveats that you need to be aware of.

=over 2

=item Storing CODE refs in shared variables

Since forks::shared requires Storable to serialize shared data structures,
storing CODE refs in shared variables is not enabled by default (primarily
for security reasons).

If need share CODE refs between threads, the minimum you must do before storing
CODE refs is:

    $Storable::Deparse = $Storable::Eval = 1;

See L<Storable/"CODE_REFERENCES"> for detailed information, including potential
security risks and ways to protect yourself against them.

=item test-suite exits in a weird way

Although there are no errors in the test-suite, the test harness sometimes
thinks there is something wrong because of an unexpected exit() value.  This
is an issue with Test::More's END block, which wasn't designed to co-exist
with a threads environment and forked processes.  Hopefully, that module will
be patched in the future, but for now, the warnings are harmless and may be
safely ignored.

=back

=head1 CURRENT AUTHOR AND MAINTAINER

Eric Rybski <rybskej@yahoo.com>.  Please send all module inquries to me.

=head1 ORIGINAL AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c)
 2005-2014 Eric Rybski <rybskej@yahoo.com>,
 2002-2004 Elizabeth Mattijsen <liz@dijkmat.nl>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<threads::shared>, L<forks>, L<forks::BerkeleyDB::shared>.

=cut
