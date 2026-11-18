package Text::Nunjucks::Loader::FileSystem;
# ABSTRACT: 1:1 port of Nunjucks src/node-loaders.js FileSystemLoader -- templates from search paths on disk

our $VERSION = '0.001';

use Moo;
use builtin qw( is_bool true false );
use Text::Nunjucks::Lib;
use Text::Nunjucks::Lib::Error;
use Text::Nunjucks::Runtime;
use namespace::autoclean;

no warnings 'experimental::builtin';

extends 'Text::Nunjucks::Loader';

# src/node-loaders.js defines FileSystemLoader and NodeResolveLoader and
# re-exports PrecompiledLoader. Only FileSystemLoader is ported here;
# PrecompiledLoader is Text::Nunjucks::Loader::Precompiled, NodeResolveLoader
# (require.resolve over node_modules) is out of scope (ADR 0018).
#
# The node built-ins it calls -- path.normalize, path.resolve, fs.existsSync,
# fs.readFileSync(p, 'utf-8'), console.log -- are Lib's node_* functions, node
# v24.19.0's behaviour, posix (ADR 0018). The opts it reads are any JS value
# (upstream still warns about a boolean), so they are read as JS reads them,
# through Runtime's member_lookup and truthiness.
#
# constructor(searchPaths, opts) sets this.pathsToNames, this.noCache and
# this.searchPaths: the attributes below, snake_cased for Perl. They are rw
# because the constructor body assigns them, as upstream does, once Moo built
# the object: BUILDARGS keeps the positional arguments, BUILD is the body
# (super() is Moo's).

has search_paths   => ( is => 'rw' );
has no_cache       => ( is => 'rw' );
has paths_to_names => ( is => 'rw' );
has _init_args     => ( is => 'ro' );

# Collaborators named once, reached through the invocant (house rule).
sub _lib         { 'Text::Nunjucks::Lib' }
sub _runtime     { 'Text::Nunjucks::Runtime' }
sub _error_class { 'Text::Nunjucks::Lib::Error' }

# new FileSystemLoader(searchPaths, opts) -- positional.
sub BUILDARGS {
  my ( $class, @args ) = @_;
  return { _init_args => [@args] };
}

# constructor(searchPaths, opts)
sub BUILD {
  my ($self) = @_;
  my ( $search_paths, $opts ) = @{ $self->_init_args // [] };
  delete $self->{_init_args};
  my $rt = $self->_runtime;
  if ( is_bool($opts) ) {
    $self->_lib->node_console_log(
      '[nunjucks] Warning: you passed a boolean as the second '
        . 'argument to FileSystemLoader, but it now takes an options '
        . 'object. See http://mozilla.github.io/nunjucks/api.html#filesystemloader'
    );
  }

  $opts = $rt->_truthy($opts) ? $opts : {};
  $self->paths_to_names( {} );
  $self->no_cache( $rt->_truthy( $rt->member_lookup( $opts, 'noCache' ) ) ? true : false );

  if ( $rt->_truthy($search_paths) ) {
    $search_paths = $self->_lib->is_array($search_paths) ? $search_paths : [$search_paths];
    # For windows, convert to forward slashes
    $self->search_paths( [ map { $self->_lib->node_path_normalize($_) } @$search_paths ] );
  }
  else {
    $self->search_paths( ['.'] );
  }

  if ( $rt->_truthy( $rt->member_lookup( $opts, 'watch' ) ) ) {
    # Watch all the templates in the paths and fire an event when
    # they change -- through chokidar, which has no Perl image: the port is
    # upstream without it installed, so its require() fails and upstream's
    # catch throws (ADR 0018).
    die $self->_error_class->new('watch requires chokidar to be installed');
  }
}

sub get_source {
  my ( $self, $name ) = @_;
  my $fullpath = undef;
  my $paths    = $self->search_paths;

  for ( my $i = 0; $i < @$paths; $i++ ) {
    my $base_path = $self->_lib->node_path_resolve( $paths->[$i] );
    my $p         = $self->_lib->node_path_resolve( $paths->[$i], $name );

    # Only allow the current directory and anything
    # underneath it to be searched
    #
    # A string-prefix test, as upstream's p.indexOf(basePath) === 0: a sibling
    # whose name extends the search path's passes it ('views' admits
    # '../views2/x.njk'). Ported as is (ADR 0004).
    if ( index( $p, $base_path ) == 0 && $self->_lib->node_fs_exists_sync($p) ) {
      $fullpath = $p;
      last;
    }
  }

  if ( !$fullpath ) {
    return undef;
  }

  $self->paths_to_names->{$fullpath} = $name;

  my $source = {
    src     => $self->_lib->node_fs_read_file_sync_utf8($fullpath),
    path    => $fullpath,
    noCache => $self->no_cache,
  };
  $self->emit( 'load', $name, $source );
  return $source;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Loader::FileSystem - 1:1 port of Nunjucks src/node-loaders.js FileSystemLoader -- templates from search paths on disk

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Loads templates from directories on disk, a port of the C<FileSystemLoader> of
Nunjucks C<src/node-loaders.js>. A template name is looked up in each search
path in turn and the first file that exists is read as UTF-8 and returned.

    use Text::Nunjucks::Environment;
    use Text::Nunjucks::Loader::FileSystem;

    my $loader = Text::Nunjucks::Loader::FileSystem->new( [ 'views', 'shared' ], { noCache => 1 } );
    my $env    = Text::Nunjucks::Environment->new($loader);

=head2 search_paths

Array reference of the directories searched, in order.

=head2 no_cache

True when the Environment must not cache the templates this loader returns.

=head2 paths_to_names

Hash reference mapping the absolute path of each template the loader has read
to the name it was asked for.

=head2 new

    Text::Nunjucks::Loader::FileSystem->new;
    Text::Nunjucks::Loader::FileSystem->new( $search_paths, \%opts );

Positional. C<$search_paths> is a directory or an array reference of them;
without it the search path is C<.>. The options are a hash reference with one
useful key, C<noCache>: when true the templates are not cached and are read
again on each lookup. A C<watch> option that is true dies with a
L<Text::Nunjucks::Lib::Error> whose message is
C<watch requires chokidar to be installed>.

=head2 get_source

    my $source = $loader->get_source($name);

Returns C<< { src => $text, path => $absolute_path, noCache => $bool } >> for
the first search path that holds the template, or C<undef> when none does. A
file is only found when its absolute path begins with the absolute search path,
so C<../outside.njk> is not served from beyond the search path (the check is a
string prefix test, which a sibling directory whose name starts with the search
path's name passes). Emits C<load> with the name and the source.

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
