package Win32::HideConsole;

use Win32;
use Win32::API;
use base qw(Exporter);

use constant SW_HIDE => 0;
use constant SW_SHOWNORMAL => 1;

our @EXPORT = qw(hide_console);

our $VERSION = '1.01';

sub hide_console
{
	my $GetConsoleTitle = new Win32::API('kernel32', 'GetConsoleTitle', 'PN', 'N');
	my $SetConsoleTitle = new Win32::API('kernel32', 'SetConsoleTitle', 'P', 'N');
	my $FindWindow = new Win32::API('user32', 'FindWindow', 'PP', 'N');
	my $ShowWindow = new Win32::API('user32', 'ShowWindow', 'NN', 'N');
	my $old_title = " " x 1024;
	$GetConsoleTitle->Call($old_title, 1024);
	my $title = "PERL-$$-".Win32::GetTickCount();
	$SetConsoleTitle->Call($title);
	Win32::Sleep(100);
	$hw = $FindWindow->Call(0, $title);
	$SetConsoleTitle->Call($old_title);
	$ShowWindow->Call($hw, SW_HIDE);
}

=head1 NAME

Win32::HideConsole

=head1 SYNOPSIS

	use Tk;
	use Win32::HideConsole;
	
	hide_console;
	
	my $main_window = MainWindow->new();
	
	$main_window->Label(
	   -text => 'A GUI app with the console hidden!',
	   -font => 'arial 14')->pack(-side => 'top');
	   
	$main_window->MainLoop();
	
=head1 DESCRIPTION

Use this in GUI applications (Tk, Win32::GUI, etc.) to hide that annoying console window that appears at execution time.

Pollutes the namespace with one function: hide_console

=head1 METHODS

=head2 hide_console

Place this command near the beginning of your code (right after the "use" directives) to hide the console window.

=head1 Version History

1.00 - Initial Release

1.01 - Fixed this POD document

=head1 Author

Brandon Bourret

=head1 License

Permission is granted to use this software under the same terms as Perl itself.

Refer to the L<Perl Artistic|perlartistic> license for details.

=head1 Credits

Credit goes to "jdporter" who posted this clever solution on PerlMonks. I just modified it a bit and put it in module form
for easy reusability.

=cut