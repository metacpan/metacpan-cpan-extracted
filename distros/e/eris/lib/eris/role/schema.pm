package eris::role::schema;
# ABSTRACT: Role for implementing a schema

use eris::dictionary;
use JSON::MaybeXS;
use Moo::Role;
use POSIX qw(strftime);
use Types::Standard qw(Bool HashRef InstanceOf Int Str);
use namespace::autoclean;

with qw(
    eris::role::plugin
);

our $VERSION = '0.008'; # VERSION



requires qw( match_log );


has 'index_name_strftime' => (
    is => 'lazy',
    isa => Str,
);
sub _build_index_name_strftime { '%Y.%m.%d' }


has 'index_name' => (
    is => 'lazy',
    isa => Str,
);
sub _build_index_name {
    my ($self) = @_;
    my $class = ref $self;

    my $base = $class =~ /::schema::(.*)$/ ? $1
             : $self->name;

    return join('-', $base, $self->index_name_strftime);
}


has 'default_type' => (
    is => 'lazy',
    isa => Str,
);
sub _build_default_type   { 'log' }


has 'types' => (
    is => 'lazy',
    isa => HashRef,
);
sub _build_types {
    my $self = shift;
    return { $self->default_type => 1 };
}


has 'dictionary' => (
    is => 'lazy',
    isa => InstanceOf["eris::dictionary"],
);
sub _build_dictionary {
    my $self = shift;
    return eris::dictionary->new( %{ $self->dictionaries } );
}


has 'use_dictionary' => (
    is => 'lazy',
    isa => Bool,
);
sub _build_use_dictionary { 1 }

has 'dictionaries' => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { +{} }
);


has 'final' => (
    is => 'lazy',
    isa => Bool,
);
sub _build_final          { 1 }


has 'flatten' => (
    is => 'lazy',
    isa => Bool,
);
sub _build_flatten        { 1 }


has 'es_version' => (
    is      => 'ro',
    isa     => Str,
    default => sub { '6.4' },
);


has 'es_template' => (
    is  => 'lazy',
    isa => HashRef,
);
sub _build_es_template {
    my $self = shift;

    return {
        ($self->es_version > 6 ? 'index_pattern' : 'template' ) => sprintf "%s-*", $self->name,
        mapping => {
            dynamic_properties => [
                {
                },
            ],
            properties => {
                timestamp => { type => 'datetime' },
                time      => { type => 'datetime' },
            },
        }
    };
}


sub as_bulk {
    my ($self,$log) = @_;

    return sprintf "%s\n%s\n",
        map { encode_json($_) }
        {
            index => {
                _index => strftime($self->index_name, gmtime $log->epoch ),
                _type  => exists $self->types->{$log->type} ? $log->type : $self->default_type,
                $log->uuid ? ( _id => $log->uuid ) : (),
            }
        },
        $self->to_document( $log );
}


sub to_document {
    my ($self,$log) = @_;

    # Clone Context or Complete
    my $doc = $log->as_doc( complete => !$self->flatten );
    # Prune Keys using the dictionary
    if( $self->use_dictionary ) {
        foreach my $k ( keys %$doc ) {
            delete $doc->{$k} unless $self->dictionary->lookup( $k );
        }
    }
    return $doc;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::schema - Role for implementing a schema

=head1 VERSION

version 0.008

=head1 SYNOPSIS

To implement a schema that takes the processed log entry
without field filtering, you could:

    package my::app::schema::full;

    use Moo;

    with qw(eris::role::schema);

    sub _build_flatten        { 0 }
    sub _build_use_dictionary { 0 }

    sub match_log { 1 }

=head1 ATTRIBUTES

=head2 index_name_strftime

Defaults to a daily index pattern, '%Y.%m.%d' per Logstash.

=head2 index_name

Defaults to taking the schema's class, trimming off the namespace and then
replacing '::' with an underscore.  It then joins this with
C<index_name_strftime> to form the index name that's evaluated foreach
document.

Without overriding this via a config element, we get:

    Schema Class            Index Name
    --------------------    --------------
    eris::schema::syslog    yslog-%Y.%m.%d
    eris::schema::access    ccess-%Y.%m.%d
    my::app::schema::log    y_app_schema_log-%Y.%m.%d

=head2 default_type

The type for the Elasticsearch index to assume.  Defaults to 'log'.

=head2 types

A HashRef of valid types for the Elasticsearch index, defaults to just
the default_type.

=head2 dictionary

An instance of L<eris::dictionary> configured for the schema.  Parameters passed via
the C<dictionary> sub section of the config will be used to build the dictionary.

=head2 use_dictionary

A boolean, if true the fields in the document will be filtered by
the C<dictionary> element.

=head2 dictionaries

A hashref to configure the loading the dictionaries.  Defaults to empty.

=head2 final

Boolean, defaults to true. If true this schema "steals" the document and
the only one bulk item will be appended to the C<as_bulk> per document.
Set to false to indexing the same log into multiple indices.

You'll need to consider the B<priority> of the schema if you set this to false
to ensure the schema is early enough in the chain to accept the document.

=head2 flatten

Boolean, defaults to true.  If true only the B<context> hash from the L<eris::log> object
is indexed.  If set to false, the C<complete> hash is used instead.

=head2 es_version

The ElasticSearch version to target for commands and mappings.  Defaults to B<6.4>.

=head2 es_template

The ElasticSearch index template definition from this schema.

=head1 METHODS

=head2 as_bulk

Takes an L<eris::log> object and returns the bulk newline delimited JSON to add
that object to the cluster.

=head2 to_document

Takes an L<eris::log> object and returns a hash reference representing that document
for indexing.

=head1 INTERFACE

=head2 match_log()

Takes an C<eris::log> and determines if this schema applies.

Returns boolean

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
