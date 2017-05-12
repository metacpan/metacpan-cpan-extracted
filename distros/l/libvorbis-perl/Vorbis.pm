package Ogg::Vorbis;

use strict;
use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

BEGIN {
  $VERSION = '0.04';
  @ISA = qw(Exporter DynaLoader);
  # We don't EXPORT anything by default
  @EXPORT = ();
  @EXPORT_OK = qw(
    clear
    open
    streams
    seekable
    bitrate
    bitrate_instant
    serialnumber
    raw_total
    pcm_total
    time_total
    raw_seek
    pcm_seek
    pcm_seek_page
    time_seek
    time_seek_page
    raw_tell
    pcm_tell
    time_tell
    info
    comment
    read
  );
  %EXPORT_TAGS = (all => \@EXPORT_OK);
}

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
		croak "Your vendor has not defined Ogg::Vorbis macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap Ogg::Vorbis $VERSION;

1;
__END__


=head1 NAME

Ogg::Vorbis - Perl extension for Ogg Vorbis streams

=head1 SYNOPSIS

  use Ogg::Vorbis;
  $ogg = Ogg::Vorbis->new;
  open(INPUT, "< file.ogg");
  open(OUTPUT, "> file.pcm");
  $ogg->open(INPUT);
  $info = $ogg->info;
  %comments = %{$ogg->comment};
  $buffer = '-' x 4096;
  while ($bytes = $ogg->read($buffer,4096,0,2,1,$current_bitstream) > 0) {
    syswrite(OUTPUT, $buffer, $bytes);
  }
  $ogg->clear;
  close(OUTPUT);
  close(INPUT);

=head1 DESCRIPTION

This is an object-oriented interface to the Ogg Vorbis libvorbisfile
convenience library.  To create a vorbisfile object, call
Ogg::Vorbis->new.  You can then open it on input streams with the
open() method, read data from it with read() method, and clean up with
clear().  Other methods for obtaining information are available as in
libvorbisfile.

The info() method returns an Ogg::Vorbis::Info object.  You can access
the various fields of the vorbis_info struct with methods of the same
name.

The comment() method returns a hash of comment name => value entries.

Currently libvorbisfile does not support writing or encoding, so you
cannot change comment values or encode a new file, but the
functionality to do so will be added soon.

=head1 AUTHOR

Alex Shinn, foof@debian.org

=head1 SEE ALSO

Ao(3pm), ogg123(1), oggenc(1), perl(1).

=cut

