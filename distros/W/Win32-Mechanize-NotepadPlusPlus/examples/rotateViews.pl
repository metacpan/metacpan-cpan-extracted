#!perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use Win32::Mechanize::NotepadPlusPlus ':all';

## 
#  Based on:
#   https://community.notepad-plus-plus.org/topic/18615/shortcut-or-menu-path-to-rotate-to-right-left/4

my $ROTATION_A_LEFT  = 2000;
my $ROTATION_A_RIGHT = 2001;
my $WM_COMMAND       = 0x111;
my $FindWindowEx     = Win32::API->new( 'user32', 'FindWindowEx', 'NNPP', 'N' );
my $SendMessage      = Win32::API->new( 'user32', 'SendMessage', 'qIQq', 'q' );
my $IsWindowVisible  = Win32::API->new( 'user32', 'IsWindowVisible', 'q', 'N' );
sub LOWORD { return ( $_[0] & 0xFFFF); }

my $swap = 0;
my $rotate = $ROTATION_A_RIGHT;
sub rotate { 
    if ( $_[0] eq 'l' ) {
        $rotate = $ROTATION_A_LEFT
    }
}

GetOptions(
    'l|left'     => \&rotate,
    'r|right'    => \&rotate,
    's|swap'     => \$swap,
    'help!'      => sub { pod2usage( -verbose => 1 ) },
    'man!'       => sub { pod2usage( -verbose => 2 ) }
) or pod2usage( -verbose => 0 );

# Begin
my $splitterHwnd = $FindWindowEx->Call( notepad->hwnd(), 0, "splitterContainer", 0 );
my $isVisible    = $IsWindowVisible->Call($splitterHwnd);

if ($isVisible) {
    rotateViews();
    if ( $swap ) {
        rotateViews();
    }
}

sub rotateViews {
    $SendMessage->Call( $splitterHwnd, $WM_COMMAND, LOWORD( $rotate ), 0 );
}


__END__

=head1 NAME

rotateViews - Rotate Scintilla edit views

=head1 SYNOPSIS

 rotateViews [options]

=head1 DESCRIPTION

This rotates the two Scintilla edit view windows (if visible).  It is 
equivalent to right-clicking the splitter bar and selecting "Rotate to right" 
or "Rotate to left" from the pop-up menu.

=head1 OPTIONS

 -l           Rotate to left.
 -r           Rotate to right. [Defauilt]
 -s           Swap views.

 --help       Print Options and Arguments.
 --man        Print complete man page.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2020 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
