use strict;
use warnings;
package WebService::SendGrid3;

use Moo;
with 'WebService::Client';

our $VERSION = '0.10'; # VERSION

# ABSTRACT: Client library for SendGrid API v3

use MIME::Base64;

has username => ( is => 'ro', required => 1 );
has password => ( is => 'ro', required => 1 );

has '+base_url' => ( default => 'https://api.sendgrid.com/v3' );

sub BUILD {
    my ($self) = @_;

    my $u = $self->username();
    my $p = $self->password();
    my $base64_encoded_auth = encode_base64("$u:$p");

    $self->ua->default_header(Authorization => "Basic " . $base64_encoded_auth);
}

## CATEGORIES

sub get_categories {
    my ($self, %args) = @_;
    return $self->get("/categories/", $args{query} || {});
}

## SETTINGS

sub get_enforced_tls {
    my ($self, %args) = @_;
    return $self->get("/user/settings/enforced_tls", $args{query} || {});

}

## STATS

sub get_stats_global {
    my ($self, %args) = @_;
    return $self->get("/stats", $args{query} || {});
}

sub get_stats_category {
    my ($self, %args) = @_;

    if (defined($args{query}{categories})) {
        $args{query}{categories} = $self->_serialise_for_get(
            'categories',
            $args{query}{categories}
        );
    }

    return $self->get("/categories/stats", $args{query} || {});
}

sub get_stats_category_sums {
    my ($self, %args) = @_;

    return $self->get("/categories/stats/sums", $args{query} || {});
}

sub get_stats_subusers {
    my ($self, %args) = @_;

    use Data::Dumper;
    print Dumper \%args;

    if (defined($args{query}{subusers})) {
        $args{query}{subusers} = $self->_serialise_for_get(
            'subusers',
            $args{query}{subusers}
        );
    }

    return $self->get("/subusers/stats", $args{query} || {});
}

sub get_stats_subusers_sums {
    my ($self, %args) = @_;

    return $self->get("/subusers/stats/sums", $args{query} || {});
}

sub get_stats_geo {
    my ($self, %args) = @_;

    return $self->get("/geo/stats", $args{query} || {});
}

sub get_stats_devices {
    my ($self, %args) = @_;

    return $self->get("/devices/stats", $args{query} || {});
}

sub get_stats_clients {
    my ($self, %args) = @_;

    return $self->get("/clients/stats", $args{query} || {});
}

sub get_stats_for_client {
    my ($self, $type, %args) = @_;

    return $self->get("/clients/$type/stats", $args{query} || {});
}

sub get_stats_esp {
    my ($self, %args) = @_;

    if (defined($args{query}{esps})) {
        $args{query}{esps} = $self->_serialise_for_get(
            'esps',
            $args{query}{esps}
        );
    }

    return $self->get("/esp/stats", $args{query} || {});
}

sub get_stats_browsers {
    my ($self, %args) = @_;

    if (defined($args{query}{browsers})) {
        $args{query}{browsers} = $self->_serialise_for_get(
            'browsers',
            $args{query}{browsers}
        );
    }

    return $self->get("/browsers/stats", $args{query} || {});
}

sub get_stats_parse {
    my ($self, %args) = @_;

    return $self->get("/parse/stats", $args{query} || {});
}

## PRIVATE

sub _serialise_for_get {
    my ($self, $name, $ra) = @_;

    # We need to serialise arrays into query strings due to a limitation
    # in WebService::Client - HACK
    my $first = shift @$ra;
    my @rest = map { "&$name=$_" } @$ra;
    return $first . join('', @rest);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid3 - Client library for SendGrid API v3

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use WebService::SendGrid3;
  my $SendGrid = WebService::SendGrid3->new(
    username => 'user',
    password => 'pass'
  );

  my $response = $SendGrid->get_stats_global(
     query => {
            start_date => '2015-01-01',
            end_date => '2015-01-03',
            aggregated_by => 'day',
     }
  );

=head1 DESCRIPTION

Simple client for talking to SendGrid API v3.

=head1 METHODS

=head2 username

=head2 password

=head2 BUILD

=head1 CATEGORIES

=head2 get_categories

=head1 SETTINGS

=head2 get_enforced_tls

=head1 STATISTICS

=head2 get_stats_global

=head2 get_stats_category

=head2 get_stats_category_sums

=head2 get_stats_subusers

=head2 get_stats_subusers_sums

=head2 get_stats_geo

=head2 get_stats_devices

=head2 get_stats_clients

=head2 get_stats_for_client

=head2 get_stats_esp

=head2 get_stats_browsers

=head2 get_stats_parse

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
