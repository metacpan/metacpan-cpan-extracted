package Text::Nunjucks::Lib::Error;
# ABSTRACT: Port representation of a JS built-in Error / TypeError (name + message)

our $VERSION = '0.001';

use Moo;
use namespace::autoclean;

# src/lib.js reaches for the JS globals `new Error(...)` (inOperator) and
# `new TypeError(...)` (groupBy). Perl has no universal Error base, so the port
# models a thrown JS error as a small object carrying { name, message } -- the
# two fields _prettifyError reads back ("${cause.name}: ${cause.message}") and
# the corpus harness reads (->name / ->message). `name` defaults to 'Error';
# callers that want a different JS error type pass name => 'TypeError'.
#
# NOTE (open mapping): how JS built-in error types map to Perl is not yet
# settled by an ADR -- see the k9 report. This class is the single, minimal
# place that representation is encapsulated.

has message => ( is => 'ro' );
has name    => ( is => 'ro', default => sub { 'Error' } );

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  return $class->$orig(@args) if @args == 1 && ref $args[0] eq 'HASH';
  my ( $message, %opts ) = @args;
  return $class->$orig( message => $message, %opts );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Lib::Error - Port representation of a JS built-in Error / TypeError (name + message)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

A plain error with a name and a message. The engine throws it where JavaScript
throws a built-in C<Error> or C<TypeError> (ADR 0010) and where Nunjucks throws
C<new Error(...)>: C<template not found: NAME>, C<filter not found: NAME>,
C<watch requires chokidar to be installed> and so on. Without the C<dev>
option, a failed render also arrives as one of these, with the name
C<Template render error> and the message of the L<Text::Nunjucks::Lib::TemplateError>
it was made from. Catch it with C<eval>:

    eval { $env->render( 'page.njk', {} ); 1 } or do {
      my $err = $@;
      print $err->name, ': ', $err->message, "\n";
    };

=head2 message

The error text.

=head2 name

The error's name: C<Error> unless given, C<TypeError> for the type errors, C<RangeError> for an invalid array length,
C<URIError> for malformed URI input, C<Template render error> for a failed render.

=head2 new

    Text::Nunjucks::Lib::Error->new('something broke');
    Text::Nunjucks::Lib::Error->new( 'wrong type', name => 'TypeError' );

Takes the message and, optionally, C<< name => ... >>; a single hash reference
of attributes works too.

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
