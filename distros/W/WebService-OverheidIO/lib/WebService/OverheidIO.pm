package WebService::OverheidIO;
use Moose;

# ABSTRACT: A (semi) abstract class that implements logic to talk to Overheid.IO

our $VERSION = '1.1';

use LWP::UserAgent;
use URI;
use Carp;
use JSON;

has ua => (
    is       => 'ro',
    isa      => 'LWP::UserAgent',
    builder  => '_build_useragent',
    lazy     => 1,
);

has base_uri => (
    is      => 'ro',
    isa     => 'URI',
    builder => '_build_base_uri',
    lazy => 1,
);

has max_query_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 30,
);


has key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has type => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_type',
);


has fieldnames => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_fieldnames',
);

has queryfields => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_queryfields',
);

sub search {
    my $self        = shift;
    my $search_term = shift;
    my $opts        = {@_};

    my $filter = $opts->{filter};
    $filter->{actief} = 'true' if $self->type eq 'kvk';

    my %query = map { sprintf('filters[%s]', $_), => $filter->{$_} }
        grep { defined $filter->{$_} } keys %{$filter};

    $query{size} = $self->max_query_size;

    my $uri = $self->base_uri->clone;

    $uri->query_form(
        %query,
        'fields[]'      => $self->fieldnames,
        'queryfields[]' => $self->queryfields,
        query           => $search_term,
    );

    return $self->_call_overheid_io($uri);
}

sub _build_base_uri {
    my $self = shift;
    return URI->new_abs( "/api/". $self->type, 'https://overheid.io');
}

sub _build_useragent {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        ssl_opts => {
            SSL_ca_path     => '/etc/ssl/certs',
            verify_hostname => 1,
        }
    );
    $ua->default_header('ovio-api-key', $self->key);
    return $ua;
}

sub _call_overheid_io {
    my ($self, $uri) = @_;

    my $res = $self->ua->get($uri->as_string);
    my $decoded = $res->decoded_content;

    if (!$res->is_success) {
        die sprintf("%s - %s", $res->status_line, $res->decoded_content), $/;
    }

    my $json = JSON->new->decode($decoded);

    return $json;
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OverheidIO - A (semi) abstract class that implements logic to talk to Overheid.IO

=head1 VERSION

version 1.1

=head1 SYNOPSIS

    package WebService::OverheidIO::Foo;
    use Moose;
    extends 'WebService::OverheidIO';

    # You must implement the following builders:
    # _build_type
    # _build_fieldnames
    # _build_queryfields

=head1 DESCRIPTION

L<Overheid.IO|https://overheid.io> is a open data initiative to expose
data the Dutch government exposes via a JSON API. This is a Perl
implemenation for talking to that JSON API.

=head1 ATTRIBUTES

=head2 ua

An L<LWP::UserAgent> object

=head2 base_uri

The base URI of the Overheid.IO, lazy loaded.

=head2 max_query_size

The max query size, defaults to 30.

=head2 key

The required Overheid.IO API key.

=head2 type

The type of Overheid.IO api

=head2 fieldnames

The names of the fields which the Overheid.IO will respond with

=head2 queryfields

The names of the fields which will be used to query on

=head1 METHODS

=head2 search

Search OverheidIO by a search term, you can apply additional filters for zipcodes and such

    $overheidio->search(
        "Mintlab",
        filter => {
            postcode => '1051JL',
        }
    );

=head1 SEE ALSO

=over

=item L<WebService::OverheidIO::KvK>

Chamber of commerce data

=item L<WebService::OverheidIO::BAG>

BAG stands for Basis Administratie Gebouwen. This is basicly a huge
address table.

=back

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mintlab BV.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
