
# tkMCI.pl  A poorly implemented media player

use Win32::MultiMedia::Mci;
use Tk;
use Tk::ProgressBar;
use Tk::Frame;
use Tk::Button;

$mw = MainWindow->new();
$display = $mw->Frame(-width=>300,-height=>300)->form(-top=>["%0"],-left=>["%0"]);
$control = $mw->Frame()->form(-top=>["%0"],-right=>["%100"]);

$control->Button(-text=>"Open", -command=>[\&open])->pack;

$control->Button(-text=>"CD", -command=>[\&open, "cdaudio"])->pack;

$control->Button(-text=>"Play", -command=>[sub{$mci->play() && error()}])->pack;

$control->Button(-text=>"Restart", -command=>[sub{$mci->play(from=>0) && error()}])->pack;

$control->Button(-text=>"Seek 0", -command=>[sub{$mci->seek(to=>"start") && error()}])->pack;

$control->Button(-text=>"Pause", -command=>[sub{$mci->pause() && error()}])->pack;

$control->Button(-text=>"Stop", -command=>[sub{$mci->stop() && error()}])->pack;

MainLoop;
$mci->stop;
$mci->close;


sub error
{
   $mw->messageBox(-message=>$mci->error);
}

sub open
{
   my ($file) = $_[0] || $mw->getOpenFile();
   print "Opening $file\n";
   eval{$mci->stop;$mci->close} if $mci;
   if ($file =~ /\.avi$/i)
   {
      $mci = Win32::MultiMedia::Mci->open($file, parent=>hex($display->id), style=>"child");
   }
   elsif ($file =~ /(\d+)\.cda$/i)
   {
      $mci = Win32::MultiMedia::Mci->open($file, shareable=>1,wait=>1);
      $mci->set("time format tmsf","wait");
      $mci->seek(to=>$1+0, "wait");
   }
   else
   {
      $mci = Win32::MultiMedia::Mci->open($file);
   }
   $mci->error && error();
   progress();
}

sub transtime
{
   my ($t) = @_;
   $t =~ /^(\d+)(?::(\d+):(\d+))?/;
   $t = "$1.$2$3" + 0;
   return $t;

}

sub setpos
{
   my $p = $progress->get();
   $mci->seek(to=>int($p),"wait");
}

sub progress
{
  eval{$progress->afterCancel($repeatid);};
  my $pos1 = 0;
   $progress = $mw->Scale(
         -orient=>"horizontal",
         -length => 200,
         -from => 0,
         -to => transtime($mci->status("length")),
         -command=>[\&setpos],
         -resolution=>.0001,
         -variable=>\$pos1
    )->form(-bottom=>['%100'],-left=>['%0']);
   $repeatid = $progress->repeat(500,[sub{$pos1 = transtime($mci->status("position"))}]);
}