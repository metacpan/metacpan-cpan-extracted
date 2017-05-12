package WWW::Cache::Google;

use strict;
use vars qw($VERSION);
$VERSION = 0.04;

use URI;
use URI::Escape;

sub cache_base {
    return 'http://www.google.com/search?q=cache:%s';
}


# ro-accessor
sub orig   { $_[0]->[0] }
sub cache  { $_[0]->[1] }

sub new {
    my($class, $thingy) = @_;
    my $uri = _make_uri($thingy);
    my $self = bless [ $uri ], $class;
    $self->init;
    return $self;
}

sub _make_uri {
    my $thingy = shift;
    return $thingy if UNIVERSAL::isa($thingy => 'URL');
    return URI->new($thingy);
}

sub init {
    my $self = shift;
    my $uri = sprintf $self->cache_base, $self->_cache_param;
    $self->[1] = URI->new($uri);
}

sub _cache_param {
    my $self = shift;
    return $self->orig->host . uri_escape($self->orig->path_query, q(\W));
}

sub fetch {
    require LWP::Simple;
    my $self = shift;
    return LWP::Simple::get($self->cache->as_string);
}

sub DESTROY { }

use vars qw($AUTOLOAD);
sub AUTOLOAD {
    my $self = shift;
    (my $meth = $AUTOLOAD) =~ s/.*://;
    $self->cache->$meth(@_);
}


1;
__END__


=head1 NAME

WWW::Cache::Google - URI class for Google cache

=head1 SYNOPSIS

  use WWW::Cache::Google;

  $cache = WWW::Cache::Google->new('http://www.yahoo.com/');

  $url  = $cache->as_string;	# cache URL
  $html = $cache->fetch; 	# fetches via LWP::Simple

=head1 DESCRIPTION

Oops, 404 Not Found. But wait ... there might be a google cache!

WWW::Cache::Google provides an easy way conversion from an URL to
Google cache URL.

If all you want is only to get cache B<content>, consider using Google
Web APIs at http://www.google.com/apis/index.html

  $html = SOAP::Lite
      ->uri('urn:GoogleSearch')
      ->proxy('http://api.google.com/search/beta2') # may change
      ->doGetCachedPage($GoogleKey, 'http://cpan.org/')
      ->result;

=head1 METHODS

=over 4

=item $cache = WWW::Cache::Google->new($url);

constructs WWW::Cache::Google instance.

=item $orig_uri = $cache->orig;

returns original URL as URI instance.

=item $cache_uri = $cache->cache;

returns Google cache URL as URI instance.

=item $html = $cache->fetch;

gets HTML contents of Google cache. Requires LWP::Simple.

=item $url_str = $cache->as_string;

returns Google cache's URL as string. Every method defined in URI
class is autoloaded through $cache->cache. See L<URI> for details.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

It comes WITHOUT WARRANTY OF ANY KIND.

=head1 SEE ALSO

L<WWW::Cache::Google::Imode>, L<URI>, L<URI::Escape>, L<LWP::Simple>,
http;//www.google.com/ http://www.google.com/apis/index.html

=cut
