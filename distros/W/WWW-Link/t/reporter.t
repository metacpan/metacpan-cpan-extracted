#!/usr/bin/perl -w

=head1 reporter.t

tests for all of the different reporters

=cut

$::verbose=0 unless defined $::verbose;
BEGIN {print "1..79\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

use WWW::Link::Reporter;
use WWW::Link::Reporter::Compile;

use WWW::Link::Reporter::Text;
use WWW::Link::Reporter::URI;
use WWW::Link::Reporter::LongList;

use WWW::Link::Reporter::HTML;
use WWW::Link::Reporter::RepairForm;

use WWW::Link;

$loaded = 1;
ok(1);

package myindex;

=head1 DESCRIPTION

This provides the minimum functions needed for the index used by
longlist.

=cut

use vars qw($next %store);

sub new {return bless {}, "myindex"}

%store = (
  'http://www.bounce.com/' => 'http://www.fake.com/banana.html',
);

%erost=();

while (my ($key,$value) = each (%store)) {
  $erost{$value}=$key;
}

sub lookup_second {
  my $self=shift;
  my $key=shift;
  print STDERR "lookup second $key\n" if $::verbose;
  return [split /\s/, $store{$key}];
}

package main;

use Cwd;

sub my_url_to_file {
  my $file=shift;
  my $cwd = cwd();
  $file =~ s,http://www\.fake\.com/.*,$cwd/sample-infostruc/banana.html,;
  return $file;
}


#n.b. we do not test WWW::Link::Reporter!

@reporters=qw(WWW::Link::Reporter::Compile WWW::Link::Reporter::URI
	      WWW::Link::Reporter::Text WWW::Link::Reporter::LongList
	      WWW::Link::Reporter::HTML WWW::Link::Reporter::RepairForm);
$testno=2;

$WWW::Link::inter_test_time = -1; #accept immediate testing.. 

sub try_report ($$);

$tempfile="/tmp/test-temp.$$";


foreach my $class (@reporters) {
  my $reporter;
 CASE: {
    $class =~ m/LongList/ && do {
      my $index=new myindex;
      $reporter=$class->new(\&my_url_to_file, $index);
      last CASE;
    };
    $reporter=new $class ;
  }
  my $link=new WWW::Link "http://www.bounce.com/";

  print STDERR " test $testno testing reporter: $class\n";

  $i=10;
  $link->failed_test while $i--;
#test that we report a link failed link by default
  nogo unless try_report($reporter,$link);
  ok $testno;
  $testno++;

#test that we can switch off a report
  $reporter->report_broken(0);
  nogo if try_report($reporter,$link);
  ok $testno;
  $testno++;

#test various other reports

  $reporter->all_reports(0);

  $link->passed_test;
  nogo if try_report($reporter,$link);
  ok $testno;
  $testno++;
  $reporter->report_okay(1);
  nogo unless try_report($reporter,$link);
  ok $testno;
  $testno++;

  $link->failed_test;
  nogo if try_report($reporter,$link);
  ok $testno;
  $testno++;
  #it's only failed once, so it's not broken yet
  $reporter->report_broken(1);
  nogo if try_report($reporter,$link);
  ok $testno;
  $testno++;
  $reporter->report_damaged(1);
  nogo unless try_report($reporter,$link);
  ok $testno;
  $testno++;

  $link->disallowed;
  nogo if try_report($reporter,$link);
  ok $testno;
  $testno++;
  $reporter->report_disallowed(1);
  nogo unless try_report($reporter,$link);
  ok $testno;
  $testno++;

  $link->unsupported;
  nogo if try_report($reporter,$link);
  ok $testno;
  $testno++;
  $reporter->report_unsupported(1);
  nogo unless try_report($reporter,$link);
  ok $testno;
  $testno++;

  #N.B. not_perfect is not orthogonal.   Clear status first;

  $reporter->all_reports(0);

  $link->failed_test;
  nogo if try_report($reporter,$link);
  ok $testno;
  $testno++;
  $reporter->report_not_perfect();
  nogo unless try_report($reporter,$link);
  ok $testno;
  $testno++;

}


sub try_report ($$){
  my ($reporter,$link)=@_;
  open ( SAVEOUT, ">&STDOUT" ) || die "couldn't duplicate stdout";
  print SAVEOUT ""; #silence perl warning that SAVEOUT is only used once
  open ( STDOUT, "> $tempfile" ) || die "couldn't open tempfile to write";

  $reporter->examine($link);

  close ( STDOUT ) || die "couldn't close tempfile";
  open ( STDOUT, ">&SAVEOUT" ) || die "couldn't recover stdout";

  open ( TEMPFILE, "< $tempfile" ) || die "couldn't open tempfile to read";
  my $found=0;
  while (<TEMPFILE>) {
    $found=1 if m,http://www.bounce.com/,;
  }
  close ( TEMPFILE ) || die "couldn't close tempfile";
  return $found;
}

