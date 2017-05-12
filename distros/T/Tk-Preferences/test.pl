# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { use Tk; plan tests => 2 };
use Tk::Preferences;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

##sample preferences configuration
%theme = (
    'ThemeID'   => "Shady Milkman",
    'Palette'   => "honeydew4",
    'Label' => {
        '-foreground'   => "LightBlue4",
        '-background'   => "#FFCC18",
        '-font'         => "-adobe-helvetica-medium-r-normal--10-*-*-*-*-*-*-*"
    },
    'Button' => {
        '-background'   => "#555555",
        '-foreground'   => "#EEEEEE",
        '-font'         => "-adobe-helvetica-medium-r-normal--10-*-*-*-*-*-*-*"
    },
    'Optionmenu' => {
        '-background'       => "LightBlue4",
        '-foreground'       => "#FFCC18",
        '-activebackground' => "#555555",
        '-activeforeground' => "#FFCC18",
        '-font'             => "-adobe-helvetica-medium-r-normal--10-*-*-*-*-*-*-*"
    },
    'Heading'   => {
        '-background'       => "honeydew4",
        '-foreground'       => "#EEEEEE",
        '-font'             => "-adobe-courier-medium-r-normal--12-*-*-*-*-*-*-*"
    },
    'Entry' => {
        '-background'   => "LightBlue4",
        '-foreground'   => "#FFCC18",
        '-font' => "-adobe-courier-medium-r-normal--12-*-*-*-*-*-*-*"
    }
);

##sample gui upon which to test
$mw = MainWindow->new();
my $label = $mw->Label(-text => "sample gui")->pack(-fill=>'x', -expand => 1, -anchor => 'w');
$label->{'Heading'} = 1;

$mw->Label(-text => "Choose a thing:")->pack();
$mw->Optionmenu(
    -options    => ["fluffy", "puff","made", "from", "the", "best", "stuff"]
)->pack();
$mw->Entry(-width => 10)->pack(-side => 'left', -anchor => 'c');
$mw->Button(-text => "Secret Eating")->pack(-side => 'left', -anchor => 'c');

$mw->update();
sleep(1);

$mw->SetPrefs(
    -debug => 1,
    -prefs => \%theme,
    -Button => \&ButtonCallback
);
$mw->update();

sleep(2);
ok(1);


sub ButtonCallback{
    my ($widget, $options) = @_;
    print "WOW I found a button!\n";
    print "let's configure it anyhow\n";
    $widget->configure(%{$options->{'-prefs'}->{'Button'}});
    $widget->update();
}