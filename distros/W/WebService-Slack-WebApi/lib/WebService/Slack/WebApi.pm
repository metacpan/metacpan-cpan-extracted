package WebService::Slack::WebApi;
use strict;
use warnings;
use utf8;

use Class::Load qw/ load_class /;
use Class::Accessor::Lite::Lazy (
    new     => 1,
    rw      => [qw/ team_domain token opt /],
    ro_lazy => [qw/ client api auth channels chat emoji files groups im oauth pins reactions rtm search stars team users /],
);

use WebService::Slack::WebApi::Client;

our $VERSION = '0.09';

sub _build_client {
    my $self = shift;
    return WebService::Slack::WebApi::Client->new(
        team_domain => $self->team_domain,
        token       => $self->token,
        opt         => $self->opt,
    );
}

for my $class_name (qw/ api auth channels chat emoji files groups im oauth pins reactions rtm search stars team users /) {
    my $method = sprintf '%s::_build_%s', __PACKAGE__, $class_name;
    my $class  = sprintf '%s::%s', __PACKAGE__, ucfirst($class_name);

    no strict 'refs';
    *$method = sub {
        load_class $class;
        return $class->new(client => shift->client)
    };
}

1;

__END__
=pod

=head1 NAME

WebService::Slack::WebApi - a simple wrapper for Slack Web API

=head1 SYNOPSIS

    use WebService::Slack::WebApi;

    # the token is required unless using $slack->oauth->access
    my $slack = WebService::Slack::WebApi->new(token => 'access token');

    # getting channel's descriptions
    my $channels = $slack->channels->list;

    # posting message to specified channel and getting message description
    my $posted_message = $slack->chat->post_message(
        channel  => 'channel id', # required
        text     => 'hoge',       # required (not required if 'attachments' argument exists)
        username => 'fuga',       # optional
        # other optional parameters...
    );

=head1 DESCRIPTION

WebService::Slack::WebApi is a simple wrapper for Slack Web API (https://api.slack.com/web).

=head1 Options

You can set some options by giving C<opt> parameter to C<new> method.
Almost values of C<opt> are gived to C<Furl#new>.

    WebService::Slack::WebApi->new(token => 'access token', opt => {});

=head2 Proxy

C<opt> can contain C<env_proxy> as boolean value .
If C<env_proxy> is true then proxy settings are loaded from C<$ENV{HTTP_PROXY}> and C<$ENV{NO_PROXY}> by calling C<Furl#env_proxy> method.
See also https://metacpan.org/pod/Furl#furl-env_proxy.

=head1 METHODS

This module provides all methods declared in the API reference (https://api.slack.com/methods).

=head2 Basis

C<WebService::Slack::WebApi::Namespace::method_name> corresponds to C<namespace.methodName> in Slack Web API.
For example C<WebService::Slack::WebApi::Chat::post_message> corresponds to C<chat.postMessage>.
You describe as below to call C<Chat::post_message> method.

    my $result = $slack->chat->post_message;

=head2 Return value

All methods return HashRef.
When you want to know what is contained in HashRef, see the API reference.

=head2 The token parameter

The API reference shows C<chat.update> method require 4 parameters: C<token>, C<ts>, C<channel> and C<text>.
When using this module C<token> parameter is added implicitly except using C<oauth.access> method.
So you pass the other 3 parameters to C<Chat::update> method as shown below.

    my $result = $slack->chat->update(
        ts      => '1401383885.000061',  # as Str
        channel => 'channel id',
        text    => 'hoge',
    );

=head2 Optional parameters

Some methods have optional parameters.
If a parameter is optional in the API reference, it is also optional in this module.

=head2 Not primitive parameters

These parameters are not primitive:

=over

=item C<files.upload.file>: string of path to local file

=item C<files.upload.channels>: ArrayRef of channel id string

=back

=head1 SEE ALSO

=over

=item https://api.slack.com/web

=item https://api.slack.com/methods

=back

=head1 AUTHOR

Mihyaeru/mihyaeru21 E<lt>mihyaeru21@gmail.comE<gt>

=head1 LICENSE

Copyright (C) Mihyaeru/mihyaeru21

Released under the MIT license.

See C<LICENSE> file.

=cut

