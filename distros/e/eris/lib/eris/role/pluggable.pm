package eris::role::pluggable;

use Moo::Role;
use Types::Standard qw(ArrayRef HashRef InstanceOf Str);
use namespace::autoclean;
use Module::Pluggable::Object;

########################################################################
# Attributes
has namespace => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_namespace',
);
has search_path => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    lazy    => 1,
    default => sub { [] },
);
has disabled => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    lazy    => 1,
    default => sub { [] },
);
has 'loader' => (
    is      => 'ro',
    isa     => InstanceOf['Module::Pluggable::Object'],
    lazy    => 1,
    builder => '_build_loader',
);
has 'plugins' => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    builder => '_build_plugins',
);
has 'plugins_config' => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub {{}},
);
########################################################################
# Builders
sub _build_loader {
    my ($self) = @_;
    my $loader = Module::Pluggable::Object->new(
            search_path => [ $self->namespace, @{$self->search_path} ],
            except      => $self->disabled,
            instantiate => 'new',
    );
    return $loader;
}

sub _build_plugins {
    my $self = shift;
    return [ sort { $a->priority <=> $b->priority || $a->name cmp $b->name } $self->loader->plugins( %{ $self->plugins_config } ) ];
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::pluggable

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
