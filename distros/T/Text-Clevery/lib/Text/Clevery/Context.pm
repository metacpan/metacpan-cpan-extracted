package Text::Clevery::Context;
use Any::Moose;

has _engine => (
    is  => 'ro',
    isa => 'Object',

    weak_ref => 1,
);

has env => (
    is  => 'ro',
    isa => 'HashRef',

    default => sub { \%ENV },
);

has request => (
    is  => 'ro',
    isa => 'Object',

    lazy    => 1,
    default => sub {
        my($self) = @_;
        require Plack::Request;
        return Plack::Request->new( $self->env );
    },

    handles => {
        cookies => 'cookies',
    },
);

has get => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => sub {
        my($self) = @_;
        return $self->request->query_parameters->as_hashref();
    },
);

has post => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => sub {
        my($self) = @_;
        return $self->request->body_parameters->as_hashref();
    },
);

has session => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has const => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has capture => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has section => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has foreach => (
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

has _storage => ( # per-request storage
    is  => 'ro',
    isa => 'HashRef',

    lazy    => 1,
    default => \&_build_hashref,
);

sub config {
    my($self) = @_;

    my $file   = $self->_engine->current_file();
    my $config = $self->_storage->{config} ||= {};
    return $config->{$file} ||= do {
        require Storable;
        my $proto = $config->{'@global'} ||= {};
        Storable::dclone($proto);
    };
}

sub template {
    my($self) = @_;
    return $self->_engine->current_file();
}

sub ldelim {
    my($self) = @_;
    return $self->_engine->{tag_start};
}

sub rdelim {
    my($self) = @_;
    return $self->_engine->{tag_end};
}

sub server { shift()->env }

sub version { Text::Clevery->smarty_compatible_version }

sub now { time }

sub _build_hashref {
    return {};
}
no Any::Moose;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Text::Clevery::Context - Per-request context object

=head1

This class represents the C<$smarty> variable, a per-request context object.

=head1 METHODS

=head2 C<< $smarty->get($name) >>

=head2 C<< $smarty->post($name) >>

=head2 C<< $smarty->config >>

=head2 C<< $smarty->template >>

=head2 C<< $smarty->ldelim >>

=head2 C<< $smarty->rdelim >>

=head2 C<< $smarty->now >>

=head2 C<< $smarty->version >>

=head2 C<< $smarty->server >>

=head2

=head1 SEE ALSO

L<Text::Clevery>

=cut

