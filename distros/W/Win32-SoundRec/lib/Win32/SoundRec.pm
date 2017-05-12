#!/usr/bin/perl
package Win32::SoundRec;

use strict;
use warnings;
use Win32::API::Prototype;

use vars qw ($VERSION);
$VERSION     = 0.02;

BEGIN
{
   ApiLink( 'winmm.dll', 
             'DWORD mciSendString( LPTSTR lpstrCommand, LPTSTR lpstrReturnString, DWORD uReturnLength, HWND hwndCallBack)' ) 
             || die "Can't register mciSendString";
   ApiLink( 'winmm.dll', 
             'DWORD mciGetErrorString( DWORD dwError, LPTSTR lpstrBuffer, DWORD uLength)' ) 
             || die "Can't register mciGetErrorString";
} 
sub new
{
    my $proto = shift;
    my $char = shift;
    my $self = {};
    my $class = ref($proto) || $proto;
    bless $self, $class;
    $self->{alias} = 'mysound';
    $self->{bitspersample} = 8;
    $self->{samplespersec} = 11025;
    $self->{channels} = 1;
    $self->{filename} = 'test.wav';

    
    return $self;
}

sub record 
{
    my $self = shift;
    my $bitspersample = shift || $self->{bitspersample};
    my $samplespersec = shift || $self->{samplespersec};
    my $channels = shift || $self->{channels};
    
    my $uReturnLength = 1024;
    my $lpstrReturnString = NewString( $uReturnLength );
    my $lpstrBuffer = NewString( $uReturnLength );
        
    my $Result = main::mciSendString( "open new type waveaudio alias ".$self->{alias}, 
                                $lpstrReturnString, 
                                1024, 
                                0);
    if ( $Result != 0 ) 
    {
       my $eResult = main::mciGetErrorString($Result, $lpstrBuffer, 1024);
       warn CleanString( $lpstrBuffer ) . "\n";
    }
    
    
    $Result = main::mciSendString( "set ".$self->{alias}." time format ms bitspersample $bitspersample samplespersec $samplespersec channels $channels", 
                             $lpstrReturnString, 
                             1024, 
                             0);
    if ( $Result != 0 ) 
    {
       my $eResult = main::mciGetErrorString($Result, $lpstrBuffer, 1024);
       warn CleanString( $lpstrBuffer ) . "\n";
    }
    
    
    $Result = main::mciSendString( "record ".$self->{alias}, 
                             $lpstrReturnString, 
                             1024, 
                             0);
    if ( $Result != 0 ) 
    {
       my $eResult = main::mciGetErrorString($Result, $lpstrBuffer, 1024);
       warn CleanString( $lpstrBuffer ) . "\n";
    }

}

sub play 
{
    my $self = shift;

    my $uReturnLength = 1024;
    my $lpstrReturnString = NewString( $uReturnLength );
    my $lpstrBuffer = NewString( $uReturnLength );

    my $Result = main::mciSendString( "play ".$self->{alias}." from 1", 
                                $lpstrReturnString, 
                                1024, 
                                0);
    if ( $Result != 0 ) 
    {
       my $eResult = main::mciGetErrorString($Result, $lpstrBuffer, 1024);
       warn CleanString( $lpstrBuffer ) . "\n";
    }
}


sub stop 
{
    my $self = shift;
    my $uReturnLength = 1024;
    my $lpstrReturnString = NewString( $uReturnLength );
    my $lpstrBuffer = NewString( $uReturnLength );

    my $Result = main::mciSendString( "stop ".$self->{alias}, 
                                $lpstrReturnString, 
                                1024, 
                                0);
    if ( $Result != 0 ) 
    {
       my $eResult = main::mciGetErrorString($Result, $lpstrBuffer, 1024);
       warn CleanString( $lpstrBuffer ) . "\n";
    }
}



sub save 
{
    my $self = shift;
    my $filename = shift || $self->{filename};

    my $uReturnLength = 1024;
    my $lpstrReturnString = NewString( $uReturnLength );
    my $lpstrBuffer = NewString( $uReturnLength );

    my $Result = main::mciSendString( "save ".$self->{alias}." $filename", 
                                $lpstrReturnString, 
                                1024, 
                                0);
    if ( $Result != 0 ) 
    {
       my $eResult = main::mciGetErrorString($Result, $lpstrBuffer, 1024);
       warn CleanString( $lpstrBuffer ) . "\n";
    }

    $Result = main::mciSendString( "close ".$self->{alias}, 
                             $lpstrReturnString, 
                             1024, 
                             0);

    if ( $Result != 0 ) 
    {
       my $eResult = main::mciGetErrorString($Result, $lpstrBuffer, 1024);
       warn CleanString( $lpstrBuffer ) . "\n";
    }
}

=pod

=head1 NAME

Win32::SoundRec - Module for recording sound on Win32 platforms

=head1 SYNOPSIS

    use Win32::SoundRec;
    
    my $r =  Win32::SoundRec->new();
    # start recording...
    $r->record();
    # wait 5 seconds
    sleep(5);
    # Playback the recording buffer
    $r->play();
    sleep(5);
    # stop record or playback
    $r->stop();
    # save the recording
    $r->save('my.wav');

=head1 DESCRIPTION

This module allows recording of sound on Win32 platforms using the MCI interface (which
depends on winmm.dll).

=head1 PREREQUISITES

An MCI compatible soundcard

=head1 USAGE

=head2 new()

The new() method is the constructor. It connects to the mci interface.

=head2 record([$bitspersample, $samplespersec, $channels])

This method starts recording the audio. After calling the record function, you
should sleep() as long as you want to record.
The three parameters are optional. $bitspersample defaults to 8, $samplespersec
defaults to 11025, $channels defaults to 1. 

=head2 play

This method plays back the unsaved recording buffer

=head2 stop

This method stops the playback or record action

=head2 save([$filename])

This methods closes and saves the recording. By default the recording buffer is saved
in 'test.wav'. If you specify a valid $filename, the buffer is saved in that file
    
=head1 SUPPORT

You can email the author for support on this module.

=head1 AUTHOR

	Jouke Visser
	jouke@cpan.org
	http://jouke.pvoice.org

    Based largely on code posted to the perl-win32-users mailinglist by Jeff Slutzky
    
=head1 COPYRIGHT

Copyright (c) 2003-2005 Jouke Visser. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

"Yet Another True Value";

__END__


