package Tivoli::AccessManager::Admin::AuthzRule;
use strict;
use warnings;
use Carp;
use Devel::Peek;

use Tivoli::AccessManager::Admin::Response;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: ACL.pm 189 2005-12-15 05:39:43Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::AuthzRule::VERSION = '1.11';
use Inline( C => 'DATA',
		 INC  => '-I/opt/PolicyDirector/include',
                 LIBS => ' -lpthread  -lpdadminapi -lstdc++',
		 CCFLAGS => '-Wall',
		 VERSION => '1.11',
		 NAME => 'Tivoli::AccessManager::Admin::AuthzRule');

sub new {
    my $class = shift;
    my $cont = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $name = '';

    unless ( defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context' ) ) {
	return undef;
    }

    if ( @_ == 1 ) {
	$name = shift;
    }
    elsif ( @_ % 2 ) {
	warn "Invalid syntax for new";
	return undef;
    }
    elsif ( @_ ) {
	my %opts = @_;
	$name = $opts{name} || '';
    }

    my $self = bless {}, $class;
    $self->{exist} = 0;
    $self->_authzrule_stash();
    $self->{context} = $cont;
    $self->{name} = $name;

    if ( $self->{name} ) {
	my $rc = $self->authzrule_get( $resp );
	$self->{exist} = 1 if $rc;
    }

    return $self;
}

sub list {
    my $class = shift;
    my ($pd,@rules);
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    if ( ref($class) ) {
	$pd = $class->{context};
    }
    else {
	$pd = shift;
	unless ( defined($pd) and UNIVERSAL::isa($pd,'Tivoli::AccessManager::Admin::Context' ) ) {
	    $resp->set_message("Incorrect syntax -- did you forget the context?");
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
    my @temp = authzrule_list($pd,$resp);

    @rules = ();
    if ( $resp->isok() ) {
	if ( defined($opts{pattern}) ) {
	    $opts{pattern} =~ s/\*/.*/g;
	    $opts{pattern} =~ s/\?/.?/g;
	    @rules = sort grep /^$opts{pattern}/, @temp;
	}
	else {
	    @rules = sort @temp;
	}
	$resp->set_value(\@rules);
    }

    return $resp;
}

sub find {
    my $self = shift;
    my $pd = $self->{context};

    return Tivoli::AccessManager::Admin::ProtObject->find( $pd, authzrule => $self->name );
}

sub attach {
    my $self = shift;
    my @temp = @_;
    my ($resp,@attach);

    unless ( $self->{exist} ) {
	$resp = Tivoli::AccessManager::Admin::Response->new;
	$resp->set_message("Cannot attach a non-existant rule");
	$resp->set_isok(0);
	return $resp;
    }

    for my $name ( @temp ) {
	my $obj = Tivoli::AccessManager::Admin::ProtObject->new($self->{context}, name => $name );
	$resp = $obj->authzrule( attach => $self->name );
	return $resp unless $resp->isok;
	push @attach, $name;
    }
    $resp->set_value(\@attach);
    return $resp;
}

sub detach {
    my $self = shift;
    my @temp = @_;
    my ($resp,@detach);

    unless ( $self->{exist} ) {
	$resp = Tivoli::AccessManager::Admin::Response->new;
	$resp->set_message("Cannot detach a non-existant rule");
	$resp->set_isok(0);
	return $resp;
    }

    unless ( @temp ) {
	$resp = $self->find;
	return $resp unless $resp->isok;
	@temp = $resp->value;
    }

    for my $name ( @temp ) {
	my $obj = Tivoli::AccessManager::Admin::ProtObject->new($self->{context}, name => $name );
	$resp = $obj->authzrule( detach => $self->name );
	return $resp unless $resp->isok;
	push @detach, $name;
    }
    $resp->set_value(\@detach);
    return $resp;
}

sub _readfile {
    my $fname = shift;
    my $resp  = shift;
    my $text  = '';

    unless ( open(RULE,$fname) ) {
	$resp->set_message( $! );
	$resp->set_isok(0);
	return $resp;
    }
    while (my $line = <RULE>) {
	$text .= $line;
    }

    $resp->set_value($text);
}

sub create {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();
    my $text = '';

    unless ( ref($self) ) {
	my $pd = shift;
	$self = $self->new($pd, @_);
    }

    if ( $self->exist ) {
	$resp->set_message( $self->name . " already exists" );
	$resp->set_iswarning(1);
	$resp->set_value( $self );
	return $resp;
    }

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax for create: @_");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    if ( defined($opts{file}) ) {
	_readfile( $opts{file}, $resp );
	if ( $resp->isok ) {
	    $text = $resp->value;
	}
	else {
	    return $resp;
	}
    }
    elsif ( defined($opts{rule}) ) {
	$text = $opts{rule};
    }
    else {
	$resp->set_message( "Cannot create an authzrule w/o the rule" );
	$resp->set_isok(0);
	return $resp;
    }

    my $rc = $self->authzrule_create( $resp,
				      $opts{description} || '',
				      $text,
				      $opts{failreason} || '',
				  );
    $self->{exist} = 1 if $resp->isok;
    $resp->set_value( $self );
    return $resp;
}

sub delete {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot delete a non-existant rule");
	$resp->set_isok(0);
	return $resp;
    }

    my $rc = $self->authzrule_delete( $resp );

    if ( $rc ) {
	$self->{exist} = 0;
    }
    $resp->set_value( $rc );
    return $resp;
}

sub description {
    my $self = shift;
    my ($rc,$acl,$desc); 
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
    else {
	$desc = '';
    }

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot describe a non-existant rule");
	$resp->set_isok(0);
	return $resp;
    }
    # Set description
    if ( $desc ) {
	$rc = $self->authzrule_setdescription( $resp, $desc );
	$resp->set_value( $rc );
    }

    if ( $resp->isok ) {
	$self->authzrule_get($resp);
	$desc = $self->authzrule_getdescription();
	$resp->set_value( $desc || '' );
    }
    return $resp;
}

sub ruletext {
    my $self = shift;
    my ( $rc, $text, $string );
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    if ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    my %opts = @_;

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot add rule text to a non-existant rule");
	$resp->set_isok(0);
	return $resp;
    }

    if ( defined($opts{file}) ) {
	_readfile( $opts{file}, $resp );
	if ( $resp->isok ) {
	    $text = $resp->value;
	}
	else {
	    return $resp;
	}
    }
    elsif ( defined($opts{rule}) ) {
	$text = $opts{rule};
    }

    if ( $text ) {
	$rc = $self->authzrule_setruletext( $resp, $text );
    }

    if ( $resp->isok ) {
	$rc = $self->authzrule_get($resp);
	if ( $resp->isok ) {
	    $string = $self->authzrule_getruletext();
	    $resp->set_value( $string );
	}
    }
    return $resp;
}

sub failreason {
    my $self = shift;
    my $reason = '';
    my $rc;

    my $resp = Tivoli::AccessManager::Admin::Response->new();

    if ( @_ == 1 ) {
	$reason = shift;
    }
    elsif ( @_ % 2 ) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif (@_) {
	my %opts = @_;
	$reason = $opts{reason} || '';
    }

    unless ( $self->{exist} ) {
	$resp->set_message("Cannot get/set fail reason on a non-existant rule");
	$resp->set_isok(0);
	return $resp;
    }

    # Set the failreason
    if ( $reason ) {
	$rc = $self->authzrule_setfailreason( $resp, $reason );
    }

    if ( $resp->isok ) {
	$self->authzrule_get($resp);
	$reason = $self->authzrule_getfailreason();
	$resp->set_value( $reason || '' );
    }
    return $resp;
}

sub DESTROY {
    my $self = shift;

    $self->_authzrulefree;
}

sub exist { $_[0]->{exist} }

sub name  { $_[0]->{name} }

1;

=head1 NAME

Tivoli::AccessManager::Admin::AuthzRule

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new( PDADMIN, NAME )

Creates a blessed B<Tivoli::AccessManager::Admin::AuthzRule> object and returns it.

=head3 Parameters

=over 4

=item PDADMIN

An initializæd L<Tivoli::AccessManager::Admin::Context> object.  You should note that, once the
B<Tivoli::AccessManager::Admin::AuthzRule> object is instantiated, you cannot change the
context.

=item NAME

The name of the authzrule to which the object refers.  This is an optional
argument.

=back

=head3 Returns

A fully blessed L<Tivoli::AccessManager::Admin::AuthzRule> object.  If you forget the
L<Tivoli::AccessManager::Admin::Context> object (which I can do with astonishing frequency),
L</new> returns undef.

=head2 create(PDADMIN, name =E<gt> NAME, rule =E<gt> TEXT | file =E<gt> "/path/to/file"[,description =E<gt> STRING][, failreason =E<gt> REASON])

create can also be used as a constructor.  

=head3 Parameters

=over 4

=item PDADMIN

As you would expect, this is a fully blessed L<Tivoli::AccessManager::Admin::Context> object.

=item name =E<gt> NAME

The name of the authzrule.  This is a required parameter when using B<create>
as a constructor.

=item rule =E<gt> TEXT

The text of the rule to be created.  You must provide either this parameter or
the file parameter.

=item file =E<gt> /path/to/file

Instead of providing the text as a string, you can specify a path that
contains the authzrule.  It is important that this file be readable by the
userid running the program.

=item description =E<gt> STRING

Some descriptive text about the authzrule.  This is optional.

=item failreason =E<gt> REASON

The fail reason.  I don't understand what this really does.  But it
seems to take any random text.  This too is optional.

=back

=head3 Returns

It returns the fully blessed L<Tivoli::AccessManager::Admin::AuthzRule> object buried in a
L<Tivoli::AccessManager::Admin::Response> object.

=head1 CLASS METHODS

Class methods behave like instance methods -- they return
L<Tivoli::AccessManager::Admin::Response> objects.

=head2 list(PDADMIN[,pattern =E<gt> STRING])

Lists some subset of the defined authzrules.  No export is available for this
method -- it must be called with the complete class name.

=head3 Parameters

=over 4

=item PDADMIN

A fully blessed L<Tivoli::AccessManager::Admin::Context> object.  Since this is a class method,
and L<Tivoli::AccessManager::Admin::Context> objects are stored in the instances, you must
provide it.

=item pattern =E<gt> STRING

The pattern to search on.  This will be interpreted as a standard perl regex
expression with two differences: * and ? will be translated to .* and .?,
respectively.  This makes it work a bit more like shell wild cards.

=back

=head3 Returns

The resulting list of authzrules.

=head1 METHODS

=head2 create(rule =E<gt> TEXT | file =E<gt> "/path/to/file"[,name =E<gt> NAME,description =E<gt> STRING][, failreason =E<gt> REASON])

create as an instance method.

=head3 Parameters

=over 4

=item rule =E<gt> TEXT

The text of the rule to be created.  You must provide either this parameter or
the file parameter.

=item file =E<gt> /path/to/file

Instead of providing the text as a string, you can specify a path that
contains the authzrule.  It is important that this file be readable by the
userid running the program.

=item name =E<gt> NAME

The name of the authzrule.  This parameter is optional if object was
constructed with the name parameter.

=item description =E<gt> STRING

Some descriptive text about the authzrule.  This is optional.

=item failreason =E<gt> REASON

The fail reason.  I really don't understand what this really does.  But it
seems to take any random text.  This too is optional.

=back

=head3 Returns

A fully blessed L<Tivoli::AccessManager::Admin::AuthzRule> object. 

=head2 delete

Deletes the authzrule.  You need to make sure this isn't attached anywhere
before calling this method -- see L</find>.

=head3 Parameters

None.

=head3 Returns

The success or failure of the operation.

=head2 description([STRING])

Gets or sets the authzrule's description.

=head3 Parameters

=over 4

=item STRING

If this parameter is present, the description will be changed to STRING.

=back

=head3 Returns

No matter how it is called, it always returns the current description
(possibly an empty string).

=head2 ruletext([STRING])

Gets or sets the authzrule's rule text.

=head3 Parameters

=over 4

=item STRING

If this parameter is present, the rule text will be changed to STRING.

=back

=head3 Returns

No matter how it is called, it always returns the current rule text.

=head2 failreason([STRING])

Gets or sets the authzrule's fail reason.  Still wish I understood this.

=head3 Parameters

=over 4

=item STRING

If this parameter is present, the rule's failreason will be set to STRING.

=back

=head3 Returns

No matter how it is called, it always returns the current failreason.

=head2 find

Finds where the authzrule is attached.

=head3 Parameters

None

=head3 Returns

A list of places in the objectspace to which this authzrule is attached.

=head2 attach( STRING[,STRING...] )

Attaches the authzrule to the named places in the object space.

=head3 Parameters

=over 4

=item STRING[, STRING...]

Where in the objectspace to attach the autzrule.  It will DWYM if you send it
an array.

=back

=head3 Returns

The list of places where the authzrule was attached.  This is useful if an
error occurs -- you can at least figure out where the work is done.

=head2 detach([STRING[,STRING...]])

Detaches the authzrule.  

=head3 Parameters

=over 4

=item STRING[,STRING...]

A list of places from which the authzrule is to be detached.  If this
parameter is empty, the authzrule will be detached from B<every> place it is
attached.

=back

=head3 Returns

The list of places from which the authzrule was detached.

=head2 exist

Returns the existence of the authzrule.

=head3 Parameters

None

=head3 Returns

1 if the object exists, 0 if it doesn't.  B<NOTE>: This return value is B<not>
buried in a L<Tivoli::AccessManager::Admin::Response> object.

=head2 name

Returns the name of the authzrule.

=head3 Parameters

None

=head3 Returns

The name of the authzrule.  B<NOTE>: This return value is B<not>
buried in a L<Tivoli::AccessManager::Admin::Response> object.

=head1 ACKNOWLEDGEMENTS

Please read L<Tivoli::AccessManager::Admin> for the full list of acks.  I stand upon the
shoulders of giants.

=head1 BUGS

=head1 AUTHOR

Mik Firestone E<lt>mikfire@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005-2012 Mik Firestone.  All rights reserved.  This program is
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
    return( rsp );
}

static ivadmin_context* _getcontext( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"context", 7, 0 );

    if ( fetched == NULL ) {
	croak("Couldn't get context");
    }
    return( (ivadmin_context*)SvIV(SvRV(*fetched)) );
}

static char* _getname(SV* self) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"name",4,0);

    return( fetched ? SvPV_nolen(*fetched) : NULL );
}

static ivadmin_authzrule* _getauthzrule(SV* self) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"_authzrule",10,0);

    if ( fetched ) {
	return (ivadmin_authzrule*) SvIV(*fetched);
    }
    else {
	return(NULL);
    }
}

void _authzrule_stash(SV *self) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash, "_authzrule",10,1);
    ivadmin_authzrule* authzrule;

    Newz( 5, authzrule, 1, ivadmin_authzrule );
    if ( fetched == NULL ) {
	croak ( "Couldn't create the _authzrule slot");
    }

    sv_setiv(*fetched, (IV) authzrule );
    SvREADONLY_on(*fetched);
}

int authzrule_create( SV* self, SV* resp, char* ruledesc, 
		      char* ruletext, char* failreason ) {
    ivadmin_context*   ctx    = _getcontext(self);
    ivadmin_response*  rsp    = _getresponse(resp);
    char* ruleid            = _getname(self);

    unsigned long rc;
    
    if ( ruleid == NULL )
	croak("authzrule_create: could not retrieve name");

    if (! strlen(ruledesc) )
	ruledesc = NULL;
    if (! strlen(failreason) )
	failreason = NULL;

    rc = ivadmin_authzrule_create( *ctx,
				   ruleid,
				   ruledesc,
				   ruletext,
				   failreason,
				   rsp );
    return( rc == IVADMIN_TRUE );
}

int authzrule_delete( SV* self, SV* resp ) {
    ivadmin_context* ctx  = _getcontext(self);
    ivadmin_response* rsp = _getresponse( resp );
    char *ruleid  = _getname(self);
    unsigned long rc = 0;

    if ( ruleid == NULL )
	croak("authzrule_delete: could not retrieve name");

    rc = ivadmin_authzrule_delete( *ctx, ruleid, rsp );
    return(rc == IVADMIN_TRUE);
}
				   
int authzrule_get( SV* self, SV* resp ) {
    ivadmin_context*   ctx  = _getcontext(self);
    ivadmin_response*  rsp  = _getresponse(resp);
    ivadmin_authzrule* rule = _getauthzrule(self);
    char* ruleid            = _getname(self);

    unsigned long rc;

    if ( rule == NULL ) {
	_authzrule_stash(self);
	rule = _getauthzrule(self);
    }

    if ( ruleid == NULL )
	croak("authzrule_get: could not retrieve name");

    if ( rule == NULL )
	croak("authzrule_get: could not retrieve authzrule");

    rc = ivadmin_authzrule_get( *ctx,
				ruleid,
				rule,
				rsp );
    return(rc == IVADMIN_TRUE);
}

SV* authzrule_getdescription(SV *self) {
    ivadmin_authzrule* rule = _getauthzrule(self);
    const char *action;

    if ( rule == NULL )
	croak("authzrule_getdescription: Couldn't retrieve the ivadmin_authzrule object");

    action = ivadmin_authzrule_getdescription(*rule);
    return(action ? newSVpv(action,0) : NULL);
}

int authzrule_setdescription(SV *self, SV* resp, const char* desc) {
    ivadmin_context*  ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char* ruleid = _getname(self);
    unsigned long rc;


    if ( ruleid == NULL )
	croak("authzrule_getdescription: Could not retrieve name");


    rc = ivadmin_authzrule_setdescription(*ctx, ruleid, desc, rsp);
    return(rc == IVADMIN_TRUE);
}

SV* authzrule_getfailreason(SV *self) {
    ivadmin_authzrule* rule = _getauthzrule(self);
    const char *action;

    if ( rule == NULL )
	croak("authzrule_getfailreason: Couldn't retrieve the ivadmin_authzrule object");

    action = ivadmin_authzrule_getfailreason(*rule);
    return(action ? newSVpv(action,0) : NULL);
}

int authzrule_setfailreason(SV *self, SV* resp, const char* reason) {
    ivadmin_context*  ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char* ruleid = _getname(self);
    unsigned long rc;


    if ( ruleid == NULL )
	croak("authzrule_setfailreason: Could not retrieve name");

    rc = ivadmin_authzrule_setfailreason(*ctx, ruleid, reason, rsp);
    return(rc == IVADMIN_TRUE);
}

SV* authzrule_getid(SV *self) {
    ivadmin_authzrule* rule = _getauthzrule(self);
    const char *action;

    if ( rule == NULL )
	croak("authzrule_getid: Couldn't retrieve the ivadmin_authzrule object");

    action = ivadmin_authzrule_getid(*rule);
    return(action ? newSVpv(action,0) : NULL);
}

SV* authzrule_getruletext(SV *self) {
    ivadmin_authzrule* rule = _getauthzrule(self);
    const char *action;

    if ( rule == NULL )
	croak("authzrule_getruletext: Couldn't retrieve the ivadmin_authzrule object");

    action = ivadmin_authzrule_getruletext(*rule);
    return(action ? newSVpv(action,0) : NULL);
}

int authzrule_setruletext(SV *self, SV* resp, const char* rule) {
    ivadmin_context*  ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char* ruleid = _getname(self);
    unsigned long rc;


    if ( ruleid == NULL )
	croak("authzrule_setruletext: Could not retrieve name");

    rc = ivadmin_authzrule_setruletext(*ctx, ruleid, rule, rsp);
    return(rc == IVADMIN_TRUE);
}

void authzrule_list( SV* pd, SV* resp ) {
    ivadmin_context* ctx = (ivadmin_context*) SvIV(SvRV(pd));
    ivadmin_response* rsp = _getresponse( resp );

    unsigned long count;
    unsigned long rc;
    int i;
    char **ruleids;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_authzrule_list( *ctx,
    			   &count,
			   &ruleids,
			   rsp );

    if ( rc == IVADMIN_TRUE) {
	for ( i=0; i < count; i++ ) {
	    Inline_Stack_Push(sv_2mortal(newSVpv(ruleids[i],0)));
	    ivadmin_free( ruleids[i] );
	}
    }
    Inline_Stack_Done;
}

void _authzrulefree(SV *self) {
    ivadmin_authzrule* rule = _getauthzrule(self);

    if ( rule != NULL ) {
	Safefree( rule );
    }

    hv_delete((HV*)SvRV(self), "_authzrule", 10, 0 );
}

