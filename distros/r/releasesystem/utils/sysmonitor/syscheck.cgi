#!/usr/local/bin/perl5

# copyright 1996-2000 by hewlett-packard company
# may be distributed under the terms of the artistic license

use CGI;

$DEBUG = 0;
$SEMAPHORE_PARAMETER = 0;

if ($DEBUG)
{
  $CONFIG_FILE = "/home/idsweb/public_html/wmTools/scripts/syscheck/syscheck.rc";
}
else
{
  $CONFIG_FILE   = "/opt/ims/local/syscheck/syscheck.rc";
  $CONFIG_FILE = "/home/idsweb/public_html/wmTools/scripts/syscheck/syscheck.rc";
}

if ($DEBUG) 
{
  print "Content-type: text/plain\n\n";
}

&main;

sub main
{
  my ($var) = new CGI;

  my ($id,$pass,$fail);
  my (%list);

  &read_config ($CONFIG_FILE, \%list);

  $id = $var->param('c');
  $pass = $var->param('a');
  $fail = $var->param('b');

if ($DEBUG)
{
  print "ID:$id PASS:$pass FAIL:$fail\n";
  print "SEM: $list{$id}->[$SEMAPHORE_PARAMETER]\n"; #fail
}
  if (-e $list{$id}->[$SEMAPHORE_PARAMETER]) #fail
  {
    print "Location: $fail\n\n";
  }
  else #succeed
  {
    print "Location: $pass\n\n";
  }
}

###############################################################
sub read_config
{
  my ($configfile,$listref) = @_;
  my (@line); 
  my ($key);

  open (CONFIG, '<'.$configfile) || 
      die "Cannot open config file:$configfile\n";
  while (<CONFIG>)
  {
   chomp $_;
    next if /^#/;

    ($key,@line) = split (',',$_);
    $listref->{$key} = [ @line ]; 

  }

  close CONFIG;
}

