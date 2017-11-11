package Win32::Shortkeys::Kbh;
#use blib qw( U:/docs/perl/mod/hg_Win32-Shortkeys-Kbh/blib);

=head1 NAME

Win32::Shortkeys::Kbh - Perl extension for hooking the keyboard on windows

=cut

use strict;
use warnings;
use Carp;
require Exporter;
#use AutoLoader qw(AUTOLOAD);

our $VERSION = '0.01';

=head1 VERSION

0.01

=cut

our @ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Win32::Shortkeys::Kbh ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    input => [ qw(send_string send_cmd paste_from_clpb) ],
   hook => [qw(register_hook unregister_hook msg_loop set_key_processor quit)],
   vkcode => [qw (
VK_LBUTTON VK_RBUTTON VK_CANCEL VK_MBUTTON VK_XBUTTON1 VK_XBUTTON2 VK_BACK 
VK_TAB VK_CLEAR VK_RETURN VK_SHIFT VK_CONTROL VK_MENU VK_PAUSE VK_CAPITAL 
VK_KANA VK_HANGEUL VK_HANGUL VK_JUNJA VK_FINAL VK_HANJA VK_KANJI VK_ESCAPE 
VK_CONVERT VK_NONCONVERT VK_ACCEPT VK_MODECHANGE VK_SPACE VK_PRIOR VK_NEXT 
VK_END VK_HOME VK_LEFT VK_UP VK_RIGHT VK_DOWN VK_SELECT VK_PRINT VK_EXECUTE 
VK_SNAPSHOT VK_INSERT VK_DELETE VK_HELP VK_LWIN VK_RWIN VK_APPS VK_SLEEP 
VK_NUMPAD0 VK_NUMPAD1 VK_NUMPAD2 VK_NUMPAD3 VK_NUMPAD4 VK_NUMPAD5 VK_NUMPAD6 
VK_NUMPAD7 VK_NUMPAD8 VK_NUMPAD9 VK_MULTIPLY VK_ADD VK_SEPARATOR VK_SUBTRACT 
VK_DECIMAL VK_DIVIDE VK_F1 VK_F2 VK_F3 VK_F4 VK_F5 VK_F6 VK_F7 VK_F8 VK_F9 
VK_F10 VK_F11 VK_F12 VK_F13 VK_F14 VK_F15 VK_F16 VK_F17 VK_F18 VK_F19 VK_F20 
VK_F21 VK_F22 VK_F23 VK_F24 VK_NUMLOCK VK_SCROLL VK_OEM_NEC_EQUAL 
VK_OEM_FJ_JISHO VK_OEM_FJ_MASSHOU VK_OEM_FJ_TOUROKU VK_OEM_FJ_LOYA 
VK_OEM_FJ_ROYA VK_LSHIFT VK_RSHIFT VK_LCONTROL VK_RCONTROL VK_LMENU 
VK_RMENU VK_BROWSER_BACK VK_BROWSER_FORWARD VK_BROWSER_REFRESH 
VK_BROWSER_STOP VK_BROWSER_SEARCH VK_BROWSER_FAVORITES VK_BROWSER_HOME 
VK_VOLUME_MUTE VK_VOLUME_DOWN VK_VOLUME_UP VK_MEDIA_NEXT_TRACK 
VK_MEDIA_PREV_TRACK VK_MEDIA_STOP VK_MEDIA_PLAY_PAUSE VK_LAUNCH_MAIL 
VK_LAUNCH_MEDIA_SELECT VK_LAUNCH_APP1 VK_LAUNCH_APP2 VK_OEM_1 VK_OEM_PLUS 
VK_OEM_COMMA VK_OEM_MINUS VK_OEM_PERIOD VK_OEM_2 VK_OEM_3 VK_OEM_4 VK_OEM_5 
VK_OEM_6 VK_OEM_7 VK_OEM_8 VK_OEM_AX VK_OEM_102 VK_ICO_HELP VK_ICO_00 
VK_PROCESSKEY VK_ICO_CLEAR VK_PACKET VK_OEM_RESET VK_OEM_JUMP VK_OEM_PA1 
VK_OEM_PA2 VK_OEM_PA3 VK_OEM_WSCTRL VK_OEM_CUSEL VK_OEM_ATTN VK_OEM_FINISH 
VK_OEM_COPY VK_OEM_AUTO VK_OEM_ENLW VK_OEM_BACKTAB VK_ATTN VK_CRSEL 
VK_EXSEL VK_EREOF VK_PLAY VK_ZOOM VK_NONAME VK_PA1 VK_OEM_CLEAR
)],
 );
 my %seen;
push @{$EXPORT_TAGS{all}},
grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
 
Exporter::export_tags('hook');
Exporter::export_ok_tags(qw(input vkcode)); 


require XSLoader;
XSLoader::load('Win32::Shortkeys::Kbh', $VERSION);

use constant {
 VK_LBUTTON =>0x01,
 VK_RBUTTON =>0x02,
 VK_CANCEL =>0x03,
 VK_MBUTTON =>0x04,
 VK_XBUTTON1 =>0x05,
 VK_XBUTTON2 =>0x06,
 VK_BACK =>0x08,
 VK_TAB =>0x09,
 VK_CLEAR =>0x0C,
 VK_RETURN =>0x0D,
 VK_SHIFT =>0x10,
 VK_CONTROL =>0x11,
 VK_MENU =>0x12,
 VK_PAUSE =>0x13,
 VK_CAPITAL =>0x14,
 VK_KANA =>0x15,
 VK_HANGEUL =>0x15,
 VK_HANGUL =>0x15,
 VK_JUNJA =>0x17,
 VK_FINAL =>0x18,
 VK_HANJA =>0x19,
 VK_KANJI =>0x19,
 VK_ESCAPE =>0x1B,
 VK_CONVERT =>0x1C,
 VK_NONCONVERT =>0x1D,
 VK_ACCEPT =>0x1E,
 VK_MODECHANGE =>0x1F,
 VK_SPACE =>0x20,
 VK_PRIOR =>0x21,
 VK_NEXT =>0x22,
 VK_END =>0x23,
 VK_HOME =>0x24,
 VK_LEFT =>0x25,
 VK_UP =>0x26,
 VK_RIGHT =>0x27,
 VK_DOWN =>0x28,
 VK_SELECT =>0x29,
 VK_PRINT =>0x2A,
 VK_EXECUTE =>0x2B,
 VK_SNAPSHOT =>0x2C,
 VK_INSERT =>0x2D,
 VK_DELETE =>0x2E,
 VK_HELP =>0x2F,
 VK_LWIN =>0x5B,
 VK_RWIN =>0x5C,
 VK_APPS =>0x5D,
 VK_SLEEP =>0x5F,
 VK_NUMPAD0 =>0x60,
 VK_NUMPAD1 =>0x61,
 VK_NUMPAD2 =>0x62,
 VK_NUMPAD3 =>0x63,
 VK_NUMPAD4 =>0x64,
 VK_NUMPAD5 =>0x65,
 VK_NUMPAD6 =>0x66,
 VK_NUMPAD7 =>0x67,
 VK_NUMPAD8 =>0x68,
 VK_NUMPAD9 =>0x69,
 VK_MULTIPLY =>0x6A,
 VK_ADD =>0x6B,
 VK_SEPARATOR =>0x6C,
 VK_SUBTRACT =>0x6D,
 VK_DECIMAL =>0x6E,
 VK_DIVIDE =>0x6F,
 VK_F1 =>0x70,
 VK_F2 =>0x71,
 VK_F3 =>0x72,
 VK_F4 =>0x73,
 VK_F5 =>0x74,
 VK_F6 =>0x75,
 VK_F7 =>0x76,
 VK_F8 =>0x77,
 VK_F9 =>0x78,
 VK_F10 =>0x79,
 VK_F11 =>0x7A,
 VK_F12 =>0x7B,
 VK_F13 =>0x7C,
 VK_F14 =>0x7D,
 VK_F15 =>0x7E,
 VK_F16 =>0x7F,
 VK_F17 =>0x80,
 VK_F18 =>0x81,
 VK_F19 =>0x82,
 VK_F20 =>0x83,
 VK_F21 =>0x84,
 VK_F22 =>0x85,
 VK_F23 =>0x86,
 VK_F24 =>0x87,
 VK_NUMLOCK =>0x90,
 VK_SCROLL =>0x91,
 VK_OEM_NEC_EQUAL =>0x92,
 VK_OEM_FJ_JISHO =>0x92,
 VK_OEM_FJ_MASSHOU =>0x93,
 VK_OEM_FJ_TOUROKU =>0x94,
 VK_OEM_FJ_LOYA =>0x95,
 VK_OEM_FJ_ROYA =>0x96,
 VK_LSHIFT =>0xA0,
 VK_RSHIFT =>0xA1,
 VK_LCONTROL =>0xA2,
 VK_RCONTROL =>0xA3,
 VK_LMENU =>0xA4,
 VK_RMENU =>0xA5,
 VK_BROWSER_BACK =>0xA6,
 VK_BROWSER_FORWARD =>0xA7,
 VK_BROWSER_REFRESH =>0xA8,
 VK_BROWSER_STOP =>0xA9,
 VK_BROWSER_SEARCH =>0xAA,
 VK_BROWSER_FAVORITES =>0xAB,
 VK_BROWSER_HOME =>0xAC,
 VK_VOLUME_MUTE =>0xAD,
 VK_VOLUME_DOWN =>0xAE,
 VK_VOLUME_UP =>0xAF,
 VK_MEDIA_NEXT_TRACK =>0xB0,
 VK_MEDIA_PREV_TRACK =>0xB1,
 VK_MEDIA_STOP =>0xB2,
 VK_MEDIA_PLAY_PAUSE =>0xB3,
 VK_LAUNCH_MAIL =>0xB4,
 VK_LAUNCH_MEDIA_SELECT =>0xB5,
 VK_LAUNCH_APP1 =>0xB6,
 VK_LAUNCH_APP2 =>0xB7,
 VK_OEM_1 =>0xBA,
 VK_OEM_PLUS =>0xBB,
 VK_OEM_COMMA =>0xBC,
 VK_OEM_MINUS =>0xBD,
 VK_OEM_PERIOD =>0xBE,
 VK_OEM_2 =>0xBF,
 VK_OEM_3 =>0xC0,
 VK_OEM_4 =>0xDB,
 VK_OEM_5 =>0xDC,
 VK_OEM_6 =>0xDD,
 VK_OEM_7 =>0xDE,
 VK_OEM_8 =>0xDF,
 VK_OEM_AX =>0xE1,
 VK_OEM_102 =>0xE2,
 VK_ICO_HELP =>0xE3,
 VK_ICO_00 =>0xE4,
 VK_PROCESSKEY =>0xE5,
 VK_ICO_CLEAR =>0xE6,
 VK_PACKET =>0xE7,
 VK_OEM_RESET =>0xE9,
 VK_OEM_JUMP =>0xEA,
 VK_OEM_PA1 =>0xEB,
 VK_OEM_PA2 =>0xEC,
 VK_OEM_PA3 =>0xED,
 VK_OEM_WSCTRL =>0xEE,
 VK_OEM_CUSEL =>0xEF,
 VK_OEM_ATTN =>0xF0,
 VK_OEM_FINISH =>0xF1,
 VK_OEM_COPY =>0xF2,
 VK_OEM_AUTO =>0xF3,
 VK_OEM_ENLW =>0xF4,
 VK_OEM_BACKTAB =>0xF5,
 VK_ATTN =>0xF6,
 VK_CRSEL =>0xF7,
 VK_EXSEL =>0xF8,
 VK_EREOF =>0xF9,
 VK_PLAY =>0xFA,
 VK_ZOOM =>0xFB,
 VK_NONAME =>0xFC,
 VK_PA1 =>0xFD,
 VK_OEM_CLEAR =>0xF
};


my $key_processor;

sub set_key_processor {
    $key_processor = shift;
    confess ("set_key_processor must receive a sub ref") unless (ref $key_processor eq "CODE");
}

sub process_key {

    #  my ($cup, $code, $alt, $ext) = @_;
    #print "process_key in perl cup: $cup code: $code alt: $alt ext: $ext \n";
    $key_processor->(@_);
   
}

1;

__END__

=head1 SYNOPSIS
   
    use Win32::Shortkeys::Kbh qw(:hook :input VK_BACK VK_TAB);
    
    set_key_processor(sub {
        my ($cup, $code, $alt, $ext) = @_;
       # return on keypressed
        return if $cup == 0;

         print "process_key in perl cup: $cup code: $code alt: $alt ext: $ext \n";
        if ($code == 123) { 
            unregister_hook(); 
            quit();
        }

        if ($code == 83) { 
             sleep 1; #or usleep from Time::HiRes for shorter time
             unregister_hook();
             send_cmd(1, VK_BACK); #erase the key pressed
             send_string("You hit the s key !!!"); #and send something else
             register_hook();
        }
    
    });
    register_hook();
    msg_loop();



=head1 DESCRIPTION

This module uses Win32 API fucntions to create a keyboard hook with C<register_hook>. 
A sub ref is pass to the hook with C<set_key_processor>. 
This sub is called on key press and key release. It receives the key code and can react using C<seng_string> or C<send_cmd>. 

If you run the code (also in example/example.pl) in the synopsis and if you open the notepad any keys except the s will be print out normaly. 
When the s key is relead the keyboard will print 'You hit the s key'. 
F12 will terminate the script. 

=head2 C<set_key_processor( $my_sub_ref )>

The sub passed to this function received the following parameters

=over

=item  $cup

Indicates if the key is released ($cup > 0) or pressed ($cup == 0)

=item $code

The virtual key code of the key

=item $alt

Indicates if the alt key is pressed ($alt > 0) or not ($alt == 0)

=item $ext

Indicates  ($ext == 1) if extended-key flag is set or not ($ext == 0). Following ms windows documentation this flag is set 
if one of the additional keys on the enhanced keyboard is used. 
The extended keys consist of the ALT and CTRL keys on the right-hand side of the keyboard; 
the INS, DEL, HOME, END, PAGE UP, PAGE DOWN, and arrow keys in the clusters to the left of the numeric keypad; 
the NUM LOCK key; the BREAK (CTRL+PAUSE) key; the PRINT SCRN key; 
and the divide (/) and ENTER keys in the numeric keypad.

=back

=head2 C<register_hook>

=head2 C<unregister_hook>

=head2 C<msg_loop>

calls this to prevent your script from leaving and use next function to quit.

=head2 C<quit>

=head2 C<send_cmd($how_much, $vk_code)>

VK_CODE are exported by this module and can be use as constant in the perl code.

=head2 C<send_string("bla")>

 C<register_hook>. Send string (C<send_string("bla")>or commands C<send_cmd(how_much, VK_TAB)> to the keyboard: 

=head2 EXPORT

None by default.

=head2 EXPORT_OK

The following export tags are defined to import on request:

C<input> for C<send_string send_cmd paste_from_clpb>

C<hook> for C<register_hook unregister_hook msg_loop set_key_processor qui>

C<vkcode> to import all the VK_CODE defined

C<all> to import everything.

=head1 EXAMPLE

The code from the SYNOPSIS above can be run from the example/example.pl script.

=head1 INSTALLATION

To install this module type the following:
	perl Makefile.PL
	make
	make test
	make install

On windows use nmake or dmake instead of make.

=head1 SEE ALSO

L<Win32::Shortkeys>

=head1 SUPPORT

Questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from

L<http://sourceforge.net/projects/win32-shortkeys-kbh/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
