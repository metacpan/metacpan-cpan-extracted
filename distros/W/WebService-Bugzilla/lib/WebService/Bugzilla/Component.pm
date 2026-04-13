#!/usr/bin/false
# ABSTRACT: Bugzilla Component object and service
# PODNAME: WebService::Bugzilla::Component

package WebService::Bugzilla::Component 0.001;
use strictures 2;
use Moo;
use namespace::clean;

extends 'WebService::Bugzilla::Object';

sub _unwrap_key { 'components' }

has default_assignee => (is => 'ro', lazy => 1, builder => '_build_default_assignee');
has default_cc       => (is => 'ro', lazy => 1, builder => '_build_default_cc');
has default_qa_contact => (is => 'ro', lazy => 1, builder => '_build_default_qa_contact');
has description      => (is => 'ro', lazy => 1, builder => '_build_description');
has flag_types       => (is => 'ro', lazy => 1, builder => '_build_flag_types');
has is_active        => (is => 'ro', lazy => 1, builder => '_build_is_active');
has name             => (is => 'ro', lazy => 1, builder => '_build_name');
has product_id       => (is => 'ro', lazy => 1, builder => '_build_product_id');
has sort_key         => (is => 'ro', lazy => 1, builder => '_build_sort_key');
has triage_owner     => (is => 'ro', lazy => 1, builder => '_build_triage_owner');

my @attrs = qw(
    default_assignee
    default_cc
    default_qa_contact
    description
    flag_types
    is_active
    name
    product_id
    sort_key
    triage_owner
);

for my $attr (@attrs) {
    my $build = "_build_$attr";
    {
        no strict 'refs';
        *{ $build } = sub {
            my ($self) = @_;
            if ($self->_api_data && $self->_api_data->{product} && $self->_api_data->{name}) {
                $self->_fetch_full($self->_mkuri('component/' . $self->_api_data->{product} . '/' . $self->_api_data->{name}));
            }
            return $self->_api_data ? $self->_api_data->{$attr} : undef;
        };
    }
}

sub create {
    my ($self, %params) = @_;
    my $res = $self->client->post($self->_mkuri('component'), \%params);
    return $self->new(
        client => $self->client,
        _data  => { %params, id => $res->{id} },
    );
}

sub get {
    my ($self, $product, $name) = @_;
    my $res = $self->client->get($self->_mkuri("component/$product/$name"));
    return unless $res->{components} && @{ $res->{components} };
    return $self->new(
        client => $self->client,
        _data  => $res->{components}[0],
    );
}

sub update {
    my ($self, $product, $name, %params) = @_;
    my $res = $self->client->put($self->_mkuri("component/$product/$name"), \%params);
    return $self->new(
        client => $self->client,
        _data  => $res->{components}[0],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::Component - Bugzilla Component object and service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $comp = $bz->component->get('Firefox', 'General');
    say $comp->name, ': ', $comp->description;

    my $new = $bz->component->create(
        product     => 'Firefox',
        name        => 'Networking',
        description => 'Network-related issues',
    );

=head1 DESCRIPTION

Provides access to the
L<Bugzilla Component API|https://bmo.readthedocs.io/en/latest/api/core/v1/component.html>.
Component objects represent product components and expose attributes about
the component plus helpers to create, fetch, and update them.

=head1 ATTRIBUTES

All attributes are read-only and lazy.

=over 4

=item C<default_assignee>

Default assignee email for new bugs in this component.

=item C<default_cc>

Arrayref of login names placed on CC by default.

=item C<default_qa_contact>

Default QA contact email.

=item C<description>

Human-readable description of the component.

=item C<flag_types>

Flag types applicable to bugs/attachments in this component.

=item C<is_active>

Boolean.  Whether the component is active.

=item C<name>

Component name.

=item C<product_id>

Numeric ID of the owning product.

=item C<sort_key>

Numeric sort key used for ordering components.

=item C<triage_owner>

Login name of the triage owner, if set.

=back

=head1 METHODS

=head2 create

    my $comp = $bz->component->create(%params);

Create a new component.
See L<POST /rest/component|https://bmo.readthedocs.io/en/latest/api/core/v1/component.html#create-component>.

=head2 get

    my $comp = $bz->component->get($product, $name);

Fetch a component by product name and component name.
See L<GET /rest/component/{product}/{component}|https://bmo.readthedocs.io/en/latest/api/core/v1/component.html#get-component>.

Returns a L<WebService::Bugzilla::Component>, or C<undef> if not found.

=head2 update

    my $comp = $bz->component->update($product, $name, %params);

Update an existing component.
See L<PUT /rest/component/{product}/{component}|https://bmo.readthedocs.io/en/latest/api/core/v1/component.html#update-component>.

=head1 SEE ALSO

L<WebService::Bugzilla> - main client

L<WebService::Bugzilla::Product> - product objects

L<https://bmo.readthedocs.io/en/latest/api/core/v1/component.html> - Bugzilla Component REST API

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
