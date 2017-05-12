#ChooseDate - Popup calendar

use Tk;
use Tk::ChooseDate;

use vars qw/$TOP/;
use vars qw/$cd_i @cd_color $cd_col $r1 $r2 $r3/;

sub choosedate {
  my ($demo) = @_;
  my $text = qq/
Popup calendar for
choosing dates quickly.
Support for varying
languages and dates
before 1970.
It is a read-only
widget, but the get
and set methods
allow one to retrieve
and change the date
programmatically.
/;

@cd_color = qw(CC FF AA);
  $TOP = $MW->WidgetDemo(
    -name             => $demo,
    -text             => $text,
    -title            => 'ChooseDate Demonstration',
    -iconname         => 'ChooseDate',
    -geometry_manager => 'grid',
  );

  $cd_i = 0;
  foreach (qw/English French German Spanish Portuguese
              Dutch Italian Norwegian Swedish Danish Finnish
              Hungarian Polish Romanian/){
     $cd_col='#'.$cd_color[(int(rand(3)))].$cd_color[(int(rand(3)))].$cd_color[(int(rand(3)))];
     $TOP->Label(-text=>$_)->grid(-row=>$cd_i, -column=>0, -sticky=>'e');
     $TOP->ChooseDate(-highlightcolor=>$cd_col,-language=>$_)->grid(-row=>$cd_i, -column=>1,-sticky =>'w');
     $cd_i++;
  }

}

return 1 if caller();

require WidgetDemo;

$MW = new MainWindow;
$MW->geometry("+0+0");
$MW->Button(
  -text    => 'Close',
  -command => sub { $MW->destroy }
)->pack;
choosedate('choosedate');
MainLoop;
