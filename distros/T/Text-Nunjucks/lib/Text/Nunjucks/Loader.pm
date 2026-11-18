package Text::Nunjucks::Loader;
# ABSTRACT: 1:1 port of Nunjucks src/loader.js -- the base Loader (resolve/isRelative)

our $VERSION = '0.001';

use Moo;
with 'Text::Nunjucks::EmitterObj';
use Text::Nunjucks::Lib;
use namespace::autoclean;

# src/loader.js: `module.exports = class Loader extends EmitterObj { resolve;
# isRelative }`. EmitterObj -> the on/emit role (ADR 0002). The concrete
# loaders extend it in their own modules: src/node-loaders.js's FileSystemLoader
# is Text::Nunjucks::Loader::FileSystem, src/precompiled-loader.js's
# PrecompiledLoader is Text::Nunjucks::Loader::Precompiled (ADR 0018).
#
# `cache` is not declared by loader.js -- Environment attaches `loader.cache = {}`
# in _initLoaders. Declaring it here (with the same empty-hash default) gives the
# Environment a clean accessor to reach for instead of poking the object's guts.
has cache => ( is => 'rw', default => sub { {} } );

# loaders opt into async by setting `loader.async = true`; the base is sync.
# Environment reads `loader.async`, so the base answers it (falsey).
sub async { return }

sub _lib { 'Text::Nunjucks::Lib' }

# resolve(from, to) -- path.resolve(path.dirname(from), to), through node's own
# path functions in Lib (ADR 0018): lexical, so '..' collapses on the string
# and the file system is never asked (from 'views/sub/page.njk', '../d.njk' is
# '<cwd>/views/d.njk'), anchored at the working directory only when `from` is
# relative. Environment.resolveTemplate calls it for a relative name, and the
# result is both the loader's cache key and the name getSource receives.
sub resolve {
  my ( $self, $from, $to ) = @_;
  return $self->_lib->node_path_resolve( $self->_lib->node_path_dirname($from), $to );
}

# isRelative(filename) -- a name starting './' or '../'.
sub is_relative {
  my ( $self, $filename ) = @_;
  return ( index( $filename, './' ) == 0 || index( $filename, '../' ) == 0 ) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Loader - 1:1 port of Nunjucks src/loader.js -- the base Loader (resolve/isRelative)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The base class of every template loader, a port of Nunjucks C<src/loader.js>.
A loader finds the source of a template by name for an
L<Text::Nunjucks::Environment>. L<Text::Nunjucks::Loader::FileSystem> and
L<Text::Nunjucks::Loader::Precompiled> extend it, and so does a loader of your
own. It does the C<resolve> / C<is_relative> work for relative template names
and takes the C<on> / C<emit> event methods from L<Text::Nunjucks::EmitterObj>.

=head2 Writing a loader

Extend this class and provide C<get_source>:

    package My::Loader;
    use Moo;
    extends 'Text::Nunjucks::Loader';

    sub get_source {
      my ( $self, $name ) = @_;
      return unless exists $self->templates->{$name};
      return { src => $self->templates->{$name}, path => $name, noCache => 0 };
    }
    has templates => ( is => 'ro', default => sub { {} } );

    my $env = Text::Nunjucks::Environment->new( My::Loader->new( templates => { 'hi.njk' => 'Hi {{ who }}' } ) );

C<get_source($name)> returns a hash reference, or C<undef> (or an empty
return) when the loader does not have the template, so the next loader is
asked. The hash has these keys:

=over 4

=item src

The template source as a string. A hash reference C<< { type => 'code', obj =>
\%compiled } >> is a precompiled template, see
L<Text::Nunjucks::Loader::Precompiled>.

=item path

The template's path or name, shown in error messages.

=item noCache

True to keep the Environment from caching the template, so the next lookup
asks the loader again. The key keeps its JavaScript spelling because the
Environment reads it by that name.

=back

A loader that finds its templates asynchronously defines C<async> to return a
true value; its C<get_source> then receives a callback as the second argument
and calls it, instead of returning:

    sub async { 1 }
    sub get_source {
      my ( $self, $name, $cb ) = @_;
      $cb->( undef, { src => $src, path => $path } );   # found
      $cb->( undef, undef );                            # not found, next loader
      $cb->($err);                                      # failed
    }

The callbacks run synchronously unless the loader defers them (ADR 0003).
An asynchronous loader serves C<render> and C<render_string> with a callback,
and C<get_template> with a callback.

A loader announces what it did with C<emit>: C<< $self->emit( load => $name,
$source ) >> after a template was read, C<< $self->emit( update => $name,
$fullname ) >> when one changed on its own. The Environment listens to both.

=head2 cache

Hash reference of the compiled templates the loader holds. The Environment
sets it to a fresh hash when it takes the loader over and replaces it on
C<invalidate_cache>.

=head2 async

Returns false. A loader that is asynchronous overrides it to return true, see
above.

=head2 resolve

    my $name = $loader->resolve( $from, $to );

Resolves the relative template name C<$to> against the template C<$from>, as
Node's C<path.resolve( path.dirname($from), $to )>: purely on the strings (a
C<..> removes the directory before it, the file system is not asked), and
against the current working directory when C<$from> is itself relative. The
result is the name the loader's C<get_source> receives and its cache key
(ADR 0018).

=head2 is_relative

    my $bool = $loader->is_relative($filename);

True (C<1>) when the name starts with C<./> or C<../>, otherwise C<0>.

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
