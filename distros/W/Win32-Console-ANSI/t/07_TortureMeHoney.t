#!/usr/bin/perl -w
use strict;
use Win32::Pipe;
use Win32::Process;
$|++;

my $npipe = new Win32::Pipe("ANSINamedPipe", 1) or die $^E;

my $ProcessObj;
Win32::Process::Create($ProcessObj,
                       "$^X",
                       "perl -I$INC[0] -I$INC[1] t\\07_TortureMeHoney.pl",
                       0,
                       NORMAL_PRIORITY_CLASS | CREATE_NEW_CONSOLE,
                       ".") or die $^E;

$npipe->Connect();
while (1) {
  $npipe->Write("_ok");
  my $s = $npipe->Read();
  last if $s eq "_OVER";
  print $s;
}
$npipe->Disconnect();

__END__