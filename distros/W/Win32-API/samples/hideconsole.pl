use Win32::API 0.20;

# just for completeness...
use constant SW_HIDE       => 0;
use constant SW_SHOWNORMAL => 1;

# the API we need
my $GetConsoleTitle = new Win32::API('kernel32', 'GetConsoleTitle', 'PN', 'N');
my $SetConsoleTitle = new Win32::API('kernel32', 'SetConsoleTitle', 'P',  'N');
my $FindWindow      = new Win32::API('user32',   'FindWindow',      'PP', 'N');
my $ShowWindow      = new Win32::API('user32',   'ShowWindow',      'NN', 'N');

# save the current console title
my $old_title = " " x 1024;
$GetConsoleTitle->Call($old_title, 1024);

# build up a new (fake) title
my $title = "PERL-$$-" . Win32::GetTickCount();

# sets our string as the console title
$SetConsoleTitle->Call($title);

# sleep 40 milliseconds to let Windows rename the window
Win32::Sleep(40);

# find the window by title
$hw = $FindWindow->Call(0, $title);

# restore the old title
$SetConsoleTitle->Call($old_title);

# hide the console!
$ShowWindow->Call($hw, SW_HIDE);

# sleep one second, then show the console again
sleep(1);
$ShowWindow->Call($hw, SW_SHOWNORMAL);
