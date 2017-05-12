package WebService::Slack::IncomingWebHook;
use 5.008001;
use strict;
use warnings;
use utf8;

use JSON;
use Furl;
use Carp ();

our $VERSION = "0.02";

sub new {
    my ($class, %args) = @_;
    Carp::croak('required webhook url') if ! exists $args{webhook_url};

    my $self = bless {
        map { ( $_ => $args{$_} ) } qw( webhook_url channel icon_emoji icon_url username )
    } => $class;

    $self->{json} = JSON->new->utf8;
    $self->{furl} = Furl->new(agent => "$class.$VERSION");

    return $self;
}

sub post {
    my ($self, %args) = @_;

    my $post_data = $self->_make_post_data(%args);

    my $res = $self->{furl}->post(
        $self->{webhook_url},
        ['Content-Type' => 'application/json'],
        $self->{json}->encode($post_data),
    );
    if (! $res->is_success) {
        Carp::carp('post failed: '. $res->body);
    }
}

sub _make_post_data {
    my ($self, %args) = @_;
    return +{
        (
            map {
                exists $args{$_} ? ( $_ => $args{$_} ) : ()
            } qw( text pretext color fields attachments )
        ),
        # override if parameter specified
        (
            map {
                ( $_ => exists $args{$_} ? $args{$_} : $self->{$_} )
            } qw( channel icon_emoji icon_url username )
        ),
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Slack::IncomingWebHook - slack incoming webhook client

=head1 SYNOPSIS

    # for perl program
    use WebService::Slack::IncomingWebHook;
    my $client = WebService::Slack::IncomingWebHook->new(
        webhook_url => 'http://xxxxxxxxxxxxxx',
    );
    $client->post(
        text       => 'yahoooooo!!',
    );

    # for cli
    % post-slack --webhook_url='https://xxxxxx' --text='yahooo'


=head1 DESCRIPTION

WebService::Slack::IncomingWebHook is slack incoming webhooks client.
L<Slack|https://slack.com/> is chat web service.
For cli, this distribution provides post-slack command.


=head1 METHOD

=over 4

=item WebService::Slack::IncomingWebHook->new(%params)

    my $client = WebService::Slack::IncomingWebHook->new(
        webhook_url => 'http://xxxxxxxxxxxxxx', # required
        channel    => '#general',               # optional
        username   => 'masasuzu',               # optional
        icon_emoji => ':sushi:',                # optional
        icon_url   => 'http://xxxxx/xxx.jpeg',  # optional
    );

Creates new object.

=item $client->post(%params)

    $client->post(
        text       => 'yahoooooo!!',
        channel    => '#general',
        username   => 'masasuzu',
        icon_emoji => ':sushi:',
        icon_url   => 'http://xxxxx/xxx.jpeg',
    );

Posts to slack incoming webhooks.
I<channel>, I<username>, I<icon_emoji> and I<icon_url> parameters can override constructor's parameter.

I<text>, I<pretext>, I<color>, I<fields> and I<attachments> parameter are available.
See also slack incoming webhook document.

=back

=head1 SCRIPT

    % post-slack --webhook_url='https://xxxxxx' --text='yahooo'

available options are ...

=over 4

=item  --webhook_url (required)

=item  --text (required)

=item  --channel (optional)

=item  --username (optional)

=item  --icon_url (optional)

=item  --icon_emoji (optional)

=back


=head1 SEE ALSO

L<https://my.slack.com/services/new/incoming-webhook>

=head1 LICENSE

Copyright (C) SUZUKI Masashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

SUZUKI Masashi E<lt>m15.suzuki.masashi@gmail.comE<gt>

=cut

