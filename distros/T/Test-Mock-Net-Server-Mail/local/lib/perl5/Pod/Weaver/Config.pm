package Pod::Weaver::Config;
# ABSTRACT: stored configuration loader role
$Pod::Weaver::Config::VERSION = '4.015';
use Moose::Role;

use Config::MVP 2;
use Pod::Weaver::Config::Assembler;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod The config role provides some helpers for writing a configuration loader using
#pod the L<Config::MVP|Config::MVP> system to load and validate its configuration.
#pod
#pod =attr assembler
#pod
#pod The L<assembler> attribute must be a Config::MVP::Assembler, has a sensible
#pod default that will handle the standard needs of a config loader.  Namely, it
#pod will be pre-loaded with a starting section for root configuration.
#pod
#pod =cut

sub build_assembler {
  my $assembler = Pod::Weaver::Config::Assembler->new;

  my $root = $assembler->section_class->new({
    name    => '_',
  });

  $assembler->sequence->add_section($root);

  return $assembler;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Config - stored configuration loader role

=head1 VERSION

version 4.015

=head1 DESCRIPTION

The config role provides some helpers for writing a configuration loader using
the L<Config::MVP|Config::MVP> system to load and validate its configuration.

=head1 ATTRIBUTES

=head2 assembler

The L<assembler> attribute must be a Config::MVP::Assembler, has a sensible
default that will handle the standard needs of a config loader.  Namely, it
will be pre-loaded with a starting section for root configuration.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
