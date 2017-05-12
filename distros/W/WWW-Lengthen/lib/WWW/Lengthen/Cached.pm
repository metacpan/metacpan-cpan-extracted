package WWW::Lengthen::Cached;

use strict;
use warnings;
use Carp;
use base qw( WWW::Lengthen );

sub setup_cached {
  my ($self, $cache) = @_;

  croak "cached doesn't have get" unless $cache->can('get');
  croak "cached doesn't have set" unless $cache->can('set');

  $self->{cache} = $cache;
}

sub cache { shift->{cache} }

sub try {
  my ($self, $url) = @_;

  my $longer_url;
  if ( $longer_url = $self->cache->get( "www-lengthen:$url" ) ) {
    return $longer_url;
  }

  $longer_url = $self->SUPER::try( $url );

  if ( defined $longer_url ) {
    $self->cache->set( "www-lengthen:$url" => $longer_url );
  }
  return $longer_url;
}

1;

__END__

=head1 NAME

WWW::Lengthen::Cached

=head1 SYNOPSIS

    use WWW::Lengthen::Cached;
    use Cache::Memcached;
    my $lengthener = WWW::Lengthen::Cached->new;
    my $cached = Cache::Memcached->new(...);
    $lengthener->setup_cached($cached)

    my $lengthened_url = $lengthener->try($url);

=head1 DESCRIPTION

You may want to reuse lengthened URLs. With this, you can store them in cache servers. Cache::Memcached and the likes (which have set/get methods) are supported.

=head1 METHODS

=head2 setup_cached

takes an cache daemon object and store internally.

=head2 cache

If you want to change some settings of the stored cached, use this.

=head2 try

If the requested URL is stored in the cache, just returns it. Otherwise, tries to lengthen it, and stores it if appropriate.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
