package Text::Treesitter::Bash::Security::Rule::SensitiveAccess;
# ABSTRACT: Detect access to sensitive files and directories
our $VERSION = '0.001';
use strict;
use warnings;
use parent 'Text::Treesitter::Bash::Security::Rule';

my @SENSITIVE_PATTERNS = (
  [ qr{/etc/shadow},       'high',   'Shadow password file access' ],
  [ qr{/etc/sudoers},      'high',   'sudoers file access' ],
  [ qr{/\.ssh/},           'high',   'SSH directory access' ],
  [ qr{/\.aws/},           'high',   'AWS credentials directory access' ],
  [ qr{/\.kube/},          'high',   'Kubernetes config access' ],
  [ qr{/etc/passwd},       'medium', 'Password database access' ],
  [ qr{/etc/group},        'medium', 'Group database access' ],
  [ qr{/proc/self/},       'medium', 'Process self introspection' ],
  [ qr{/sys/fs/},          'medium', 'Filesystem sysfs access' ],
  [ qr{/dev/},             'low',    'Device file access' ],
);

sub check {
  my ( $class, $command ) = @_;

  for my $arg ( @{ $command->{argv} // [] } ) {
    next if ref $arg;

    for my $tuple (@SENSITIVE_PATTERNS) {
      my ( $pattern, $severity, $message ) = @$tuple;

      if ( $arg =~ $pattern ) {
        return {
          rule     => 'SensitiveAccess',
          severity => $severity,
          message  => "$message: $arg",
          arg      => $arg,
          command  => $command->{command}
        };
      }
    }
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Treesitter::Bash::Security::Rule::SensitiveAccess - Detect access to sensitive files and directories

=head1 VERSION

version 0.001

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-text-treesitter-bash/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
