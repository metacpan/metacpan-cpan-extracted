package TheEye::Plugin::Notify::HipChat;

use 5.010;
use Mouse::Role;
use LWP::UserAgent;

# ABSTRACT: Plugin for TheEye to raise alerts in Pager Duty
#
our $VERSION = '0.5'; # VERSION

has 'hc_token' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => '',
);

has 'hc_room' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => 'monitoring'
);

has 'hc_from' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => 'TheEye'
);

has 'hc_url' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    required => 1,
    default  => 'https://api.hipchat.com/v1/rooms/message?format=json&auth_token=',
);

has 'hc_err' => (
    is        => 'rw',
    isa       => 'HashRef',
    required  => 0,
    default   => 0,
    predicate => 'has_hc_err',
);

around 'notify' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    my @errors;
    my $ua = LWP::UserAgent->new(agent => 'TheEye');
    foreach my $test (@{$tests}) {
        foreach my $step ( @{ $test->{steps} } ) {
            if ( $step->{status} eq 'not_ok' ) {

                if($step->{message} =~ m{^(not ok \d+ -) ([^\s]+) (.*)$}){
                    $step->{lead_in} = $1;
                    $step->{node} = $2;
                    $step->{test_error} = $3;
                }


                my $res = $ua->post(
                    $self->hc_url . $self->hc_token, {
                        room_id => $self->hc_room,
                        from    => $self->hc_from,
                        message => $step->{message},
                        message_format => 'text',
                        notify         => 1,
                        color          => 'red',
                    });
                print $res->decoded_content if $self->is_debug;
            }
        }
    }
};

1;

=pod

=encoding UTF-8

=head1 NAME

TheEye::Plugin::Notify::HipChat - Plugin for TheEye to raise alerts in Pager Duty

=head1 VERSION

version 0.5

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

=for Pod::Coverage hc_send
