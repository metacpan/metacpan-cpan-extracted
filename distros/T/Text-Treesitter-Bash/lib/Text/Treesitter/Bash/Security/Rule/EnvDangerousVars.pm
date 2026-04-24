package Text::Treesitter::Bash::Security::Rule::EnvDangerousVars;
# ABSTRACT: Detect dangerous environment variables in commands
our $VERSION = '0.001';
use strict;
use warnings;
use parent 'Text::Treesitter::Bash::Security::Rule';

my @DANGEROUS_VARS = (
  [ 'LD_PRELOAD',   'high',   'LD_PRELOAD can inject shared libraries' ],
  [ 'LD_AUDIT',     'high',   'LD_AUDIT can inject shared libraries' ],
  [ 'DYLD_INSERT_LIBRARIES', 'high', 'macOS DYLD injection' ],
  [ 'DYLD_LIBRARY_PATH',     'high', 'macOS DYLD library path hijacking' ],
  [ 'BASH_ENV',     'high',   'BASH_ENV executes code in non-interactive bash' ],
  [ 'ENV',          'high',   'ENV executes code in interactive bash' ],
  [ 'CDPATH',       'low',    'CDPATH can cause unexpected directory changes' ],
  [ 'GIT_DIR',      'low',    'GIT_DIR can redirect git operations' ],
);

sub check {
  my ( $class, $command ) = @_;

  my $source = $command->{source} // '';

  for my $tuple (@DANGEROUS_VARS) {
    my ( $var, $severity, $message ) = @$tuple;

    if ( $source =~ m{\b(?:export\s+)?\Q$var\E\b}s ) {
      return {
        rule     => 'EnvDangerousVars',
        severity => $severity,
        message  => "$message in command",
        command  => $command->{command},
        source   => $source
      };
    }
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Treesitter::Bash::Security::Rule::EnvDangerousVars - Detect dangerous environment variables in commands

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
