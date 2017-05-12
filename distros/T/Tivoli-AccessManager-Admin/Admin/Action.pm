package Tivoli::AccessManager::Admin::Action;
use Carp;
use strict;
use warnings;
use Data::Dumper;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: Action.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

$Tivoli::AccessManager::Admin::Action::VERSION = '1.11';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
		NAME => 'Tivoli::AccessManager::Admin::Action',
	  );
use Tivoli::AccessManager::Admin::Response;

sub new {
    my $class = shift;
    my $cont = shift;

    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    if ( @_ % 2 ) {
	warn "Invalid syntax -- you did not send a hash\n";
	return undef;
    }
    my %opts = @_;

    my $self = bless {}, $class;
    $self->{actionid}    = $opts{actionid} || '';
    $self->{description} = $opts{description} || '';
    $self->{type}        = $opts{type} || '';
    $self->{context}     = $cont;

    return $self;
}

sub create {
    my $self = shift;
    my $rc;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    unless ( ref $self ) {
	my $pd = shift;
	unless ( UNIVERSAL::isa($pd, 'Tivoli::AccessManager::Admin::Context') ) {
	    $resp->set_message('syntax error - no context');
	    $resp->set_isok(0);
	    return $resp;
	}
	$self = $self->new( $pd, @_ );
    }

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    unless ( $self->{actionid} ) {
	$self->{actionid} = $opts{actionid} || '';
    }

    unless ( $self->{description} ) {
	$self->{description} = $opts{description} || '';
    }

    unless ( $self->{type} ) {
	$self->{type} = $opts{type} || '';
    }

    unless ( $self->{actionid} and $self->{description} and $self->{type} ) {
	$resp->set_isok(0);
	$resp->set_message("actionid, description and type must be defined" );
	return $resp;
    }

    if ( defined $opts{group} ) {
	$rc = $self->action_create_in_group($resp, $opts{group});
    }
    else {
	$rc = $self->action_create($resp);
    }

    $resp->isok and $resp->set_value( $self );
    return $resp;
}

sub delete {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $rc;

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    if ( defined $opts{group} ) {
	$rc = $self->action_delete_from_group($resp, $opts{group});
    }
    else {
	$rc = $self->action_delete($resp);
    }
    # Because we need to rely on the information held in the perl code's
    # cache, I want to make certain we zero it all out if the delete 
    # worked.  
    if ( $resp->isok ) {
	$self->{actionid} = undef;
	$self->{description} = undef;
	$self->{type} = undef;
    }
    return $resp;
}

sub group {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $pd;

    if ( ref $self ) {
	$pd = $self->{context};
    }
    else {
	$pd = shift;
	unless ( UNIVERSAL::isa($pd, 'Tivoli::AccessManager::Admin::Context' ) ) {
	    $resp->set_message( 'syntax error -- no context object' );
	    $resp->set_isok(0);
	    return $resp;
	}
    }

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;
    my %dispatch = ( create => \&action_group_create,
		     remove => \&action_group_delete
		 );
    my $rc;

    DISPATCH:
    for my $com ( qw/remove create/ ) {
	next unless defined $opts{$com}; 

	if ( ref $opts{$com} eq 'ARRAY' ) {
	    for my $grp ( @{$opts{$com}} ) {
		$rc = $dispatch{$com}->( $pd, $resp, $grp );
		last DISPATCH unless $resp->isok;
	    }
	}
	else {
	    $rc =$dispatch{$com}->( $pd, $resp, $opts{$com} );
	    last DISPATCH unless $resp->isok;
	}
    }

    if ( $resp->isok ) {
	my @list = action_group_list( $pd, $resp );
	$resp->isok and $resp->set_value(\@list);
    }

    return $resp;
}
    
sub list {
    my $self = shift;
    my ($pd,$class);
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    
    if ( ref $self ) {
	$pd = $self->{context};
	$class = ref $self;
    }
    else {
	$pd = shift;
	unless ( UNIVERSAL::isa($pd, 'Tivoli::AccessManager::Admin::Context' ) ) {
	    $resp->set_message( 'syntax error -- no context object' );
	    $resp->set_isok(0);
	    return $resp;
	}
	$class = $self;
    }

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;
    my (@rc,@objs);

    if ( defined $opts{group} ) {
	@rc = action_list_in_group( $pd, $resp, $opts{group} );
    }
    else {
	@rc = action_list( $pd, $resp );
    }

    if ( $resp->isok ) {
	for ( @rc ) {
	    bless $_, $class;
	    $_->{context}     = $pd;
	}
	$resp->set_value(\@rc);
    }
    return $resp;
}

sub description { return $_[0]->{description} }
sub id { return $_[0]->{actionid} }
sub type { return $_[0]->{type} }

1;

=head1 NAME

Tivoli::AccessManager::Admin::Action

=head1 SYNOPSIS

  use Tivoli::AccessManager::Admin;

  my $pd = Tivoli::AccessManager::Admin->new( password => 'N3ew0nk' );
  my ( @acts, $resp, @lists, @grps, @gnames );

  # Create an action via new and create
  $acts[0] = Tivoli::AccessManager::Admin::Action->new( $pd,
				  actionid    => 'Z',
				  description => 'Action Z!',
				  type        => 'This is action Z'
				);
  $resp = $acts[0]->create;

  # Or, create an action through create alone
  $resp = Tivoli::AccessManager::Admin::Action->create( $pd,
				      actionid    => 'X',
				      description => 'Action X!',
				      type        => 'This is action X'
				    );
  $acts[1] = $resp->value if $resp->isok;

  # Print the description, the type and the action id out
  for my $act ( @acts ) {
      print "Action ID  : " . $act->id . "\n";
      print "Description: " . $act->description . "\n";
      print "Type       : " . $act->type . "\n\n";
  }

  @gnames = qw/ateam dirty12 ratpack/;
  # Create some action groups.
  for my $name ( @gnames ) {
      $resp = Tivoli::AccessManager::Admin::Action->group( $pd, create => $name );
      push( @grps, $name ) if $resp->isok;
  }

  # Delete the groups
  for my $name ( @gnames ) {
      $resp = Tivoli::AccessManager::Admin::Action->group( $pd, delete => $name );
      push( @grps, $name ) if $resp->isok;
  }

  # Create them another way, just for fun
  $resp = Tivoli::AccessManager::Admin::Action->group( $pd, create => \@gnames );
  @grps = @gnames if $resp->isok;

  # Create a new actions in a group
  $resp = Tivoli::AccessManager::Admin::Action->create( $pd, 
				  actionid    => 'T',
				  description => 'Pity the fool',
				  type        => 'Mr T action',
				  group	      => 'ateam',
				);

  # Get the list of all the groups
  $resp = Tivoli::AccessManager::Admin::Action->group;

  # list the default actions 
  $resp = Tivoli::AccessManager::Admin::Action->list;
  for my $obj ( @{$resp->value} ) {
      printf "Found action %s -- %s\n",
	     $obj->id, $obj->description;
  }

  # list the actions in a group
  $resp = Tivoli::AccessManager::Admin::Action->list( group => 'ateam' );

=head1 DESCRIPTION

Tivoli::AccessManager::Admin::Action implements the interface to the action portion of the API.
I will warn you -- the underlying API is somewhat half baked.

=head1 CONSTRUCTORS

=head2 new( PDADMIN[, actionid =E<gt> ID, description =E<gt> DESC, type =E<gt> TYPE, group =E<gt> GROUP] )

Creates a blessed L<Tivoli::AccessManager::Admin::Action> object.  You will need to destroy this
object if you wish to change the context.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  This is the only required
parameter.

=item actionid =E<gt> ID

The action id to create.  This is currently limitted by the C API to one
character.

=item description =E<gt> DESC

A description of the action.

=item type =E<gt> TYPE

The action's type.  This is usually a one word description thst is displayed
by the WPM.

=item group =E<gt> GROUP

If provided, name the action group in which the action will be created.

=back

=head3 Returns

A blessed L<Tivoli::AccessManager::Admin::Action> object. 

=head2 create( PDADMIN, actionid =E<gt> ID, description =E<gt> DESC, type =E<gt> TYPE[, group =E<gt> GROUP] )

Instantiates a L<Tivoli::AccessManager::Admin::Context> object and creates the action in the
policy database if used as a class method.

=head3 Parameters

The parameters are identical to those for L</"new">.  Unlike L</"new">, they
are all required, except for the group name.

=head3 Returns

A blessed L<Tivoli::AccessManager::Admin::Action> object, buried in a L<Tivoli::AccessManager::Admin::Response>
object.

=head2 list(PDADMIN[, group =E<gt> GROUP] )

Lists all the defined actions.  The return is a list of L<Tivoli::AccessManager::Admin::Action>
objects, buried in a L<Tivoli::AccessManager::Admin::Response> object.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  This is the only required
arameter.

=item group =E<gt> GROUP

If provided, the return will be the list of actions within the named group.
It will otherwise search the default group.

=back

=head3 Returns

A list of blessed L<Tivoli::AccessManager::Admin::Action> objects.

=head1 CLASS METHODS

=head2 group(PDADMIN[, create =E<gt> name, remove =E<gt> name ] )

Lists, creates and/or deletes action groups.  If none of the optional
parameters are provided, L</"group"> will return a list of all the action
groups.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  This is the only required
parameter.

=item create =E<gt> name

The name of an action group to create.  This can also be a reference to an
array of group names.

=item remove =E<gt> name

The name of an action group to remove.  This can also be a reference to an
array of group names.  If create and remove are both specified, removes are
done first.

=back

=head3 Returns

Regardless of the operation performed, a list of action group names will be
returned.

=head1 METHODS

=head2 create( [actionid =E<gt> ID, description =E<gt> DESC, type =E<gt> TYPE, group =E<gt> GROUP] )

Yes, this can called as an instance method if you want.  Notice the different
signature -- the context object is no longer required.

=head3 Parameters

See L</"new">.  Any parameter yiu did not provide to L</"new"> must be
provided to L</"create">.

=head3 Returns

The results if the create operation

=head2 delete([group =E<gt> GROUP])

Deletes the action.

=head3 Parameters

=over 4

=item group =E<gt> GROUP

If provided, the action will be deleted from the named group.

=back

=head3 Returns

The results of the delete call.

=head2 id

Returns the action id.  This is a read-only method.

=head3 Parameters

None

=head3 Returns

The action id.

=head2 description

Returns the description.  This is a read-only method.

=head3 Parameters

None

=head3 Returns

The description.

=head2 type

Returns the type.  This is a read-only method.

=head3 Parameters

None

=head3 Returns

The type.

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin> for the list.  This was not possible without the help of a
bunch of people smarter than me.

=head1 BUGS

The underlying C API is very different from the other portions -- there is no
way to get an ivadmin_action struct w/o doing a list.  I have worked around
this in the perl code.  This is surely a bug.

There is no way to change the description or type w/o deleting the action and
recreating it.  

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

char* _fetch( SV* self, char* key ) {
    HV* self_hash = (HV*)SvRV(self);
    SV** fetched  = hv_fetch( self_hash, key, strlen(key), 0 );

    return(fetched ? SvPV_nolen( *fetched ) : NULL );
}

int action_create( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);

    const char* actionid = _fetch(self,"actionid");
    const char* description = _fetch(self,"description");
    const char* type = _fetch(self,"type");

    unsigned long rc = 0;

    if ( actionid == NULL )
	croak( "action_create: couldn't get the actionid" );
    
    if ( description == NULL )
	croak( "action_create: couldn't get the description" );
    
    if ( type == NULL ) 
	croak( "action_create: couldn't get the type" );

    rc = ivadmin_action_create( *ctx,
			        actionid,
				description,
				type,
				rsp );
    return(rc == IVADMIN_TRUE);
}

int action_create_in_group( SV* self, SV* resp, const char* group ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);

    const char* actionid    = _fetch( self, "actionid" );
    const char* description = _fetch( self, "description" );
    const char* type	= _fetch( self, "type" );       

    unsigned long rc = 0;

    if (actionid == NULL)
	croak( "action_create: couldn't get the actionid" );

    if (description == NULL)
	croak( "action_create: couldn't get the description" );

    if (type == NULL)
	croak( "action_create: couldn't get the type" );

    rc = ivadmin_action_create_in_group( 
				*ctx,
			        actionid,
				description,
				type,
				group,
				rsp );
    return(rc == IVADMIN_TRUE);
}

int action_delete( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    const char* actionid = _fetch(self,"actionid");

    unsigned long rc = 0;

    if (actionid == NULL)
	croak( "action_delete: couldn't get the actionid" );

    rc = ivadmin_action_delete( *ctx, actionid, rsp );
    return(rc == IVADMIN_TRUE);
}

int action_delete_from_group( SV* self, SV* resp, const char* group ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    const char* actionid = _fetch(self,"actionid");

    unsigned long rc = 0;

    if (actionid == NULL)
	croak( "action_delete_from_group: couldn't get the actionid" );

    rc = ivadmin_action_delete_from_group( *ctx, actionid, group, rsp );
    return(rc == IVADMIN_TRUE);
}

int action_group_create( SV* pd, SV* resp, const char* group ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse(resp);

    unsigned long rc = 0;

    rc = ivadmin_action_group_create( *ctx, group, rsp );
    return(rc == IVADMIN_TRUE);
}

int action_group_delete( SV* pd, SV* resp, const char* group ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse(resp);

    unsigned long rc = 0;

    rc = ivadmin_action_group_delete( *ctx, group, rsp );
    return(rc == IVADMIN_TRUE);
}


void action_group_list( SV* pd, SV* resp ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long count;
    unsigned long rc;
    int i;
    char **names;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_action_group_list( *ctx,
    			   &count,
			   &names,
			   rsp );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(names[i],0)));
	    ivadmin_free( names[i] );
	}
    }
    Inline_Stack_Done;
}

void action_list( SV* pd, SV* resp ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long count;
    unsigned long rc;
    int i;
    ivadmin_action *actions;

    HV* hash;


    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_action_list( *ctx,
    			   &count,
			   &actions,
			   rsp );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    /* Create the proto-object */
	    hash = newHV();
	    hv_store( hash, "actionid", 8, 
		      newSVpv( ivadmin_action_getid( actions[i] ), 0 ),
		      0 );

	    hv_store( hash, "description", 11, 
		      newSVpv( ivadmin_action_getdescription( actions[i] ), 0 ),
		      0 );

	    hv_store( hash, "type", 4, 
		      newSVpv( ivadmin_action_gettype( actions[i] ), 0 ),
		      0 );

	    Inline_Stack_Push(sv_2mortal(newRV_noinc((SV*)hash)));
	    ivadmin_free(actions[i]);
	}
    }
    Inline_Stack_Done;
}

void action_list_in_group( SV* pd, SV* resp, char* group ) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long count;
    unsigned long rc;
    int i;
    ivadmin_action *actions;

    HV* hash;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_action_list_in_group( *ctx,
			   group,
    			   &count,
			   &actions,
			   rsp );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    hash = newHV();
	    hv_store( hash, "actionid", 8, 
		      newSVpv( ivadmin_action_getid( actions[i] ), 0 ),
		      0 );

	    hv_store( hash, "description", 11, 
		      newSVpv( ivadmin_action_getdescription( actions[i] ), 0 ),
		      0 );

	    hv_store( hash, "type", 4, 
		      newSVpv( ivadmin_action_gettype( actions[i] ), 0 ),
		      0 );

	    Inline_Stack_Push(sv_2mortal(newRV_noinc((SV*)hash)));
	    ivadmin_free(actions[i]);
	}
    }
    Inline_Stack_Done;
}

