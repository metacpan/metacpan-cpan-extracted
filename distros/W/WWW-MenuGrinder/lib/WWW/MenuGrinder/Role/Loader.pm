package WWW::MenuGrinder::Role::Loader;
BEGIN {
  $WWW::MenuGrinder::Role::Loader::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder role for plugins that load menu data.

use Moose::Role;

with 'WWW::MenuGrinder::Role::Plugin';


requires 'load';

no Moose::Role;

1;

__END__
=pod

=head1 NAME

WWW::MenuGrinder::Role::Loader - WWW::MenuGrinder role for plugins that load menu data.

=head1 VERSION

version 0.06

=head1 METHODS

=head2 C<< $plugin->load >>

Is expected to return a menu structure ready for pre-mogrification. Data may
come from disk, the network, attributes, or whatever. Takes no arguments, but
C<< $self->grinder->config >> is available.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

