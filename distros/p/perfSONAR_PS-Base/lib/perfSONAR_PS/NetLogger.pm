package perfSONAR_PS::NetLogger;

use strict;
use warnings;
require 5.002;
use Time::HiRes;
  
our $VERSION = 0.09;

# initialize Global GUID
my $GUID = get_guid();

sub format {
  my($evnt, $data) = @_;
  my($str) = "";
  if ( exists $data->{'ts'} ) {
    $str = "ts=$data->{ 'ts' } ";
  }
  else {
    my $dt = date();
    $str = "ts=$dt ";
  }
  $str .= "event=$evnt ";
  foreach my $k (keys %$data) {
    $str .= "$k=$data->{$k} ";
  }
  $str .= "guid=".$GUID;
  return $str;
};


sub date {
  my($tm, $usec) = Time::HiRes::gettimeofday();
  my($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=gmtime($tm);
  return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.%06dZ",$year + 1900,$mon + 1,
                 $mday,$hour,$min,$sec,$usec);
}

sub get_guid
{
  my $guid = `uuidgen`; chomp $guid;
  return ($guid);
}

sub reset_guid  # reset GUID
{
  $GUID = `uuidgen`; chomp $GUID;
  return;
}


1;


__END__

=head1 NAME
     
NetLogger - A module that provides tools to generate NetLogger formatted messages for log4perl
    
=head1 DESCRIPTION
      
For more information on NetLogger see: http://dsd.lbl.gov/NetLoggerWiki/index.php/Main_Page
    
=head1 SYNOPSIS


=head1 API
    
The API of NetLogger is used to format log messages in the NetLogger 'Best Practices' format.
See: http://www.cedps.net/wiki/index.php/LoggingBestPractices
     
=head2 format("event_name", list of name=>value pairs)

Sample use:

  use Log::Log4perl qw(:easy);
  use NetLogger;
  Log::Log4perl->easy_init($DEBUG);

  my $logger = get_logger("my_prog");

  $logger->info(NetLogger::format("org.perfsonar.client.parseResults.start"));
  # call function here
  $logger->info(NetLogger::format("org.perfsonar.client.parseResults.end", {val=>12,}));
  

This will generate a log that looks like this:

2007/12/19 13:51:26 39899 INFO> myprog:NN main:: - ts=2007-12-19T21:51:26.030823Z \
	event=org.perfsonar.client.runQuery1.end guid=736ee764-ae7c-11dc-9f7d-000f1f6ed15d


=head1 AUTHOR

Dan Gunter, dkgunter@lbl.gov

=head1 LICENSE

See: http://dsd.lbl.gov/NetLoggerWiki/index.php/Licensing

=head1 COPYRIGHT

Copyright (c) 2004-2007, Lawrenence Berkeley National Lab and the University of California
All rights reserved.

=cut

