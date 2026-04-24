package Text::Treesitter::Bash::Security::Rule::PathTraversal;
# ABSTRACT: Detect path traversal patterns in commands
our $VERSION = '0.001';
use strict;
use warnings;
use parent 'Text::Treesitter::Bash::Security::Rule';

sub check {
  my ( $class, $command ) = @_;

  my @issues;

  for my $arg ( @{ $command->{argv} // [] } ) {
    next if ref $arg;

    if ( $arg =~ m{(?:\.\./|/etc/../|/proc/../|/sys/../)} ) {
      push @issues, {
        rule     => 'PathTraversal',
        severity => 'high',
        message  => "Path traversal detected: $arg",
        arg      => $arg,
        command  => $command->{command}
      };
    }

    if ( $arg =~ m{(?:\A|\s)(/proc/self|/proc/\$\$|/sys/fs)} ) {
      push @issues, {
        rule     => 'PathTraversal',
        severity  => 'medium',
        message   => "Sensitive path access: $arg",
        arg       => $arg,
        command   => $command->{command}
      };
    }
  }

  return @issues;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Treesitter::Bash::Security::Rule::PathTraversal - Detect path traversal patterns in commands

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
