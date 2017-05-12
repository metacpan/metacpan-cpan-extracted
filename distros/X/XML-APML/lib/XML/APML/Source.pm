package XML::APML::Source;

use strict;
use warnings;

use base 'XML::APML::Node';

__PACKAGE__->mk_accessors(qw/name type/);
__PACKAGE__->tag_name('Source');

use XML::APML::Author;

=head1 NAME

XML::APML::Source - Source markup.

=head1 SYNOPSIS

    my $explicit_source = XML::APML::Source->new;
    $explicit_source->key('http://feeds.feedburner.com/apmlspec');
    $explicit_source->value(1.00);
    $explicit_source->name('APML.org');
    $explicit_source->type('application/rss+xml');

    my $implicit_source = XML::APML::Source->new(
        key     => 'http://feeds.feedburner.com/apmlspec',
        value   => 1.00,
        from    => 'GatheringTool.com',
        updated => '2007-03-11T01:55:00Z',
        name    => 'APML.org',
        type    => 'application/rss+xml',
    );

    $implicit_source->add_author($author);

    foreach my $author ($implicit_source->authors) {
        print $author->key;
    }

=head1 DESCRIPTION

Class that represents Source mark-up for APML.

=head1 METHODS

=head2 new

=cut

sub new {
    my ($class, %args) = shift;
    my $self = $class->SUPER::new(%args);
    $self->{name} = exists $args{name} ? delete $args{name} : undef;
    $self->{type} = exists $args{type} ? delete $args{type} : undef;
    $self->{authors} = [];
    bless $self, $class;
}

=head2 authors

=cut

sub authors {
    my $self = shift;
    $self->add_author($_) for @_;
    return wantarray ? @{ $self->{authors} } : $self->{authors};
}

=head2 add_author

=cut

sub add_author {
    my ($self, $author) = @_;
    push @{ $self->{authors} }, $author;
}

sub parse_node {
    my ($class, $node, $is_implicit) = @_;
    my $source = $class->SUPER::parse_node($node, $is_implicit);
    my @nodes = $node->findnodes('*[local-name()=\'Author\']');
    my $name = $node->getAttribute('name');
    $source->name($name) if (defined $name && $name ne '');
    my $type = $node->getAttribute('type');
    $source->type($type) if (defined $type && $type ne '');
    $source->add_author(XML::APML::Author->parse_node($_, $is_implicit)) for @nodes;
    $source;
}

sub build_dom {
    my ($self, $doc, $is_implicit) = @_;
    my $elem = $self->SUPER::build_dom($doc, $is_implicit);
    my $name = $self->name;
    Carp::croak(q{source needs its name.}) unless (defined $name && $name ne '');
    $elem->setAttribute(name => $name);
    my $type = $self->type;
    Carp::croak(q{source needs its type.}) unless (defined $type && $type ne '');
    $elem->setAttribute(type => $type);
    for my $author (@{$self->{authors}}) {
        my $author_elem = $author->build_dom($doc, $is_implicit);
        $elem->appendChild($author_elem);
    }
    $elem;
}

1;
