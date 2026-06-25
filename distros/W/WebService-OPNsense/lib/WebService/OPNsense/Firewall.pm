#!/bin/false
# ABSTRACT: Firewall API controller
# PODNAME: WebService::OPNsense::Firewall
use strictures 2;

package WebService::OPNsense::Firewall;
$WebService::OPNsense::Firewall::VERSION = '0.001';
use Moo;
use namespace::clean;

has client => ( is => 'ro', required => 1 );

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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OPNsense::Firewall - Firewall API controller

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $fw = $opn->firewall;
    my $rules = $fw->filter->search_rule;

=head1 DESCRIPTION

Provides access to firewall-related API controllers.

=head1 NAME

WebService::OPNsense::Firewall - Firewall API controller

=head1 ATTRIBUTES

=head2 C<filter>

Lazy accessor returning a L<WebService::OPNsense::Firewall::Filter> instance.

=head2 C<alias>

Lazy accessor returning a L<WebService::OPNsense::Firewall::Alias> instance.

=head2 C<category>

Lazy accessor returning a L<WebService::OPNsense::Firewall::Category> instance.

=head2 C<d_nat>

Lazy accessor returning a L<WebService::OPNsense::Firewall::DNat> instance.

=head2 C<one_to_one>

Lazy accessor returning a L<WebService::OPNsense::Firewall::OneToOne> instance.

=head2 C<source_nat>

Lazy accessor returning a L<WebService::OPNsense::Firewall::SourceNat> instance.

=head2 C<npt>

Lazy accessor returning a L<WebService::OPNsense::Firewall::Npt> instance.

=for Pod::Coverage client

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
