# perl -w
#
#  DateTime sample
#
use strict;
use warnings;

use Win32::GUI();

# main Window
my $Window = new Win32::GUI::Window (
    -name     => "Window",
    -title    => "DateTime Test",
    -pos      => [100, 100],
    -size     => [400, 400],
) or die "new Window";

# Date time control
my $DateTime = $Window->AddDateTime (
    -name     => "DateTime",
    -pos      => [10, 10],
    -size     => [180, 20],
    -updown   => 1,
);

#Set date format
$DateTime->Format('dd-MMM-yyyy HH:mm:ss');

# Date time control
my $DateTime1 = $Window->AddDateTime (
    -name     => "DateTime1",
    -pos      => [10, 30],
    -size     => [180, 20],
    -format   => "time",
);

# Date time control
my $DateTime2 = $Window->AddDateTime (
    -name     => "DateTime2",
    -pos      => [10, 50],
    -size     => [180, 20],
    -format   => "shortdate",
);

# Date time control
my $DateTime3 = $Window->AddDateTime (
    -name     => "DateTime3",
    -pos      => [10, 70],
    -size     => [180, 20],
    -format   => "longdate",
);

# Date time control
my $DateTime4 = $Window->AddDateTime (
    -name     => "DateTime4",
    -pos      => [10, 90],
    -size     => [180, 20],
    -format   => "shortdate",
    -shownone => 1,
    -align    => "right",
);

# Some Test Buttons
my $Button = $Window->AddButton  (
    -name     => "Gettime",
    -text     => "Get the time",
    -pos      => [200, 10],
    -size     => [90, 25],
);

my $Button1 = $Window->AddButton  (
    -name     => "Settime",
    -text     => "Set the time",
    -pos      => [300, 10],
    -size     => [90, 25],
);

my $Button2 = $Window->AddButton  (
    -name     => "SetNone",
    -text     => "Set None",
    -pos      => [200, 90],
    -size     => [90, 25],
);

my $Button3 = $Window->AddButton  (
    -name     => "IsNone",
    -text     => "Is None",
    -pos      => [300, 90],
    -size     => [90, 25],
);

# Event loop
$Window->Show();
Win32::GUI::Dialog();

# Main window event handler
sub Window_Terminate {
  return -1;
}

# Button events
sub Gettime_Click {
  my ($mday, $mon, $year, undef, $hour, $min,$sec) = $DateTime->GetDateTime();
  print "Year $year Month $mon Day $mday Hour $hour Min $min Sec $sec \n";

}
sub Settime_Click {
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year += 1900;
  $DateTime->SetDateTime($year, $mon, $mday, $hour,$min, $sec);
}

sub SetNone_Click {
  $DateTime4->SetNone();
}

sub IsNone_Click {
  print "Is None : " . $DateTime4->IsNone() . "\n";
}
