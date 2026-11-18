package Text::Nunjucks::Lib::TemplateError;
# ABSTRACT: Nunjucks TemplateError (src/lib.js) -- name is always 'Template render error'

our $VERSION = '0.001';

use Moo;
use Scalar::Util qw( blessed );
use namespace::autoclean;

# 1:1 port of the TemplateError constructor / Update method in src/lib.js. The
# JS constructor is positional -- new TemplateError(message, lineno, colno) --
# and 'message' may itself be an Error, in which case it becomes the cause and
# the message turns into "${cause.name}: ${cause.message}". BUILDARGS mirrors
# that. Object.setPrototypeOf / Error.captureStackTrace / the stack + cause
# getters are JS-runtime plumbing with no Perl analogue and are not ported.

has message      => ( is => 'rw' );
has name         => ( is => 'ro', init_arg => undef, default => sub { 'Template render error' } );
has lineno       => ( is => 'ro' );
has colno        => ( is => 'ro' );
has cause        => ( is => 'ro' );
has first_update => ( is => 'rw', default => sub { 1 } );

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  return $class->$orig(@args) if @args == 1 && ref $args[0] eq 'HASH';

  my ( $message, $lineno, $colno ) = @args;
  my %attrs = ( lineno => $lineno, colno => $colno );

  # if (message instanceof Error) -- a caught error object we are wrapping
  if ( blessed($message) && $message->can('name') && $message->can('message') ) {
    $attrs{cause}   = $message;
    $attrs{message} = $message->name . ': ' . $message->message;
  } else {
    $attrs{message} = $message;
  }

  return $class->$orig(%attrs);
};

# err.Update(path) -- prepend the template path and, on the first update only,
# the line/column of the originating template.
sub update {
  my ( $self, $path ) = @_;

  # JS: '(' + (path || 'unknown path') + ')'  -- '' is falsy in JS too
  my $msg = '(' . ( ( defined $path && length $path ) ? $path : 'unknown path' ) . ')';

  # only show lineno + colno next to path of template where error occurred
  if ( $self->first_update ) {
    if ( $self->lineno && $self->colno ) {
      $msg .= ' [Line ' . $self->lineno . ', Column ' . $self->colno . ']';
    } elsif ( $self->lineno ) {
      $msg .= ' [Line ' . $self->lineno . ']';
    }
  }

  $msg .= "\n ";
  if ( $self->first_update ) {
    $msg .= ' ';
  }

  $self->message( $msg . ( $self->message // '' ) );
  $self->first_update(0);
  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Lib::TemplateError - Nunjucks TemplateError (src/lib.js) -- name is always 'Template render error'

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The error a failed template raises when the Environment is built with the
C<dev> option, a port of Nunjucks' C<TemplateError> from C<src/lib.js>. Without
C<dev> the same message and name arrive as a plain L<Text::Nunjucks::Lib::Error>.
Catch it with C<eval>, or receive it as the first argument of a render callback.

    my $env = Text::Nunjucks::Environment->new( [], { dev => 1 } );
    eval { $env->render_string( '{% if %}', {} ); 1 } or do {
      my $err = $@;
      printf "%s at %d:%d\n%s\n", $err->name, $err->lineno, $err->colno, $err->message;
    };

=head2 message

The text. For an error raised while a template renders it is prefixed with the
template path and, for the first prefix, the line and column:
C<(page.njk) [Line 3, Column 5]> followed by a newline and the reason. An error
from compiling a template (C<compile> of L<Text::Nunjucks::Template>,
or the one C<get_exported> hands to its callback) carries the bare reason.

=head2 name

Always C<Template render error>.

=head2 lineno

The line of the template where the error happened. Errors from the parser and
from C<throwOnUndefined> count from 1; errors raised while rendering carry
Nunjucks' own value, which counts from 0 (C<a\nb {{ foo() }}> gives line 1,
column 8, shown as C<[Line 1, Column 8]>).

=head2 colno

The column, counted like L</lineno>.

=head2 cause

The error object this one wraps, when it was made from one (its message is then
C<NAME: MESSAGE> of the cause).

=head2 new

    Text::Nunjucks::Lib::TemplateError->new( $message, $lineno, $colno );

Positional. C<$message> is a string, or an error object with C<name> and
C<message> that becomes the C<cause>.

=head2 update

    $err->update($path);

Prefixes the message with the template path (C<unknown path> when it is empty)
and, on the first call only, with the line and column. Called by the engine as
the error travels up through the templates that included each other; returns
the error.

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
