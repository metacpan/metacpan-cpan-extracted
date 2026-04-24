package Text::Treesitter::Bash::Security::Rule::MissingAbsolutePath;
# ABSTRACT: Detect commands without absolute paths
our $VERSION = '0.001';
use strict;
use warnings;
use parent 'Text::Treesitter::Bash::Security::Rule';

my %KNOWN_COMMANDS = map { $_ => 1 } qw(
  ls cat rm cp mv mkdir rmdir chmod chown find grep sed awk
  tar zip unzip curl wget ssh scp git docker kubectl helm
  perl python ruby node npm pip cargo go
);

sub check {
  my ( $class, $command ) = @_;

  my $name = $command->{command} // '';

  return if $name =~ m{/};

  return if $name =~ m{^\./} || $name =~ m{^\.\./};

  return if exists $KNOWN_COMMANDS{$name};

  my $source = $command->{source} // '';

  if ( $name !~ m{^[a-zA-Z_]} ) {
    return {
      rule     => 'MissingAbsolutePath',
      severity => 'low',
      message  => "Command '$name' used without absolute path",
      command  => $name
    };
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Treesitter::Bash::Security::Rule::MissingAbsolutePath - Detect commands without absolute paths

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
