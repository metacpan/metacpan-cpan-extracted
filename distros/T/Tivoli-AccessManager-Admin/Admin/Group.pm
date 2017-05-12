package Tivoli::AccessManager::Admin::Group;
use strict;
use warnings;
use Carp;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: Group.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::Group::VERSION = '1.11';
use Inline( C => 'DATA',
	        INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
	        NAME   => 'Tivoli::AccessManager::Admin::Group',
		);
use Tivoli::AccessManager::Admin::Response;

sub new {
    my $class = shift;
    my $cont  = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    unless (defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context')) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    if (@_ % 2) {
	warn "Invalid syntax -- you did not send a hash\n";
	return undef;
    }
    my %opts  = @_;

    my $self  = bless {}, $class;

    $self->{name}    = $opts{name} || '';
    $self->{cn}      = $opts{cn}   || '';
    $self->{dn}      = $opts{dn}   || '';
    $self->{exist}   = 0;
    $self->_groupstore();
    $self->{context} = $cont;

    if ($self->{dn}) {
	my $rc = $self->group_getbydn($resp);

	# The group already exists
	if ($resp->isok()) {
	    $self->{dn} = $self->group_getdn();
	    $self->{cn}   = $self->group_getcn();
	    $self->{name} = $self->group_getname();
	    $self->{exist} = $self->group_get($resp);
	}
    }

    if ($self->{name} and not $self->{exist}) {
	my $rc = $self->group_get($resp);
	if ($resp->isok) {
	    $self->{dn} = $self->group_getdn();
	    $self->{cn} = $self->group_getcn();
	    $self->{exist} = 1;
	}
    }

    return $self;
}

sub create {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $rc;

    unless (ref $self) {
	my $pd = shift;
	$self = new($self, $pd, @_);
    }

    if (@_ % 2) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    if ($self->{exist}) {
	$resp->set_message("The group $self->{name} already exists");
	$resp->set_iswarning(1);
	$resp->set_value($self);

	return $resp;
    }

    $self->{name}  = $opts{name} || $self->{name} || '';
    $self->{dn}    = $opts{dn}   || $self->{dn}   || '';
    $self->{cn}    = $opts{cn}   || $self->{cn}   || '';

    $self->{cn} = $self->{name} unless $opts{cn};

    if ($self->{cn} and $self->{dn} and $self->{name}) {
	$rc = $self->group_create($resp, $opts{container} || "");
	if ($resp->isok) {
	    $self->{exist} = 1;
	    $resp->set_value($self);
	}
    }
    else {
	$resp->set_message("Syntax error in creating group -- the cn, dn and name must be defined");
	$resp->set_isok(0);
	$resp->set_value('undef');
    }

    return $resp;
}

sub delete {
    my $self = shift;

    my $resp = Tivoli::AccessManager::Admin::Response->new();

    if ($self->{exist}) {
	my $rc;
	my $reg  = 0;

	if (@_ == 1) {
	    $reg = shift;
	}
	elsif (@_ % 2) {
	    $resp->set_message("Invalid syntax");
	    $resp->set_isok(0);
	    return $resp;
	}
	elsif (@_) {
	    my %opts = @_;
	    $reg = $opts{registry} || 0;
	}

	$rc = $self->group_delete($resp,$reg);
	if ($resp->isok) {
	    $resp->set_value($rc);
	    $self->_groupfree;
	    $self->{exist} = 0;
	}
    }
    else {
	$resp->set_message("The specified group does not exist");
	$resp->set_isok(0);
    }

    return $resp;
}

sub description {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
   
    if ($self->{exist}) {
	my $desc  = '';

	if (@_ == 1) {
	    $desc = shift;
	}
	elsif (@_ % 2) {
	    $resp->set_message("Invalid syntax");
	    $resp->set_isok(0);
	    return $resp;
	}
	elsif (@_) {
	    my %opts = @_;
	    $desc = $opts{description} || '';
	}

	if ($desc) {
	    my $rc = $self->group_setdescription($resp, $desc);
	    $resp->isok && $self->group_get($resp);
	}
	if ($resp->isok) {
	    $resp->set_value($self->group_getdescription || '');
	}
    }
    else {
	$resp->set_message("The group does not yet exist");
	$resp->set_isok(0);
    }

    return $resp;
}

sub cn { 
    my $self = shift;
    
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    if ($self->{cn}) {
	$resp->set_value($self->{cn});
    }
    else {
	$resp->set_message("The cn for this group is not defined");
	$resp->set_isok(0);
    }
    return $resp;
}

sub dn { 
    my $self = shift;
    
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    if ($self->{dn}) {
	$resp->set_value($self->{dn});
    }
    else {
	$resp->set_message("The dn for this group is not defined");
	$resp->set_isok(0);
    }
    return $resp;
}

sub _addmembers {
    my $self = shift;
    my %opts = @_;

    my (%hash, @junc,@add);

    my $resp = Tivoli::AccessManager::Admin::Response->new();
    # This is suckage.  I need to make sure there are no duplicates in the add
    # list.
    %hash = map { $_ => 1 } @{$opts{add}};
    @add = keys %hash;

    # We need to translate the existing users into a hash for the next step.
    # This also forces the names to lower case.
    %hash = map { my $f = lc $_; $f => 1 } @{$opts{existing}};

    # Finally.  Create a list of all the users in the add list that are not in
    # the existing list.
    @junc = grep { not $hash{lc($_)} } @add;

    # In theory, the two lists (those we are adding and those who are not in
    # the list) should be the same.  
    if (@junc != @add and $opts{force}) {
	@add = @junc;
	unless (@add) {
	    $resp->set_message("All of the users are already members in $self->{name}");
	    $resp->set_iswarning(1);
	    return $resp;
	}
    }
    elsif (@junc != @add) {
	my $message = "The following users are already in $self->{name}: ";
	$resp->set_message($message . join(", ", @{$opts{existing}}));
	$resp->set_value([@junc]);
	$resp->set_iswarning(1);
	return $resp;
    }

    my $rc = $self->group_addmembers($resp,\@add);

    return $resp;
}

sub _removemembers {
    my $self = shift;
    my %opts = @_;

    my (%hash, @intersect, @rem);

    my $resp = Tivoli::AccessManager::Admin::Response->new();
    %hash = map { my $f = lc $_; $f => 1 } @{$opts{remove}};
    @rem = keys %hash;

    %hash = map { my $f = lc $_; $f => 1 } @{$opts{existing}};
    @intersect = grep { $hash{$_} } @rem;

    if (@intersect != @rem and $opts{force}) {
	unless (@intersect) {
	    $resp->set_message("There are no members to remove");
	    $resp->set_iswarning(1);
	    return $resp;
	}
	@rem = @intersect;
    }
    elsif (@intersect != @rem) {
	%hash = map {$_ => 1} @rem;
	delete $hash{lc($_)} for @intersect;

	my $message = "The following are not in $self->{name}: ";
	$resp->set_message($message,  join(", ", keys %hash));
	$resp->set_isok(0);
	return $resp;
    }

    my $rc = $self->group_removemembers($resp, \@rem);
    
    return $resp; 
}

sub members {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my %job = (add => \&_addmembers,
    		remove => \&_removemembers);

    if (@_ % 2) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    $opts{force} = defined($opts{force}) ? $opts{force} : 0;
    unless ($self->{exist}) {
	$resp->set_message("The group does not exist");
	$resp->set_isok(0);
	return $resp;
    }

    # Get the list of users, 
    my @rc = sort $self->group_getmembers($resp);
    return $resp unless ($resp->isok);

    unless (defined($opts{add}) or defined($opts{remove})) {
	$resp->set_value(\@rc);
	return $resp;
    }

    for my $action (qw/remove add/) {
	if (defined($opts{$action}) and ref($opts{$action}) eq 'ARRAY') {
	    $resp = $job{$action}-> ($self, %opts, existing => \@rc) ;
	    return $resp unless $resp->isok;
	}
	elsif (defined($opts{$action})) {
	    $resp->set_message("Invalid syntax: $action => array ref");
	    $resp->set_isok(0);
	    return $resp;
	}
	@rc = sort $self->group_getmembers($resp);
	return $resp unless $resp->isok;
    }
    $resp->set_value(\@rc);
    return $resp;
}

sub list {
    my $class = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $pd;

    # I want this to be called as either Tivoli::AccessManager::Admin::Group->list of
    # $self->list
    if (ref $class) {
	$pd = $class->{context};
    }
    else {
	$pd = shift;
    }

    if (@_ % 2) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;
    $opts{bydn} ||= 0;

    $opts{maxreturn} = 0 unless defined($opts{maxreturn});
    $opts{pattern}   = '*' unless defined($opts{pattern});


    my @rc = $opts{bydn} ? group_listbydn($pd, $resp, $opts{pattern},
				 	 $opts{maxreturn}) :
			   group_list($pd, $resp, $opts{pattern},
				         $opts{maxreturn});
    $resp->isok() && $resp->set_value(\@rc);
    return $resp;
}

sub groupimport {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    unless (ref $self) {
	my $pd = shift;
	$self = new($self, $pd, @_);
    }

    if (@_ % 2) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    if ($self->{exist}) {
	$resp->set_message("Cannot import a group that already exists");
	$resp->set_isok(0);
	return $resp;
    }

    unless ($self->{name}) {
	$self->{name} = $opts{name} || "";
    }

    unless ($self->{dn}) {
	$self->{dn} = $opts{dn} || "";
    }

    if ($self->{name} and $self->{dn}) {
	my $rc = $self->group_import($resp, $opts{container} || "");
	if ($resp->isok()) {
	    $self->group_get($resp);
	    $self->{cn} = $self->group_getcn();
	    $self->{exist} = 1;
	}
    }
    else {
	$resp->set_message("groupimport needs the name and the DN");
	$resp->set_isok(0);
    }
    return $resp;
}

sub DESTROY {
    my $self = shift;

    $self->_groupfree();
}

sub name { $_[0]->{name} }
sub exist { $_[0]->{exist} }

1;

=head1 NAME

Tivoli::AccessManager::Admin::Group

=head1 SYNOPSIS

    use Tivoli::AccessManager::Admin;

    my ($resp, @groups);

    my $pd  = Tivoli::AccessManager::Admin->new(password => 'N3ew0nk');

    # Lets see who is there
    $resp = Tivoli::AccessManager::Admin::Group->list($pd, pattern => "lgroup*");
    print join("\n", @{$resp->value});
    # Alternately, search by DN.
    $resp = Tivoli::AccessManager::Admin::Group->list($pd, pattern => "lgroup*", bydn => 1);
    print join("\n", @{$resp->value});

    # Create a new group the easy way
    $resp = Tivoli::AccessManager::Admin::Group->create($pd, 
					name => 'lgroup',
					dn => 'cn=lgroup,ou=groups,o=rox,c=us',
					cn => 'lgroup'
				   );
    $groups[0] = $resp->value if $resp->is_ok;

    # Create a few more groups in a different way
    for my $i (1 .. 3) {
	my $name = sprintf "lgroup%02d", $i;
	$groups[$i] = Tivoli::AccessManager::Admin::Group->new($pd, name => $name);
	# Don't attempt to create something that already exists
	next if $groups[$i]->exist;

	$resp = $groups[$i]->create(dn => "cn=$name,ou=groups,o=rox,c=us");
    }

    # Add members to the group, skipping those users already in the group
    $resp = $groups[0]->members(add => [qw/luser01 luser02 luser03 luser04 luser05/ ], 
    			     force => 1);

    # List the members
    $resp = $groups[0]->members();
    print "\t$_\n" for (@{$resp->value()});

    # Remove members
    $resp = $groups[0]->members(remove => [qw/luser02 luser03/]);

    # Add and remove members at the same time
    $resp = $groups[0]->members(remove => [qw/luser01 luser04/],
			     add    => [qw/luser02 luser03/ ]
			   );
    # Delete the group
    $resp = $groups[0]->delete();

    # We didn't remove it from the registry.  Import it and delete it again
    $resp = $groups[0]->groupimport();
    $resp = $groups[0]->delete(1);
    
=head1 DESCRIPTION

B<Tivoli::AccessManager::Admin::Group> provides the interface to the group portion of the TAM API.

=head1 CONSTRUCTOR

=head2 new(PDADMIN[, name=E<gt> NAME, dn =E<gt> DN, cn =E<gt> CN])

Creates a blessed B<Tivoli::AccessManager::Admin::Group> object and returns it.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  Please note that, after the
L<Tivoli::AccessManager::Admin::Group> object is created, you cannot change the context w/o destroying
the object and recreating it.

=item name =E<gt> NAME

The name of the group to which the object refers.  B<new> will query TAM to determine if the
group exists or not, retrieving the other values (cn and dn) if it does.

=item dn =E<gt> DN

The group's DN.  If this value is provided (but L</"name"> is not), B<new>
will look to see if the group is already defined.  If the group is, the other
fields (name and cn) will be retrieved from TAM.

=item cn =E<gt> CN

The group's common name.  Nothing special happens if you provide the cn.  If
this parameter is not provided, I will assume it is the same as the group's
name.

=back

=head3 Returns

A fully blessed L<Tivoli::AccessManager::Admin::Group> object.

=head1 CLASS METHODS

Class methods behave like instance methods -- they return
L<Tivoli::AccessManager::Adming::Response> objects.

=head2 list(PDADMIN [,maxreturn =E<gt> N, pattern =E<gt> STRING, bydn => 1])

Lists some subset of TAM groups.  

=head3 Parameters

=over 4

=item PDADMIN

A fully blessed L<Tivoli::AccessManager::Admin::Context> object.  Since this is a class method,
and L<Tivoli::AccessManager::Admin::Context> objects are stored in the instances, you must
provide it.

=item maxreturn =E<gt> N

The number of users to return from the query.  This will default to 0, which
means all users matching the pattern.  Depending on how your LDAP is
configured, this may cause issues.

=item pattern =E<gt> STRING

The pattern to search on.  The standard rules for TAM searches apply -- * and
? are legal wild cards.  If not specified, it will default to *, which may
cause issues with your LDAP.  

=item bydn =E<gt> 1

Search by DN instead of group name.  This changes the semantics of the search
in an interesting fashion.  By default, you will only get tamified groups.
Searching by dn will return any LDAP object that TAM recognizes as a group,
irrespective of the TAMification.  This parameters defaults to 0.

=back

=head3 Returns

The resulting list of users.

=head1 METHODS

This verse is the same as all the rest.  Methods called with optional
parameters will attempt to set.  Methods called with no options will perform a
get.

Given that all return values are cleverly hidden in the returned
L<Tivoli::AccessManager::Admin::Response> object, I am not going to worry about documenting that
part.  I will only say what will be in the object.

=head2 create(name =E<gt> NAME, dn =E<gt> DN, cn =E<gt> CN, container =E<gt> 'CONTAINER NAME')

L</"create"> a new group in TAM.  At the bare minimum, both the name and
the DN must be defined.  See L</"Parameters"> below for a full discussion.
B<create> can be called instead of B<new>.  The new object can be retrieved
from the L<Tivoli::AccessManager::Admin::Response> object.

=head3 Parameters

=over 4

=item container =E<gt> 'CONTAINER NAME'

The group container, if there is one.  This parameter is optional.  If you
don't understand it, don't provide it.

=item name =E<gt> NAME

=item dn   =E<gt> DN

=item cn   =E<gt> CN

These are the same as defined for L</"new"> and are only required if you either
did not provide them when you created the instance or if you are calling
L</"create"> to create a new object.

=back

=head3 Returns

The success of the ooerstion if B<new> was used, the new L<Tivoli::AccessManager::Admin::Group>
object otherwise.

=head2 delete([1])

Deletes the group from TAM.  

=head3 Parameters

=over 4

=item 1

If anything is provided that perl will interpret as "true", the group will be
deleted from the registry.  Defaults to false.

=back

=head3 Returns

The success of the operation

=head2 description([STRING])

Gets or sets the description of the group.

=head3 Parameters

=over 4

=item STRING

The new description for the group.  This is an optional parameter.

=back

=head3 Returns

The description for the group for either the set or the get.

=head2 exist

A flag indicating if the group exists or not.

=head2 cn

Returns the CN for the group.  This is a read-only function.  No sets are
allowed via the TAM API (go see L<Net::LDAP> if you really want to do this).

=head2 dn

Returns the DN for the group.  This is a read-only function.  No sets are
allowed via the TAM API. 

=head2 name

Returns the name for the group.  This is a read-only function.  No sets are
allowed via the TAM API. 

=head2 members(add =E<gt> [qw/list of users/],
	         remove =E<gt> [qw/list of users/],
	         force =E<gt> 1)

Adds, removes and retrieves the members of a group.  The add and remove
option can be used at the same time -- removes are processed first.  If the
removal fails, no adds will be attempted.

=head3 Parameters

=over 4

=item add =E<gt> [qw/list of users/]

An array reference to the list of users to be added to the group.

=item remove =E<gt> [qw/list of users/]

An array reference to the list of users to be removed from the group.

=item force =E<gt> 1

Under normal circumstances, TAM will get unhappy if you try to either add
members that are already in the group or delete members that don't exist.
Using the force option will cause B<members> to only add those members that
are not in the group or delete those that are.

If no members will be added/deleted, you will get a warning in the response.

=back

=head3 Returns

Unless there is an error, you will get the new membership list for the group.

=head2 list(maxreturn =E<gt> NUMBER, pattern =E<gt> STRING)

Gets a list of groups defined in TAM.  If the pattern contains an '=', list
will search by DNs.  Otherwise, it will search by name.  Yes, this is the same
as the class method.  I like being able to call this way as well, although it
rather breaks the metaphor.

=head3 Parameters

=over 4

=item maxreturn =E<gt> NUMBER

The maximum number of groups to return.  It will default to 0, which means
return all matching groups.  That could cause problems with the LDAP.

=item pattern =E<gt> STRING

The pattern to search for.  You can use the * and ? wildcards, but that is
about it.  This will default to *.  It too could cause issues with the LDAP.

=back

=head3 Returns

The list of groups that matched the search criteria.

=head2 groupimport([name =E<gt> NAME, dn =E<gt> DN, container =E<gt> 'CONTAINER')

Imports an already existing LDAP group into TAM.  This can also be used to
create a new L<Tivoli::AccessManager::Admin::Group> object.

=head3 Parameters

See L<create> for the full explanation.  Have I mentioned I am a lazy POD
writer yet?

=head3 Returns

The success or failure of the import if called as an instance method, the new
L<Tivoli::AccessManager::Admin::Group> object otherwise.

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin>.  I stand upon the shoulders of giants.

=head1 BUGS

None known yet.

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

ivadmin_response* _getresponse(SV* self) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"response",8,0);
    ivadmin_response* rsp;

    if (fetched == NULL) {
	croak("Couldn't fetch the _response in $self");
    }
    rsp = (ivadmin_response*) SvIV(*fetched);

    fetched = hv_fetch(self_hash, "used",4,0);
    if (fetched) {
	sv_setiv(*fetched, 1);
    }
    return(rsp);
}

static ivadmin_context* _getcontext(SV* self) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"context", 7, 0);

    if (fetched == NULL) {
	croak("Couldn't get context");
    }
    return((ivadmin_context*)SvIV(SvRV(*fetched)));
}

static char* _getname(SV* self) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "name", 4, 0);

    return(fetched ? SvPV_nolen(*fetched) : NULL);
}

static char* _fetch(SV* self, char* field) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, field, strlen(field), 0);

    return fetched ? SvPV_nolen(*fetched) : NULL;
}

void _groupstore(SV* self) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash, "_group",6,1);
    ivadmin_ldapgroup* group;

    if (fetched == NULL)
	croak ("Couldn't create the _group slot");

    Newz(5, group, 1, ivadmin_ldapgroup);

    sv_setiv(*fetched, (IV) group);
    SvREADONLY_on(*fetched);
}

ivadmin_ldapgroup* _getgroup(SV* self) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "_group", 6, 0);

    if (fetched == NULL) {
	return(NULL);
    }

    return((ivadmin_ldapgroup*) SvIV(*fetched));
}

int group_create(SV* self, SV* resp, char* container) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);

    char *name = _getname(self);
    char *dn = _fetch(self,"dn");
    char *cn = _fetch(self,"cn");

    unsigned long rc = 0;

    if (name == NULL)
	croak("group_create: Couldn't retrieve group name");

    if (dn == NULL)
	croak("group_create: Couldn't retrieve group dn");

    if (cn == NULL)
	croak("group_create: Couldn't retrieve group cn");

    rc = ivadmin_group_create2(*ctx, 
				name, 
				dn, 
				cn, 
				container, 
				rsp);

    return (rc == IVADMIN_TRUE);
}

int group_delete(SV* self, SV* resp, unsigned long registry) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char *name = _getname(self);

    unsigned long rc = 0;

    if (name == NULL)
	croak("group_delete: Couldn't retrieve group name");

    rc = ivadmin_group_delete2(*ctx, name, registry, rsp);

    return ( rc == IVADMIN_TRUE);
}

int  group_get(SV* self, SV* resp) {
    ivadmin_context*   ctx   = _getcontext(self);
    ivadmin_ldapgroup* group = _getgroup(self);
    char *name		     = _getname(self);
    ivadmin_response*  rsp   = _getresponse(resp);

    unsigned long rc;

    if (name == NULL)
	croak("group_get: Couldn't retrieve group name");

    if (! group) {
	_groupstore(self);
	group = _getgroup(self);
    }

    if (! group)
	return IVADMIN_FALSE;

    rc = ivadmin_group_get(*ctx, 
    			    name, 
			    group, 
			    rsp);
    return (rc == IVADMIN_TRUE);
}

int group_getbydn(SV* self, SV* resp) {
    ivadmin_context*   ctx   = _getcontext(self);
    ivadmin_ldapgroup* group = _getgroup(self);
    ivadmin_response*  rsp   = _getresponse(resp);

    char *dn = _fetch(self,"dn");
    unsigned long rc;

    if (group == NULL) {
	_groupstore(self);
	group = _getgroup(self);
    }

    if (dn == NULL)
	croak("group_getbydn: Couldn't retrieve group dn");

    rc = ivadmin_group_getbydn(*ctx, 
    				dn, 
				group, 
				rsp);
    return (rc == IVADMIN_TRUE);
}

SV* group_getcn(SV* self) {
    ivadmin_ldapgroup* grp = _getgroup(self);
    char *cn;

    if (grp == NULL) 
	croak("group_getcn: could not retrieve ivadmin_ldapgroup object");
   
    cn = (char*)ivadmin_group_getcn(*grp);
    return(cn ? newSVpv(cn,0) : NULL);
}

SV* group_getdescription(SV* self) {
    ivadmin_ldapgroup* grp = _getgroup(self);
    char *desc;
   
    if (grp == NULL) 
	croak("group_getdescription: could not retrieve ivadmin_ldapgroup object");
   
    desc = (char*)ivadmin_group_getdescription(*grp);

    return(desc ? newSVpv(desc,0) : NULL);
}

SV* group_getdn(SV* self) {
    ivadmin_ldapgroup* grp = _getgroup(self);
    char *dn;

    if (grp == NULL) 
	croak("group_getdn: could not retrieve ivadmin_ldapgroup object");
  
    dn = (char*)ivadmin_group_getdn(*grp);
    return(dn ? newSVpv(dn,0) : NULL);
}

SV* group_getname(SV* self) {
    ivadmin_ldapgroup* grp = _getgroup(self);
    char *name;

    if (grp == NULL) 
	croak("group_getname: could not retrieve ivadmin_ldapgroup object");
 
    name = (char*)ivadmin_group_getid(*grp);
    return(name ? newSVpv(name,0):NULL);
}

void group_getmembers(SV* self, SV* resp) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char* name            = _getname(self);

    unsigned long count;
    unsigned long rc;
    unsigned long i;

    char **users;

    if (name == NULL)
	croak("group_getmembers: Couldn't retrieve group name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_group_getmembers(*ctx,
    				   name,
				   &count,
				   &users,
				   rsp 
			        );

    if (rc == IVADMIN_TRUE) {
	for (i=0; i < count; i++) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(users[i],0)));
	    ivadmin_free(users[i]);
	}
    }

    Inline_Stack_Done;
}

int group_import(SV* self, SV* resp, char* container) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char* name	          = _getname(self);

    char* dn = _fetch(self,"dn");

    unsigned long rc;

    if (name == NULL)
	croak("group_getmembers: Couldn't retrieve group name");

    if (dn == NULL)
	croak("group_import: Couldn't retrieve group dn");

    rc = ivadmin_group_import2(*ctx, name, dn, container, rsp);
    return (rc == IVADMIN_TRUE);
}

void group_list(SV* pd, SV* resp, char* pattern, unsigned long maxret) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse(resp);

    unsigned long count;
    unsigned long rc;
    unsigned long i;

    char **groups;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if (! strlen(pattern)) 
	pattern = IVADMIN_ALLPATTERN;

    if (maxret == 0) 
        maxret = IVADMIN_MAXRETURN;

    rc = ivadmin_group_list(*ctx,
    			     pattern,
			     maxret,
			     &count,
			     &groups,
			     rsp 
			   );

    if (rc == IVADMIN_TRUE) {
	for (i=0; i < count; i++) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(groups[i],0)));
	    ivadmin_free(groups[i]);
	}
    }
    Inline_Stack_Done;
}

void group_listbydn(SV* pd, SV* resp, char* pattern, 
		     unsigned long maxret) {
    ivadmin_context* ctx  = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse(resp);

    unsigned long count;
    unsigned long rc;
    unsigned long i;

    char **groups;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    if (! strlen(pattern)) 
	pattern = IVADMIN_ALLPATTERN;

    if (maxret == 0) 
        maxret = IVADMIN_MAXRETURN;

    rc = ivadmin_group_listbydn(*ctx,
    				 pattern,
				 maxret,
				 &count,
				 &groups,
				 rsp 
			      );

    if (rc == IVADMIN_TRUE) {
	for (i=0; i < count; i++) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(groups[i],0)));
	    ivadmin_free(groups[i]);
	}
    }
    Inline_Stack_Done;
}

int group_removemembers(SV* self, SV* resp, AV* users) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char *name		  = _getname(self);

    unsigned long count;
    unsigned long rc;
    unsigned long i;

    const char** members;
    SV** elem;

    if (name == NULL)
	croak("group_removemembers: Couldn't retrieve group name");

    /* We need to pull the users to be deleted from the perl array ref into a
    * char**
    */
    count = av_len(users) + 1;
    Newz(5, members, count, const char*);
    for (i=0; i < count; i++) {
	elem = av_fetch(users,i,0);
	members[i] = elem ? (const char*)SvPV_nolen(*elem) : NULL;
    }

    rc = ivadmin_group_removemembers(*ctx,
    				      name,
				      count,
				      members,
				      rsp 
				   );
    return (rc == IVADMIN_TRUE);
}

int group_addmembers(SV* self, SV* resp, AV* users) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char* name		  = _getname(self);

    unsigned long count;
    unsigned long rc;
    unsigned long i;
    SV** elem;

    const char** members;

    if (name == NULL)
	croak("group_addmembers: Couldn't retrieve group name");

    /* We need to pull the users to be deleted from the perl array ref into a
    * char**
    */
    count = av_len(users) + 1;
    Newz(5, members, count, const char*);
    for (i=0; i < count; i++) {
	elem = av_fetch(users,i,0);
	members[i] = elem ? (const char*)SvPV_nolen(*elem) : NULL;
    }

    rc = ivadmin_group_addmembers(*ctx,
    				   name,
				   count,
				   members,
				   rsp 
				);
    return (rc == IVADMIN_TRUE);
}

int group_setdescription(SV* self, SV* resp, char* desc) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char* name		  = _getname(self);

    unsigned long rc;
    
    if (name == NULL)
	croak("group_setdescription: Couldn't retrieve group name");

    rc = ivadmin_group_setdescription(*ctx,
    				       name,
				       desc,
				       rsp
				    );
    return (rc == IVADMIN_TRUE);
}


void _groupfree(SV* self) {
    ivadmin_ldapgroup* grp = _getgroup(self);

    if (grp != NULL)
	Safefree(grp);

    hv_delete((HV*)SvRV(self), "_group", 6, 0);
}
