package Win32::IEFavorites::DateTime;

use strict;
use warnings;

our $VERSION = '0.06';

use base qw( DateTime );
use Win32::FileTime;

sub new {
  my ($class, $filetime) = @_;

  my $self = $class->SUPER::new( &_filetime_hash($filetime) );

  $self;
}

sub _filetime_hash {
  my $filetime_str = shift;

  # Can safely omit the last two digit of the string.
  # See http://www.cyanwerks.com/file-format-url.html
  # and especially his VB6 demo there.

  my @hexes = unpack('a2a2a2a2a2a2a2a2',$filetime_str);
  my $filetime = pack(
    'LL',
    hex(join('', reverse @hexes[0..3] )),
    hex(join('', reverse @hexes[4..7] )),
  );

  my @systimes = Win32::FileTime->getTime($filetime);

  return (
    year      => $systimes[0],
    month     => $systimes[1],
#   dayofweek => $systimes[2],
    day       => $systimes[3],
    hour      => $systimes[4],
    minute    => $systimes[5],
    second    => $systimes[6],
  );
}

1;
__END__

=head1 NAME

Win32::IEFavorites::DateTime - DateTime-ize IE's Favorites' modified time

=head1 SYNOPSIS

  use Win32::IEFavorites;

  my @items = Win32::IEFavorites->find;

  foreach my $item (@items) {
    print $item->url,"\n";
    print $item->modified->ymd,"\n";
  }

=head1 METHODS

=head2 new ( FILETIME string )

Returns an DateTime object.

=head1 SEE ALSO

L<http://www.cyanwerks.com/file-format-url.html>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
