package Win32::InternetShortcut;

use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Win32::InternetShortcut', $VERSION);

sub new {
  my ($class, $path) = @_;

  bless {
    path               => $path,
    _cached            => 0,
    _cached_properties => 0,
    _has_datetime      => undef,
  }, $class;
}

sub _value {
  my ($self, $type) = @_;

  return unless $self->path;

  $self->_load unless $self->{_cached};

  $self->{$type};
}

sub _property {
  my ($self, $type) = @_;

  return unless $self->path;

  $self->_load_properties unless $self->{_cached_properties};

  $self->{properties}->{$type};
}

sub _site_property {
  my ($self, $type) = @_;

  return unless $self->path;

  $self->_load_properties unless $self->{_cached_properties};

  $self->{site_properties}->{$type};
}

sub _load {
  my $self = shift;

  $self->load($self->path);

  $self->{_cached} = 1;
}

sub _load_properties {
  my $self = shift;

  $self->load_properties($self->path);

  $self->{_cached_properties} = 1;
}

sub path {
  my ($self, $newpath) = @_;

  if (defined $newpath) {
    $_[0]->{path} = $newpath;

    if ($newpath) {
      $self->_load            if $self->{_cached};
      $self->_load_properties if $self->{_cached_properties};
    }
    else {
      $self->clear;
    }
  }

  $_[0]->{path};
}

sub clear {
  my $self = shift;

  $self->{path}            = undef;
  $self->{url}             = undef;
  $self->{modified}        = undef;
  $self->{modified_dt}     = undef;
  $self->{iconindex}       = undef;
  $self->{iconfile}        = undef;
  $self->{properties}      = undef;
  $self->{site_properties} = undef;

  $self->{_cached}            = 0;
  $self->{_cached_properties} = 0;
}

sub url       { $_[0]->_value('url'); }
sub iconfile  { $_[0]->_value('iconfile'); }
sub iconindex { $_[0]->_value('iconindex'); }

sub modified  {
  my $self = shift;

  if ($self->_check_datetime) {
    unless ($self->{modified_dt}) {
      $self->{modified_dt} = 
        $self->_datetime( $self->_value('modified') );
    }
    $self->{modified_dt};
  }
  else {
    $self->_value('modified');
  }
}

sub title       { $_[0]->_site_property('title'); }

sub lastvisits  {
  my $self = shift;

  if ($self->_check_datetime) {
    unless ($self->_site_property('lastvisits_dt')) {
      $self->{site_properties}->{lastvisits_dt} =
        $self->_datetime( $self->_site_property('lastvisits') );
    }
    $self->_site_property('lastvisits_dt');
  }
  else {
    $self->_site_property('lastvisits');
  }
}

sub lastmod     {
  my $self = shift;

  if ($self->_check_datetime) {
    unless ($self->_site_property('lastmod_dt')) {
      $self->{site_properties}->{lastmod_dt} =
        $self->_datetime( $self->_site_property('lastmod') );
    }
    $self->_site_property('lastmod_dt');
  }
  else {
    $self->_site_property('lastmod');
  }
}

sub _check_datetime {
  my $self = shift;

  unless (defined $self->{_has_datetime}) {
    eval "require DateTime";
    $self->{_has_datetime} = $@ ? 0 : 1;
  }
  $self->{_has_datetime};
}

sub _datetime {
  my ($self, $str) = @_;

  return DateTime->from_epoch( epoch => 0 )
    unless defined $str || $str !~ /^[\d :\-]+$/;

  my @t_array = split(/[: \-]/, $str);
  return DateTime->new(
    year   => $t_array[0],
    month  => $t_array[1],
    day    => $t_array[2],
    hour   => $t_array[3],
    minute => $t_array[4],
    second => $t_array[5],
  );
}

1;
__END__

=head1 NAME

Win32::InternetShortcut - handles Internet Shortcut (IE's Favorite)

=head1 SYNOPSIS

  use Win32::InternetShortcut;

  # You can get information on an existing shortcut (if possible)

  my $shortcut = Win32::InternetShortcut->new('sample.url');

  my $url        = $shortcut->url;
  my $lastvisits = $shortcut->lastvisits;

  print "You visited $url on $lastvisits";

  # and you can create a new shortcut.

  $shortcut->save('new.url', 'http://www.example.com/');

  # You also can invoke Internet Explorer if you want.

  $shortcut->invoke('new.url');

=head1 DESCRIPTION

L<Win32::InternetShortcut> handles Internet Shortcuts (.URL files 
or Internet Explorer's Favorites files). Theoretically Internet
Shortcuts are mere .INI (text) files, so you even can read with
perl's C<open>, though they have some external information, not
written in the INI text. This module can handle all, ahem, almost
all of them via XS.

=head1 METHODS

=head2 new (path)

Creates an object. You can pass .URL file's path.

=head2 load (path) [XS]

Loads basic information (stored as plain text) into my $self,
including C<url>, C<modified>, C<iconindex>, C<iconfile>.
You (almost) always can get the first two.

=head2 load_properties (path) [XS]

Loads advanced (and somewhat volatile) information into my $self.
Most of them would be undef or duplicated, but C<lastvisits> or
C<title> may be useful. These values seem to be lost if you move
shortcuts to other folders than your Favorites folder.

=head2 save (path, url) [XS]

Creates (or updates) a shortcut to the url.

=head2 invoke (path) [XS]

Invokes your default browser (probably Internet Explorer) and goes
to the url the shortcut points to.

=head2 invoke_url (url) [XS]

Also invokes your default browser and goes to the url you point to.

=head2 path (optional path)

Returns (or sets) the path of the shortcut.
Relative path would be converted into full (absolute) path
internally (and stored in $self->{fullpath}).

=head2 clear

Clears the information my $self has.

=head2 url

Returns the url the shortcut points to.

=head2 title

Would return the stored title of the website the shortcut points
to. This property is not always defined.

=head2 iconindex

Would return the icon index of the shortcut (not always defined).

=head2 iconfile

Would return the icon file of the shortcut (not always defined).

=head2 modified

Returns the modified time(?) of the shortcut. This value is stored
in the shortcut as plain (but obfuscated) text, so probably you can
always access. If you have DateTime module, returns a DateTime
object initialized by the time.

=head2 lastvisits

Would return the time you last visited the website the shortcut
points to. This value is volatile. If you have DateTime module,
returns a DateTime object initialized by the time.

=head2 lastmod

Would return the last modified time(?) of the website the shortcut
points to. This value is volatile. If you have DateTime module,
returns a DateTime object initialized by the time.

=head1 NOTES

See L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/shell/programmersguide/shell_int/shell_int_programming/shortcuts/internet_shortcuts.asp> for details.

However, do NOT trust it too much. Some of the features might not
be implemented or changed for your PC.

Below sites provide some useful information (at least for me).

=over 4

=item L<http://www.cyanwerks.com/file-format-url.html>

=item L<http://www.techieone.com/detail-6264254.html>

=item L<http://www.arstdesign.com/articles/iefavorites.html>

=back

=head1 SEE ALSO

L<Win32::IEFavorites>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
