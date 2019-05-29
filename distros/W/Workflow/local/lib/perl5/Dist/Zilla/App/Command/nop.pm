use strict;
use warnings;
package Dist::Zilla::App::Command::nop 6.010;
# ABSTRACT: initialize dzil, then exit

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod This command does nothing.  It initializes Dist::Zilla, then exits.  This is
#pod useful to see the logging output of plugin initialization.
#pod
#pod   dzil nop -v
#pod
#pod Seriously, this command is almost entirely for diagnostic purposes.  Don't
#pod overthink it, okay?
#pod
#pod =cut

sub abstract { 'do nothing: initialize dzil, then exit' }

sub description {
  "This command does nothing but initialize Dist::Zilla and exit.\n" .
  "It is sometimes useful for diagnostic purposes."
}

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->zilla;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::nop - initialize dzil, then exit

=head1 VERSION

version 6.010

=head1 SYNOPSIS

This command does nothing.  It initializes Dist::Zilla, then exits.  This is
useful to see the logging output of plugin initialization.

  dzil nop -v

Seriously, this command is almost entirely for diagnostic purposes.  Don't
overthink it, okay?

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
