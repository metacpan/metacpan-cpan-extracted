package Win32::IEFavorites::Item;

use strict;
use warnings;

our $VERSION = '0.06';

use Config::IniFiles;
use Win32::IEFavorites::DateTime;

sub new {
  my ($class, $path) = @_;

  bless {
    path     => $path,
    cached   => 0,
    datetime => undef,
  }, $class;
}

sub _value {
  my ($self, $type) = @_;
  $self->_load unless $self->{cached};

  $self->{$type};
}

sub _load {
  my $self = shift;
  my $ini  = Config::IniFiles->new( -file => $self->{path} );
  foreach my $type (qw/URL Modified IconFile IconIndex/) {
    if (defined $ini) {
      $self->{lc($type)} = $ini->val('InternetShortcut',$type) || '';
    } else {
      $self->{lc($type)} = '';
    }
  }
  $self->{cached} = 1;
}

sub path      { $_[0]->{path}; }
sub url       { $_[0]->_value('url'); }
sub iconfile  { $_[0]->_value('iconfile'); }
sub iconindex { $_[0]->_value('iconindex'); }

sub modified  {
  my $self     = shift;
  unless ($self->{datetime}) {
    my $modified = $self->_value('modified');
    $self->{datetime} = Win32::IEFavorites::DateTime->new($modified);
  }
  $self->{datetime};
}

1;
__END__

=head1 NAME

Win32::IEFavorites::Item - Internet Explorer's Favorites item

=head1 SYNOPSIS

  use Win32::IEFavorites;

  my @items = Win32::IEFavorites->find;

  foreach my $item (@items) {
    print $item->url,"\n";
    print $item->modified->ymd,"\n";
  }

=head1 METHODS

=head2 new

Creates an object.

=head2 path

Returns the path of the shortcut.

=head2 url

Returns the url of the shortcut.

=head2 modified

Returns a DateTime object for the modified time of the shortcut.

=head2 iconfile

Returns the icon file of the shortcut.

=head2 iconindex

Returns the icon index of the shortcut.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
