package WWW::MenuGrinder::Role::Plugin;
BEGIN {
  $WWW::MenuGrinder::Role::Plugin::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder role for all plugins.

use Moose::Role;

has 'grinder' => (
  is => 'ro',
  isa => 'WWW::MenuGrinder',
  required => 1,
);

sub verify_plugin {
  my ($self) = @_;

  if ($self->can('plugin_required_grinder_methods')) {
    my @methods = $self->plugin_required_grinder_methods;
    for my $m (@methods) {
      if (! $self->grinder->can($m)) {
        die ref($self) . " requires method '$m' but " . ref($self->grinder)
          . "doesn't provide it.\n";
      }
    }
  }
}

no Moose::Role;

1;

__END__
=pod

=head1 NAME

WWW::MenuGrinder::Role::Plugin - WWW::MenuGrinder role for all plugins.

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

