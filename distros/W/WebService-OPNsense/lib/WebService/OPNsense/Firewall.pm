#!/bin/false
# ABSTRACT: Firewall API controller
# PODNAME: WebService::OPNsense::Firewall
use strictures 2;

package WebService::OPNsense::Firewall;
$WebService::OPNsense::Firewall::VERSION = '0.002';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

has 'alias' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::Alias;
        return WebService::OPNsense::Firewall::Alias->new(
            client => $self->client,
        );
    },
);

has 'category' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::Category;
        return WebService::OPNsense::Firewall::Category->new(
            client => $self->client,
        );
    },
);

has 'd_nat' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::DNat;
        return WebService::OPNsense::Firewall::DNat->new(
            client => $self->client,
        );
    },
);

has 'filter' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::Filter;
        return WebService::OPNsense::Firewall::Filter->new(
            client => $self->client,
        );
    },
);

has 'npt' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::Npt;
        return WebService::OPNsense::Firewall::Npt->new(
            client => $self->client,
        );
    },
);

has 'one_to_one' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::OneToOne;
        return WebService::OPNsense::Firewall::OneToOne->new(
            client => $self->client,
        );
    },
);

has 'source_nat' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        require WebService::OPNsense::Firewall::SourceNat;
        return WebService::OPNsense::Firewall::SourceNat->new(
            client => $self->client,
        );
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall - Firewall API controller

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $fw = $opn->firewall;
    my $rules = $fw->filter->search_rule;

=head1 DESCRIPTION

Provides access to firewall-related API controllers.

=head1 ATTRIBUTES

    alias         WebService::OPNsense::Firewall::Alias
    category      WebService::OPNsense::Firewall::Category
    d_nat         WebService::OPNsense::Firewall::DNat
    filter        WebService::OPNsense::Firewall::Filter
    npt           WebService::OPNsense::Firewall::Npt
    one_to_one    WebService::OPNsense::Firewall::OneToOne
    source_nat    WebService::OPNsense::Firewall::SourceNat

=head2 client

    my $http_client = $fw->client;

Returns the underlying HTTP client object used for API requests.

=head1 SEE ALSO

L<WebService::OPNsense>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
