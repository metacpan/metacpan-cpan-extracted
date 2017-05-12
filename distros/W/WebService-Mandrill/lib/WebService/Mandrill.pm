package WebService::Mandrill;

use Modern::Perl;
use Mouse;

# ABSTRACT: WebService::Mandrill - an interface to mandrillapp.com's RESTful Web API using Web::API

our $VERSION = '0.8'; # VERSION

with 'Web::API';


has 'commands' => (
    is      => 'rw',
    default => sub {
        {
            # ping
            ping => { path => 'users/ping2' },

            # user
            user_info    => { path => 'users/info' },
            user_senders => { path => 'users/senders' },

            # message commands
            send => {
                path      => 'messages/send',
                mandatory => [ 'subject', 'from_email', 'to' ],
                wrapper   => 'message',
            },
            send_raw => {
                path      => 'messages/send-raw',
                mandatory => ['raw_message'],
            },
            send_template => {
                path      => 'messages/send-template',
                mandatory => [ 'template_name', 'template_content', 'message' ],
            },
            parse => {
                path      => 'messages/parse',
                mandatory => ['raw_message'],
            },
            search           => { path => 'messages/search' },
            list_scheduled   => { path => 'messages/list-scheduled' },
            cancel_scheduled => {
                path      => 'messages/cancel-scheduled',
                mandatory => ['id'],
            },
            reschedule => {
                path      => 'messages/reschedule',
                mandatory => [ 'id', 'send_at' ],
            },

            # tags
            tags => { path => 'tags/list' },
            tag  => {
                path      => 'tags/info',
                mandatory => ['tag'],
            },
            delete_tag => {
                path      => 'tags/delete',
                mandatory => ['tag'],
            },
            tag_history => {
                path      => 'tags/time-series',
                mandatory => ['tag'],
            },
            all_tag_history => {
                path      => 'tags/all-time-series',
                mandatory => ['tag'],
            },

            # rejects
            rejects       => { path => 'rejects/list' },
            delete_reject => {
                path      => 'rejects/delete',
                mandatory => ['email']
            },

            # senders
            senders        => { path => 'senders/list' },
            sender_domains => { path => 'senders/domains' },
            sender         => {
                path      => 'senders/info',
                mandatory => ['address'],
            },
            sender_history => {
                path      => 'senders/time-series',
                mandatory => ['address'],
            },

            # urls
            urls        => { path => 'urls/list' },
            search_urls => {
                path      => 'urls/search',
                mandatory => ['q'],
            },
            url_history => {
                path      => 'urls/time-series',
                mandatory => ['url'],
            },

            # webhooks
            webhooks => { path => 'webhooks/list' },
            webhook  => {
                path      => 'webhooks/info',
                mandatory => ['id'],
            },
            add_webhook => {
                path      => 'webhooks/add',
                mandatory => ['url'],
            },
            update_webhook => {
                path      => 'webhooks/update',
                mandatory => [ 'id', 'url' ],
            },
            delete_webhook => {
                path      => 'webhooks/delete',
                mandatory => ['id'],
            },

            # inbounds
            inbound_domains => { path => 'inbound/domains' },
            inbound_routes  => {
                path      => 'inbound/routes',
                mandatory => ['domain'],
            },
            inbound_raw => {
                path      => 'inbound/send-raw',
                mandatory => ['raw_message'],
            },

            # templates
            templates    => { path => 'templates/list' },
            add_template => {
                path      => 'templates/add',
                mandatory => ['name'],
            },
            get_template => {
                path      => 'templates/info',
                mandatory => ['name'],
            },
            update_template => {
                path      => 'templates/update',
                mandatory => ['name'],
            },
            publish_template => {
                path      => 'templates/publish',
                mandatory => ['name'],
            },
            delete_template => {
                path      => 'templates/delete',
                mandatory => ['name'],
            },
            time_series_template => {
                path      => 'templates/time-series',
                mandatory => ['name'],
            },
            render_template => {
                path      => 'templates/render',
                mandatory => ['name'],
            },

            # exports
            exports    => { path => 'exports/list' },
            get_export => {
                path      => 'exports/info',
                mandatory => ['id'],
            },
            export_rejects   => { path => 'exports/rejects' },
            export_whitelist => { path => 'exports/whitelist' },
            export_activity  => { path => 'exports/activity' },
        };
    },
);


sub commands {
    my ($self) = @_;
    return $self->commands;
}


sub BUILD {
    my ($self) = @_;

    $self->user_agent(__PACKAGE__ . ' ' . $WebService::Mandrill::VERSION);
    $self->strict_ssl(1);
    $self->content_type('application/json');
    $self->default_method('POST');
    $self->extension('json');
    $self->base_url('https://mandrillapp.com/api/1.0');
    $self->auth_type('hash_key');
    $self->error_keys(['message']);

    return $self;
}


1;    # End of WebService::Mandrill

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Mandrill - WebService::Mandrill - an interface to mandrillapp.com's RESTful Web API using Web::API

=head1 VERSION

version 0.8

=head1 SYNOPSIS

Please refer to the API documentation at L<http://mandrillapp.com/api/docs/index.html>

    use WebService::Mandrill;
    
    my $mandrill = WebService::Mandrill->new(
        debug   => 1,
        api_key => '12345678-9abc-def0-1234-56789abcdef0',
    );
    
    my $response = $mandrill->send(
        subject      => "h4x0r",
        from_email   => "mail@example.com",
        text         => "what zee fug",
        track_opens  => 1,
        track_clicks => 1,
        to => [
            { email => 'mail@example.com' }
        ],
    );

=head1 SUBROUTINES/METHODS

=head2 ping

=head2 user_info

=head2 user_senders

=head2 send

=head2 send_template

=head2 send_raw

=head2 list_scheduled

=head2 cancel_scheduled

=head2 reschedule

=head2 parse

=head2 search

=head2 tags

=head2 tag

=head2 delete_tag

=head2 tag_history

=head2 all_tag_history

=head2 rejects

=head2 delete_reject

=head2 senders

=head2 sender

=head2 sender_domains

=head2 sender_history

=head2 urls

=head2 search_urls

=head2 url_history

=head2 webhooks

=head2 webhook

=head2 add_webhook

=head2 update_webhook

=head2 delete_webhook

=head2 inbound_domains

=head2 inbound_routes

=head2 inbound_raw

=head2 templates

=head2 add_template

=head2 get_template

=head2 update_template

=head2 publish_template

=head2 delete_template

=head2 render_template

=head2 exports

=head2 get_export

=head2 export_rejects

=head2 export_whitelist

=head2 export_activity

=head1 INTERNALS

=head2 BUILD

basic configuration for the client API happens usually in the BUILD method when using Web::API

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/nupfel/WebService-Mandrill/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Mandrill

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/nupfel/WebService-Mandrill>

=item * MetaCPAN

L<https://metacpan.org/module/WebService::Mandrill>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService::Mandrill>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService::Mandrill>

=back

=head1 AUTHOR

Tobias Kirschstein <lev@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Tobias Kirschstein.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
