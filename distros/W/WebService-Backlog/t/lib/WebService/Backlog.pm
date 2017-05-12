package WebService::Backlog;

# $Id: Backlog.pm 600 2008-05-09 13:48:50Z yamamoto $

use strict;
use 5.008001;

our $VERSION = '0.04';

use Carp;
use RPC::XML::Client;

use WebService::Backlog::Project;
use WebService::Backlog::Component;
use WebService::Backlog::Version;
use WebService::Backlog::User;
use WebService::Backlog::Issue;
use WebService::Backlog::FindCondition;

use WebService::Backlog::CreateIssue;
use WebService::Backlog::UpdateIssue;
use WebService::Backlog::SwitchStatus;

sub new {
    my ( $class, %args ) = @_;
    croak('space must be specified')    unless ( defined $args{space} );
    croak('username must be specified') unless ( defined $args{username} );
    croak('password must be specified') unless ( defined $args{password} );

    my $client = RPC::XML::Client->new(
        'https://' . $args{space} . '.backlog.jp/XML-RPC' );
    $client->credentials( 'Backlog Basic Authenticate',
        $args{username}, $args{password} );
    $client->useragent->parse_head(0);
    $client->useragent->env_proxy;
    $client->useragent->agent("WebService::Backlog/$VERSION");
    bless { %args, client => $client }, $class;
}

sub getProjects {
    my $self = shift;
    my $req  = RPC::XML::request->new( 'backlog.getProjects', );
    my $res  = $self->{client}->send_request($req);
    croak "Error backlog.getProjects : " . $res->value->{faultString}
      if ( $res->is_fault );

    my @projects = ();
    for my $project ( @{ $res->value } ) {
        push( @projects, WebService::Backlog::Project->new($project) );
    }
    return \@projects;
}

sub getProject {
    my ( $self, $keyOrId ) = @_;
    croak "key or projectId must be specified." unless ($keyOrId);
    my $req = RPC::XML::request->new( 'backlog.getProject', $keyOrId, );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.getProject : " . $res->value->{faultString}
      if ( $res->is_fault );
    return unless ( $res->value->{id} );
    return WebService::Backlog::Project->new( $res->value );
}

sub getComponents {
    my ( $self, $pid ) = @_;
    croak "projectId must be specified." unless ($pid);
    my $req = RPC::XML::request->new( 'backlog.getComponents', $pid, );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.getComponents : " . $res->value->{faultString}
      if ( $res->is_fault );
    my @components = ();
    for my $component ( @{ $res->value } ) {
        push( @components, WebService::Backlog::Component->new($component) );
    }
    return \@components;
}

sub getVersions {
    my ( $self, $pid ) = @_;
    croak "projectId must be specified." unless ($pid);
    my $req = RPC::XML::request->new( 'backlog.getVersions', $pid, );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.getVersions : " . $res->value->{faultString}
      if ( $res->is_fault );
    my @versions = ();
    for my $version ( @{ $res->value } ) {
        push( @versions, WebService::Backlog::Version->new($version) );
    }
    return \@versions;
}

sub getUsers {
    my ( $self, $pid ) = @_;
    croak "projectId must be specified." unless ($pid);
    my $req = RPC::XML::request->new( 'backlog.getUsers', $pid, );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.getUsers : " . $res->value->{faultString}
      if ( $res->is_fault );
    my @users = ();
    for my $user ( @{ $res->value } ) {
        push( @users, WebService::Backlog::User->new($user) );
    }
    return \@users;
}

sub getIssue {
    my ( $self, $keyOrId ) = @_;
    croak "key or issueId must be specified." unless ($keyOrId);
    my $req = RPC::XML::request->new( 'backlog.getIssue', $keyOrId, );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.getIssue : " . $res->value->{faultString}
      if ( $res->is_fault );
    return unless ( $res->value->{id} );
    return WebService::Backlog::Issue->new( $res->value );
}

sub getComments {
    my ( $self, $id ) = @_;
    croak "issueId must be specified." unless ($id);
    my $req = RPC::XML::request->new( 'backlog.getComments', $id, );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.getComments : " . $res->value->{faultString}
      if ( $res->is_fault );
    my @comments = ();
    for my $comment ( @{ $res->value } ) {
        push( @comments, WebService::Backlog::Comment->new($comment) );
    }
    return \@comments;
}

sub countIssue {
    my ( $self, $arg ) = @_;
    my $cond;

    if ( ref($arg) eq 'WebService::Backlog::FindCondition' ) {
        $cond = $arg->toCountCond;
    }
    elsif ( ref($arg) eq 'HASH' ) {
        $cond = WebService::Backlog::FindCondition->new($arg)->toCountCond;
    }
    else {
        croak(  'arg must be WebService::Backlog::FindCondition object'
              . ' or reference to hash. ['
              . ref($arg)
              . ']' );
    }
    croak("projectId must be specified.") unless ( $cond->{projectId} );

    my $req = RPC::XML::request->new( 'backlog.countIssue', $cond );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.countIssue : " . $res->value->{faultString}
      if ( $res->is_fault );

    return $res->value;
}

sub findIssue {
    my ( $self, $arg ) = @_;
    my $cond;

    if ( ref($arg) eq 'WebService::Backlog::FindCondition' ) {
        $cond = $arg->toFindCond;
    }
    elsif ( ref($arg) eq 'HASH' ) {
        $cond = WebService::Backlog::FindCondition->new($arg)->toFindCond;
    }
    else {
        croak(  'arg must be WebService::Backlog::FindCondition object'
              . ' or reference to hash. ['
              . ref($arg)
              . ']' );
    }
    croak("projectId must be specified.") unless ( $cond->{projectId} );

    my $req = RPC::XML::request->new( 'backlog.findIssue', $cond );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.findIssue : " . $res->value->{faultString}
      if ( $res->is_fault );

    my @issues = ();
    for my $issue ( @{ $res->value } ) {
        push( @issues, WebService::Backlog::Issue->new($issue) );
    }
    return \@issues;
}

sub createIssue {
    my ( $self, $arg ) = @_;
    my $issue;
    if ( ref($arg) eq 'WebService::Backlog::CreateIssue' ) {
        $issue = $arg;
    }
    elsif ( ref($arg) eq 'HASH' ) {
        $issue = WebService::Backlog::CreateIssue->new($arg);
    }
    else {
        croak(  'arg must be WebService::Backlog::CreateIssue object'
              . ' or reference to hash. ['
              . ref($arg)
              . ']' );
    }
    croak("projectId must be specified.") unless ( $issue->projectId );
    croak("summary must be specified.")   unless ( $issue->summary );

    my $req = RPC::XML::request->new( 'backlog.createIssue', $issue->hash );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.createIssue : " . $res->value->{faultString}
      if ( $res->is_fault );

    return WebService::Backlog::Issue->new( $res->value );
}

sub updateIssue {
    my ( $self, $arg ) = @_;
    my $issue;
    if ( ref($arg) eq 'WebService::Backlog::UpdateIssue' ) {
        $issue = $arg;
    }
    elsif ( ref($arg) eq 'HASH' ) {
        $issue = WebService::Backlog::UpdateIssue->new($arg);
    }
    else {
        croak(  'arg must be WebService::Backlog::UpdateIssue object'
              . ' or reference to hash. ['
              . ref($arg)
              . ']' );
    }
    croak("key must be specified.")     unless ( $issue->key );
    croak("summary must be specified.") unless ( $issue->summary );

    my $req = RPC::XML::request->new( 'backlog.updateIssue', $issue->hash );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.updateIssue : " . $res->value->{faultString}
      if ( $res->is_fault );

    return WebService::Backlog::Issue->new( $res->value );
}

sub switchStatus {
    my ( $self, $arg ) = @_;
    my $switch;
    if ( ref($arg) eq 'WebService::Backlog::SwitchStatus' ) {
        $switch = $arg;
    }
    elsif ( ref($arg) eq 'HASH' ) {
        $switch = WebService::Backlog::SwitchStatus->new($arg);
    }
    else {
        croak(  'arg must be WebService::Backlog::SwitchStatus object'
              . ' or reference to hash. ['
              . ref($arg)
              . ']' );
    }
    croak("key must be specified.")      unless ( $switch->key );
    croak("StatusId must be specified.") unless ( $switch->statusId );

    my $req = RPC::XML::request->new( 'backlog.switchStatus', $switch->hash );
    my $res = $self->{client}->send_request($req);
    croak "Error backlog.switchStatus : " . $res->value->{faultString}
      if ( $res->is_fault );

    return WebService::Backlog::Issue->new( $res->value );
}

1;
__END__

=head1 NAME

WebService::Backlog - Perl interface to Backlog.

=head1 SYNOPSIS

  use WebService::Backlog;
  my $backlog = WebService::Backlog->new(
    space    => 'yourspaceid',
    username => 'username',
    password => 'password'
  );

  # get your projects.
  my $projects  = $backlog->getProjects; # List of objects (WebService::Backlog::Project)
  for my $project (@{$project}) {
    print $project->name . "\n";
  }

  # get assigned issues.
  my $issues = $backlog->findIssue({
    projectId  => 1, # your project id.
    assignerId => 2, # your user id.
  });

  # and more ...

=head1 DESCRIPTION

WebService::Backlog provides interface to Backlog.
Backlog is a web based project collaboration tool.

For more information on Backlog, visit the Backlog website. http://www.backlog.jp/

=head1 METHODS

=head2 new

=head2 getProjects

=head2 getProject

=head2 getComponents

=head2 getVersions

=head2 getUsers

=head2 getIssue

=head2 getComments

=head2 countIssue

=head2 findIssue

=head2 createIssue

=head2 updateIssue

=head2 switchStatus


=head1 AUTHOR

Ryuzo Yamamoto E<lt>yamamoto@nulab.co.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Backlog : http://www.backlog.jp/
Backlog API : http://www.backlog.jp/api/

=cut

