package Test::MockFile::Plugins;

use strict;
use warnings;

our $VERSION = '0.036';

our @NAMESPACES = (q[Test::MockFile::Plugin]);

sub load_plugin {
    my ($name_or_array) = @_;

    my $list = ref $name_or_array ? $name_or_array : [$name_or_array];

    my @plugins;
    foreach my $name (@$list) {
        push @plugins, _load_plugin($name);
    }

    return @plugins;
}

sub _load_plugin {
    my ($name) = @_;

    my @candidates = map { "${_}::$name" } @NAMESPACES;

    foreach my $c (@candidates) {
        next unless _load($c);

        my $plugin = $c->new();
        return $plugin->register;
    }

    die qq[Cannot find a Test::MockFile plugin for $name];
}

sub _load {
    my ($pkg) = @_;

    return unless eval qq{ require $pkg; 1 };

    return $pkg->isa('Test::MockFile::Plugin');
}

1;

=encoding utf8

=head1 NAME

Test::MockFile::Plugins - Plugin loader

=head1 SYNOPSIS

  use Test::MockFile::Plugins;

  unshift @Test::MockFile::Plugins::NAMESPACES, q[Your::NameSpace];

  Test::MockFile::Plugins::load_plugins( 'YourPlugin' );

=head1 DESCRIPTION

L<Test::MockFile::Plugins> is responsible for loading plugins.

BETA WARNING: This is a preliminary plugins implementation. It might
change in the future.

=head1 METHODS

=head2 load_plugin( $plugin_name )

  Test::MockFile::Plugins::load_plugin( 'YourPlugin' );

=head1 SEE ALSO

L<Test::MockFile>, L<Test::MockFile::Plugin>

=cut
