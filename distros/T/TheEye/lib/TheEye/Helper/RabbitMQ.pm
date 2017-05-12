package TheEye::Helper::RabbitMQ;

use 5.010;
use Mouse;
use LWP::UserAgent;
use HTTP::Request;
use Test::More;
use JSON;

# ABSTRACT: Graphite plugin for TheEye
#
our $VERSION = '0.5'; # VERSION

has 'json' => (
    is      => 'rw',
    isa     => 'JSON',
    default => sub {
        JSON->new->utf8->allow_nonref->allow_blessed->convert_blessed;
    },
);

has 'url' => (
    is  => 'rw',
    isa => 'Str',
);

has 'realm' => (
    is  => 'rw',
    isa => 'Str',
);

has 'user' => (
    is  => 'rw',
    isa => 'Str',
);

has 'pass' => (
    is  => 'rw',
    isa => 'Str',
);


sub get_numbers {
    my ($self, @ignore) = @_;

    my $ua   = LWP::UserAgent->new();

    my $req = HTTP::Request->new(GET => $self->url . '/api/queues');
    $req->authorization_basic($self->user, $self->pass);

    my $res = $ua->request($req);
    if ($res->is_success) {

        my $json;
        my $result;
        eval { $json = $self->json->decode($res->content) };
        unless ($@) {
            foreach my $queue (@{$json}){
                my $name = $queue->{vhost} . '/' . $queue->{name};
                next if map { $name =~ m/$_/ } @ignore;
                push(
                    @{$result}, {
                        node       => $name,
                        from       => time,
                        to         => time,
                        resolution => 1,
                        value      => $queue->{messages},
                    });
            }
        }
        return {error => 'Could not parse JSON'} unless $result;
        return $result;
    }
    else {
        return { error => $res->status_line, };
    }
}


sub byte_to_gb {
    my ($self, $bytes) = @_;

    return $bytes / 1024 / 1024 / 1024;
}


sub byte_to_mb {
    my ($self, $bytes) = @_;

    return $bytes / 1024 / 1024;
}


sub test_rabbit {
    my ($self, $data, $limits) = @_;

    if (ref $data eq 'HASH') {
        fail("Communication error: " . $data->{error});
    }
    else {
        foreach my $res (@{$data}) {
            if (exists $limits->{lower}) {
                cmp_ok($res->{value}, '>=', $limits->{lower},
                    "$res->{node} has less than $limits->{lower} $limits->{what} - currently: $res->{value}"
                );
            }
            if (exists $limits->{upper}) {
                cmp_ok($res->{value}, '<=', $limits->{upper},
                    "$res->{node} has more than $limits->{upper} $limits->{what} - currently: $res->{value}"
                );
            }
            if (exists $limits->{stale}) {
                cmp_ok($res->{to}, '>=', time - $limits->{stale},
                    "$res->{node} has stale data (currently $res->{to} seconds old)"
                );
            }
        }
    }

}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

TheEye::Helper::RabbitMQ - Graphite plugin for TheEye

=head1 VERSION

version 0.5

=head2 get_numbers

Get the numbers from the Graphite server

=head2 byte_to_gb

Convert bytes into GB

=head2 byte_to_mb

Convert bytes into MB

=head2 test_graphite

Test a grahite data source for stale data and min/max

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
