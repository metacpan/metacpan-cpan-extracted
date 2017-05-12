package YAWF::Reply;

=pod

=head1 NAME

YAWF::Reply - Reply object for a YAWF request

=head1 SYNOPSIS

  $object->dummy;

=head1 DESCRIPTION

Created during YAWF request init, holds all reply information.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use CGI::Cookie;

use Class::XSAccessor accessors => {
    yawf     => 'yawf',
    headers  => 'headers',
    template => 'template',
    data     => 'data',
    content  => 'content',
    content_fh => 'content_fh',
    redir => 'redir',
};

our $VERSION = '0.01';

=pod

=head2 new

The reply object is part of a YAWF request and created during YAWF init.

=cut

sub new {
    my $class = shift;

    my $self = bless {@_}, $class;

    # Prepare a basic data container
    $self->{data} ||= { yawf => $self->yawf };

    # Set some defaults
    $self->{headers} ||= {
        Status         => 200,
        'Content-type' => 'text/html'
    };

    return $self;
}

sub status {
    my $self = shift;

    $self->headers->{Status} = shift if $#_ > -1;

    return $self->headers->{Status};
}

=pod

=head2 cookie

  cookie(-name    => 'foo',
         -value   => 'bar',
         -expires => '+3d',
         -domain  => 'foo.bar.com',
         -path    => '/foo');

Add a cookie to the current HTTP reply

=cut

sub cookie {
    my $self = shift;
    my %args = @_;

    if (defined($args{'-domain'}) and ( $args{'-domain'} eq 'auto' )) {
        if ( $self->yawf->request->domain =~
            /^[012]?\d{1,2}\.[012]?\d{1,2}\.[012]?\d{1,2}\.[012]?\d{1,2}$/ )
        { # IP
            $args{'-domain'} = $self->yawf->request->domain;
        }
        elsif ( $self->yawf->request->domain =~
            /\.([a-z0-9\-]+\.[a-z0-9\-]+)$/i )
        {
            $args{'-domain'} = $1;
        }
        elsif ( $self->yawf->config->domain =~
            /^[012]?\d{1,2}\.[012]?\d{1,2}\.[012]?\d{1,2}\.[012]?\d{1,2}$/ )
        { # IP
            $args{'-domain'} = $self->yawf->config->domain;
        }
        elsif ( $self->yawf->config->domain =~
            /\.([a-z0-9\-]+\.[a-z0-9\-]+)$/i )
        {
            $args{'-domain'} = $1;
        }
        else {
            $args{'-domain'} = $self->yawf->request->domain
              || $self->yawf->config->domain;
        }
    }

    $self->header('Set-Cookie',CGI::Cookie->new(%args)->as_string);
}

=pod

=head2 header

  $reply->header('x-name','value');

Add the specified header to the reply (doesn't overwrite an existing header of this name).

=cut

sub header {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    
    if (defined($self->{headers}->{$key})) {
        $self->{headers}->{$key} = [$self->{headers}->{$key}] unless ref($self->{headers}->{$key}) eq 'ARRAY';
        push @{$self->{headers}->{$key}},$value;
    } else {
        $self->{headers}->{$key} = $value;
    }

    return 1;
}

1;

=pod

=head1 SUPPORT

See YAWF

=head1 AUTHOR

Copyright 2010 Sebastian Willing.

=cut
