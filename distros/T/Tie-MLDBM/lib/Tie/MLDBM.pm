package Tie::MLDBM;

use Carp;
use Tie::Hash;

use strict;
use vars qw/ @ISA $AUTOLOAD $VERSION /;

@ISA = qw/ Tie::Hash /;
$VERSION = '1.04';


sub AUTOLOAD {
    my ( $self, @params ) = @_;

    #   Parse method name from $AUTOLOAD variable and validate this method against 
    #   a list of methods allowed to be accessed through the AUTOLOAD subroutine.

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    my @methods = qw/ EXISTS FIRSTKEY NEXTKEY /;

    unless ( grep /\Q$method\E/, @methods ) {

        croak( __PACKAGE__, '->AUTOLOAD : Unsupported method for tied object - ', $method );

    }

    $self->{'Modules'}->{'Lock'}->lock_shared;

    my $rv = $self->{ 'Store' }->$method( @params );

    $self->{'Modules'}->{'Lock'}->unlock;

    return $rv;
}


sub CLEAR {
    my ( $self, @params ) = @_;

    #   Acquire an exclusive lock, execute the CLEAR method on the tied hash and 
    #   synchronise the tied hash.  The synchronisation of this hash is performed 
    #   by the Sync method of this class by way of re-opening the tied hash object 
    #   and storing this object reference

    $self->{'Modules'}->{'Lock'}->lock_exclusive;

    my $rv = $self->{'Store'}->CLEAR( @params );

    $self->{'Modules'}->{'Lock'}->unlock;

    $self->Sync;

    return $rv;
}


sub DELETE {
    my ( $self, @params ) = @_;

    #   Acquire an exclusive lock and execute the DELETE method on the tied hash.

    $self->{'Modules'}->{'Lock'}->lock_exclusive;

    my $rv = $self->{'Store'}->DELETE( @params );

    $self->{'Modules'}->{'Lock'}->unlock;

    return $rv;
}


sub FETCH {
    my ( $self, $key ) = @_;

    #   Retrieve the value indexed by the passed key argument from the second-level
    #   tied hash.  This fetched value is then deserialised using the serialisation
    #   component module of the Tie::MLDBM framework and returned to the calling
    #   process.

    $self->{'Modules'}->{'Lock'}->lock_shared;

    my $value = $self->{'Store'}->FETCH( $key );

    $self->{'Modules'}->{'Lock'}->unlock;

    return $self->{'Modules'}->{'Serialise'}->deserialise( $value );
}


sub STORE {
    my ( $self, $key, $value ) = @_;

    #   Serialise the passed value argument using the serialisation component
    #   module of the Tie::MLDBM framework.  The result of this serialisation is
    #   stored in the second-level tied hash.

    $value = $self->{'Modules'}->{'Serialise'}->serialise( $value );
    
    $self->{'Modules'}->{'Lock'}->lock_exclusive;

    my $rv = $self->{'Store'}->STORE( $key, $value );

    $self->{'Modules'}->{'Lock'}->unlock;

    return $rv;
}


sub TIEHASH {
    my ( $class, $args, @params ) = @_;
    my $self = bless {}, $class;

    #   The first argument to the TIEHASH object constructor should be a hash 
    #   reference which contains configuration options for this framework.  There 
    #   is no strict checking of the elements of the passed hash so as to allow for 
    #   the expansion of this framework and definition of additional configuration 
    #   options for framework components.

    unless ( ref $args eq 'HASH' ) {

        croak( __PACKAGE__, '->TIEHASH : First argument to TIEHASH constructor should be a hash reference' );

    }

    #   The following simply cleans up the keys of the passed argument hash so that 
    #   all keys are word-like with an uppercase first character and all lowercase 
    #   for the remaining characters.
    #
    #   The result is stored in $self->{ 'Config' } so that these arguments can be 
    #   accessed by component modules.

    $self->{'Config'} = { map { ucfirst lc $_ => delete ${$args}{$_} } keys %{$args} };

    #   The %modules hash contains a list of configuration parameters which may be 
    #   specified within the hash reference argument to the TIEHASH object 
    #   constructor.
    #
    #   The hash of configuration parameters are then iterated through and if any 
    #   of the options specified in the %modules hash are present, the component 
    #   module to which the configuration option refers (at this level of the 
    #   Tie::MLDBM framework) is called upon.

    my %modules = (
        'Lock'          =>  'Null',
        'Serialise'     =>  undef,
        'Store'         =>  undef
    );

    foreach my $arg ( keys %modules ) {

        if ( exists $self->{'Config'}->{$arg} ) {

            $modules{$arg} = join '::', __PACKAGE__, $arg, $self->{'Config'}->{$arg};
            eval "require $modules{$arg}" or
                croak( __PACKAGE__, '->TIEHASH : Cannot include framework component module ', $modules{$arg}, ' - ', $! );

        }

    }

    $self->{'Modules'} = \%modules;

    #   The arguments passed to the TIEHASH method of this class are stored for 
    #   re-use at a later stage after locking or CLEAR operations where the tied 
    #   hash is synchronised.

    $self->{'Args'} = [ @params ];

    #   Create a second-level tie to the underlying storage mechanism for 
    #   serialised data structures and store the tied object within the blessed 
    #   package object.

    my $db;
    $db = $self->{'Modules'}->{'Store'}->TIEHASH( @{ $self->{'Args'} } ) or
        croak( __PACKAGE__, '->TIEHASH : Failed to tie second level hash object - ', $! );
    $self->{'Store'} = $db;

    return $self;
}


sub Sync {
    my ( $self ) = @_;

    #   The synchronisation of the tied hash is carried out in the same manner by  
    #   which this is achieved in MLDBM::Sync.  This calls for the re-opening of 
    #   the tied hash object and storing this object reference in the Tie::MLDBM 
    #   class object.

    my $db;
    $db = $self->{'Modules'}->{'Store'}->TIEHASH( @{ $self->{'Args'} } ) or
        croak( __PACKAGE__, '->Sync : Failed to tie second level hash object - ', $! );
    $self->{'Store'} = $db;

    return $self;
}


sub UNTIE {
    my ( $self, @params ) = @_;
    return $self->{'Store'}->UNTIE( @params );
}


1;


__END__

=pod

=head1 NAME

Tie::MLDBM - Multi-Level Storage and Locking Class

=head1 SYNOPSIS

 use Tie::MLDBM;

 my $obj = tie my %hash, 'Tie::MLDBM', {
     'Lock'      =>  'File',
     'Serialise' =>  'Storable',
     'Store'     =>  'DB_File'
 } [.. other DBM arguments..] or die $!;

=head1 DESCRIPTION

This module provides the means to store arbitrary perl data, including nested 
references, in a serialised form within persistent data back-ends.  This module 
builds upon the storage and locking mechanisms of B<MLDBM> and B<MLDBM::Sync> 
by incorporating a more expandible framework that allows for a much wider 
variety of component modules for serialisation, storage and resource locking.  
Indeed, all storage components of this framework exist as a direct IS-A 
inherited class of their parent storage module such that almost any module 
employing a tied-interface can now store multi-level nested data structures and 
incorporate locking synchronisation.

The B<Tie::MLDBM> framework consists of four components: the interface, the 
locking component, the serialisation component and the storage component.  The 
interface is implemented as a TIEHASH by the B<Tie::MLDBM> module which in turn 
depends upon the functions provided by component modules.  The locking or 
synchronisation component implements shared and exclusive access to the 
underlying storage component by means of semaphores.  The serialisation 
component is that which serialises the nested data structure into a flat form 
ready for storage in the underlying storage component.  The storage component 
can be any new or existing module which implements a TIEHASH interface to a 
persistent store.  All storage modules of this framework inherit directly from 
the storage mechanism which they represent.

=head1 INTERFACE

The interface to the B<Tie::MLDBM> module is intended to be simple and impose 
little in the way of a learning curve in its usage.

The mandatory first argument of the TIEHASH interface of this module is a hash 
reference which contains configuration parameters for the B<Tie::MLDBM> framework. 
These configuration parameters define the interface behaviour and component modules 
of the B<Tie::MLDBM> interface.  

The following configuration parameters are mandatory:

=over 4

=item B<Lock>

The Lock parameter defines the B<Tie::MLDBM::Lock::*> component module to be 
employed by the B<Tie::MLDBM> framework for locking and synchronisation.  

If left unspecified, this parameter defaults to C<Null> which calls upon the 
B<Tie::MLDBM::Lock::Null> module for locking and synchronisation - This module 
fulfills the locking component of the B<Tie::MLDBM> framework, without actually 
implementing any resource synchronisation or locking.

The available locking and synchronisation mechanisms are dictated by those 
modules installed in the B<Tie::MLDBM::Lock::*> namespace.

=item B<Serialise>

The Serialise parameter defines the B<Tie::MLDBM::Serialise::*> component module 
to be employed by the B<Tie::MLDBM> framework for the serialisation of nested data 
structures into flat forms ready for persistent storage.

The available serialisation mechanisms are dictated by those modules installed 
in the B<Tie::MLDBM::Serialise::*> namespace.

=item B<Store>

The Store parameter defines the B<Tie::MLDBM::Store::*> component module to be 
employed by the B<Tie::MLDBM> framework for the persistent storage of serialised 
data.

The available serialisation mechanisms are dictated by those modules installed 
in the B<Tie::MLDBM::Store::*> namespace.

=back

In addition to these configuration parameters, component modules may require 
additional configuration parameters to be defined in order to change their 
behaviour.  For example, the B<Tie::MLDBM::Lock::File> module allows for the 
filename and directory location of the semaphore file employed to be defined 
via a C<Lockfile> configuration argument.

The remaining arguments to the TIEHASH interface of the B<Tie::MLDBM> module are 
passed directly onto the underlying storage TIEHASH, as defined by the C<Store> 
configuration parameter.  This arrangement allows for any module employing a 
TIEHASH interface to a persistent store to be used by the B<Tie::MLDBM> framework, 
for the persistent storage of serialised data.

=head1 EXAMPLES

=head2 Example Using DB_File

An example of the TIEHASH interface of B<Tie::MLDBM>, employing the B<DB_File> 
TIEHASH interface for persistent storage:

 use Tie::MLDBM;

 tie my %test, 'Tie::MLDBM', {
     'Serialise' =>  'Storable',
     'Store'     =>  'DB_File'
 }, 'testdb.dbm', O_CREAT|O_RDWR, 0640 or die $!;

The above example creates a persistent store for the hash C<%test> called 
C<testdb.dbm> with B<DB_File> in which data is serialised using B<Storable>.

=head2 Example Using DBI

An example of the TIEHASH interface of B<Tie::MLDBM>, employing the TIEHASH 
interface of B<Tie::DBI> (by means of B<Tie::MLDBM::Store::DBI> for persistent 
storage:

 use Tie::MLDBM;

 tie my %db, 'Tie::MLDBM', {
     'Lock'      =>  'File',
     'Serialise' =>  'Storable',
     'Store'     =>  'DBI'
 }, {
     'db'        =>  "Pg:dbname=@{[ DATABASE ]}",
     'table'     =>  'sessions',
     'key'       =>  'id',
     'user'      =>  USERNAME,
     'password'  =>  PASSWORD,
     'CLOBBER'   =>  0
 } or die $!;

The above example creates a persistent store for the hash C<%db> which employs 
the C<sessions> table of a PostgreSQL database for the storage of data 
serialised by B<Storable>.

=head1 WARNINGS

The addition or alteration of elements to nested data structures is not entirely 
transparent in Perl.  As such, in order to store a reference or modify an existing 
reference value within a tied hash, the value must first be retrieved and stored in 
a temporary variable before modification.  For example, the following will not 
work:

 $hash{'key'}{'subkey'} = 'value';   #   Will not work

Instead, this operation should be performed in a two-step process, like thus:

 $temp = $hash{'key'};               #   Retrieve element
 $temp->{'subkey'} = 'value';
 $hash{'key'} = $temp;               #   Store element

This limitation exists because the perl TIEHASH interface currently has no support 
for multidimensional ties.

=head1 VERSION

1.04

=head1 AUTHOR

Rob Casey <robau@cpan.org>

=head1 COPYRIGHT

Copyright 2002 Rob Casey, robau@cpan.org

=head1 SEE ALSO

L<MLDBM>, L<MLDBM::Sync>

=cut
