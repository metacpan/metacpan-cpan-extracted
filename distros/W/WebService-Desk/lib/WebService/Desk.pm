package WebService::Desk;

use 5.010;
use Mouse;

# ABSTRACT: WebService::Desk - an interface to desk.com's RESTful Web API using Web::API

our $VERSION = '0.6'; # VERSION

with 'Web::API';


has 'commands' => (
    is      => 'rw',
    default => sub {
        {
            # articles
            articles       => {},
            article        => { path => 'articles/:id' },
            create_article => { path => 'articles', method => 'POST' },
            update_article => {
                path    => 'articles/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },
            delete_article => { path => 'articles/:id', method => 'DELETE' },
            search_article => {
                path      => 'articles/search',
                mandatory => ['text'],
                optional  => ['topic_ids']
            },
            article_translations => { path => 'articles/:id/translations' },
            article_translation =>
                { path => 'articles/:id/translations/:locale' },
            create_article_translation => {
                path      => 'articles/:id/translations',
                method    => 'POST',
                mandatory => [ 'locale', 'subject' ]
            },
            update_article_translation => {
                path    => 'articles/:id/translations/:locale',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },

            # cases
            cases       => {},
            case        => { path => 'cases/:id' },
            search_case => { path => 'cases/search' },
            create_case =>
                { path => 'cases', method => 'POST', mandatory => ['message'] },
            update_case => {
                path    => 'cases/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },
            history      => { path => 'cases/:id/history' },
            message      => { path => 'cases/:id/message' },
            replies      => { path => 'cases/:id/replies' },
            reply        => { path => 'cases/:case_id/replies/:id' },
            create_reply => {
                path      => 'cases/:case_id/replies',
                method    => 'POST',
                mandatory => ['body'],
            },
            update_reply => {
                path    => 'cases/:case_id/replies/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },
            notes       => { path => 'cases/:case_id/notes' },
            note        => { path => 'cases/:case_id/notes/:id' },
            create_note => {
                path      => 'cases/:case_id/notes',
                method    => 'POST',
                mandatory => ['body'],
            },
            attachments => { path => 'cases/:case_id/attachments' },
            message_attachments =>
                { path => 'cases/:case_id/message/attachments' },
            reply_attachments =>
                { path => 'cases/:case_id/replies/:id/attachments' },
            attachment => { path => 'cases/:case_id/attachments/:id' },
            message_attachment =>
                { path => 'cases/:case_id/message/attachments/:id' },
            reply_attachment =>
                { path => 'cases/:case_id/replies/:reply_id/attachments/:id' },
            create_attachment =>
                { path => 'cases/:case_id/attachments', method => 'POST' },
            create_message_attachment => {
                path   => 'cases/:case_id/message/attachments',
                method => 'POST',
            },
            create_reply_attachment => {
                path   => 'cases/:case_id/replies/:reply_id/attachments',
                method => 'POST',
            },
            delete_attachment => {
                path   => 'cases/:case_id/attachments/:id',
                method => 'DELETE',
            },
            delete_message_attachment => {
                path   => 'cases/:case_id/message/attachments/:id',
                method => 'DELETE',
            },
            delete_reply_attachment => {
                path   => 'cases/:case_id/replies/:reply_id/attachments/:id',
                method => 'DELETE',
            },

            # companies
            companies      => {},
            company        => { path => 'companies/:id' },
            create_company => {
                path      => 'companies',
                method    => 'POST',
                mandatory => ['name']
            },
            update_company => {
                path    => 'companies/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },

            # custom fields
            custom_fields => {},
            custom_field  => { path => 'custom_fields/:id' },

            # customers
            customers       => {},
            customer        => { path => 'customers/:id' },
            search_customer => { path => 'customers/search' },
            create_customer => { path => 'customers', method => 'POST' },
            update_customer => {
                path    => 'customers/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },

            # filters
            filters      => {},
            filter       => { path => 'filters/:id' },
            filter_cases => { path => 'filters/:id/cases' },

            # groups
            groups        => {},
            group         => { path => 'groups/:id' },
            group_filters => { path => 'groups/:id/filters' },
            group_users   => { path => 'groups/:id/users' },

            # inbound mailboxes
            mailboxes => { path => 'mailboxes/inbound' },
            mailbox   => { path => 'mailboxes/inbound/:id' },

            # insights
            insight_meta  => { path => 'insights/meta' },
            create_report => { path => 'insights/report', method => 'POST' },

            # integration URLS
            integration_urls => {},
            integration_url  => { path => 'integration_urls/:id' },
            create_integration_url =>
                { path => 'integration_urls', method => 'POST' },
            update_integration_url => {
                path    => 'integration_urls/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },
            delete_integration_url =>
                { path => 'integration_urls/:id', method => 'DELETE' },

            # jobs
            jobs       => {},
            job        => { path => 'jobs/:id' },
            create_job => { path => 'jobs', method => 'POST' },

            # labels
            labels => {},
            label  => { path => 'labels/:id' },
            create_label =>
                { path => 'labels', method => 'POST', mandatory => ['name'] },
            update_label => { path => 'labels/:id' },
            delete_label => {
                path    => 'labels/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },

            # macros
            macros       => {},
            macro        => { path => 'macros/:id' },
            create_macro => { path => 'macros', method => 'POST' },
            update_macro => {
                path    => 'macros/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },
            delete_macro => { path => 'macros/:id', method => 'DELETE' },
            actions       => { path => 'macros/:macro_id/actions' },
            action        => { path => 'macros/:macro_id/actions/:id' },
            update_action => {
                path    => 'macros/:macro_id/actions/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },

            # rules
            rules => {},
            rule  => { path => 'rules/:id' },

            # site settings
            site_settings => {},
            site_setting  => { path => 'site_settings/:id' },

            # system message
            system_message => {},

            # topics
            topics => {},
            topic  => { path => 'topics/:id' },
            create_topic =>
                { path => 'topics', method => 'POST', mandatory => ['name'] },
            update_topic => {
                path    => 'topics/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },
            delete_topic => { path => 'topics/:id', method => 'DELETE' },
            topic_translations => { path => 'topics/:id/translations' },
            topic_translation  => { path => 'topics/:id/translations/:locale' },
            create_topic_translation => {
                path      => 'topics/:id/translations',
                method    => 'POST',
                mandatory => ['locale']
            },
            update_topic_translation => {
                path    => 'topics/:id/translations/:locale',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },
            delete_topic_translation => {
                path   => 'topics/:id/translations/:locale',
                method => 'DELETE'
            },

            # twitter
            twitter_accounts => {},
            twitter_account  => { path => 'twitter_accounts/:id' },
            tweets           => { path => 'twitter_accounts/:id/tweets' },
            tweet => { path => 'twitter_accounts/:account_id/tweets/:id' },
            create_tweet => {
                path      => 'twitter_accounts/:id/tweets',
                method    => 'POST',
                mandatory => ['body']
            },

            # users
            users            => {},
            user             => { path => 'users/:id' },
            user_preferences => { path => 'users/:id/preferences' },
            user_preference  => { path => 'users/:user_id/preferences/:id' },
            update_user_preference => {
                path    => 'users/:user_id/preferences/:id',
                method  => 'POST',
                headers => { 'X-HTTP-Method-Override' => 'PATCH' },
            },
        };
    },
);


sub commands {
    my ($self) = @_;
    return $self->commands;
}


sub BUILD {
    my ($self) = @_;

    $self->user_agent(__PACKAGE__ . ' ' . $WebService::Desk::VERSION);
    $self->content_type('application/json');
    $self->base_url('https://' . $self->user . '.desk.com/api/v2');
    $self->auth_type('oauth_header');
    $self->oauth_post_body(0);
    $self->error_keys(['message']);

    return $self;
}


1;    # End of WebService::Desk

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Desk - WebService::Desk - an interface to desk.com's RESTful Web API using Web::API

=head1 VERSION

version 0.6

=head1 SYNOPSIS

Please refer to the API documentation at L<http://dev.desk.com/docs/api>

    use WebService::Desk;
    
    my $desk = WebService::Desk->new(
        debug   => 1,
        api_key => '12345678-9abc-def0-1234-56789abcdef0',
    );
    
    my $response = $desk->create_interaction(
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

=head2 article

=head2 articles

=head2 create_article

=head2 update_article

=head2 delete_article

=head2 search_article

=head2 article_translations

=head2 article_translation

=head2 create_article_translation

=head2 update_article_translation

=head2 cases

=head2 case

=head2 search_case

=head2 create_case

=head2 update_case

=head2 history

=head2 message

=head2 replies

=head2 reply

=head2 create_reply

=head2 update_reply

=head2 notes

=head2 note

=head2 create_note

=head2 attachments

=head2 attachment

=head2 message_attachment

=head2 reply_attachment

=head2 create_attachment

=head2 create_message_attachment

=head2 create_reply_attachment

=head2 delete_attachment

=head2 delete_message_attachment

=head2 delete_reply_attachment

=head2 companies

=head2 company

=head2 create_company

=head2 update_company

=head2 custom_fields

=head2 custom_field

=head2 customers

=head2 customer

=head2 search_customer

=head2 create_customer

=head2 update_customer

=head2 filters

=head2 filter

=head2 filter_cases

=head2 groups

=head2 group

=head2 group_filters

=head2 group_users

=head2 mailboxes

=head2 mailbox

=head2 insight_meta

=head2 create_report

=head2 integration_urls

=head2 integration_url

=head2 create_integration_url

=head2 update_integration_url

=head2 delete_integration_url

=head2 jobs

=head2 job

=head2 create_job

=head2 labels

=head2 label

=head2 create_label

=head2 update_label

=head2 delete_label

=head2 macros

=head2 macro

=head2 create_macro

=head2 update_macro

=head2 delete_macro

=head2 actions

=head2 action

=head2 update_action

=head2 rules

=head2 rule

=head2 site_settings

=head2 site_setting

=head2 system_message

=head2 topics

=head2 topic

=head2 create_topic

=head2 update_topic

=head2 delete_topic

=head2 topic_translations

=head2 topic_translation

=head2 create_topic_translation

=head2 update_topic_translation

=head2 delete_topic_translation

=head2 twitter_accounts

=head2 twitter_account

=head2 tweets

=head2 tweet

=head2 create_tweet

=head2 users

=head2 user

=head2 user_preferences

=head2 user_preference

=head2 update_user_preference

=head1 INTERNALS

=head2 BUILD

basic configuration for the client API happens usually in the BUILD method when using Web::API

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/nupfel/WebService-Desk/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Desk

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/nupfel/WebService-Desk>

=item * MetaCPAN

L<https://metacpan.org/module/WebService::Desk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService::Desk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService::Desk>

=back

=head1 AUTHOR

Tobias Kirschstein <lev@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Tobias Kirschstein.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
