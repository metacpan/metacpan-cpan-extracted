#!/usr/bin/perl
# $Id: showwin.pl,v 1.2 2004/03/21 08:05:06 ctrondlp Exp $
# This script has been written by Jarek Jurasz jurasz@imb.uni-karlsruhe.de
# selectively show/hide a group of windows
# side effect: showing the window activates it

use Win32::GuiTest qw(:ALL :SW);


$name = shift;
$show = shift;
$class = undef;

die <<EOT unless $name;
Usage: $0 "^Title" [+1|-1]
+1 show windows
-1 hide windows
 0 or empty show status
Be careful when using bare title words: when running the script, the title of 
the console will change and include the title words, too...
EOT


# $name = "^Microsoft Excel" unless $name;
my @win = FindWindowLike(0, $name, $class);

showall(@win);

sub showall
{
  my @win = @_;
  for $win (@win)
  {
    # should normally be only one
    show($win);
    # children
    # showall(FindWindowLike($win, undef, undef));
  }
}

sub show
{
  my $win = shift;

  # dumpwin($win);
  if ($show > 0)
  {
    ShowWindow($win, SW_SHOW) unless (IsWindowVisible($win));
    # EnableWindow($win, 1);
  }
  elsif ($show < 0)
  {
    ShowWindow($win, SW_HIDE) if (IsWindowVisible($win));
  }
  
  dumpwin($win);
}

sub dumpwin
{
  my $win = shift;
  print "Null handle\n", return unless ($win);
  print "$win>\tt:", GetWindowText($win), " c:", GetClassName($win);
  print " vis:", IsWindowVisible($win);
  print " en:", IsWindowEnabled($win);
  print "\n";
}
