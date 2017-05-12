package ZimbraManager;

use Mojo::Base 'Mojolicious';


use Mojo::Util qw(dumper);
use Mojo::JSON qw(decode_json encode_json);

use ZimbraManager::SOAP;
use ZimbraManager::SOAP::Friendly;

use HTTP::CookieJar::LWP;

our $VERSION = "0.15";


has 'soap' => sub {
    my $self = shift;
    return ZimbraManager::SOAP::Friendly->new(
        log => $self->log,
        mode => 'full',
        # soapDebug => '1',           # enables SOAP backend communication debugging
        # soapErrorsToConsumer => '1' # returns SOAP error to consumer
    );
};


has log => sub {
    my $self = shift;
    Mojo::Log->new(
        path  => $ENV{MOJO_LOG_FILE}  // '/dev/stderr',
        level => $ENV{MOJO_LOG_LEVEL} // 'debug',
    );
};


my $renderOutput = sub {
    my ($self, $ctrl, $ret, $err, $plain) = @_;
    my $text = $err ? $err : $ret;
    if ($err) {
        $ctrl->res->code(510);
    }
    if ($plain) {
        if (ref $text eq 'HASH') {
            $text = dumper $text;
        }
        $ctrl->render(text => "<pre>$text</pre>") if ($plain);
    }
    else {
        $ctrl->render(json => $text);
    }
};


my $buildAuthRequest = sub {
     my $user = shift;
     my $password = shift;
     return (
     'authRequest',
    { persistAuthTokenCookie => 1,
           password => $password,
            account =>  {
                 by => 'name',
                  _ => $user}}
    );
};


my $handleZimbraAuth = sub {
    my $self     = shift;
    my $ctrl     = shift;
    my $user     = shift;
    my $password = shift;
    my $ret;
    my $err;
    if ($ctrl->session('ZM_ADMIN_AUTH_TOKEN')) {
        $ret = 'true';
    }
    else {
        my ($action, $args) = $buildAuthRequest->($user,$password);
        ($ret, $err) = $self->soap->call({
            action    => $action,
            args      => $args,
            authToken => undef,
        });
        if (!$err) {
           my $token = $ret->{authToken};
           $ctrl->session('ZM_ADMIN_AUTH_TOKEN' => $token);
        }
        $self->log->debug(dumper("User Session",$ctrl->session));
    }
    $ret = { auth => 'Authentication sucessful!' } if ($ret);
    return ($ret, $err);
};


sub startup {
    my $self = shift;

    $self->secrets(['bb732c382ded15e58eb02bb0fe0e112e']);
    # session is valid for 1 day
    $self->sessions->default_expiration(1*24*3600);
    $self->sessions->cookie_name('zimbra-manager');

    my $r = $self->routes;

    # Special routing for authentication function for session handling
    $r->post('/auth' => sub {
        my $ctrl        = shift;
        my $perl_args   = decode_json($ctrl->req->body);
        my $user        = $perl_args->{'user'};
        my $password    = $perl_args->{'password'};
        my $plain       = $perl_args->{'plain'};
        my ($ret, $err) = $handleZimbraAuth->($self, $ctrl, $user, $password);
        $renderOutput->($self, $ctrl, $ret, $err, $plain);
    });
    $r->get('/auth' => sub {
        my $ctrl        = shift;
        my $user        = $ctrl->param('user');
        my $password    = $ctrl->param('password');
        my $plain       = $ctrl->param('plain');
        my ($ret, $err) = $handleZimbraAuth->($self, $ctrl, $user, $password);
        $renderOutput->($self, $ctrl, $ret, $err, $plain);
    });

    # Friendly calls to ZimbraManager with key / value parmeters
    $r->post('/friendly/:call' => sub {
        my $ctrl        = shift;
        my $action      = $ctrl->param('call');
        my $plain       = $ctrl->param('plain');
        my $perl_args   = decode_json($ctrl->req->body);
        my ($ret, $err) = $self->soap->callFriendly({
            action    => $action,
            args      => $perl_args,
            authToken => $ctrl->session('ZM_ADMIN_AUTH_TOKEN'),
        });
        $renderOutput->($self, $ctrl, $ret, $err, $plain);
    });
    $r->get('/friendly/:call' => sub {
        my $ctrl        = shift;
        my $action      = $ctrl->param('call');
        my $plain       = $ctrl->param('plain');
        my @param_names = $ctrl->param;
        my $params;
        for my $p (@param_names) {
            $params->{$p} = $ctrl->param($p) unless (($p eq 'action') or ($p eq 'plain'));
        }
        my ($ret, $err) = $self->soap->callFriendly({
            action    => $action,
            args      => $params,
            authToken => $ctrl->session('ZM_ADMIN_AUTH_TOKEN'),
        });
        $renderOutput->($self, $ctrl, $ret, $err, $plain);
    });

    # Handle direct SOAP calls with Zimbra SOAP Datastructure
    $r->post('/:call' => sub {
        my $ctrl        = shift;
        my $action      = $ctrl->param('call');
        my $plain       = $ctrl->param('plain');
        my $perl_args   = decode_json($ctrl->req->body);
        my ($ret, $err) = $self->soap->call({
            action     => $action,
            args       => $perl_args,
            authToken  => $ctrl->session('ZM_ADMIN_AUTH_TOKEN')
        });
        $renderOutput->($self, $ctrl, $ret, $err, $plain);
    });

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZimbraManager

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    use ZimbraManager;

    # Start commands
    Mojolicious::Commands->start_app('ZimbraManager');

=head1 NAME

ZimbraManager - A Mojolicious application to manage Zimbra with SOAP

=head1 ATTRIBUTES

=head2 soap

The ZimbraManager SOAP object

=head2 log

Mojo Log object

=head1 METHODS

All the methods of L<Mojo::Base> plus:

=head2 private functions

Private functions used in the startup function

=head3 renderOutput

Renders the Output in JSON or readable plain text

=head3 buildAuthRequest

Builds auth call for SOAP

=head3 handleZimbraAuth

Handle the authentication to Zimbra and store the Zimbra authentication
token to the Mojolicious session of the consumer. So the auth token will
be transparently taken to from consumer to the Zimbra end system.

=head2 startup

Calls Zimbra with the given argument and returns the SOAP response as perl hash.

=head1 COPYRIGHT

Copyright (c) 2014 by Roman Plessl. All rights reserved.

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see L<http://www.gnu.org/licenses/>.

=head1 AUTHOR

S<Roman Plessl E<lt>roman@plessl.infoE<gt>>

=head1 HISTORY

 2014-03-20 rp Initial Version
 2014-04-29 rp New API and added handling of sessions
 2014-05-07 rp Added new API with named parameters

=head1 AUTHOR

Roman Plessl <rplessl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Roman Plessl.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
