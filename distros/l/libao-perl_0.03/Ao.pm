package Ao;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	AO_ALSA
	AO_BEOS
	AO_DRIVERS
	AO_ESD
	AO_IRIX
	AO_NULL
	AO_OSS
	AO_RAW
	AO_SOLARIS
	AO_WAV
	AO_WIN32
);
@EXPORT_OK = qw(
        get_driver_id
        get_driver_info
        play
        is_big_endian
);
$VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Ao macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap Ao $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Ao - Perl extension for ao cross-platform audio library

=head1 SYNOPSIS

  use Ao;

  $ao_id1 = Ao::get_driver_id('oss');
  %ao_info = %{Ao::get_driver_info($ao_id1)};
  $ao_endian = Ao::is_big_endian();
  $ao_dev1 = Ao::open($ao_id);
  Ao::play($ao_dev1, $buffer, $len);
  Ao::close($ao_dev1);

  $ao_id2 = Ao::get_driver_id('wav');
  %ao_options = ('file' => 'out.wav');
  $ao_dev2 = Ao::open($ao_id2, 16, 44100, 2, %ao_options);
  $ao_dev2->play($buffer, $len);
  $ao_dev2->close();

=head1 DESCRIPTION

This is a simple object-oriented wrapper around the ao audio library.
Use Ao::get_driver_id to obtain an integer id from a short driver
name.  Currently supported drivers are oss, irix, solaris, esd, alsa
and wav.

A small hash of driver info (with fields name, short_name, author and
comments) can be obtained with Ao::get_driver_info.

Ao::is_big_endian can be used to test the byte-order of the machine.

Open a device with

  Ao::open($driver_id, $bits_per_sample, $rate, $channels, %options)

where the default values are 16 bits at 44100 Hz stereo, and no
options.  options is a hash of named parameters to pass to the
specific driver.  The wav driver defaults to writing output to the
file output.wav - you can change this by passing the file option.
Other options can be found in the ao documentation.

Play to a device with

  Ao::play($device, $buffer, $len)

where $device is the device returned from Ao::open, $buffer is a
pointer to a buffer of sound input, and $len is the length of the
buffered sound to play.  To obtain sound input you will need to use a
separate module such as Ogg::Vorbis.

When you are done, close the device with Ao::close($device).

=head1 Exported constants

  AO_ALSA
  AO_BEOS
  AO_DRIVERS
  AO_ESD
  AO_IRIX
  AO_NULL
  AO_OSS
  AO_RAW
  AO_SOLARIS
  AO_WAV
  AO_WIN32


=head1 AUTHOR

Alex Shinn, foof@debian.org

=head1 SEE ALSO

perl(1), Ogg::Vorbis(3pm), and the README distributed with ao.

=cut
