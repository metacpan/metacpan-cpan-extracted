package XML::APML::Profile;

use strict;
use warnings;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/implicit_data explicit_data name/);

use XML::APML::ImplicitData;
use XML::APML::ExplicitData;

*implicit = \&implicit_data;
*explicit = \&explicit_data;

=head1 NAME

XML::APML::Profile - profile markup

=head1 SYNOPSIS

    my $home = XML::APML::Profile->new( name => 'Home' );
    my $work = XML::APML::Profile->new;
    $work->name('Work');

    print $work->name;

    my $implicit = $work->implicit_data;
    my $explicit = $work->explicit_data;

=head1 DESCRIPTION

Class that represents Profile mark-up for APML.

=head1 METHODS

=head2 new

Constructor

    my $p = XML::APML::Profile->new;
    $p->name('Name');

    my $p = XML::APML::Profile->new( name => 'Name' );

=head2 name

accessor for name

    my $p = XML::APML::Profile->new;
    $p->name('ProfileName');
    print $p->name;

=head2 implicit_data

returns XML::APML::ImplicitData object.

    my $implicit = $p->implicit_data;
    my @concepts = $implicit->concepts;

=head2 implicit

alias for implicit_data

=head2 explicit_data

returns XML::APML::ExplicitData object.

    my $explicit = $p->explicit_data;
    my @concepts = $explicit->concepts;

=head2 explicit

alias for explicit_data

=cut

sub new {
    my ($class, %args) = @_;
    my $self = bless { 
        implicit_data => XML::APML::ImplicitData->new,
        explicit_data => XML::APML::ExplicitData->new,
    }, $class;
    $self->{name} = exists $args{name} ? delete $args{name} : undef;
    $self;
}

sub parse_node {
    my $class = shift;
    my $node = shift;
    my $profile = $class->new;
    my $name = $node->getAttribute('name');
    $profile->name($name) if (defined $name && $name ne '');
    my @enodes = $node->findnodes('*[local-name()=\'ExplicitData\']');
    if (@enodes) {
        $profile->explicit_data(XML::APML::ExplicitData->parse_node($enodes[0]));
    }
    my @inodes = $node->findnodes('*[local-name()=\'ImplicitData\']');
    if (@inodes) {
        $profile->implicit_data(XML::APML::ImplicitData->parse_node($inodes[0]));
    }
    $profile;
}

sub build_dom {
    my ($self, $doc) = @_;
    my $elem = $doc->createElement('Profile');
    $elem->setAttribute(name => $self->name);
    $elem->appendChild($self->implicit_data->build_dom($doc));
    $elem->appendChild($self->explicit_data->build_dom($doc));
    $elem;
}

1;

