package WebService::Mattermost::V4::API::Response;

use Mojo::JSON 'decode_json';
use Moo;
use Types::Standard qw(Any ArrayRef Bool InstanceOf Int Maybe Object Str);

use WebService::Mattermost::V4::API::Object::Analytics::Old;
use WebService::Mattermost::V4::API::Object::Application;
use WebService::Mattermost::V4::API::Object::Audit;
use WebService::Mattermost::V4::API::Object::Channel::Member;
use WebService::Mattermost::V4::API::Object::Channel;
use WebService::Mattermost::V4::API::Object::ChannelStats;
use WebService::Mattermost::V4::API::Object::Compliance::Report;
use WebService::Mattermost::V4::API::Object::Config;
use WebService::Mattermost::V4::API::Object::DataRetentionPolicy;
use WebService::Mattermost::V4::API::Object::Emoji;
use WebService::Mattermost::V4::API::Object::Error;
use WebService::Mattermost::V4::API::Object::File;
use WebService::Mattermost::V4::API::Object::Icon;
use WebService::Mattermost::V4::API::Object::Job;
use WebService::Mattermost::V4::API::Object::Log;
use WebService::Mattermost::V4::API::Object::NewLogEntry;
use WebService::Mattermost::V4::API::Object::Plugin;
use WebService::Mattermost::V4::API::Object::Plugins;
use WebService::Mattermost::V4::API::Object::Post;
use WebService::Mattermost::V4::API::Object::Reaction;
use WebService::Mattermost::V4::API::Object::Response;
use WebService::Mattermost::V4::API::Object::Status;
use WebService::Mattermost::V4::API::Object::Team;
use WebService::Mattermost::V4::API::Object::TeamStats;
use WebService::Mattermost::V4::API::Object::Thread;
use WebService::Mattermost::V4::API::Object::User::Preference;
use WebService::Mattermost::V4::API::Object::User::Session;
use WebService::Mattermost::V4::API::Object::User::Status;
use WebService::Mattermost::V4::API::Object::User;
use WebService::Mattermost::V4::API::Object::WebRTCToken;
use WebService::Mattermost::Helper::Alias 'view';

################################################################################

has base_url    => (is => 'ro', isa => Str,                                   required => 1);
has auth_token  => (is => 'ro', isa => Str,                                   required => 1);
has code        => (is => 'ro', isa => Int,                                   required => 1);
has headers     => (is => 'ro', isa => InstanceOf['Mojo::Headers'],           required => 1);
has message     => (is => 'ro', isa => Str,                                   required => 0);
has prev        => (is => 'ro', isa => InstanceOf['Mojo::Message::Response'], required => 1);
has raw_content => (is => 'ro', isa => Str,                                   required => 0);
has item_view   => (is => 'ro', isa => Maybe[Str],                            required => 0);
has single_item => (is => 'ro', isa => Bool,                                  required => 0);

has is_error   => (is => 'ro', isa => Bool, default => 0);
has is_success => (is => 'ro', isa => Bool, default => 1);

has content => (is => 'rw', isa => Any, default => sub { {} });

has item  => (is => 'ro', isa => Maybe[Object],   lazy => 1, builder => 1);
has items => (is => 'ro', isa => Maybe[ArrayRef], lazy => 1, builder => 1);

################################################################################

sub BUILD {
    my $self = shift;

    if ($self->_looks_like_json($self->raw_content)) {
        $self->content(decode_json($self->raw_content));
    }

    return 1;
}

################################################################################

sub _looks_like_json {
    my $self = shift;
    my $inp  = shift;

    # Rudimentary "is it JSON?" hack
    return $inp && $inp =~ /^[\{\[]/ ? 1 : 0;
}

################################################################################

sub _build_item {
    my $self = shift;

    my $item;

    if (scalar @{$self->items}) {
        $item = $self->items->[0];
    }

    return $item;
}

sub _build_items {
    my $self = shift;

    my @ret;

    if ($self->item_view) {
        my @init_items = ref $self->content eq 'ARRAY' ? @{$self->content} : ($self->content);
        my @items;

        # Sometimes, for example in GET /logs, a JSON string is returned rather
        # than a hash.
        foreach (@init_items) {
            $_ =~ s/\n//sg;

            if ($self->_looks_like_json($_)) {
                push @items, decode_json($_);
            } else {
                push @items, $_ if $_;
            }
        }

        if ($items[0]->{status_code} && $items[0]->{status_code} != 200) {
            # The response is actually an error - create an Error view
            push @ret, view('Error')->new({
                raw_data    => $items[0],
                auth_token  => $self->auth_token,
                base_url    => $self->base_url,
            });
        } else {
            @ret = map {
                view($self->item_view)->new({
                    auth_token  => $self->auth_token,
                    base_url    => $self->base_url,
                    raw_data    => $_,
                })
            } @items;
        }
    }

    return \@ret;
}

################################################################################

1;
__END__

=head1 NAME

WebService::Mattermost::API::Response - container for responses from the Mattermost API

=head1 DESCRIPTION

A common container for responses from the Mattermost API.

=head2 ATTRIBUTES

=over 4

=item C<code>

The HTTP code returned.

=item C<headers>

Headers from the C<Mojo::Message::Response> object.

=item C<message>

A message (or undef) from the API (for example if there is a C<code> of 403,
the C<message> will be "Forbidden").

=item C<prev>

The returned C<Mojo::Message::Response> object.

=item C<raw_content>

JSON-encoded content or undef.

=item C<is_error>

=item C<is_success>

=item C<content>

Decoded content in ArrayRef or HashRef form.

=item C<item_view>

Whether or not the response should try to create a v4::Object object.

=item C<single_item>

Whether or not the expected v4::Object should be an ArrayRef.

=item C<item>

The first v4::Object object.

=item C<items>

All view objects.

=back

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

