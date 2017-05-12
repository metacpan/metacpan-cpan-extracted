package YAWF::Session;

=pod

=head1 NAME

YAWF::Session - Session management for web users

=head1 SYNOPSIS

  my $object = YAWF::Session->new(
        query         => $CGI->Vars,
        cookies       => \%Cookies,
  );
  
=head1 DESCRIPTION

Object for web user sessions

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use Apache::Session::SharedMem;

use YAWF;

our $VERSION = '0.01';

=pod

=head2 new

  my $object = YAWF::Session->new(
        query         => $CGI->Vars,
        cookies       => \%Cookies,
  );

The C<new> constructor lets you create a new B<YAWF::Session> object.

So no big surprises there...

Returns a new B<YAWF::Session> or dies on error.

=cut

sub new {
    my $class = shift;

    my %args = @_;

    my $id = $args{query}->{SID};
    $id =~ s/\x00.*$// if defined($id);    # Remove double-transmitted SIDs

    $id ||=
         $args{cookies}->{sessionid}
      || $args{cookies}->{phpsessionid}
      || $args{cookies}->{aspsessionid}
      if YAWF->SINGLETON->config->session->{cookie};

    return undef unless defined($id) or $args{create};

    my %Session;
    for ( 1 .. 2 ) {
        eval {
            tie %Session, 'Apache::Session::SharedMem', $id,
              { expires_in =>
                  ( YAWF->SINGLETON->config->session->{timeout} || 21600 ) };
        };
        last if $@ eq '';
        $id = '';    # Retry and create a new session
    }
    if ( defined( $Session{'Last_Action'} )
        and ( $Session{'Last_Action'} < ( time - 21600 ) ) )
    {

        # Session expired, clean content but keep SessionID:
        %Session = ( '_session_id' => $Session{'_session_id'} );
    }
    $id                     = $Session{'_session_id'};
    $Session{id}            = $id;
    $Session{'Last_Action'} = time;
    $Session{___SESSION_HASH_REFERENCE___} = \%Session;   # required for tied()!

    my $self = bless \%Session, $class;

    if ( YAWF->SINGLETON->config->session->{cookie} ) {

        for my $name ( 'sessionid', 'phpsessionid', 'aspsessionid' ) {
            YAWF->SINGLETON->reply->cookie(
                -name    => $name,
                -value   => $Session{id},
                -expires => '+365d',
                -domain  => YAWF->SINGLETON->config->session->{cookiedomain} || 'auto',
                -path    => '/'
            );
        }

    }

    return $self;
}

=pod

=head2 save

Flush the current unsaved session data to storage.

=cut

sub save {
    my $self = shift;

    return unless ref($self);

    my $ref = $self->{___SESSION_HASH_REFERENCE___};
    delete $self->{___SESSION_HASH_REFERENCE___};

    tied( %{$ref} )->save;

    $self->{___SESSION_HASH_REFERENCE___} = $ref;
}

=pod

=head2 login

Mark the current session as logged in.

=cut

sub login {
    my $self = shift;

    $self->{loggedin} = 1;

    return 1;
}

=pod

=head2 logout

Mark the current session as logged out.

=cut

sub logout {
    my $self = shift;

    $self->{loggedin} = 0;

    return 1;
}

=pod

=head2 reset

Clears the current session-id and creates a new session object without clearing the data of
the current sesssion-id.

=cut

sub reset {
    my $self = shift;

    YAWF->SINGLETON->{session} = ref($self)->new(create => 1);

    return 1;
}

=pod

=head2 capcha

Returns a short HTML code for a capcha images and stores the code in $self->{capcha}.

The capcha code is unaccessible from Template::Toolkit (which would prefer the method call).

=cut

sub capcha {
    my $self = shift;
    my %args = @_;

    delete $args{length} if defined($args{length}) and ($args{length} < 6);
    $self->{capcha} = join('',map { substr("ABCDEFGHJKLMNPQRSTUVWXYZ23456789",int(rand(33)),1)} (1..($args{length} || 6+int(rand(3)))));
    
    return '<img src="/capcha/'.$self->{id}.'/'.($args{width} || 250).'/'.($args{height} || 75).'/'.time.$$.int(rand(2**31)).'" '.
           'border="0">';

    return 1;
}

sub DESTROY {
    my $self = shift;

    delete $self->{___SESSION_HASH_REFERENCE___} if defined($self);

    untie %{$self};

}

1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2010 Sebastian Willing.

=cut
