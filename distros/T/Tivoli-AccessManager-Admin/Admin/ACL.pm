package Tivoli::AccessManager::Admin::ACL;
use strict;
use warnings;
use Carp;

use Tivoli::AccessManager::Admin::Response;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: ACL.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::ACL::VERSION = '1.11';
use Inline( C => 'DATA',
		 INC  => '-I/opt/PolicyDirector/include',
                 LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		 CCFLAGS => '-Wall',
		 VERSION => '1.11',
		 NAME => 'Tivoli::AccessManager::Admin::ACL');

sub new {
    my $class = shift;
    my $cont = shift;
    my $self = {};
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $name = '';

    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    bless $self, $class;

    if ( @_ == 1 ) {
	$name = shift;
    }
    elsif ( @_ % 2 ) {
	warn "Incorrent syntax -- too many parameters\n";
	return undef;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$name = $opts{name} || '';
    }

    $self->{name} = $name;
    $self->{context} = $cont;

    if ( $name ) {
	$self->{exist} = $self->acl_get( $resp );
    }
    else {
	$self->{exist} = 0;
    }

    return $self;
}

sub list {
    my $class = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $pd;

    if ( ref($class) ) {
	$pd = $class->{context};
    }
    else {
	$pd = shift;
    }

    my @acls = acl_list($pd,$resp);
    $resp->isok and $resp->set_value(\@acls);

    return $resp;
}

sub find {
    my $self = shift;
    my $pd = $self->{context};

    return Tivoli::AccessManager::Admin::ProtObject->find( $pd, acl => $self->name );
}

sub listgroups {
    my $self = shift;
    my ($acl, @groups);

    my $resp = Tivoli::AccessManager::Admin::Response->new();

    unless ( $self->exist ) {
	$resp->set_message($self->name . " does not exist");
	$resp->set_isok(0);
	return $resp;
    }

    @groups = $self->acl_listgroups();
    if ( @groups ) {
	$resp->set_value( $groups[0],\@groups );
    }
    else {
	$resp->set_value( 'none' );
    }
    return $resp;
}

sub listusers {
    my $self = shift;
    my ($acl, @users);

    my $resp = Tivoli::AccessManager::Admin::Response->new();

    unless ( $self->exist ) {
	$resp->set_message($self->name . " does not exist");
	$resp->set_isok(0);
	return $resp;
    }

    @users = $self->acl_listusers();
    if ( @users ) {
	$resp->set_value( $users[0], \@users );
    }
    else {
	$resp->set_value( 'none' );
    }
    return $resp;
}

sub create {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    unless ( ref( $self ) ) {
	my $pd = shift;
	unless (defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context')){
	    $resp->set_message("Invalid Tivoli::AccessManager::Admin::Context object");
	    $resp->set_isok(0);
	    return $resp;
	}
	$self = $self->new( $pd, @_ );
    }

    if ( $self->{exist} ) {
	$resp->set_message( $self->name . " already exists" );
	$resp->set_iswarning( 1 );
	$resp->set_value( $self );
	return $resp;
    }

    my $rc = $self->acl_create( $resp );
    $self->{exist} = $resp->isok;

    $resp->set_value( $self );

    return $resp;
}

sub delete {
    my $self = shift;

    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $rc = $self->acl_delete( $resp );

    unless ( $self->exist ) {
	$resp->set_message($self->name . " does not exist");
	$resp->set_iswarning(1);
	return $resp;
    }

    $self->{exist} = 0 if $rc;
    $resp->set_value( $rc );
    return $resp;
}

sub description {
    my $self = shift;
    my $desc = '';
    my ($rc,$acl);

    my $resp = Tivoli::AccessManager::Admin::Response->new();

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
	$desc = $opts{description} || '';
    }

    # Set description
    if ( $desc ) {
	$rc = $self->acl_setdescription($resp,$desc);
	$self->acl_get($resp);
    }

    if ( $resp->isok ) {
	$desc = $self->acl_getdescription();
	$resp->set_value( $desc || 'none' );
    }
    return $resp;
}

sub _mod_perms {
    my $self = shift;
    my ($rc,$string,$acl,%opts,$name);

    my %dispatch = ( unauth   => { remove  => \&acl_removeunauth,
				   get	   => \&acl_getunauth,
				   set     => \&acl_setunauth },
		     anyother => { remove  => \&acl_removeanyother,
				   get	   => \&acl_getanyother,
			           set     => \&acl_setanyother },
		     group    => { remove  => \&acl_removegroup,
				   get	   => \&acl_getgroup,
				   set     => \&acl_setgroup },
		     user     => { remove  => \&acl_removeuser,
				   get	   => \&acl_getuser,
			           set     => \&acl_setuser }
		    );


    my $resp = Tivoli::AccessManager::Admin::Response->new();

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }

    unless ( $self->exist ) {
	$resp->set_message( $self->name . " doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    %opts = @_;

    if ( ($opts{action} eq 'user' or $opts{action} eq 'group') and not defined($opts{name}) ) {
	$resp->set_message( "Syntax error.  You must define the $opts{action} name");
	$resp->set_isok(0);
	return $resp;
    }

    if ( defined($opts{perms}) ) {
	if ( $opts{perms} eq 'remove' ) {
	    $rc = $dispatch{$opts{action}}{remove}->($self,$resp,$opts{name});
	}
	else {
	    $rc = $dispatch{$opts{action}}{set}->($self,$resp,$opts{perms},$opts{name});
	}
    }

    if ( $resp->isok ) {
	$self->acl_get($resp);
	$string = $dispatch{$opts{action}}{get}->($self,$opts{name});
	$resp->set_value( $string || '');
    }
    return $resp;
}

sub unauth { _mod_perms(@_, action => 'unauth', name => ''); }
sub anyother { _mod_perms(@_, action => 'anyother', name => ''); }
sub group { _mod_perms(@_, action => 'group') }
sub user { _mod_perms(@_, action => 'user') }

sub _addval {
    my $self = shift;
    my $vals = shift;

    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $rc;

    for my $key ( keys %{$vals} ) {
	# Loop if given an array.  Don't otherwise.
	if ( ref($vals->{$key} ) ) {
	    for my $val ( @{$vals->{$key}} ) {
		$rc = $self->acl_attrput( $resp, $key, $val );
		return $resp unless $resp->isok;
	    }
	}
	else {
	    $rc = $self->acl_attrput( $resp, $key, $vals->{$key} );
	}
	return $resp unless $resp->isok;
    }
    return $resp;
}

sub _remvalue {
    my $self = shift;
    my $vals = shift;

    my $resp = Tivoli::AccessManager::Admin::Response->new();

    my $rc;
    
    for my $key ( keys %{$vals} ) {
	# Loop if given an array.  Don't otherwise.
	if ( ref($vals->{$key}) ) {
	    for my $val ( @{$vals->{$key}} ) {
		$rc = $self->acl_attrdelval( $resp, $key, $val );
		return $resp unless $resp->isok;
	    }
	}
	else {
	    $rc = $self->acl_attrdelval( $resp, $key, $vals->{$key} );
	}
	return $resp unless $resp->isok;
    }
    return $resp;
}

sub _remkey {
    my $self = shift;
    my $keys = shift;

    my $resp = Tivoli::AccessManager::Admin::Response->new();

    my $rc;
    for ( @{$keys} ) {
	$rc = $self->acl_attrdelkey( $resp, $_ );
	return $resp unless $resp->isok;
    }
    return $resp;
}

sub attributes {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $rhash = {};

    my %dpatch = ( remove    => \&_remvalue,
		   removekey => \&_remkey,
		   add       => \&_addval
	       );

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    unless ( $self->exist ) {
	$resp->set_message( $self->name . " doesn't exist");
	$resp->set_isok(0);
	return $resp;
    }

    for my $op ( qw/remove removekey add/ ) {
	if ( defined( $opts{$op} ) ) {
	    $resp = $dpatch{$op}->($self, $opts{$op});
	    return $resp unless $resp->isok;
	    $self->acl_get($resp);
	}
    }

    # The "return" in the loop means I will never get here unless either the
    # loop succeeded, or no parameters where sent.
    for my $key ( $self->acl_attrlist ) {
	$rhash->{$key} = [ $self->acl_attrget($key) ];
    }
    $resp->set_value( $rhash );

    return $resp;
}

sub DESTROY {
    my $self = shift;

    $self->_aclfree;
}

sub exist { $_[0]->{exist} }
sub name  { $_[0]->{name} }

1;

=head1 NAME

Tivoli::AccessManager::Admin::ACL

=head1 SYNOPSIS

    use Tivoli::AccessManager::Admin;

    my $tam  = Tivoli::AccessManager::Admin->new( password => 'foobar' );
    my ($resp,$rc);

    # See what ACLs exist
    $resp = Tivoli::AccessManager::Admin::ACL->list($tam);
    print join("\n", $resp->value);

    # Create a new ACL
    my $acl = Tivoli::AccessManager::Admin::ACL->new( $tam );
    $resp = $acl->create('bob') unless $acl->exist;

    my $name = $acl->name;

    # Give the group 'jon' permissions in this ACL
    $resp = $acl->group(name => 'jons', perms => 'Trx' );

    print "The group 'jons' is granted these privileges by acl '$name':\n";
    print $resp->value,"\n";

    # Give the user "dave" the same access privs
    $resp = $acl->user(name => 'dave', perms => 'Trx' );

    # Dave was a mistake, lets remove him
    $resp = $acl->user(name => 'dave', perms => 'remove' );

    # Deny all access to anyother and unauth
    $resp = $acl->anyother( perms => "" );
    $resp = $acl->unauth( perms => '' );

    # list the users specified in the ACL
    $resp = $acl->listusers();

    # list the groups specified in the ACL
    $resp = $acl->listgroups();

    # Play with the attributes

    # well, that was fun.  What's say we clean up?
    $resp = $acl->delete();

    # Gain access to a system default ACL
    $acl = Tivoli::AccessManager::Admin::ACL->new($tam, 'default-webseal');

    # And find out where it is attached
    $resp = $acl->find;

=head1 DESCRIPTION

L<Tivoli::AccessManager::Admin::ACL|Tivoli::AccessManager::Admin::ACL> provides the interface to the ACL portion of the TAM
Admin API.  

=head1 CONSTRUCTOR

=head2 new( PDADMIN, NAME )

Creates a blessed B<Tivoli::AccessManager::Admin::ACL> object and returns it.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context|Tivoli::AccessManager::Admin::Context> object.  Please note that, after the
L<Tivoli::AccessManager::Admin::ACL|Tivoli::AccessManager::Admin::ACL> object is created, you cannot change the context w/o
destroying the object and recreating it.

=item NAME

The name of the ACL to which the object refers.

=back

=head3 Returns

A fully blessed L<Tivoli::AccessManager::Admin::ACL|Tivoli::AccessManager::Admin::ACL> object.

=head2 create(PDADMIN,NAME)

Creates a new ACL.  This is different than L<"/new"> in that the ACL will be
created in the policy database as well.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context|Tivoli::AccessManager::Admin::Context> object.  Please note that, after the
L<Tivoli::AccessManager::Admin::ACL|Tivoli::AccessManager::Admin::ACL> object is created, you cannot change the context w/o
destroying the object and recreating it.

=item NAME

The name of the ACL to create.  This parameter is optional, if you instatiated
the object with a name.  Otherwise, it will croak in a most unappealing
fashion.

=back

=head3 Returns

If the operational was successful, you will get the new
L<Tivoli::AccessManager::Admin::ACL|Tivoli::AccessManager::Admin::ACL> object.  If it wasn't successful, you will
get an error message why.  If the object already exists, you will get a
warning and the L<Tivoli::AccessManager::Admin::ACL|Tivoli::AccessManager::Admin::ACL> object.  And all of this
will be embedded in a L<Tivoli::AccessManager::Admin::Response|Tivoli::AccessManager::Admin::Response> object.

=head1 CLASS METHODS

Class methods behave like instance methods -- they return
L<Tivoli::AccessManager::Admin::Response|Tivoli::AccessManager::Admin::Response> objects.

=head2 list(PDADMIN)

Lists all ACLs.

=head3 Parameters

=over 4

=item PDADMIN

A fully blessed L<Tivoli::AccessManager::Admin::Context|Tivoli::AccessManager::Admin::Context> object.  

=back

=head3 Returns

The resulting list of ACLs.

=head1 METHODS

All of the methods return a L<Tam::Admin::Response|Tivoli::AccessManager::Admin::Response> object.  See the
documentation for that module on how to coax the values out.

The methods, for the most part, follow the same pattern.  If the optional
parameters are sent, it has the effect of setting the attributes.  All methods
calls will embed the results of a 'get' in the L<Tivoli::AccessManager::Admin::Response|Tivoli::AccessManager::Admin::Response> object.

=head2 list

Lists all of the ACLs.  

=head3 Parameters

none

=head3 Returns

A list of all the defined ACLs.

=head2 listgroups

Lists all the groups defined in the ACL.

=head3 Parameters

None

=head3 Returns

A list of the groups defined in the ACL.

=head2 listusers

Lists all the users defined in the ACL.

=head3 Parameters

None

=head3 Returns

A list of the users defined in the ACL.

=head2 create([NAME])

L<"/create"> can also be used as an instance method.

=head3 Parameters

=over 4

=item NAME

The name of the ACL to create.  This parameter is optional, if you instatiated
the object with a name.  Otherwise, it will croak in a most unappealing
fashion.

=back

=head3 Returns

True if the create succeeded, false it failed and a warning if the ACL already
existed.

=head2 description([STRING])

Sets the description on the ACL

=head3 Parameters

=over 4

=item STRING

The description to be set.  This is an optional parameter

=back

=head3 Returns

The current (possible empty) description.

=head2 find

Finds where in the object space the ACL has been attached.  This is really
just a wrapper for L<Tivoli::AccessManager::Admin::ProtObject|Tivoli::AccessManager::Admin::ProtObject>.  I like
an ACL object being able to tell you where it is.

=head3 Parameters

None

=head3 Returns
 
A possibly empty list of places the ACL is attached.

=head2 delete

Deletes the ACL.  

=head3 Parameters

None

=head3 Returns

True if the operation succeeded, and error and message otherwise.

=head2 anyother([perms =E<gt> STRING])

Sets or gets the permissions for any-other in the ACL.  The ACL must exist
before calling this method.

=head3 Parameters

=over 4

=item perms =E<gt> STRING

If this parameter is set, L<"anyother"> will attempt to set the permissions for
any-other to this value.  

If the value of this parameter is 'remove', L<"anyother"> will be removed from
the ACL.  

=back

=head3 Returns

The permissions currently allowed by the ACL for any-other.

=head2 unauth([perms =E<gt> STRING])

Sets or gets the permissions for unauth in the ACL.  The ACL must exist before
calling this method.

=head3 Parameters

=over 4

=item perms =E<gt> STRING

If this parameter is set, L</"unauth"> will attempt to set the permissions for
unauth to this value.  

If the value of this parameter is 'remove', L</"unauth"> will be removed from
the ACL.  

=back

=head3 Returns

A list of all of the actions currently allowed by the ACL for unauthenticated users.

=head2 group( name =E<gt> 'group'[, perms =E<gt> STRING )

Sets or gets the permissions for the named group in the ACL.  The ACL must
exist before calling this method.

=head3 Parameters

=over 4

=item name =E<gt> group

The name of the group to which the permissions apply.  This parameter is
mandatory.

=item perms =E<gt> STRING

If this parameter is set, L</"group"> will attempt to set the permissions for
the group to this value.  

If the value of this parameter is 'remove', the named group will be removed
from the ACL.  

=back

=head3 Returns

A list of all of the actions currently allowed by the ACL for the group.

=head2 user( name =E<gt> userid[, perms =E<gt> STRING )

Sets or gets the permissions for the named user in the ACL.  The ACL must
exist before calling this method.

=head3 Parameters

=over 4

=item name =E<gt> userid

The user id to which the permissions apply.  This parameter is mandatory.

=item perms =E<gt> STRING

If this parameter is set, L</"user"> will attempt to set the permissions for
the user to this value.  

If the value of this parameter is 'remove', The user will be removed from
the ACL.  

=back

=head3 Returns

A list of all of the permission currently allowed by the ACL for the user.

=head2 attributes([add =E<gt> { key => [qw/value0 value1/] | 'value0' }, 
				remove =E<gt> { key => [qw/value0 value1/] | 'value0' },
				removekey =E<gt> [qw/key0 key1] ] )

Adds key/value attributes to an ACL, removes the values and removes the
entire key/value pairs.  I find these to be the more ... annoying functions.

=head3 Parameters

=over 4

=item add =E<gt> { key =E<gt> [qw/ value0 value1/] | 'value0' }

Causes L</"attribute"> to add any number of key/value pairs to the ACL.  As
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

Removes both the attribute and any associated values from the ACL.

=back

=head3 Returns

A hash of lists.  The hash is keyed off of the attribute names.  The values
for each attribute are returned as a list -- even if there is only one value.  

=head2 exist

Lets you know if the ACL exists in the TAM database or not.

=head3 Parameters

None

=head3 Returns

0 if the ACL does not exist, 1 if it does.

=head2 name

Returns the name of the ACL

=head3 Parameters

None

=head3 Returns

Uhh.  The name of the ACL.

=head1 ACKNOWLEDGEMENTS

Please read L<Tivoli::AccessManager::Admin|Tivoli::AccessManager::Admin> for the full list of acks.  I stand upon the
shoulders of giants.

=head1 BUGS

The documentation is now horribly gobsmacked.  

The previous comment is really unhelpful.

The permissions needs to be extended to handle things like [PDWebPI].  It
would be better to extend them to be dynamically extendable.

=head1 AUTHOR

Mik Firestone E<lt>mikfire@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2011 Mik Firestone.  All rights reserved.  This program is
free software; you can redistibute it and/or modify it under the same terms as
Perl itself.

All references to TAM, Tivoli Access Manager, etc are copyrighted, trademarked
and otherwise patented by IBM.

=cut 

__DATA__

__C__

#include "ivadminapi.h"

ivadmin_response* _getresponse( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"response",8,0);
    ivadmin_response* rsp;

    if ( fetched == NULL )
	croak("Couldn't fetch the _response in $self");

    rsp = (ivadmin_response*) SvIV(*fetched);

    fetched = hv_fetch( self_hash, "used",4,0);
    if ( fetched ) {
	sv_setiv( *fetched, 1 );
    }
    return( rsp );
}

static ivadmin_context* _getcontext( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"context", 7, 0 );

    if ( fetched == NULL )
	croak("Couldn't get context");

    return( (ivadmin_context*)SvIV(SvRV(*fetched)) );
}

static char* _getname( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "name", 4, 0 );

    return( fetched ? SvPV_nolen(*fetched) : NULL );
}

void _aclstash( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash, "_acl",4,1);
    ivadmin_acl* acl;

    Newz( 5, acl, 1, ivadmin_acl );
    if ( fetched == NULL )
	croak ( "Couldn't create the _acl slot");

    sv_setiv(*fetched, (IV) acl );
    SvREADONLY_on(*fetched);
}

static ivadmin_acl* _getacl( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "_acl", 4, 0 );

    return( fetched ? (ivadmin_acl*) SvIV(*fetched) : NULL );
}

void acl_list( SV* pd, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long count;
    unsigned long rc;
    int i;
    char **aclids;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_acl_list( *ctx,
    			   &count,
			   &aclids,
			   rsp );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(aclids[i],0)));
	    ivadmin_free( aclids[i] );
	}
    }
    Inline_Stack_Done;
}

void acl_listgroups( SV* self ) {
    ivadmin_acl* acl = _getacl(self);

    unsigned long count;
    unsigned long rc;
    int i;
    char **groups;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( acl == NULL )
	croak("acl_listgroups: Couldn't retrieve the ivadmin_acl object");

    rc = ivadmin_acl_listgroups( *acl,
			         &count,
			         &groups
			       );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(groups[i],0)));
	    ivadmin_free(groups[i]);
	}
    }
    Inline_Stack_Done;
}

void acl_listusers( SV* self ) {
    ivadmin_acl* acl = _getacl(self);

    unsigned long count;
    unsigned long rc;
    int i;
    char **users;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( acl == NULL )
	croak("acl_listusers: Couldn't retrieve the ivadmin_acl object");

    rc = ivadmin_acl_listusers( *acl,
			        &count,
			        &users
			       );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(users[i],0)));
	    ivadmin_free( users[i] );
	}
    }
    Inline_Stack_Done;
}

int acl_get( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    ivadmin_acl *acl      = _getacl(self);
    char *aclid           = _getname(self);

    unsigned long rc;

    if ( acl == NULL ) {
	_aclstash(self);
	acl = _getacl(self);
    }

    if ( aclid == NULL )
	croak("acl_get: could not retrieve name");

    if ( acl == NULL )
	croak("acl_get: Couldn't retrieve the ivadmin_acl object");

    rc = ivadmin_acl_get( *ctx,
    			  aclid,
			  acl,
			  rsp );
    return(rc == IVADMIN_TRUE);
}

/* the unused variable is there so I can use one call to set/get the
* permissions for groups, users, any-other and unauth with one dispatch method
* */
SV* acl_getanyother( SV* self,const char* unused ) {
    ivadmin_acl* acl = _getacl(self);
    const char *action;

    if ( acl == NULL )
	croak("acl_getanyother: Couldn't retrieve the ivadmin_acl object");

    action = ivadmin_acl_getanyother(*acl);
    return(action ? newSVpv(action,0) : NULL);
}

SV* acl_getdescription( SV* self ) {
    ivadmin_acl* acl = _getacl(self);
    const char *action;

    if ( acl == NULL )
	croak("acl_getdescription: Couldn't retrieve the ivadmin_acl object");

    action = ivadmin_acl_getdescription(*acl);
    return(action ? newSVpv(action,0) : NULL);
}

SV* acl_getgroup( SV* self, const char* groupid ) {
    ivadmin_acl* acl = _getacl(self);
    const char *action;

    if ( acl == NULL )
	croak("acl_getgroup: Couldn't retrieve the ivadmin_acl object");

    action = ivadmin_acl_getgroup(*acl,groupid);
    return(action ? newSVpv(action,0) : NULL);
}

SV* acl_getunauth( SV* self,const char* unused ) {
    ivadmin_acl* acl = _getacl(self);
    const char *action;

    if ( acl == NULL )
	croak("acl_getunauth: Couldn't retrieve the ivadmin_acl object");

    action = ivadmin_acl_getunauth(*acl);
    return(action ? newSVpv(action,0) : NULL);
}

SV* acl_getuser( SV* self, const char* userid ) {
    ivadmin_acl* acl = _getacl(self);
    const char *action;

    if ( acl == NULL )
	croak("acl_getuser: Couldn't retrieve the ivadmin_acl object");

    action = ivadmin_acl_getuser(*acl,userid);
    return(action ? newSVpv(action,0) : NULL);
}

int acl_setanyother( SV* self, SV* resp, const char* actions, const char* unused ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char *aclid = _getname(self);

    unsigned long rc;

    if ( aclid == NULL )
	croak("acl_setanyother: could not retrieve name");

    rc = ivadmin_acl_setanyother( *ctx, aclid, actions, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_setdescription( SV* self, SV* resp, const char* description ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char *aclid = _getname(self);

    unsigned long rc;

    if ( aclid == NULL )
	croak("acl_setdescription: could not retrieve name");

    rc = ivadmin_acl_setdescription( *ctx, aclid, description, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_setgroup( SV* self, SV* resp, const char* actions, const char* groupid ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char* aclid = _getname(self);

    unsigned int rc;

    if ( aclid == NULL )
	croak("acl_setgroup: could not retrieve name");

    rc = ivadmin_acl_setgroup( *ctx, aclid, groupid, actions, rsp );
    return (rc == IVADMIN_TRUE);
}

int acl_setunauth( SV* self, SV* resp, const char* actions, const char* unused ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char* aclid  = _getname(self);

    unsigned int rc;

    if ( aclid == NULL )
	croak("acl_setunauth: could not retrieve name");

    rc = ivadmin_acl_setunauth( *ctx, aclid, actions, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_setuser( SV* self, SV* resp, const char* actions, const char* userid  ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char* aclid = _getname(self);

    unsigned int rc;

    if ( aclid == NULL )
	croak("acl_setuser: could not retrieve name");

    rc = ivadmin_acl_setuser( *ctx, aclid, userid, actions, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_removeanyother( SV* self, SV* resp, const char* unused ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char* aclid  = _getname(self);

    unsigned int rc;

    if ( aclid == NULL )
	croak("acl_removeanyother: could not retrieve name");

    rc = ivadmin_acl_removeanyother( *ctx, aclid, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_removegroup( SV* self, SV* resp, const char* groupid ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char* aclid = _getname(self);

    unsigned int rc;

    if ( aclid == NULL )
	croak("acl_removegroup: could not retrieve name");

    rc = ivadmin_acl_removegroup( *ctx, aclid, groupid, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_removeunauth( SV* self, SV* resp, const char* unused ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char* aclid = _getname(self);

    unsigned int rc;

    if ( aclid == NULL )
	croak("acl_removeunauth: could not retrieve name");

    rc = ivadmin_acl_removeunauth( *ctx, aclid, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_removeuser( SV* self, SV* resp, const char* userid ) {
    ivadmin_context* ctx  = _getcontext( self );
    ivadmin_response* rsp = _getresponse( resp );
    char* aclid = _getname(self);

    unsigned int rc;

    if ( aclid == NULL )
	croak("acl_removeuser: could not retrieve name");

    rc = ivadmin_acl_removeuser( *ctx, aclid, userid, rsp );
    return(rc == IVADMIN_TRUE);
}

void acl_attrlist( SV* self ) {
    ivadmin_acl* acl = _getacl(self);
    unsigned long count = 0;
    unsigned long rc    = 0;
    unsigned long i;

    char **attrlist;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( acl == NULL )
	croak("acl_attrlist: Couldn't retrieve the ivadmin_acl object");

    rc = ivadmin_acl_attrlist( *acl,
    			       &count,
			       &attrlist
			     );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(attrlist[i],0)));
	    ivadmin_free( attrlist[i] );
	}
    }
    Inline_Stack_Done;
}

void acl_attrget( SV* self, char* attr_key ) {
    ivadmin_acl* acl = _getacl(self);
    unsigned long count = 0;
    unsigned long rc    = 0;
    unsigned long i;

    char **attrval;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if ( acl == NULL )
	croak("acl_attrget: Couldn't retrieve the ivadmin_acl object");

    rc = ivadmin_acl_attrget( *acl,
    			       attr_key,
    			       &count,
			       &attrval );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(attrval[i],0)));
	    ivadmin_free( attrval[i] );
	}
    }
    Inline_Stack_Done;
}

int acl_attrput( SV* self, SV* resp,  char* attr_key, char *attr_val ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char* aclid = _getname(self);
    unsigned long rc = 0;

    if ( aclid == NULL )
	croak("acl_attrput: could not retrieve name");

    rc = ivadmin_acl_attrput( *ctx, aclid, attr_key, attr_val, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_attrdelval( SV* self, SV* resp, char* attr_key, char* attr_val ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char* aclid = _getname(self);
    unsigned long rc = 0;

    if ( aclid == NULL )
	croak("acl_attrdelval: could not retrieve name");

    rc = ivadmin_acl_attrdelval( *ctx, aclid, attr_key, attr_val, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_attrdelkey( SV* self, SV* resp,  char* attr_key ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char* aclid = _getname(self);
    unsigned long rc = 0;

    if ( aclid == NULL )
	croak("acl_attrdelkey: could not retrieve name");

    rc = ivadmin_acl_attrdelkey( *ctx, aclid, attr_key, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_create( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char *aclid  = _getname(self);
    unsigned long rc = 0;

    if ( aclid == NULL )
	croak("acl_create: could not retrieve name");

    rc = ivadmin_acl_create( *ctx, aclid, rsp );
    return(rc == IVADMIN_TRUE);
}

int acl_delete( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char *aclid  = _getname(self);
    unsigned long rc = 0;

    if ( aclid == NULL )
	croak("acl_delete: could not retrieve name");

    rc = ivadmin_acl_delete( *ctx, aclid, rsp );
    return(rc == IVADMIN_TRUE);
}

void _aclfree ( SV* self ) {
    ivadmin_acl* acl = _getacl(self);

    if ( acl != NULL )
	Safefree( acl );

    hv_delete((HV*)SvRV(self), "_acl", 4, 0 );
}

