package YAWF::Handler;

=pod

=head1 NAME

YAWF::Handler - Default object for unconfigured domains

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

=pod

=head2 new

Called by YAWF::Request.

        WEB_METHODS => {	# methods allowed for web calls
		index => 1,
		},
        SESSION     => 0,	# Does this module require a session?
        LOGIN       => 0,	# Is this module restricted to users who have logged in?

Returns a new B<YAWF::Handler> or dies on error.

=cut

sub new {
    my $class = shift;

    my $self = bless {
        WEB_METHODS => {
            index => 1,
        },
        SESSION => 0,
        LOGIN   => 0,
        @_
    }, $class;

    return $self;
}

sub index {
    my $self = shift;

    $self->{yawf}->reply->template('error404');

    return 1;
}

1;

=pod

=head1 AUTHOR

Copyright 2010 Sebastian Willing.

=cut
