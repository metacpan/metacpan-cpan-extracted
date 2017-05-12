use Win32::MultiMedia::Mci;
print "Opening CD...\n";
 $mci = Win32::MultiMedia::Mci->open("cdaudio", shareable=>1);
if (!$mci->error)
{
   $mci->set("time format tmsf");
   print "n=track, s=stop, q=quit, e=eject\n";
   while (<STDIN>)
   {
      chomp;
      last if /^q/;
      ($mci->stop(), next) if /^s/;

      ($mci->set(door=>"open"), next) if /^e/;

      print "\tPlaying $_...\n";
      $mci->stop("wait");
      $mci->play( from => $_) && print $mci->error;
   }
   continue
   {
      print "n=track, s=stop, q=quit, e=eject\n";
   }
   $mci->stop;
   $mci->close;
}
else
{
   print $mci->error;
}
