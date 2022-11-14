package WebService::Async::Segment;

use strict;
use warnings;

use Net::Async::HTTP;
use IO::Async::Loop;
use Scalar::Util qw(blessed);
use URI;
use JSON::MaybeUTF8 qw(encode_json_utf8 decode_json_utf8);
use Syntax::Keyword::Try;
use Log::Any qw($log);
use Time::Moment;

use parent qw(IO::Async::Notifier);

use WebService::Async::Segment::Customer;

use constant SEGMENT_BASE_URL => 'https://api.segment.io/v1/';
use constant TIMEOUT          => 5;
use constant SNAKE_FIELDS => {
    anonymous_id => 'anonymousId',
    user_id      => 'userId',
    sent_at      => 'sentAt',
    traits       => {
        created_at => 'createdAt',
        first_name => 'firstName',
        last_name  => 'lastName',
        address    => {
            postal_code => 'postalCode',
        },
    },
    context => {
        user_agent => 'userAgent',
        group_id   => 'groupId',
        device     => {
            advertising_id      => 'advertisingId',
            ad_tracking_enabled => 'adTrackingEnabled'
        },
    },
};

our $VERSION = '0.001';

=head1 NAME

WebService::Async::Segment - Unofficial support for the Segment service

=head1 DESCRIPTION

This class acts as a L<Future>-based async Perl wrapper for segment HTTP API.

=cut

=head1 METHODS

=head2 configure

Overrides the same method of the parent class L<IO::Async::Notifier>; required for object initialization.

parameters:

=over 4

=item * C<write_key> - the API token of a Segment source.

=item * C<base_uri> - the base uri of the Segment host, primarily useful for setting up test mock servers.

=back

=cut

sub configure {
    my ($self, %args) = @_;

    for my $k (qw(write_key base_uri)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }

    $self->next::method(%args);
}

=head2 write_key

API token of the intended Segment source

=cut

sub write_key { shift->{write_key} }

=head2 base_uri

Server endpoint. Defaults to C<< https://api.segment.io/v1/ >>.

Returns a L<URI> instance.

=cut

sub base_uri {
    my $self = shift;
    return $self->{base_uri} if blessed($self->{base_uri});
    $self->{base_uri} = URI->new($self->{base_uri} // SEGMENT_BASE_URL);
    return $self->{base_uri};
}

=head2 ua

A L<Net::Async::HTTP> object acting as HTTP user agent

=cut

sub ua {
    my ($self) = @_;

    return $self->{ua} if $self->{ua};

    $self->{ua} = Net::Async::HTTP->new(
        fail_on_error            => 1,
        decode_content           => 1,
        pipeline                 => 0,
        stall_timeout            => TIMEOUT,
        max_connections_per_host => 2,
        user_agent               => 'Mozilla/4.0 (WebService::Async::Segment; DERIV@cpan.org; https://metacpan.org/pod/WebService::Async::Segment)',
    );

    $self->add_child($self->{ua});

    return $self->{ua};
}

=head2 basic_authentication

Settings required for basic HTTP authentication

=cut

sub basic_authentication {
    my $self = shift;

    #C<Net::Async::Http> basic authentication information
    return {
        user => $self->write_key // '',
        pass => ''
    };
}

=head2 method_call

Makes a Segment method call. It automatically defaults C<sent_at> to the current time and C<< context->{library} >> to the current module.

It takes the following named parameters:

=over 4

=item * C<method> - required. Segment method name (such as B<identify> and B<track>).

=item * C<args> - optional. Method arguments represented as a dictionary. This may include either common, method-specific or custom fields.

=back

Please refer to L<https://segment.com/docs/spec/common/> for a full list of common fields supported by Segment.

It returns a L<Future> object.

=cut

sub method_call {
    my ($self, $method, %args) = @_;

    $args{sent_at} ||= Time::Moment->now_utc->to_string();
    $args{context}->{library}->{name}    = ref $self;
    $args{context}->{library}->{version} = $VERSION;

    return Future->fail('ValidationError', 'segment', 'Method name is missing', 'segment', $method, %args) unless $method;

    return Future->fail('ValidationError', 'segment', 'Both user_id and anonymous_id are missing', $method, %args)
        unless $args{user_id} or $args{anonymous_id};

    %args = _snake_case_to_camelCase(\%args, SNAKE_FIELDS)->%*;

    $log->tracef('Segment method %s called with params %s', $method, \%args);

    return $self->ua->POST(
        URI->new_abs($method, $self->base_uri),
        encode_json_utf8(\%args),
        content_type => 'application/json',
        %{$self->basic_authentication},
    )->then(
        sub {
            my $result = shift;

            $log->tracef('Segment response for %s method received: %s', $method, $result);

            my $response_str = $result->content;

            if ($result->code == 200) {
                $log->tracef('Segment %s method call finished successfully.', $method);

                return Future->done(1);
            }

            return Future->fail('RequestFailed', 'segment', $response_str);
        }
    )->on_fail(
        sub {
            $log->errorf('Segment method %s call failed: %s', $method, $_[0]);
        })->retain;
}

=head2 new_customer

Creates a new C<WebService::Async::Segment::Customer> object as the starting point of making B<identify> and B<track> calls.
It may takes the following named standard arguments to populate the customer onject with:

=over 4

=item * C<user_id> or  C<userId> - Unique identifier of a user.

=item * C<anonymous_id> or C<anonymousId>- A pseudo-unique substitute for a User ID, for cases when you don't have an absolutely unique identifier.

=item * C<traits> - Free-form dictionary of traits of the user, like email or name.

=back

=cut

sub new_customer {
    my ($self, %args) = @_;

    $args{api_client} = $self;

    $log->tracef('A new customer is being created with: %s', \%args);

    return WebService::Async::Segment::Customer->new(%args);
}

=head2 _snake_case_to_camelCase

Creates a deep copy of API call args, replacing the standard snake_case keys with equivalent camelCases, necessary to keep consistent with Segment HTTP API.
It doesn't automatically alter any non-standard custom keys even they are snake_case.

=over 4

=item * C<$args> - call args as a hash reference.

=item * C<$snake_fields> - a hash ref representing mapping from snake_case to camelCase.

=back

Returns a hash reference of args with altered keys.

=cut

sub _snake_case_to_camelCase {
    my ($args, $snake_fields) = @_;

    return $args       unless ref($args) eq 'HASH';
    $snake_fields = {} unless ref($snake_fields) eq 'HASH';

    my $result;
    for my $key (keys %$args) {
        next unless defined $args->{$key};

        if ($snake_fields->{$key} and not(ref $snake_fields->{$key})) {
            my $camel = $snake_fields->{$key};
            $result->{$camel} = _snake_case_to_camelCase($args->{$camel} // $args->{$key}, $snake_fields->{$camel});
            next;
        }
        $result->{$key} = _snake_case_to_camelCase($args->{$key}, $snake_fields->{$key});
    }
    return $result;
}

1;

__END__

=head1 AUTHOR

deriv.com C<< DERIV@cpan.org >>

=head1 LICENSE

Copyright deriv.com 2019. Licensed under the same terms as Perl itself.
