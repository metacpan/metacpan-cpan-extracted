package Zenoss::Router;
use strict;
use File::Find;
use File::Basename;
use JSON qw{};
use LWP::UserAgent;
use HTTP::Request::Common qw{POST};

use Moose;
use Moose::Util qw {apply_all_roles};
use Zenoss::Response;
with 'Zenoss::Error';

#**************************************************************************
# Constants
#**************************************************************************
our $JSON_CONTENT_TYPE;     *JSON_CONTENT_TYPE = \q{application/json; charset=utf-8};

#**************************************************************************
# Public Attributes
#**************************************************************************
has 'connector' => (
    is              => 'ro',
    isa             => 'Zenoss::Connector',
    required        => 1,
);

#**************************************************************************
# Private Attributes
#**************************************************************************
has '_agent' => (
    is              => 'ro',
    isa             => 'LWP::UserAgent',
    builder         => '_build_agent',
    lazy            => 1,
    init_arg        => undef,
);

has '_is_authenticated' => (
    is              => 'rw',
    isa             => 'Bool',
    default         => 0,
);

has '_transaction_count' => (
    traits          => ['Counter'],
    is              => 'ro',
    isa             => 'Num',
    default         => 0,
    handles         => {
        _increase_transaction_count     => 'inc',
    },
);

#**************************************************************************
# Private methods
#**************************************************************************
#======================================================================
# BUILD
#======================================================================
sub BUILD {
    my $self = shift;

    # API Router location
    (my $search_path = __PACKAGE__) =~ s!::!/!g;

    # Search for available API routers
    my %router;
    my @INC_LOCAL = @INC;
    foreach my $search_dir (@INC_LOCAL) {
        $search_dir .= q{/} . $search_path;
        next if (!-d $search_dir);

        File::Find::find(
            {
                no_chdir    => 1,
                wanted      => sub {
                    return unless $File::Find::name =~ /\.pm$/;
                    (my $path = $File::Find::name) =~ s!^\\./!!;
                    my ($filename,undef, $suffix) = fileparse($path, '.pm');

                    # Storing in a hash will allow for de-duplication
                    $router{$filename} = 1 unless $filename eq 'Tree';
                },
            },
            $search_dir,
        );
    }

    # Build the FQ Router API list
    my @router_install;
    foreach (keys %router) {
        push(@router_install, "Zenoss::Router::$_");
    }

    # Install role via META
    apply_all_roles($self, @router_install);
} # END BUILD

#======================================================================
# _router_request
#======================================================================
sub _router_request {
    my ($self, $args) = @_;
    my $zenoss_url = $self->connector->endpoint;

    # Login if not already logged in
    if (!$self->_is_authenticated) {
        $self->_process_login;
    }

    # Increase the transaction counter
    $self->_increase_transaction_count;

    # Build JSON request in HASHREF
    my $JSON_DATA = {
        action  => $args->{'action'},
        method  => $args->{'method'},
        data    => $args->{'data'},
        type    => 'rpc',
        tid     => $self->_transaction_count,
    };

    # Setup query
    my $query = HTTP::Request->new(POST => "$zenoss_url/$args->{'location'}");
    my $json_encoder = JSON->new->allow_nonref;
    $query->content_type($JSON_CONTENT_TYPE);
    $query->content($json_encoder->encode($JSON_DATA));

    # Return Zenoss::Response object
    my (undef, undef, undef, $hints, undef, undef) = caller(1);
    return Zenoss::Response->new(
        {
            handler             => $self->_agent->request($query),
            sent_tid            => $self->_transaction_count,
            _caller             => $hints,
        }
    )->_validate_api_method_exists();
} # END _router_request

#======================================================================
# _check_args
#======================================================================
sub _check_args {
    my ($self, $args, $definition) = @_;
    my (undef, undef, undef, $hints, undef, undef) = caller(1);

    # Methods require HASH as argument
    unless (!defined($args) or ref($args) eq 'HASH') {
            $self->_croak("[$hints] requires [HASH] as an argument");
    }

    # Check to see if $definition provides any defaults
    # If so and we dont have the key set, merge the default in
    if (exists($definition->{'defaults'})) {
        foreach my $param (keys %{$definition->{'defaults'}}) {
            if (!exists($args->{$param})) {
                $args->{$param} = $definition->{'defaults'}{$param};
            }
        }
    }

    # Check for required parameters
    if (exists($definition->{'required'})) {
        foreach my $requirement (@{$definition->{'required'}}) {
            if (!grep { $_ eq $requirement } keys %{$args}) {
                $self->_croak("[$hints] requires [$requirement] as a provided parameter");
            }
        }
    }

    # NOTE, this method doesnt need to return specific as modifications
    # to $args are done via reference.  $args is a pointer to the original
    # memory space, thus not its own unique entity.
    return $self;
} # END _check_args

#======================================================================
# _build_agent
#======================================================================
sub _build_agent {
    my $self = shift;

    # Setup the User Agent
    my $ua = LWP::UserAgent->new;

    # Enable cookies
    $ua->cookie_jar({});

    # Timeout
    $ua->timeout($self->connector->timeout);

    return $ua;
} # END _build_agent

#======================================================================
# _process_login
#======================================================================
sub _process_login {
    my $self = shift;
    my $zenoss_url = $self->connector->endpoint;

    # Format the LOGIN request
    # application/x-www-form-urlencoded
    my $login_request = POST "$zenoss_url/zport/acl_users/cookieAuthHelper/login",
                        [
                        __ac_name       => $self->connector->username,
                        __ac_password   => $self->connector->password,
                        submitted       => 'true',
                        came_from       => "$zenoss_url/zport/dmd",
                        ];

    # Login
    $self->_agent->request($login_request);

    # Setup the test query
    my $query = HTTP::Request->new(POST => "$zenoss_url/zport/dmd/");
    $query->content_type('application/json; charset=utf-8');

    # Process the test query
    my $response = $self->_agent->request($query);
    if ($response->is_success && $response->code == 200) {
        # Set internal attribute confirming authentication
        $self->_is_authenticated(1);
    } else {
        # Bomb out
        $self->_croak("Unable to login to Zenoss with provided credentials");
    }
} # END _process_login

#**************************************************************************
# Package end
#**************************************************************************
__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

Zenoss::Router - Internal module that does the processing of sending and/or receiving Zenoss API calls

=head1 DESCRIPTION

B<This is not for public consumption.>

In brief, this module processes requests to the Zensos API and returns a Zenoss::Response object.
However, all this is considered internal and would be called by one of the higher level modules - such as
L<Zenoss>.

=head1 SEE ALSO

=over

=item *

L<Zenoss>

=back

=head1 AUTHOR

Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Patrick Baker E<lt>patricksbaker@gmail.comE<gt>

This module is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You can obtain the Artistic License 2.0 by either viewing the
LICENSE file provided with this distribution or by navigating
to L<http://opensource.org/licenses/artistic-license-2.0.php>.

=cut