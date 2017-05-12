package Win32::UrlCache::Cookies;

use strict;
use warnings;
use base qw( Win32::UrlCache );
use Win32::TieRegistry ( Delimiter => '/' );
use File::Spec;

sub new {
  my $class = shift;

  $class->SUPER::new( $class->_file );
}

sub _file {
  my $class = shift;

  my $dir   = $Registry->{'CUser/Software/Microsoft/Windows/CurrentVersion/Explorer/Shell Folders//Cookies'};

  return File::Spec->catfile( $dir, 'index.dat' );
}

1;

__END__

=head1 NAME

Win32::UrlCache::Cookies - parse Internet Explorer's Cookies index.dat

=head1 SYNOPSIS

  use Win32::UrlCache::Cookies;
  my $cache = Win32::UrlCache::Cookies->new;

=head1 DESCRIPTION

This is just a sugar for Win32::UrlCache to make Win32 users happy.

=head1 METHOD

=head2 new

searches for a cookies directory in the registry, and provides it to the parent Win32::UrlCache.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
