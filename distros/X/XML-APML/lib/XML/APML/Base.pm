package XML::APML::Base;

use strict;
use warnings;

use base qw/
    Class::Accessor::Fast
    Class::Data::Accessor
/;

__PACKAGE__->mk_accessors(qw/key value from updated/);
__PACKAGE__->mk_classaccessor(qw/tag_name/);

use Carp ();

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        key     => undef,
        value   => undef,
    }, $class;
    $self->{key} = delete $args{key} if exists $args{key};
    $self->{value} = delete $args{value} if exists $args{value};
    $self;
}

sub parse_node {
    my ($class, $node) = @_;
    my $elem = $class->new;
    my $key = $node->getAttribute('key');
    $elem->key($key) if (defined $key && $key ne '');
    my $value = $node->getAttribute('value');
    $elem->value($value) if (defined $value && $value ne '');
    $elem;
}

sub build_dom {
    my ($self, $doc) = @_;
    my $class = ref $self;
    my $elem = $doc->createElement( $class->tag_name );
    my $key = $self->key;
    Carp::croak(q{key is not found.}) unless (defined $key && $key ne '');
    $elem->setAttribute(key => $key);
    my $value = $self->value;
    Carp::croak(q{value is not found.}) unless (defined $value && $value ne '');
    $elem->setAttribute(value => $value);
    $elem;
}

1;

