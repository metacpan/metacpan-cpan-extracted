package Win32::Unicode::InternetShortcut;

use strict;
use warnings;
use Exporter;
use AutoLoader;
use Carp;
use Encode;

our @ISA = qw/Exporter AutoLoader/;
use vars qw/$AUTOLOAD/;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Unicode::InternetShortcut ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
                    COINIT_APARTMENTTHREADED
                    COINIT_MULTITHREADED
                    COINIT_DISABLE_OLE1DDE
                    COINIT_SPEED_OVER_MEMORY
);

our $VERSION = '0.02';
our $CROAK_ON_ERROR = 0;
our $utf16le = find_encoding('UTF-16LE') ||
    croak "Failed to load UTF16-LE encoding\n";

require XSLoader;
XSLoader::load('Win32::Unicode::InternetShortcut', $VERSION);

# Preloaded methods go here.
{
    no warnings 'redefine';
    sub AUTOLOAD {
	my $sub = $AUTOLOAD;
	(my $constname = $sub) =~ s/.*:://;
	my $val = constant($constname);
	if ($! != 0) {
	    if ($! =~ /Invalid/ || $!{EINVAL}) {
		$AutoLoader::AUTOLOAD = $sub;
		goto &AutoLoader::AUTOLOAD;
	    }
	    else {
		croak "Your vendor has not defined constant $constname";
	    }
	}
	{
	    no strict 'refs';
	    *$sub = sub { $val }; # same as: eval "sub $sub { $val }";
	    goto &$sub;
	}
    }
}

#=================
sub CoInitializeEx {
#=================
    my ($class, $coinit, $croak_on_failure) = @_;

    return(_CoInitializeEx($coinit, $croak_on_failure || $CROAK_ON_ERROR));
}

#===============
sub CoInitialize {
#===============
    my ($class, $croak_on_failure) = @_;

    return(_CoInitialize($croak_on_failure || $CROAK_ON_ERROR));
}

#===============
sub CoUninitialize {
#===============
    my ($class) = @_;

    _CoUninitialize();
}

sub new {
  my ($class, $path) = @_;
  my ($ilocator, $ifile) = _Instance($CROAK_ON_ERROR);

  bless {
         ilocator           => $ilocator,
         ifile              => $ifile,
         path               => $path,
         _cached            => 0,
         _cached_properties => 0,
         _has_datetime      => undef,
        }, $class;
}

sub save {
    my ($self, $path, $url, $croak_on_error) = @_;

    $self->_xssave($self->{ilocator}, $self->{ifile}, $path, $url, $croak_on_error || $CROAK_ON_ERROR);
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

sub load {
    my ($self, $path, $croak_on_error) = @_;

    $self->_xsload($self->{ilocator}, $self->{ifile}, $path, $croak_on_error || $CROAK_ON_ERROR);
}

sub _load {
  my $self = shift;

  $self->load($self->path);

  $self->{_cached} = 1;
}

sub invoke_url {
    my ($self, $url, $croak_on_error) = @_;

    $self->_xsinvoke_url($self->{ilocator}, $self->{ifile}, $url, $croak_on_error || $CROAK_ON_ERROR);
}

sub invoke {
    my ($self, $path, $croak_on_error) = @_;

    $self->_xsinvoke($self->{ilocator}, $self->{ifile}, $path, $croak_on_error || $CROAK_ON_ERROR);
}

sub load_properties {
    my ($self, $path, $croak_on_error) = @_;

    $self->_xsload_properties($self->{ilocator}, $self->{ifile}, $path, $croak_on_error || $CROAK_ON_ERROR);
}

sub save_properties {
    my ($self, $path, $croak_on_error) = @_;

    $self->_xssave_properties($self->{ilocator}, $self->{ifile}, $path, $croak_on_error || $CROAK_ON_ERROR);
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

Win32::Unicode::InternetShortcut - Perl extension for Windows Unicode Internet Shortcut interface

=head1 SYNOPSIS

  use Win32::Unicode::InternetShortcut;
  use File::Spec;
  use charnames ':full';
  use Encode;
  use Carp;

  our $utf16le = find_encoding('UTF-16LE') || croak "Failed to load UTF16-LE encoding\n";

  BEGIN { Win32::Unicode::InternetShortcut->CoInitialize(); }

  my $self = Win32::Unicode::InternetShortcut->new;
  my $url  = "http://www.example.com/?WonSign=\N{WON SIGN}";
  my $path = File::Spec->catfile(File::Spec->tmpdir, "TEST, last char is Hebrew Letter Alef, \N{HEBREW LETTER ALEF}.url");

  $self->save($path, $url);
  $self->load($path);
  ($self->{url} eq $url) || die "Not the same url\n";

  END { Win32::Unicode::InternetShortcut->CoUninitialize(); }

=head1 DESCRIPTION

This is the Unicode version of Win32::InternetShortcut. This module exposes all methods of Win32::InternetShortcut, plus the initialisation layer which is application specific. So the whole documentation of Win32::Unicode::InternetShortcut consists of: the documentation of Win32::InternetShortcut that the reader should read first, and the Methods section below.

Any bug in Win32::Unicode::InternetShortcut should be nevertheless send to me via RT of course -;

=head2 Methods

=over 8

=item Win32::Unicode::InternetShortcut->CoInitialize([CROAK_ON_FAILURE])

Unless your application has already initialized the COM layer, via Win32::OLE or Win32::API for example, you will have to do so.

=item Win32::Unicode::InternetShortcut->CoInitializeEx(COINIT_CONSTANT[, CROAK_ON_FAILURE])

You can have fine-grained granularity on the threading model, using CoInitializeEx. The COINIT_CONSTANT must be of one COINIT_APARTMENTTHREADED, COINIT_MULTITHREADED, COINIT_DISABLE_OLE1DDE or COINIT_SPEED_OVER_MEMORY. Apparently, COINIT_APARTMENTTHREADED is required to get the interface working in a multi-threaded environment.

=back

=head2 EXPORT

None by default.

=head2 NOTES

If the variable $Win32::Unicode::InternetShortcut::CROAK_ON_ERROR is setted to a true value, then the module will croak at any Windows API call error, with a meaningful message. For example doing a Load without an COM application initialisation will look like the following:

C:\>perl -e "use Win32::Unicode::InternetShortcut; $Win32::Unicode::InternetShortcut::CROAK_ON_ERROR = 1; $L = new Win32::Unicode::InternetShortcut;"
CoCreateInstance, CoInitialize has not been called

It is advisable to set this variable before the initialisation, and to reset it after, or to use the optional parameter of the initialisation functions to get it temporarly on during their execution.

None by default.

=head1 SEE ALSO

Win32::InternetShortcut
Understanding and Using COM Threading Models at http://msdn.microsoft.com/en-us/library/ms809971.aspx
Win32::OLE

=head1 AUTHOR

Jean-Damien Durand, E<lt>jeandamiendurand@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jean-Damien Durand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
