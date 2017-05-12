package Winamp::Controller;

use 5.016003;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Winamp::Controller ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Winamp::Controller - control winamp using Perl via network

=head1 SYNOPSIS

  use Winamp::Controller;
  
  # connect to Winamp
  my $winamp = new Winamp::Controller();
  $winamp->set_host("192.168.1.6");
  $winamp->set_port("4800");
  $winamp->set_password("mypassword");
  
  # clears your playlist
  $winamp->delete();

  # each element from @music array is a path to a random mp3 file
  my @music = $winamp->generateplaylist('D:\Media\MP3\Rockabilly',2);
  for (@music)
    {
    # enqueue a file on WinAmp
    $winamp->enqueuefile($_);
    }

=head1 DESCRIPTION

Winamp::Controller is a module to control winamp using Perl via network or local.

=head1 PREREQUISITES

You will need the Winamp plugin "httpQ" on the machine playing
the music via winamp. You may find it searching at the winamp website:

	http://www.winamp.com

Or directly from the author:

	http://www.kostaa.com/winamp/

After installing this plugin, open Winamp Options >> Preferences. Go to Plugins >> General purpose >> Configure selected plugin. Then you can start the service, define port number, password, and other details.

=head1 METHODS

=head2 new

Creates a new winamp object.
  
  my $winamp = new Winamp::Controller();
  
Or you can inform IP, port and password:

  my $winamp = new Winamp::Controller('192.168.0.6','4800','mypassword');

=head2 set_host

Set the host to connect to Winamp httpQ plugin. This is required. Host must be configured under Winamp httpQ settings.

  $winamp->set_host('192.168.0.4')

=head2 set_port

Set the port to connect to Winamp httpQ plugin, usually 4800. Port is a required parameter, and must be configured under Winamp httpQ settings.

  $winamp->set_port('4800');
  
=head2 set_password

Set the password to connect to Winamp httpQ plugin. Password is optional, and should be configured under Winamp httpQ settings.

  $winamp->set_password("mypassword");

=head2 httpq_version

Get httpQ plugin version, or an error message if it fails.

  $winamp->httpq_version();

=head2 chdir

Change the working direcotry to 'argument'. It returns 1 on success, 0 otherwise.

  $winamp->chdir('C:\Media\Mp3');

=head2 delete

Clears the contents of the play list. It return 1 on success, 0 otherwise.

  $winamp->delete();

=head2 deletepos

Deletes the playlist item at index 'argument'. Note that the index of first music in your playlist is 0. It return 1 on success, 0 otherwise.

  $winamp->deletepos(0);

=head2 enqueuefile

Append a file to the playlist. The file must be in the current working directory or pass in the directory along with the filename as the argument. It return 1 on success, 0 otherwise.

  $winamp->enqueuefile('D:\Media\MP3\Joy Division - Love will tear us apart.mp3');

=head2 generateplaylist

This method generates a playlist without repeating the same music. Better than shuffle option, which always repeats the same music again and again. Better than use Winamp Open Dialog or Windows Explorer to load files, because the music will always be sorted by artist name. Great to broadcast your playlist.

This method receives as argument:

$_[0] = a path to a directory containing your music. It doesn't matter how many subdiretories are inside it, all mp3/wav/wma/ogg files will be loaded to Winamp.

$_[1] = random level, 1 or 2, where:

1 = A playlist will be generated mixing all files from all subdirectories. If you have a subdirectory with dance music mp3 files, other subdirectory with heavy metal, and other with world music, music styles will be mixed.

2 = This method will randomize per subdirectory. So it will play first a directory, then other, then other.

It returns an array containing random paths to mp3 files.

  use Winamp::Controller;
  my $winamp = new Winamp::Controller('192.168.1.6','4800','passwordhere');
  my @music = $winamp->generateplaylist('D:\Media\Radio\Music',2);
  for (@music)
    {
    $winamp->enqueuefile($_);
    }

=head1 AUTHOR

Eduardo Maia, maia@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Eduardo Maia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
