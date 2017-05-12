package XML::APML::Node;

use strict;
use warnings;

use base 'XML::APML::Base';

__PACKAGE__->mk_accessors(qw/from updated/);

use Carp ();

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    bless $self, $class;
    $self->{from} = exists $args{from} ? delete $args{from} : undef;
    $self->{updated} = exists $args{updated} ? delete $args{updated} : undef;
    $self;
}

sub parse_node {
    my ($class, $node, $is_implicit) = @_;
    my $elem = $class->SUPER::parse_node($node);
    if ($is_implicit) {
        my $from = $node->getAttribute('from');
        $elem->from($from) if (defined $from && $from ne '');
        my $updated = $node->getAttribute('updated');
        $elem->updated($updated) if (defined $updated && $updated ne '');
    }
    $elem;
}

sub build_dom {
    my ($self, $doc, $is_implicit) = @_;
    my $elem = $self->SUPER::build_dom($doc);
    if ($is_implicit) {
        my $from = $self->from;
        Carp::croak(q{from is needed on implicit type element.}) unless (defined $from && $from ne ''); 
        $elem->setAttribute(from => $from);
        my $updated = $self->updated;
        Carp::croak(q{updated is needed on implicit type element.}) unless (defined $updated && $updated ne ''); 
        $elem->setAttribute(updated => $updated);
    }
    $elem;
}

1;

