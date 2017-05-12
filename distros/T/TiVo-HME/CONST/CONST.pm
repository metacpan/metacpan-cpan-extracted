package TiVo::HME::CONST;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.1';

# The empty resource
sub ID_NULL		{ 0 };

# Id of App
sub ID_ROOT_STREAM	{ 1 };

# set-resource-to-view alignments
#	for use with $view->set_resource
sub	HALIGN_LEFT 	{ 0x0 };
sub	HALIGN_CENTER 	{ 0x2 };
sub	HALIGN_RIGHT 	{ 0x4 };
sub	VALIGN_TOP 		{ 0x10 };
sub	VALIGN_CENTER 	{ 0x20 };
sub	VALIGN_BOTTOM 	{ 0x40 };
sub	TEXT_WRAP 		{ 0x100 };
sub	IMAGE_HFIT 		{ 0x1000 };
sub	IMAGE_VFIT 		{ 0x2000 };
sub	IMAGE_BESTFIT 	{ 0x4000 };

# font styles
#	for use with HME::Resource->font
sub FONT_PLAIN 		{ 0 };
sub FONT_BOLD 		{ 1 };
sub FONT_ITALIC 	{ 2 };
sub	FONT_BOLDITALIC	{ 3 };

# pre-defined sound resources
#	use 
#	HME::Resource::DEFAULT_RESOURCE[HME::CONST->ID_BONK_SOUND]->set_speed(1);
#		to play sound
#
sub ID_BONK_SOUND  		{ 20 }; #  bonk sound  
sub ID_UPDOWN_SOUND  	{ 21 }; #  up/down arrow sound  
sub ID_THUMBSUP_SOUND  	{ 22 }; #  thumbs up sound  
sub ID_THUMBSDOWN_SOUND { 23 }; #  thumbs down sound  
sub ID_SELECT_SOUND		{ 24 }; #  select sound  
sub ID_TIVO_SOUND		{ 25 }; #  TiVo ®  sound  
sub ID_LEFT_SOUND		{ 26 }; #  left arrow sound  
sub ID_RIGHT_SOUND		{ 27 }; #  right arrow sound  
sub ID_PAGEUP_SOUND		{ 28 }; #  page up sound  
sub ID_PAGEDOWN_SOUND	{ 29 }; #  page down sound  
sub ID_ALERT_SOUND  	{ 30 }; #  alert sound  
sub ID_DESELECT_SOUND  	{ 31 }; #  deselect sound  
sub ID_ERROR_SOUND  	{ 32 }; #  error sound  
sub ID_SLOWDOWN1_SOUND  { 33 }; #  trickplay slow down sound  
sub ID_SPEEDUP1_SOUND  	{ 34 }; #  trickplay speedup 1 sound  
sub ID_SPEEDUP2_SOUND  	{ 35 }; #  trickplay speedup 2 sound  
sub ID_SPEEDUP3_SOUND  	{ 36  }; # trickplay speedup 3 sound  

# Safe areas
sub SAFE_ACTION_H	{ 32 };
sub SAFE_ACTION_V	{ 24 };
sub SAFE_TITLE_H	{ 64 };
sub SAFE_TITLE_V	{ 48 };

# Events
sub EVT_DEVICE_INFO 	{ 1 };
sub EVT_APP_INFO 		{ 2 };
sub EVT_RSRC_INFO 	 	{ 3 };
sub EVT_KEY  			{ 4 };

# Key Actions
sub KEY_PRESS       { 1 };
sub KEY_REPEAT      { 2 };
sub KEY_RELEASE     { 3 };

# Keys
sub KEY_UNKNOWN     { 0 };
sub KEY_TIVO		{ 1 };
sub KEY_UP          { 2 }; # arrow up  
sub KEY_DOWN        { 3 }; # arrow down  
sub KEY_LEFT        { 4 }; # arrow left  
sub KEY_RIGHT       { 5 }; # arrow right  
sub KEY_SELECT      { 6 }; # select  
sub KEY_PLAY        { 7 }; # play  
sub KEY_PAUSE       { 8 }; # pause  
sub KEY_SLOW        { 9 }; # play slowly
sub KEY_REVERSE     { 10 }; # reverse  
sub KEY_FORWARD     { 11 }; # fast forward  
sub KEY_REPLAY      { 12 }; # instant replay  
sub KEY_ADVANCE     { 13 }; # advance to next marker
sub KEY_THUMBSUP    { 14 }; # thumbs up  
sub KEY_THUMBSDOWN  { 15 }; # thumbs down  
sub KEY_VOLUMEUP    { 16 }; # volume up  
sub KEY_VOLUMEDOWN  { 17 }; # volume down
sub KEY_CHANNELUP   { 18 }; # channel up  
sub KEY_CHANNELDOW  { 19 }; # channel down  
sub KEY_MUTE        { 20 }; # mute  
sub KEY_RECORD      { 21 }; # record  
sub KEY_WINDOW      { 22 }; # PIP
sub KEY_LIVETV      { 23 }; # back to live TV  
sub KEY_EXIT        { 24 }; # exit  
sub KEY_INFO        { 25 }; # info  
sub KEY_LIST        { 26 }; # list now playing  
sub KEY_GUIDE       { 27 }; # guide 
sub KEY_CLEAR       { 28 }; # clear  
sub KEY_ENTER       { 29 }; # enter  
sub KEY_NUM0        { 40 }; # 0  
sub KEY_NUM1        { 41 }; # 1  
sub KEY_NUM2        { 42 }; # 2  
sub KEY_NUM3        { 43 }; # 3  
sub KEY_NUM4        { 44 }; # 4
sub KEY_NUM5        { 45 }; # 5  
sub KEY_NUM6        { 46 }; # 6  
sub KEY_NUM7        { 47 }; # 7  
sub KEY_NUM8        { 48 }; # 8  
sub KEY_NUM9        { 49 }; # 9  

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

TiVo::HME::CONST - Perl extension for blah blah blah

=head1 SYNOPSIS

  use TiVo::HME::CONST;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for TiVo::HME::CONST, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Mark Ethan Trostler, E<lt>makr@zzo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Mark Ethan Trostler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
