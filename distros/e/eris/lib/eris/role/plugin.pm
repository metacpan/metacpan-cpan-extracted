package eris::role::plugin;
# ABSTRACT: Common interface for implementing an eris plugin

use Moo::Role;
use Types::Standard qw(Bool Int Str);

our $VERSION = '0.008'; # VERSION




has name => (
    is  => 'lazy',
    isa => Str,
);

sub _build_name {
    my ($self) = @_;
    my ($class) = ref $self;
    my ($namespace) = $self->namespace;
    # Trim Name Space
    my $name = $class =~ s/^${namespace}:://r;

    # Replace colons with underscores
    return $name =~ s/::/_/gr;
}


has 'priority' => (
    is  => 'lazy',
    isa => Int,
);
sub _build_priority  { 50 }


has 'enabled' => (
    is => 'lazy',
    isa => Bool,
);
sub _build_enabled   { 1 }


has 'namespace' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::plugin - Common interface for implementing an eris plugin

=head1 VERSION

version 0.008

=head1 SYNOPSIS

Sprinkled into other plugins in the eris project to set
expectations for the plugin loaders

    package eris::role::context;

    use Moo::Role;
    with qw( eris::role::plugin );

=head1 ATTRIBUTES

=head2 name

The name of the plugin.  Defaults to stripping the plugin namespace from the
object's class name and replacing '::' within an underscore.

=head2 priority

An integer representing the priority ordering of the plugin in loading, lower
priority will appear in the beginning of the plugins list. Defaults to 50.

=head2 enabled

Boolean indicating if the plugin is enabled by default.  Defaults
to true.  The L<eris::dictionary::eris::debug> uses this set to false
to prevent it's data from accidentally entering the default schemas.

=head2 namespace

The primary namespace for these plugins.  This is used to auto_trim it from the
plugin's name for simpler config templates.

This is a B<required> parameter.

=head1 SEE ALSO

L<eris::role::pluggable>, L<eris::role::context>, L<eris::role::decoder>, L<eris::role::dictionary>
L<eris::role::schema>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
