package XML::Toolkit::Builder::NamespaceRegistry;
{
  $XML::Toolkit::Builder::NamespaceRegistry::VERSION = '0.15';
}
use Moose::Role;
use MooseX::Aliases;
use namespace::autoclean;

has xmlns => (
    isa     => 'HashRef',
    is      => 'ro',
    lazy    => 1,
    builder => 'default_xmlns',
    traits  => [qw(Hash MooseX::Aliases::Meta::Trait::Attribute)],
    alias   => ['namespace_map'],
    handles => {
        default_namespace     => [ 'get', q[''] ],
        set_default_namespace => [ 'set', q[''] ],
        get_xmlns             => ['get'],
        set_xmlns             => ['set'],
        xmlns_pairs           => ['kv'],
    },
);

sub default_xmlns { { 'MyApp' => '', } }

has _unresolved_namespace_map => (
    isa      => 'HashRef',
    accessor => 'unresolved_namespace_map',
    lazy     => 1,
    default  => sub { {} },
    traits   => [qw(Hash MooseX::Aliases::Meta::Trait::Attribute)],
    alias    => ['unresolved_xmln'],
    handles  => {
        'no_unresolved_namespaces' => ['is_empty'],
        'unresolved_namespaces'    => ['keys'],
    }
);

sub end_document { }

after 'end_document' => sub {
    my ($self) = @_;
    unless ( $self->no_unresolved_namespaces ) {
        warn "These XML namespaces have no mapping:\n"
            . join( "\n", sort $self->unresolved_namespaces ) . "\n";
    }
};

sub get_class_name {
    my ( $self, $el ) = @_;

    # Get values for element
    my $xmlns     = $el->{'NamespaceURI'};
    my $namespace = $self->namespace_map->{$xmlns};

    # Add xmlns to unresolved list
    unless ($namespace) {
        $self->unresolved_namespace_map->{$xmlns} = 1;

        # Let's just return the local part here, even though it's wrong
        return $self->default_namespace . '::' . ucfirst $el->{'LocalName'};
    }

    # Construct class name
    return $namespace . '::' . ucfirst $el->{'LocalName'};
}

1;
__END__
