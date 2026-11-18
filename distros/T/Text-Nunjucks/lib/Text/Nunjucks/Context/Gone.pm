package Text::Nunjucks::Context::Gone;
# ABSTRACT: Stands in for the Context of a render that is over (ADR 0021)

our $VERSION = '0.001';

use strict;
use warnings;
use Text::Nunjucks::Lib::Error;

# A port addition with no upstream counterpart (ADR 0021). No compiled sub
# keeps the Context of its render alive (Runtime _render_scope); when a
# Context is freed, it leaves this object in every `$context` variable the
# code of its render can still see (Context DEMOLISH). Code that runs after
# that -- a macro the application kept, a continuation that is called a second
# time -- and reads nothing outside itself works as before: it calls no method
# here, or only one of the writes below. The first read -- a lookup, an
# include or import, a block call -- dies here with an error that says what
# happened, instead of Perl's "Can't call method ... on an undefined value".
#
# One process-wide object without state, like Text::Nunjucks::Runtime::None.

my $INSTANCE;
sub instance { $INSTANCE //= bless \( my $x ), __PACKAGE__ }

sub _error_class { 'Text::Nunjucks::Lib::Error' }

# The Context methods that only write. The compiled code reports each macro,
# call block and extension body it makes (Context _made_closure), and a macro
# defined inside a macro body is written into the Context, as upstream's
# compileMacro does (`context.addExport` and `context.setVariable`: the body's
# frame has no parent). A write into a Context that is gone is one nobody can
# read: everything that reads a Context -- lookup, get_variables,
# get_exported, get_block, get_super -- goes through the object, and dies
# below. So a kept macro that defines a nested macro and reads nothing outside
# itself works, as it does upstream.
#
# _keep_alive is the same kind of write: a kept macro whose body imports a
# library asks the Context to keep the library's (Context _keep_alive). The
# library's Context is held by the Template _get_exported call for as long as
# the rest of the macro body runs inside that call, so the macro renders as it
# does upstream; a macro of the library that runs later than that -- after an
# async filter deferred -- finds the library's Context gone and dies at its
# first read.
sub _made_closure { return }
sub add_export    { return }
sub set_variable  { return }
sub _keep_alive   { return }

our $AUTOLOAD;

sub AUTOLOAD {
  my ($self) = @_;
  my $method = $AUTOLOAD =~ s/.*:://r;
  return if $method eq 'DESTROY';
  die $self->_error_class->new(
    'template code ran after its render had ended: its Context is gone (' . $method . ')' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Context::Gone - Stands in for the Context of a render that is over (ADR 0021)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal. Template code that runs after its render has ended -- a macro
the application kept, or the body of its C<call> block -- finds this object
where its L<Text::Nunjucks::Context> was. A read of the Context (C<lookup>,
C<get_variables>, C<get_exported>, C<get_block>, C<get_super>, an include or
block call) dies on it with a L<Text::Nunjucks::Lib::Error> saying so; the
writes the compiled code makes into a Context nobody can read do nothing, so
a kept macro that reads only its own arguments and locals still works. See
ADR 0021 and L<Text::Nunjucks/DIFFERENCES FROM NUNJUCKS>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-text-nunjucks/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
