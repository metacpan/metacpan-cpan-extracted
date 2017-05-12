package Tivoli::AccessManager::Admin::ProtObject;
use strict;
use warnings;
use Carp;
use Data::Dumper;

use Tivoli::AccessManager::Admin::Response;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: ProtObject.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::ProtObject::VERSION = '1.11';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
		NAME => 'Tivoli::AccessManager::Admin::ProtObject',
	    );

sub new {
    my $class = shift;
    my $cont = shift;
    my $type = 0;

    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    if ( @_ % 2 ) {
	warn "Invalid syntax -- you did not send a hash\n";
	return undef;
    }
    my %opts = @_;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    my $self = bless {}, $class;

    $self->{name}        = $opts{name} || '';
    $self->{description} = $opts{description} || '';
    $self->{context}     = $cont;
    $type		 = $opts{type} || 0;

    #Figure out the object type, or set to unknown.
    unless (($type =~ /^\d+$/) and ($type < 18)) {
	carp("Unknown object type: $type");
	return undef;
    }

    $self->{type} = $type;
    $self->_protstash;
    if ( $self->protobj_exists($resp) ) {
	$self->{exist} = 1;
	$self->get;
    }

    return $self;
}

sub create {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    unless ( ref $self ) {
	my $pd = shift;
	unless (defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context')){
	    $resp->set_message("Invalid Tivoli::AccessManager::Admin::Context object");
	    $resp->set_isok(0);
	    return $resp;
	}
	$self = $self->new( $pd, @_ );
	unless ( defined $self ) {
	    $resp->set_isok(0);
	    $resp->set_message('Error creating object');
	    return $resp;
	}
    }

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax -- send a hash");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;
    my $type = $opts{type} || $self->{type} || 0;
    
    unless ( $self->{name} ) {
	$self->{name} = $opts{name} || '';
    }

    unless ( $self->{name} ) {
	$resp->set_message("Cannot create a protected object with no name");
	$resp->set_isok(0);
	return $resp;
    }

    if ( $self->exist ) { 
	$resp->set_message("Protected object already exists");
	$resp->set_iswarning(1);
	$resp->set_value($self);
	return $resp;
    }

    unless ( $type =~ /^\d+$/ and $type < 18 ) {
	$resp->set_message("Unknown object type: $type");
	$resp->set_isok(0);
	return $resp;
    }
    $self->{type} = $type;

    my $rc = $self->protobj_create( $resp, $self->{type},
				    $opts{description} || '' );
    if ( $resp->isok ) {
	$resp->set_value($self);
	$self->{exist} = 1;
	$self->get;
    }

    return $resp;
}

sub delete {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot delete an object that doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    my $rc = $self->protobj_delete($resp);
    if ( $resp->isok ) {
	$self->{exist} = 0;
    }
    return $resp;
}
    
sub get {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    my @rc = $self->protobj_get($resp);
    # I really have no clue what this will return.  I am going to leave this
    # here as a stub, and figure everything out later.  Watch this space for
    # something new.
    $resp->isok && $resp->set_value(\@rc);
    return $resp;
}

sub acl { 
    my $self = shift;
    my %opts = @_;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my %ret;

    if ( defined $opts{detach} ) { 
	my $rc = $self->protobj_detachacl( $resp );
	return $resp unless $resp->isok;
	$self->get;
    }

    if ( defined $opts{attach} ) {
	my $rc = $self->protobj_attachacl( $resp, $opts{attach} );
	return $resp unless $resp->isok;
	$self->get;
    }

    $ret{attached} = $self->protobj_getaclid() || '';
    $ret{effective} = $self->protobj_geteffaclid();

    $resp->set_value( \%ret );
    return $resp;
}

sub authzrule {
    my $self = shift;
    my %opts = @_;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my %ret;

    if ( defined $opts{detach} ) { 
	my $rc = $self->protobj_detachauthzrule( $resp );
	return $resp unless $resp->isok;
	$self->get;
    }

    if ( defined $opts{attach} ) {
	my $rc = $self->protobj_attachauthzrule( $resp, $opts{attach} );
	return $resp unless $resp->isok;
	$self->get;
    }

    $ret{attached} = $self->protobj_getauthzruleid() || '';
    $ret{effective} = $self->protobj_geteffauthzruleid() || '';

    $resp->set_value( \%ret );
    return $resp;
}

sub pop { 
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my %ret;

    $ret{attached} = $self->protobj_getpopid();
    $ret{effective} = $self->protobj_geteffpopid();

    $resp->set_value( \%ret );
    return $resp;
}

sub type { 
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $type;
    
    if ( @_ == 1 ) {
	$type = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$type = $opts{type} || 0;
    }

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot get/set the type of a non-existent object");
	$resp->set_isok(0);
	return $resp;
    }

    if ($type) {
	unless ( $type =~ /^\d+$/ and $type < 18 ) {
	    $resp->set_message("Invalid object type $type");
	    $resp->set_isok(0);
	    return $resp;
	}
	my $rc = $self->protobj_settype( $resp, $type );
	if ( $resp->isok ) {
	    $self->protobj_get($resp);
	}
    }

    $resp->isok && $resp->set_value( $self->protobj_gettype );
    return $resp;
}

sub description { 
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $desc;
    
    if ( @_ == 1 ) {
	$desc = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$desc = $opts{description} || 0;
    }

    
    unless ( $self->{exist} ) {
	$resp->set_message("Cannot describe a non-existent object");
	$resp->set_isok(0);
	return $resp;
    }

    if ( $desc ) {
	my $rc = $self->protobj_setdesc($resp,$desc);
	if ( $resp->isok ) {
	    $self->protobj_get($resp);
	}
    }

    $resp->isok && $resp->set_value( $self->protobj_getdesc );
    return $resp;
}

sub policy_attachable { 
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $att = undef;
    
    if ( @_ == 1 ) {
	$att = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$att = $opts{att} || 0;
    }
    
    if ( defined($att) ) {
	my $rc = $self->protobj_setpolicyattachable($resp,$att);
	if ( $resp->isok ) {
	    $self->protobj_get($resp);
	}
    }

    $resp->isok && $resp->set_value( $self->protobj_getpolicyattachable );
    return $resp;
}

sub list {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my @rc;

    @rc = $self->protobj_list( $resp );

    $resp->isok && $resp->set_value( \@rc );
    return $resp;
}

sub find {
    my $class = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    my ($pd,@rc);

    if ( ref($class) ) {
	$pd = $class->{context};
    }
    else {
	$pd = shift;
    }

    unless (defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context')){
	$resp->set_message("Invalid Tivoli::AccessManager::Admin::Context object");
	$resp->set_isok(0);
	return $resp;
    }
    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;
    if ( defined $opts{acl} ) {
	@rc = protobj_listbyacl( $pd, $resp, $opts{acl} );
    }
    elsif ( defined $opts{authzrule} ) {
	@rc = protobj_listbyauthzrule( $pd, $resp, $opts{authzrule} );
    }
    else {
	$resp->set_message("Must find by authzrule or acl");
	$resp->set_isok(0);
    }

    $resp->isok && $resp->set_value( \@rc );
    return $resp;
}

sub _remvalue {
    my $self = shift;
    my $dead = shift;

    my $resp = Tivoli::AccessManager::Admin::Response->new;

    for my $key ( keys %{$dead} ) {
	if ( ref( $dead->{$key} ) ) {
	    for my $val ( @{$dead->{$key}} ) {
		my $rc = $self->protobj_attrdelval( $resp, $key, $val ); 
		return $resp unless $resp->isok; 
	    }
	}
	else {
	    my $rc = $self->protobj_attrdelval( $resp, $key, $dead->{$key} ); 
	    return $resp unless $resp->isok; 
	}
    }
    return $resp;
}

sub _remkey {
    my $self = shift;
    my $dead = shift;

    my $resp = Tivoli::AccessManager::Admin::Response->new;

    if ( ref( $dead ) ) {
	for my $key ( @{$dead} ) {
	    my $rc = $self->protobj_attrdelkey( $resp, $key ); 
	    return $resp unless $resp->isok; 
	}
    }
    else {
	my $rc = $self->protobj_attrdelkey( $resp, $dead ); 
    }

    return $resp;
}

sub _addval {
    my $self = shift;
    my $add = shift;

    my $resp = Tivoli::AccessManager::Admin::Response->new;

    for my $key ( keys %{$add} ) { 
	if ( ref( $add->{$key} ) ) {
	    for my $val ( @{$add->{$key}} ) {
		my $rc = $self->protobj_attrput( $resp, $key, $val );
		return $resp unless $resp->isok;
	    }
	}
	else {
	    my $rc = $self->protobj_attrput( $resp, $key, $add->{$key} ); 
	    return $resp unless $resp->isok; 
	}
    }

    return $resp
}

sub attributes {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $rhash = {};
    my %dispatch = ( remove    => \&_remvalue,
		     removekey => \&_remkey,
		     add       => \&_addval
		    );

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    for my $action ( qw/remove removekey add/ ) {
	if ( defined $opts{$action} ) {
	    $resp = $dispatch{$action}->($self,$opts{$action}); 
	    return $resp unless $resp->isok; 
	}
    }

    # just in case one of the above branches was actually taken, refresh the
    # cached object
    $self->get($resp);
    for my $key ( $self->protobj_attrlist ) {
	$rhash->{$key} = [ $self->protobj_attrget($key) ];
    }
   
    $resp->isok && $resp->set_value( $rhash );
    return $resp;
}

sub DESTROY {
    my $self = shift;
    $self->_protobj_free();
}


sub name { $_[0]->protobj_getid }
sub exist { $_[0]->{exist} }

1;

=head1 NAME

Tivoli::AccessManager::Admin::ProtObject

=head1 SYNOPSIS

  use Tivoli::AccessManager::Admin;

  my $resp;
  my $pd = Tivoli::AccessManager::Admin->new( password => 'foobar' );
  my $pobj = Tivoli::AccessManager::Admin::ProtObject->new( $pdadmin, 
					  name => '/test/monkey');

  # Create the object unless it already exists
  $resp = $pobj->create unless $pobj->exist;

  # Set the type and the description
  $resp = $pobj->type( 'container' );
  $resp = $pobj->description( 'Monkey!' );

  # Attach an ACL
  $resp = $pobj->acl( attach => 'default-webseal' );

  # Detach  an ACL
  $resp = $pobj->acl( detach => 1 );

  # Get the attached and effective ACL
  $resp = $pobj->acl;
  my $href = $resp->value;
  print "Effective ACL: $href->{effective}\n";
  print "Attached ACL: $href->{attached}\n";

  # Find out where else the ACL is attached
  $resp = Tivoli::AccessManager::Admin::ProtObject->find( acl => $href->{attached} );

  # Attach an authorization rule
  $resp = $pobj->authzrule( attach => 'silly' );

  # Find out where else the authzrule is attached
  $resp = Tivoli::AccessManager::Admin::ProtObject->find( authzrule => 'silly' );

  # Detach an authzrule
  $resp = $pobj->authzrule( detach => 1 );

  # Get the attached and effective Authzrule
  $resp = $pobj->authzrule;
  my $href = $resp->value;
  print "Effective Authz: $href->{effective}\n";
  print "Attached Authz: $href->{attached}\n";

  # Get a list of the objects under /test
  my $top = Tivoli::AccessManager::Admin::ProtObject->new( $pd, name => '/test' );
  $resp = $top->list;

  # See what POPs are attached to the object
  $resp = $pobj->pop;

  # Set is_policy_attachable bit to 0
  $resp = $pobj->policy_attachable( 0 );
 
  # Add some attributes
  $resp = $pobj->attributes( add => { evil => 1, 
				      smoking => [ qw/strawberry crack/ ]
				    });
  # Remove one of the values
  $resp = $pobj->attributes( remove => { smoking => 'crack' } );

  # Remove the keys
  $resp = $pobj->attributes( removekey => [ qw/evil smoking/ ] )

  # Finally, delete it
  $resp = $pobj->delete;

=head1 DESCRIPTION

B<Tivoli::AccessManager::Admin::ProtObject> provides the interface to the protected object API
calls.

=head1 CONSTRUCTORS

=head2 new( PDADMIN[, name =E<gt> NAME, type =E<gt> TYPE, description => DESC ])

Creates a new L<Tivoli::AccessManager::Admin::ProtObject> object.

=head3 Parameters

=over 4

=item PDADMIN

A blessed and initialized L<Tivoli::AccessManager::Admin::Context>.  This is the only required
parameter.

=item name =E<gt> NAME

The name of the protected object.  This usually looks an awful lot like a UNIX
path.

=item type =E<gt> TYPE

The protected object type.  See L</"Types"> for a full discussion of the
allowed values.

=item description =E<gt> DESC

Some descriptive text.

=back

=head3 Returns

A blessed L<Tivoli::AccessManager::Admin::ProtObject> object.  If the type is specified and it
is not a valid type, you will get a nasty warning and a return of undef.

=head2 create(PDADMIN,name =E<gt> NAME[, type =E<gt> TYPE, description => DESC ])

L</"create">, as with all the other modules, can be used to both initialize the
L<Tivoli::AccessManager::Admin::ProtObject> instance and create the object in the policy
database.

In this case, the newly created instance will be returned to you in a
L<Tivoli::AccessManager::Admin::Response> object.  See that module's Fine Documentation to learn
how to get it.

=head3 Parameters

The parameters are identical to those for L</"new">.  The only difference is
that the name is now a required parameter.

=head3 Returns

A L<Tivoli::AccessManager::Admin::Response> object containing the new instance.

=head1 CLASS METHODS

=head2 find(PDADMIN, E<lt>acl =E<gt> 'acl name' | authzrule =E<gt> 'auth rule name'E<gt>)

Searches the object space for every object to which either the ACL or the
authzrule is attached.  You can use this method, but I think the find methods
for L<Tivoli::AccessManager::Admin::ACL> and L<Tivoli::AccessManager::Admin::Authzrule> make more sense.

=head3 Parameters

You only need to provide either the acl or authzrule.  If both are provided,
the ACL will win.

=over 4

=item PDADMIN

A blessed and initialized L<Tivoli::AccessManager::Admin::Context>.  This is the only required
parameter.

=item acl =E<gt> 'acl name'

The name of the ACL for which we are searching.  

=item authzrule =E<gt> 'auth rule name'

The name of the authzrule for which we are searching.  

=back

=head3 Returns

A L<Tivoli::AccessManager::Admin::Response> object containing a possibly empty array of all
objects found.


=head1 METHODS

Unless otherwise mentioned, everything returns a L<Tivoli::AccessManager::Admin::Response>
object.

=head2 create([ name =E<gt> NAME, type =E<gt> TYPE, description => DESC ])

Yes, L</"create"> can also be used as a method.

=head3 Parameters

The same as L</"create"> the constructor.  You must provide the name of you
did not provide it to L</"new">.

=head3 Returns

A L<Tivoli::AccessManager::Admin::Response> object containing the new instance.

=head2 delete

Deletes the object from the policy database.

=head3 Parameters

None

=head3 Returns

Success if the object exists and it can be deleted.  

=head2 get

Refreshes the cached ivadmin_protobj structure.  This should almost never need
to be used by you, unless you decide to bypass my nice interface and go
directly to the API calls.

=head3 Parameters

None

=head3 Returns

None

=head2 acl([attach => 'ACL Name', detach => 'ACL Name'])

Attaches or detaches an ACL from the object.  If called with no parameters,
returns the attached and effective ACL for that object.  If called with both
attach and detach, detaches are handled first.

=head3 Parameters

=over 4

=item attach =E<gt> 'ACL Name'

This will cause the named ACL to be attached to the the object.  

=item detach =E<gt> 'ACL Name'

The will cause the named ACL to be detached.

=back

=head3 Returns

Any attempt to attach an ACL that does not exist or detach an ACL not already
attached will result in an error.

Otherwise, you will get a hash that looks like this:

=over 4

=item attached 

The name of the attached ACL if any

=item effective

The name of the effective ACL.

=back

=head2 authzrule([attach =E<gt>  "Authzrule", detach =E<gt> "Authzrule"])

Attaches and detaches authorization rules.  Unlike L</"acl">, this code is
currently completely untested.  I don't yet know how to create authzrules to
test it.

=head3 Parameters

=over 4

=item attach =E<gt> 'authzrule Name'

This will cause the named authzrule to be attached to the the object.  

=item detach =E<gt> 'authzrule Name'

The will cause the named authzrule to be detached.

=back

=head3 Returns

Any attempt to attach an authzrule that does not exist or detach an authzrule
not already attached will result in an error.

Otherwise, you will get a hash that looks like this:

=over 4

=item attached 

The name of the attached authzrule if any

=item effective

The name of the effective authzrule.

=back

=head2 pop

Returns the attached and effective POP.  See L<Tivoli::AccessManager::Admin::POP> for the attach
and detach methods.  Don't look at me -- I didn't write the API.

=head3 Parameters

None

=head3 Returns

A hash that looks like this:

=over 4

=item attached 

The name of the attached POP if any

=item effective

The name of the effective POP.

=back

=head2 type([TYPE])

Sets or gets the object's type.  See L</"Types"> for a discussion of the valid types.

=head3 Parameters

=over 4

=item type =E<gt> TYPE

The object's new type.  

=back

=head3 Returns

The object's type.

=head2 description(['DESC'])

Give the object some enlightening description.

=head3 Parameters

=over 4

=item 'DESC'

The new description.  This is optional, as usual.

=back

=head3 Returns

The object's description.

=head2 policy_attachable([0|1])

Allow policies to be attached or not.

=head3 Parameters

=over 4

=item  0 | 1

0 to disable attaching policies, 1 to enable.

=back

=head3 Returns

1 if the object allows policies to be attached, 0 otherwise.

=head2 list

Lists all of the object immediately below the object in question.

=head3 Parameters

None

=head3 Returns

A list, possibly empty, of all the sub-objects.

=head2 attributes([add =E<gt> { key => [qw/value0 value1/] | 'value0' }, remove =E<gt> { key => [qw/value0 value1/] | 'value0' }, removekey =E<gt> [qw/key0 key1] ] )

Adds key/value attributes to an object, removes the values and removes the
entire key/value pairs.  I find these to be the more ... annoying functions.

=head3 Parameters

=over 4

=item add =E<gt> { key =E<gt> [qw/ value0 value1/] | 'value0' }

Causes L</"attribute"> to add any number of key/value pairs to the object.  As
you can have multiple values associated with any given key, you can either use
an array reference for multiple values, or a simple scalar if you are playing
with only one.

You can, obviously, add multiple keys with the same call.  You can also,
strangely enough, add the same value to a key multiple times.

=item remove =E<gt> { key =E<gt> [qw/ value0 value1/] | 'value0' }

Removes the specified value(s) from the key.  This does not remove the key,
simply the values from the key.  You will get an error if you try to remove a
value that is not defined.

=item removekey =E<gt> [qw/key0 key1]

Removes both the attribute and any associated values from the object.

=back

=head3 Returns

A hash of lists.  The hash is keyed off of the attribute names.  The values
for each attribute are returned as a list -- even if there is only one value.  

=head2 name

Returns the name of the object.  This is returned as a simple string B<not> in
a L<Tivoli::AccessManager::Admin::Response> object.

=head2 exist

Returns a boolean indicating if the object exists or not.  This does B<not>
return a L<Tivoli::AccessManager::Admin::Response> object.

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin> for the full list of acknoledgements.

=head1 BUGS

None known yet, although I am thinking there are parts of the interface that
need to change.  I do not like having to use a hash in the methods that
require only one parameter, but I do not like breaking the pattern almost as
much.

=head1 AUTHOR

Mik Firestone <mikfire@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2004-2011 Mik Firestone.  All rights reserved.  This program is
free software; you can redistibute it and/or modify it under the same terms as
Perl itself.

Standard IBM copyright, trademark, patent and ownership statement.

=cut

__DATA__
__C__

#include "ivadminapi.h"
#include "ogauthzn.h"
#include "aznutils.h"

ivadmin_response* _getresponse( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"response",8,0);
    ivadmin_response* rsp;

    if ( fetched == NULL ) {
	croak("Couldn't fetch the _response in $self");
    }
    rsp = (ivadmin_response*) SvIV(*fetched);

    fetched = hv_fetch( self_hash, "used",4,0);
    if ( fetched ) {
	sv_setiv( *fetched, 1 );
    }
    return(rsp);
}

static ivadmin_context* _getcontext( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"context", 7, 0 );

    if ( fetched == NULL ) {
	croak("Couldn't get context");
    }
    return((ivadmin_context*)SvIV(SvRV(*fetched)));
}

static char* _getname( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "name", 4, 0 );

    return(fetched ? SvPV_nolen(*fetched) : NULL);
}

ivadmin_protobj* _getprot( SV* self ) {
    HV* selfhash = (HV*)SvRV(self);
    SV** fetched = hv_fetch( selfhash, "_prot", 5, 0 );

    return(fetched ? (ivadmin_protobj*)SvIV(*fetched) : NULL);
}

void _protstash( SV* self ) {
    HV* selfhash = (HV*)SvRV(self);
    SV** fetched = hv_fetch( selfhash, "_prot", 5, 1 );

    ivadmin_protobj* prot;

    Newz( 5, prot, 1, ivadmin_protobj );
    if ( fetched == NULL )
	croak("Couldn't create the _prot slot");

    sv_setiv( *fetched, (IV) prot );
    SvREADONLY_on(*fetched);
}

int protobj_attachacl( SV* self, SV* resp, char* aclid ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    char*             name = _getname( self );

    unsigned long rc;

    if (name == NULL)
	croak("Invalid name in attachacl");

    rc = ivadmin_protobj_attachacl( *ctx,
				    name,
				    aclid,
				    rsp );

    return(rc == IVADMIN_TRUE);
}


int protobj_attachauthzrule( SV* self, SV* resp, char* authzrule ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    char*             name = _getname( self );

    unsigned long rc;

    if (name == NULL)
	croak("Invalid name in attachauthzrule");

    rc = ivadmin_protobj_attachauthzrule( *ctx,
				    name,
				    authzrule,
				    rsp );

    return(rc == IVADMIN_TRUE);
}
int protobj_create( SV* self, SV* resp, int type, const char* desc ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    char*             name = _getname( self );

    unsigned long rc;

    if (name == NULL)
	croak("Invalid name in create");

    rc = ivadmin_protobj_create( *ctx,
			         name,
				 type,
				 desc,
				 rsp );
    return(rc == IVADMIN_TRUE);
}

int protobj_delete( SV* self, SV* resp ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    char*             name = _getname( self );

    unsigned long rc;

    if (name == NULL)
	croak("Invalid name in delete");

    rc = ivadmin_protobj_delete( *ctx,
			         name,
				 rsp );
    return(rc == IVADMIN_TRUE);
}

int protobj_detachacl( SV* self, SV* resp ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    char*             name = _getname( self );

    unsigned long rc;

    if (name == NULL)
	croak("Invalid name in detachacl");

    rc = ivadmin_protobj_detachacl( *ctx,
			            name,
				    rsp );
    return(rc == IVADMIN_TRUE);
}

int protobj_detachauthzrule( SV* self, SV* resp ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    char*             name = _getname( self );

    unsigned long rc;

    if (name == NULL)
	croak("Invalid name in detachauthzrule");

    rc = ivadmin_protobj_detachauthzrule( *ctx,
			            name,
				    rsp );
    return(rc == IVADMIN_TRUE);
}

int protobj_exists( SV* self, SV* resp ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    char*             name = _getname( self );

    unsigned long rc;
    unsigned long exists;

    if (name == NULL)
	croak("Invalid name in exists");

    rc = ivadmin_protobj_exists( *ctx,
			         name,
				 &exists,
				 rsp );
    return(exists == IVADMIN_TRUE);
}

void protobj_get( SV* self, SV* resp ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    ivadmin_protobj*  prot = _getprot(self);
    char*             name = _getname( self );

    azn_attrlist_h_t* outdata = NULL;
    unsigned long rc;
    unsigned long i;
    unsigned long count = 0;
    char **results;


    if (name == NULL)
	croak("Invalid name in get");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( prot == NULL ) {
	_protstash(self);
	prot = _getprot(self);
    }

    if ( prot == NULL )
	croak("Couldn't find an ivadmin_protobj");

    rc = ivadmin_protobj_get3( *ctx,
			       name,
			       NULL,
			       prot,
			       outdata,
			       &count,
			       &results,
			       rsp );
    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(results[i],0)));
	    ivadmin_free( results[i] );
	}
    }
    Inline_Stack_Done;
}

SV* protobj_getaclid( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    const char* aclid;

    if ( prot == NULL )
	croak("protobj_getaclid: could not retrieve ivadmin_protobj");

    aclid = ivadmin_protobj_getaclid( *prot );
    return(aclid ? newSVpv( aclid, 0 ) : NULL);
}

SV* protobj_geteffaclid( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    const char* effaclid;

    if ( prot == NULL )
	croak("protobj_geteffaclid: could not retrieve ivadmin_protobj");

    effaclid = ivadmin_protobj_geteffaclid( *prot );
    return(effaclid ? newSVpv( effaclid, 0 ) : NULL);
}

SV* protobj_getauthzruleid( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    const char* authzruleid;

    if ( prot == NULL )
	croak("protobj_getauthzruleid: could not retrieve ivadmin_protobj");

    authzruleid = ivadmin_protobj_getauthzruleid( *prot );
    return(authzruleid ? newSVpv( authzruleid, 0 ) : NULL);
}

SV* protobj_geteffauthzruleid( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    const char* effauthzruleid;

    if ( prot == NULL )
	croak("protobj_geteffauthzruleid: could not retrieve ivadmin_protobj");

    effauthzruleid = ivadmin_protobj_geteffauthzruleid( *prot );
    return(effauthzruleid ? newSVpv( effauthzruleid, 0 ) : NULL);
}

SV* protobj_getpopid( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    const char* popid;

    if ( prot == NULL )
	croak("protobj_getpopid: could not retrieve ivadmin_protobj");

    popid = ivadmin_protobj_getpopid( *prot );
    return(popid ? newSVpv( popid, 0 ) : NULL);
}

SV* protobj_geteffpopid( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    const char* effpopid;

    if ( prot == NULL )
	croak("protobj_geteffpopid: could not retrieve ivadmin_protobj");

    effpopid = ivadmin_protobj_geteffpopid( *prot );
    return(effpopid ? newSVpv( effpopid, 0 ) : NULL);
}

SV* protobj_getdesc( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    const char* desc;

    if ( prot == NULL )
	croak("protobj_getdesc: could not retrieve ivadmin_protobj");

    desc = ivadmin_protobj_getdesc( *prot );
    return(desc ? newSVpv( desc, 0 ) : NULL);
}

SV* protobj_getid( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    const char* id;

    if ( prot == NULL )
	croak("protobj_getid: could not retrieve ivadmin_protobj");

    id = ivadmin_protobj_getid( *prot );
    return(id ? newSVpv( id, 0 ) : NULL);
}

int protobj_getpolicyattachable( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    unsigned long pattachable;

    if ( prot == NULL )
	croak("protobj_getpolicyattachable: could not retrieve ivadmin_protobj");

    pattachable = ivadmin_protobj_getpolicyattachable( *prot );
    return(pattachable);
}

int protobj_gettype( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    unsigned long type;

    if ( prot == NULL )
	croak("protobj_gettype: could not retrieve ivadmin_protobj");

    type = ivadmin_protobj_gettype( *prot );
    return(type);
}

void protobj_list(SV* self, SV* resp) {
    ivadmin_context*  ctx  = _getcontext(self);
    ivadmin_response* rsp  = _getresponse(resp);
    char*             name = _getname(self);

    azn_attrlist_h_t* outdata = NULL;
    char** objs;
    char** results;
    unsigned long ocnt;
    unsigned long rcnt; 
    unsigned long rc; 
    unsigned long i; 

    Inline_Stack_Vars;
    Inline_Stack_Reset;
   
    if ( name == NULL )
	croak("Undefined name in protobj_list");

    rc = ivadmin_protobj_list3( *ctx,
				name,
				NULL,
				&ocnt,
				&objs,
				outdata,
				&rcnt,
				&results,
				rsp );
    if ( rc == IVADMIN_TRUE) {
	for(i=0;i<ocnt;i++){
	    Inline_Stack_Push(sv_2mortal(newSVpv(objs[i],0)));
	    ivadmin_free(objs[i]);
	}
    }

    Inline_Stack_Done;
}

void protobj_listbyacl( SV* pd, SV* resp, char* aclid ) {
    ivadmin_context*  ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp  = _getresponse(resp);

    unsigned long count;
    unsigned long rc;
    unsigned long i;
    char** objects;

    Inline_Stack_Vars;
    Inline_Stack_Reset;
    
    rc = ivadmin_protobj_listbyacl( *ctx,
				    aclid,
				    &count,
				    &objects,
				    rsp );
    if ( rc == IVADMIN_TRUE) {
	for( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(objects[i],0)));
	    ivadmin_free( objects[i] );
	}
    }
    Inline_Stack_Done;
}

void protobj_listbyauthzrule( SV* pd, SV* resp, char* authzrule ) {
    ivadmin_context*  ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp  = _getresponse(resp);

    unsigned long count;
    unsigned long rc;
    unsigned long i;
    char** objects;

    Inline_Stack_Vars;
    Inline_Stack_Reset;
    
    rc = ivadmin_protobj_listbyauthzrule( *ctx,
					  authzrule,
					  &count,
					  &objects,
					  rsp );
    if ( rc == IVADMIN_TRUE) {
	for( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(objects[i],0)));
	    ivadmin_free( objects[i] );
	}
    }
    Inline_Stack_Done;
}

int protobj_setdesc( SV* self, SV* resp, char *desc ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    char*             name = _getname( self );

    unsigned long rc;

    if (name == NULL)
	croak("Invalid name in setdesc");

    rc = ivadmin_protobj_setdesc( *ctx,
				   name,
				   desc,
				   rsp );
    return(rc == IVADMIN_TRUE);
}


int protobj_setpolicyattachable( SV* self, SV* resp, int flag ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    char*             name = _getname( self );

    unsigned long rc;

    if (name == NULL)
	croak("Invalid name in setpolicyattachable");

    rc = ivadmin_protobj_setpolicyattachable( *ctx,
				   name,
				   flag,
				   rsp );
    return(rc == IVADMIN_TRUE);
}

int protobj_settype( SV* self, SV* resp, int type ) {
    ivadmin_context*  ctx  = _getcontext( self );
    ivadmin_response* rsp  = _getresponse( resp );
    char*             name = _getname( self );

    unsigned long rc;

    if (name == NULL)
	croak("Invalid name in settype");

    rc = ivadmin_protobj_settype( *ctx,
				   name,
				   type,
				   rsp );
    return(rc == IVADMIN_TRUE);
}

void protobj_attrlist( SV* self ) {
    ivadmin_protobj* prot = _getprot(self);
    unsigned long count = 0;
    unsigned long rc    = 0;
    unsigned long i;

    char **protlist;

    if (prot == NULL)
	croak("protobj_attrlist: could not retrience ivadmin_protobj");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( prot == NULL ) {
	croak("protobj_attrlist: Couldn't retrieve the ivadmin_protobj object");
    }

    rc = ivadmin_protobj_attrlist( *prot,
    			       &count,
			       &protlist
			     );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(protlist[i],0)));
	    ivadmin_free( protlist[i] );
	}
    }
    Inline_Stack_Done;
}

void protobj_attrget( SV* self, char* attr_key ) {
    ivadmin_protobj* prot = _getprot(self);
    unsigned long count = 0;
    unsigned long rc    = 0;
    unsigned long i;

    char **protval;

    if (prot == NULL)
	croak("protobj_attrget: could not retrience ivadmin_protobj");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_protobj_attrget( *prot,
    			       attr_key,
    			       &count,
			       &protval );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(protval[i],0)));
	    ivadmin_free( protval[i] );
	}
    }
    Inline_Stack_Done;
}

int protobj_attrput( SV* self, SV* resp,  char* attr_key,
		 char *attr_val ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char* protid = _getname(self);
    unsigned long rc = 0;

    if (protid == NULL)
	croak("protobj_attrput: could not retrieve name");

    rc = ivadmin_protobj_attrput( *ctx, protid, attr_key, attr_val, rsp );
    return(rc == IVADMIN_TRUE);
}

int protobj_attrdelval( SV* self, SV* resp, char* attr_key, 
		    char* attr_val ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char* protid = _getname(self);
    unsigned long rc = 0;

    if ( protid == NULL )
	croak("protobj_attrdelval: could not retrieve name");

    rc = ivadmin_protobj_attrdelval( *ctx, protid, attr_key, attr_val, rsp );
    return(rc == IVADMIN_TRUE);
}

int protobj_attrdelkey( SV* self, SV* resp,  char* attr_key ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char* protid = _getname(self);
    unsigned long rc = 0;

    if ( protid == NULL )
	croak("protobj_attrdelkey: could not retrieve name");
 
    rc = ivadmin_protobj_attrdelkey( *ctx, protid, attr_key, rsp );
    return(rc == IVADMIN_TRUE);
}

void _protobj_free(SV* self) {
    ivadmin_protobj* prot = _getprot(self);

    if (prot)
	Safefree(prot);
    hv_delete( (HV*)SvRV(self), "_prot", 5, 0 );
}

