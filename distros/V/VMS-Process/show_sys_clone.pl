#! perl -w
#
# Show_Sys_Clone.pl - a clone, more or less, of the output of SHOW
# SYSTEM. It's in here as a sample of what you can do with the VMS::Process
# module.
use VMS::Process qw(process_list get_all_proc_info_items);

@foo = process_list();
foreach $pid (sort @foo) {
  $procinfo = get_all_proc_info_items($pid);
  print sprintf("%8.8x", $pid), " ";
  print sprintf("%-15.15s ", $procinfo->{PRCNAM});
  print $procinfo->{STATE}, "\t";
  print $procinfo->{PRI}, "\t";
  print $procinfo->{NODENAME}, "\t";
  $cputime = $procinfo->{CPUTIM};
  $days = int($cputime / 8640000);
  $remainder = $cputime % 8640000;
  $hours = int($remainder / 360000);
  $remainder = $remainder % 360000;
  $minutes = int($remainder / 6000);
  $remainder = $remainder % 6000;
  $seconds = int($remainder / 100);
  $hundredths = $remainder % 100;
  $timestr = sprintf("%0.1u %0.2u:%0.2u:%0.2u.%0.2u", $days, $hours,
                     $minutes, $seconds, $hundredths);
  print "\t", $timestr, " ", sprintf("%9.9s ", $procinfo->{PAGEFLTS});
  print "\n";
}
