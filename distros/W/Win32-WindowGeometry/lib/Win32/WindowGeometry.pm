package Win32::WindowGeometry;

use Win32::API;
use Win32::API::Callback;
use base qw(Exporter);

our @EXPORT = qw|ListWindows AdjustWindow|;

our $VERSION = '1.03';

sub ListWindows($)
{
	my $strWinTitle = shift(@_);
     if(length($strWinTitle))
     {
          $strWinTitle = qr/\Q$strWinTitle\E/i;
     }
     else
     {
          $strWinTitle = qr/.{1,}/;
     }
	my @subListWinTitles;
	my $EnumWindows = Win32::API->new('user32', 'EnumWindows', 'KN', 'N');
	my $GetWindowText = Win32::API->new('user32', 'GetWindowText', 'NPN', 'N');
	my $cbEnumWindows = Win32::API::Callback->new(
		sub
			{
				my $hndWin = shift(@_);
				my $strWinText = ' ' x 255;
				my $strWinLength = $GetWindowText->Call($hndWin, $strWinText, 255);
				$strWinText = substr($strWinText, 0, $strWinLength);
				if ($strWinText =~ $strWinTitle)
				{
					push(@subListWinTitles, $strWinText);
				}
				1;
			}, 'NN', 'N');
	$EnumWindows->Call($cbEnumWindows, 0);
	return(@subListWinTitles);
}

sub AdjustWindow($$$$$)
{
	my($strWinTitle, $intPosX, $intPosY, $intDimX, $intDimY) = @_;
     if((!length($strWinTitle)) || ($intPosX !~ m/[0-9\-]{1,}/) ||  ($intPosY !~ m/[0-9\-]{1,}/) || ($intDimX !~ m/[0-9\-]{1,}/) || ($intDimY !~ m/[0-9\-]{1,}/))
     {
          return;
     }
	if($intPosX == 0)
	{
		$intPosX = -10;
	}
	my $FindWindow = Win32::API->new('user32', 'FindWindow', 'PP', 'N');
	my $MoveWindow = Win32::API->new('user32', 'MoveWindow', 'NIIIII', 'I');
	my $hndWin = $FindWindow->Call(0, $strWinTitle);
     if(length($hndWin))
     {
          $MoveWindow->Call($hndWin, $intPosX, $intPosY, $intDimX, $intDimY, 1);
     }
	return;
}

=head1 NAME

Win32::WindowGeometry - Simple module to search for open windows by title and move/resize them

=head1 SYNOPSIS

    use Win32::WindowGeometry;
     
    my @all_windows = ListWindows('');
    foreach(@all_windows)
    {
        if($_ =~ m/firefox/i)
        {
            AdjustWindow($_, 0, 0, 1024, 768);
        }
    }

    my @specific_windows = ListWindows('chrome');
    foreach(@specific_windows)
    {
        AdjustWindow($_, 50, 0, 800, 600);
    }

    my $super_specific_window = ListWindows('zoom - meeting');
    if(length($super_specific_window))
    {
        AdjustWindow($super_specific_window, 0, 0, 1920, 1080);
    }

=head1 DESCRIPTION

Simple module to search for open windows by title and move/resize them.

Pollutes the namespace with two functions: ListWindows & AdjustWindow.

=head1 METHODS

=head2 ListWindows

ListWindows('');

Returns a list of all open windows.

ListWindows('search_string'); # case insensitive

Returns a list of open windows whose titles match (or partially match)
the provided 'search_string' argument.

=head2 AdjustWindow

AdjustWindow('full_window_title_string', int_X_Position, int_Y_Position, int_X_Dimension, int_Y_Dimension);

Sets a window (provided by the full name of the window's title) to an x,y position with an x,y dimension.

=head1 Notes

I just whipped this up out of necessity when I had a project where I
needed to automate arranging/resizing some windows. I tried using an
app called "cmdow", but it hasn't been updated in years, and it made
my anti-virus go crazy. So it seemed best to make my own solution.

There is plenty of information around the web on how to 'FindWindow',
'GetWindow', etc. But not so much about moving/resizing windows. It
seemed like a good idea to put this out for the community.

=head1 Warning

This has not been rigorously tested, and there's not a great deal of
error checking or data validation going on under the hood. You may
want to add some of your own checks/validations for safety/functionality.

=head1 Version History

1.01 - Initial Release

1.02 - Fixed this POD document

1.03 - More documentation fixes

=head1 Author

Brandon Bourret

=head1 License

Permission is granted to use this software under the same terms as Perl itself.

Refer to the L<Perl Artistic|perlartistic> license for details.

=cut
