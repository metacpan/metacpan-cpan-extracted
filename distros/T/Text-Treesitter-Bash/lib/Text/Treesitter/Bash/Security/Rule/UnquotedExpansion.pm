package Text::Treesitter::Bash::Security::Rule::UnquotedExpansion;
# ABSTRACT: Detect unquoted variable expansions that could split
our $VERSION = '0.001';
use strict;
use warnings;
use parent 'Text::Treesitter::Bash::Security::Rule';

sub check {
  my ( $class, $command ) = @_;

  my @issues;
  my $source = $command->{source} // '';

  if ( $source =~ m{\$[a-zA-Z_][a-zA-Z0-9_]*} && $source !~ m{".*\$[a-zA-Z_]} ) {
    my @unquoted_vars;
    while ( $source =~ m{(\$[a-zA-Z_][a-zA-Z0-9_]*)}g ) {
      push @unquoted_vars, $1;
    }

    for my $var (@unquoted_vars) {
      my $pos = index( $source, $var );
      my $after = substr( $source, $pos + length($var), 1 );
      if ( defined $after && $after =~ m{[/\-\.]} ) {
        push @issues, {
          rule     => 'UnquotedExpansion',
          severity => 'medium',
          message  => "Unquoted variable expansion may cause word splitting: $var",
          var      => $var,
          command  => $command->{command}
        };
      }
    }
  }

  return @issues;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Treesitter::Bash::Security::Rule::UnquotedExpansion - Detect unquoted variable expansions that could split

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
