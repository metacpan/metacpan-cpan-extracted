package Text::Treesitter::Bash::Security::Checker;
# ABSTRACT: Run security rules against parsed Bash commands
our $VERSION = '0.001';
use strict;
use warnings;
use Carp qw( croak );
use Module::Load qw( load );

sub new {
  my ( $class, %args ) = @_;

  my @rules = @{ $args{rules} // [] };
  my @instances;

  for my $rule (@rules) {
    if ( !ref $rule ) {
      my $class_name = "Text::Treesitter::Bash::Security::Rule::$rule";
      load($class_name);
      $rule = $class_name;
    }
    push @instances, $rule;
  }

  return bless { rules => \@instances }, $class;
}

sub check_commands {
  my ( $self, @commands ) = @_;

  my @issues;

  for my $command (@commands) {
    for my $rule ( @{ $self->{rules} } ) {
      my @result = $rule->check($command);
      push @issues, @result if @result;
    }
  }

  return @issues;
}

sub check_source {
  my ( $self, $source ) = @_;

  require Text::Treesitter::Bash;
  my $bash = Text::Treesitter::Bash->new;
  my @commands = $bash->commands($source);

  return $self->check_commands(@commands);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Treesitter::Bash::Security::Checker - Run security rules against parsed Bash commands

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
