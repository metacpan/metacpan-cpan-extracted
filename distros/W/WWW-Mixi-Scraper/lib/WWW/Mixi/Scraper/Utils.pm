package WWW::Mixi::Scraper::Utils;

use strict;
use warnings;
use base qw/Exporter/;
use URI;
use URI::QueryParam;

our @EXPORT_OK = qw( _force_arrayref _uri _datetime );

sub _force_arrayref {
  my $thingy = shift;

  return []        if !defined $thingy || $thingy eq '';
  return [$thingy] if ref $thingy ne 'ARRAY';
  return $thingy;
}

sub _datetime {
  my $date = shift;

  unless ( defined $date ) {
    warn "datetime is not defined"; return;
  }

  my $time;
  if ( $date =~ s/\s*(\d+:\d+(?::\d+)?)\s*$// ) {
    $time = $1;
  }

  $date =~ s/\D/\-/g;
  $date =~ s/\-+$//;

  return $time ? "$date $time" : $date; # should be DateTime object?
}

sub _uri {
  my $uri = URI->new(shift);
  $uri->authority('mixi.jp') unless $uri->authority;
  $uri->scheme('http')       unless $uri->scheme;
  return $uri;
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Utils - internal utilities

=head1 DESCRIPTION

Used internally.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
