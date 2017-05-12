package Tivoli::AccessManager::Admin::Server;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Tivoli::AccessManager::Admin::Response;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# $Id: Server.pm 343 2006-12-13 18:27:52Z mik $
#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
$Tivoli::AccessManager::Admin::Server::VERSION = '1.11';
use Inline(C => 'DATA',
		INC  => '-I/opt/PolicyDirector/include',
                LIBS => ' -lpthread  -lpdadminapi -lpdmgrapi -lstdc++',
		CCFLAGS => '-Wall',
		VERSION => '1.11',
		NAME => 'Tivoli::AccessManager::Admin::Server',
	   );

sub new {
    my $class = shift;
    my $cont = shift;
    my $name = "";
    unless (defined($cont) and UNIVERSAL::isa($cont,'Tivoli::AccessManager::Admin::Context')) {
	warn "Incorrect syntax -- did you forget the context?\n";
	return undef;
    }

    if (@_ == 1) {
	$name = shift;
    }
    elsif (@_ % 2) {
	warn "Invalid syntax for new\n";
	return undef;
    }
    elsif (@_) {
	my %opts = @_;
	$name = $opts{name} || '';
    }

    my $self  = bless {}, $class;

    $self->{context} = $cont;
    $self->{name}    = $name;

    return $self;
}

sub tasklist {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;

    unless ($self->{name}) {
	$resp->set_message("Unnamed servers cannot list tasks");
	$resp->set_isok(0);
	return $resp;
    }

    my $rc = $self->server_gettasklist($resp);
    $resp->isok() && $resp->set_value($rc);

    return $resp;
}

sub task {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $task = '';

    unless ($self->{name}) {
	$resp->set_message("Unnamed servers cannot perform tasks");
	$resp->set_isok(0);
	return $resp;
    }
    
    if (@_ == 1) {
	$task = shift;
    }
    elsif (@_ % 2) {
	$resp->set_message("Invalid syntax");
	$resp->set_isok(0);
	return $resp;
    }
    elsif (@_) {
	my %opts = @_;
	$task = $opts{task} || '';
    }

    if ($task) {
	my $rc = $self->server_performtask($resp,$task);
	if ($resp->isok) {
	    my @temp = split("\n",$rc);
	    for (@temp) {
		chomp;
		s/^\s*//;
		s/\s*$//;
	    }
	    $resp->set_value(\@temp);
	}
    }
    else {
	$resp->set_isok(0);
	$resp->set_message("Cannot perform a nameless task");
    }
    return $resp;
}

# This is a kludge, because IBM won't expose the real calls via the C API.
# They did for java, but not C.  Bastards
sub list {
    my $class = shift;
    my ($tam,$grp,@list);
    my $resp = Tivoli::AccessManager::Admin::Response->new();

    # I want this to be called as either Tivoli::AccessManager::Admin::User->list or
    # $self->list
    if ( ref($class) ) {
	$tam = $class->{context};
    }
    else {
	$tam = shift;
	unless (defined($tam) and UNIVERSAL::isa($tam,'Tivoli::AccessManager::Admin::Context' ) ) {
	    $resp->set_message("Incorrect syntax -- did you forget the context?");
	    $resp->set_isok(0);
	    return $resp;
	}
    }

    $grp = Tivoli::AccessManager::Admin::Group->new($tam,name => 'remote-acl-users');
    $resp = $grp->members;
    return $resp unless $resp->isok;

    for ( $resp->value ) {
	next unless s#/#-#;
	push @list, $_;
    }

    $resp = Tivoli::AccessManager::Admin::Response->new;
    $resp->set_value(\@list);

    return $resp;
}

sub name {
    my $self = shift;
    my $resp = Tivoli::AccessManager::Admin::Response->new;
    my $name = "";

    if (@_ == 1) {
	$name = shift;
    }
    elsif (@_ % 2) {
	$resp->set_message("Invalid syntax for name");
	$resp->set_isok(0);
	return $resp;
    }
    elsif (@_) {
	my %opts = @_;
	$name = $opts{name} || '';
    }

    $self->{name} = $name if $name;

    $resp->set_value($self->{name});
    return $resp;
}


1;

=head1 NAME

Tivoli::AccessManager::Admin::Server

=head1 SYNOPSIS

  my $tam = Tivoli::AccessManager::Admin->new(password => 'N3ew0nk');
  my($server, $resp);

  # Lets see what servers are defined
  $resp = Tivoli::AccessManager::Admin::Server->list($tam);

  # Lets find a webSEAL
  my $wseal;
  for ($resp->value) {
      if (/webseal/) {
          $wseal = $_;
	  last;
      }
  }

  $server = Tivoli::AccessManager::Admin::Server->new($tam,$wseal);

  # Get a list of tasks from the webSEAL
  $resp = $server->tasklist;

  # Execute a task
  $resp = $server->task("list");

=head1 DESCRIPTION

L<Tivoli::AccessManager::Admin::Server> implements the server access portion
of the TAM API.  This basically means any pdadmin command that starts with the
word "server".

=head1 CONSTRUCTOR

=head2 new(PDADMIN[, NAME])

Creates a blessed L<Tivoli::AccessManager::Admin::Server> object.  As you may
well expect, you will need to destroy the object if you want to change the
context.

=head3 Parameters

=over 4

=item PDADMIN

An initialized L<Tivoli::AccessManager::Admin::Context> object.  This is the only required
parameter.

=item NAME

The servers's name.  This is technically not required, but you need to define
the name before you can use L</"tasklist"> or L</"task">.

=back

=head3 Returns

A blessed L<Tivoli::AccessManager::Admin::Server> as long as you provide a
valid context.  It will warn and return undef otherwise.

=head1 CLASS METHODS

=head2 list

Lists all servers.  This method is something of a hack.  TAM does not expose a
server list function to the C API.  This method actually uses the membership
list of the remote-acl-users group.  It isn't great, but it should work.

=head3 Parameters

None.

=head3 Returns

Hopefully, a list of all the defined servers buried in a
L<Tivoli::AccessManager::Admin::Response> object.  There may be some extra
values in there, but you shouldn't be adding your own stuff to
remove-acl-users anyway.  

=head1 METHODS

All methods return a L<Tivoli::AccessManager::Admin::Response> object.  See
the documentation for that module to get the actual values out.

=head2 task(COMMAND)

Executes the named command on the server.

=head3 Parameters

=over 4

=item COMMAND

The command to execute.  This parameter is required.

=back

=head3 Returns

An array containing the results of the command.  The API is a little weird in
this, but it makes some sense.  The API actually returns everything as one
string, separated by newlines.  I split this string on newlines to generate an
array.  It isn't pretty, but that is the way it works.

An invalid or missing command will generate an error.

=head2 tasklist

Gets a list of all the tasks defined on the server.

=head3 Parameters

None.

=head3 Returns

An array containing the output.  See the discussion in L</"task"> for more
information.

=head2 name([NAME])

Gets or sets the server's name.

=head3 Parameters

=over 4

=item NAME

The new name.  This parameter is optional.

=back

=head3 Returns

The name of the server, buried in a L<Tivoli::AccessManager::Admin::Response>
object.

=head1 ACKNOWLEDGEMENTS

See L<Tivoli::AccessManager::Admin> for the list.  This was not possible without the help of a
bunch of people smarter than I.

=head1 BUGS

I would really like a server list and server info function exposed to the C
API.  Like what Java has.  This isn't my bug.

=head1 AUTHOR

Mik Firestone E<lt>mikfire@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006-2013 Mik Firestone.  All rights reserved.  This program is
free software; you can redistibute it and/or modify it under the same terms as
Perl itself.

All references to TAM, Tivoli Access Manager, etc are copyrighted, trademarked
and otherwise patented by IBM.

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
    return rsp;
}

static ivadmin_context* _getcontext( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched = hv_fetch(self_hash,"context", 7, 0 );

    if ( fetched == NULL )
	croak("Couldn't get context");

    return (ivadmin_context*)SvIV(SvRV(*fetched));
}

static char* _getname( SV* self ) {
    HV* self_hash = (HV*) SvRV(self);
    SV** fetched  = hv_fetch(self_hash, "name", 4, 0 );

    return(fetched ? SvPV_nolen(*fetched) : NULL);
}

SV* server_gettasklist(SV* self, SV* resp) {
    ivadmin_context*  ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char *server = _getname(self);
    

    azn_attrlist_h_t* outdata = NULL;
    unsigned long tcount = 0;
    char**        tasks;
    unsigned long rcount = 0;
    char**        results;
    unsigned long rc;
    unsigned long i;

    HV* rhash = newHV();
    AV* array;

    rc = ivadmin_server_gettasklist( *ctx,
				      server,
				      NULL,
				      &tcount,
				      &tasks,
				      outdata,
				      &rcount,
				      &results,
				      rsp );
    if ( rc == IVADMIN_TRUE ) {
	if ( tcount ) {
	    array = newAV();
	    for(i=0;i<tcount;i++){
		av_push( array, newSVpv(tasks[i],0) );
		ivadmin_free(tasks[i]);
	    }
	    hv_store( rhash, "tasks", 5, (SV*)newRV_noinc((SV*)array),0);
	}

	if ( rcount ) {
	    array = newAV();
	    for(i=0;i<rcount;i++){
		av_push( array, newSVpv(results[i],0) );
		ivadmin_free(results[i]);
	    }
	    hv_store( rhash, "messages", 8, newRV_noinc((SV*)array),0);
	}
    }

    return newRV_noinc( (SV*)rhash );
}

void server_performtask( SV* self, SV* resp, char* task ) {
    ivadmin_context*  ctx = _getcontext(self);
    ivadmin_response* rsp = _getresponse(resp);
    char* server = _getname(self);

    azn_attrlist_h_t* outdata = NULL;
    unsigned long rcount = 0;
    char**        results;
    unsigned long rc;
    unsigned long i;

    if (server == NULL)
	croak("server_performtask: could not get server name");

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    rc = ivadmin_server_performtask( *ctx,
				      server,
				      task,
				      NULL,
				      outdata,
				      &rcount,
				      &results,
				      rsp );
    if (rc == IVADMIN_TRUE) {
	for(i=0;i<rcount;i++){
	    Inline_Stack_Push(sv_2mortal(newSVpv(results[i],0))); 
	    ivadmin_free(results[i]);
	}
    }

    Inline_Stack_Done;
}

