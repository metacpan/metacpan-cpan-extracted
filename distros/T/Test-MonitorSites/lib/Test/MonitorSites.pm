package Test::MonitorSites;

use warnings;
use strict;
use Carp;
use Cwd;
use Config::Simple;
use WWW::Mechanize;
use Test::WWW::Mechanize;
use Test::HTML::Tidy;
use HTTP::Request::Common;
use Test::More;
use Data::Dumper;
use Test::Builder;
use Mail::Mailer;
# use Mail::Mailer qw(mail);

use vars qw($VERSION);
$VERSION = '0.15';

1; # Magic true value required at end of module

sub new {
  my $class = shift;
  my $args = shift;
  my $self = {};
  my ($cfg,%sites,@sites,$site);

  if (defined($args->{'config_file'})){
    my $config_file = $args->{'config_file'};
    if(-s $config_file){
      $cfg = new Config::Simple($config_file);
      if(!defined($cfg->{'_DATA'})){
        $self->{'config_file'} = undef;
        $self->{'error'} .= 'No configuration data is available.';
      } else {
        foreach my $key (keys %{$cfg->{'_DATA'}}){
          if($key =~ m/^site_/){
            $site = $key;
            $site =~ s/^site_//;
            push @sites, $site;
          }
        }
        # print STDERR @sites, "\n";
        $self->{'sites'} = \@sites;
        foreach my $s (@sites){
          # if($s =~ m/not ok/) { print "Found Error; \$s is $s\n"; exit; }
          if(!defined($cfg->{'_DATA'}{"site_$s"}{'ip'})){
            $cfg->{'_DATA'}{"site_$s"}{'ip'} = [ '0.0.0.0' ];
          }
        }
        my $cwd = getcwd();
        # {
          # no strict 'refs';
          # $cwd = `pwd`;
        # }
        # print STDERR "The current working directory is: $cwd.\n";
        if(defined($cfg->param('global.result_log'))){
          if($cfg->param('global.result_log') !~ m/^\//){
            $self->{'result_log'} = $cwd . '/' . $cfg->param('global.result_log');
          } else {
            $self->{'result_log'} = $cfg->param('global.result_log');
          }
        } else {
          $self->{'result_log'} = "$cwd/Test_MonitorSites_result.log"; 
        }
        if(!defined($cfg->param('global.MonitorSites_email'))){
          $self->{'error'} .= "Configuration fails to define global.MonitorSites_email for From: line.\n";
          $cfg->param('global.MonitorSites_email','MonitorSites@example.net'); 
        } else {
          1;
        }
        foreach my $i ('ips', 'critical_errors', 'servers_with_failures', 'tests', 'sites') {
          $self->{'result'}->{$i} = 0;
        }
        if(!defined($cfg->param('global.report_success')) 
            || $cfg->param('global.report_success') != 1){
          $cfg->param('global.report_success',0);
        }
        if(!defined($cfg->param('global.MonitorSites_subject'))) {
          $cfg->param('global.MonitorSites_subject','Critical Failures');
        }
        if(!defined($cfg->param('global.MonitorSites_all_ok_subject'))) {
          $cfg->param('global.MonitorSites_all_ok_subject','Servers All OK');
        }
      }
    } else {
      $self->{'config_file'} = undef;
      $self->{'error'} .= 'The config_file was not found, or was empty.';
    }
  } else {
    $self->{'config_file'} = undef;
    $self->{'error'} .= 'The config_file was not set in the constructor.';
  }
  $self->{'config'} = $cfg;
  my $agent = WWW::Mechanize->new();
  my $mech = Test::WWW::Mechanize->new();
  $self->{'agent'} = $agent;
  $self->{'mech'} = $mech;

  bless $self, $class;
  return $self;
}

sub test_sites {
  my $self = shift;
  my $sites = shift;
  my(%sites);
  if(defined($sites)){
    %sites = %{$sites};
  } elsif(defined($self->{'config'}->{'_DATA'})) {
    %sites = %{$self->{'config'}->{'_DATA'}};
    foreach my $key (keys %sites){
      if($key !~ m/^site_/){
        delete $sites{$key};
      }
    }
  } else {
    $self->{'error'} .= 'No sites have been identified for testing.  Please add sites to: ' . $self->{'config_file'};
  }

  my ($key, $url, $expected_content,$expected,$ip);
  my(@url,@expected,@sites,@test_links,@test_valid_html);
  my $agent = $self->{'agent'};
  my $mech = $self->{'mech'};
  # print STDERR Dumper(\%sites);
  my $log_file = $self->{'result_log'};
  my $log_file_ok = $log_file . '_ok';
  my $log_file_diag = $log_file . '_diag';
  my $log_file_todo = $log_file . '_todo';

  my $Test = Test::Builder->new;
  my @handle_names = qw/ output failure_output todo_output /;
  my %old;
  $old{$_} = $Test->$_ for @handle_names;
  $Test->$_(\*STDOUT) for @handle_names;

  {
    $Test->output($log_file_ok);
    $Test->failure_output($log_file_diag);
    $Test->todo_output($log_file_todo);

    # print STDERR Dumper(\%sites);
    foreach my $site (keys %sites){
      if($site !~ m/^site_/){ next; }
      # diag("The site is $site");
      $site =~ s/^site_//;
      # if($site =~ m/not ok/) { print "Found Error; \$site is $site\n"; exit; }
      # diag("The site is $site");
      push @sites, $site;
      $self->{'result'}->{'sites'}++;
      $ip = @{$self->{'config'}->{'_DATA'}->{"site_$site"}->{'ip'}}[0];
      if (defined($ip) && !defined($self->{'result'}->{'ips_tested'}->{$ip})){
        $self->{'result'}->{'ips_tested'}->{$ip} = 1;
        $self->{'result'}->{'ips'}++;
      }
      # diag("The site is $site");
      # diag("The hash key is site_$site");
      $url = $self->{'config'}->{'_DATA'}->{"site_$site"}->{'url'};
      $expected = $self->{'config'}->{'_DATA'}->{"site_$site"}->{'expected_content'};
      # diag("The url is $url.");
      @url = @{$url};
      @expected = @{$expected};
      # $self->_test_tests();
      $self->_test_site($agent,$url[0],$expected[0]);
      $self->{'result'}->{'tests'} = $self->{'result'}->{'tests'} + 2;
      if(defined($sites{"site_$site"}{'test_links'})){
        @test_links = @{$sites{"site_$site"}{'test_links'}};
        if ($test_links[0] == 1) {
          $self->_test_links($mech,$url[0]);
          $self->{'result'}->{'tests'} = $self->{'result'}->{'tests'} + 1;
        } else {
          diag("Skipping tests of links at: $site.");
        }
      }
      if(defined($sites{"site_$site"}{'test_valid_html'})){
        @test_valid_html = @{$sites{"site_$site"}{'test_valid_html'}};
        if ($test_valid_html[0] == 1) {
          $self->_test_valid_html($mech,$url[0]);
          $self->{'result'}->{'tests'} = $self->{'result'}->{'tests'} + 1;
        } else {
          diag("Skipping tests of html validity at: $site.");
        }
      }
  
    }
  }
  $Test->todo_output(*STDOUT);
  $Test->failure_output(*STDERR);
  $Test->output(*STDOUT);

  my $critical_failures = $self->_analyze_test_logs();  
  # print STDERR "Count of critical failures: $critical_failures->{'count'}\n";
  # print "global.report_success is " . $self->{'config'}->param('global.report_success');
  if($critical_failures->{'count'} != 0){
    # print STDERR "Next we send an sms message.\n";
    $self->sms($critical_failures);
  } elsif ($self->{'config'}->param('global.report_success') == 1) {
    $self->sms($critical_failures);
  } else {
    $self->{'error'} .= "We won't send an sms, there were no critical_failures and global.report_success is not set true.\n";
  }

  if(defined($self->{'config'}->param('global.results_recipients'))){
    if($self->{'config'}->param('global.send_summary') 
        || $self->{'config'}->param('global.send_diagnostics')){
      # print STDERR "Next we send some email.\n";
      $self->email($critical_failures);
    } else {
      $self->{'error'} .= "We won't send an email, neither send_summary nor send_diagnostics were set to true in the configuration file.\n";
    }
  } else {
    $self->{'error'} .= "We won't send an email, there was no results_recipient defined in the configuration file.\n";
  }

  my %result = (
           'ips'     => $self->{'result'}->{'ips'},
           'sites'   => $self->{'sites'},
           'planned' => '',
           'run'     => $self->{'result'}->{'tests'},
           'passed'  => '',
           'failed'  => $critical_failures->{'count'},
 'critical_failures' => $critical_failures,
       );

  # print Dumper($critical_failures);
  return \%result;
}

sub _analyze_test_logs {
  my $self = shift;
  my $critical_failures = 0;
  my %critical_failures;
  $critical_failures{'count'} = 0;
  foreach my $test ('linked_to','expected_content','all_links','valid'){
    # print STDERR "This \$test is $test.\n";
    if($self->{'config'}->param("critical_failure.$test") == 1){
      $critical_failures{"$test"} = 1;
    }
  }
  my ($url,$test,$test_string,$ip,$param_name,@ip);
  open('SUMMARY','<',$self->{'config'}->param('global.result_log') . '_ok');
  while(<SUMMARY>){
    if(m/^not ok/){
      $url = $_;
      chomp($url);
      $url =~ s/^.*https?:\/\///;
      $url =~ s/\/.*$//;
      $url =~ s/\.$//;
      if($url =~ m/not ok/) { print "Found parsing error; \$url is $url\n"; exit; }
      $param_name = 'site_' . $url;
      if(defined(@{$self->{'config'}->{'_DATA'}->{"$param_name"}->{'ip'}}[0])){
        @ip = @{$self->{'config'}->{'_DATA'}->{"$param_name"}->{'ip'}};
        # @ip = @{$ip} if(ref($ip));
      } else {
        $self->{'error'} .= "IP address not defined for $url.\n";
        print 'ip array is: ' . Dumper(\$self->{'config'}->{'_DATA'}->{"$param_name"}->{'ip'});
        print 'ip: ' . @{$self->{'config'}->{'_DATA'}->{"$param_name"}->{'ip'}}[0] . "\n";
        # print Dumper(\$self->{'config'}->{'_DATA'});
        # print Dumper(\$self->{'config'}->{'_DATA'}->{"$param_name"});
        # print Dumper(\$self->{'error'});
        print "Site key is: $param_name.\n";
        print "Now exiting.\n";
        exit;
      }
      if(!defined($critical_failures{'failed_tests'}{'ip'}{"$ip[0]"}{'count'})){
        $critical_failures{'failed_tests'}{'ip'}{"$ip[0]"}{'count'} = 0;
      }
      foreach my $test (keys %critical_failures){
        if($test eq 'failed_tests'){ next; }
        $test_string = $test;
        $test_string =~ s/_/ /g;
        if($_ =~ m/$test_string/){
          $critical_failures++;
          $critical_failures{'failed_tests'}{'ip'}{"$ip[0]"}{'count'}++ if(defined($ip[0]));
          $critical_failures{'failed_tests'}{'ip'}{"$ip[0]"}{"$url"} = $_ if(defined($ip[0]));
          $critical_failures{'failed_tests'}{'url'}{"$url"}{"$test"} = $_;
          $critical_failures{'failed_tests'}{'test'}{"$test"}{"$url"} = $_;
        }
      }
    }
  }
  close('SUMMARY');  
  $critical_failures{'count'} = $critical_failures;
  if($critical_failures{'count'} == 0){
    # print STDERR "The count of critical failures is 0.\n";
  }

  return \%critical_failures;
}

sub _return_result_log {
  my $self = shift;
  return $self->{'result_log'};
}

sub email {
  my $self = shift;
  my $critical_failures = shift;
  my ($type,@args,$body);

  my %headers = (
         'To'      => $self->{'config'}->param('global.results_recipients'),
         'From'    => $self->{'config'}->param('global.MonitorSites_email'),
         'Subject' => 'MonitorSites log',
       );

  $body = "
    This summary brought to you by 
    Test::MonitorSites version $VERSION 
    ===================================\n";

    $body .= '    Tests: ' . $self->{'result'}->{'tests'};
    $body .= ', IPs: ' . $self->{'result'}->{'ips'};
    $body .= ', Sites: ' . $self->{'result'}->{'sites'};
    $body .= ', CFs: ' . $critical_failures->{'count'};
    # $body .= ', CFs: ' . $self->{'result'}->{'critical_failures'}->{'count'};
    $body .= "\n    ===================================\n\n";
    
    # $self->{'result'}->{'message'} = $body;
  # print Dumper(\$self->{'result'});

  my $file = $self->{'config'}->param('global.result_log');
  if($self->{'config'}->param('global.send_summary') == 1){
    open('RESULT','<',$file . '_ok');
    while(<RESULT>){
      $body .= $_;
    }
    close('RESULT');
  } else {
    $self->{'error'} .= "Configuration file disabled email dispatch of results log.\n";
  }

  if(defined($self->{'config'}->param('global.send_diagnostics'))
      && $self->{'config'}->param('global.send_diagnostics') == 1){
    $body .= <<'End_of_Separator';

     ==============================================
     End of Summary, Beginning of Diagnostics
     ==============================================

End_of_Separator

    open('RESULT','<',$file . '_diag');
    while(<RESULT>){
      $body .= $_;
    }
    close('RESULT');
  } else {
    $self->{'error'} .= "Configuration file disabled email dispatch of diagnostic log.\n";
  }

  # is(1,1,'About to send email now.');
  $type = 'sendmail';
  my $mailer = new Mail::Mailer $type, @args;
  $mailer->open(\%headers);
    print $mailer $body;
  $mailer->close;
  return 1;
}

sub sms {
  my $self = shift;
  my $critical_failures = shift;
  my %critical_failures = %{$critical_failures};
  my %headers = (
         'To'      => $self->{'config'}->param('global.sms_recipients'),
         'From'    => $self->{'config'}->param('global.MonitorSites_email'),
         'Subject' => $self->{'config'}->param('global.MonitorSites_subject'),
       );

  ### diag('report_by_ip is: ' . $self->{'config'}->param("global.report_by_ip"));
  my ($mailer,$type,@args,$body,$test,$url,$ip);
  my($failing_domains,$failing_domains_at_ip);
  if($critical_failures->{'count'} == 0){
    $headers{'Subject'} = $self->{'config'}->param('global.MonitorSites_all_ok_subject');

    $body = '';
    $body .= 'Tests: ' . $self->{'result'}->{'tests'};
    $body .= ', IPs: ' . $self->{'result'}->{'ips'};
    $body .= ', Sites: ' . $self->{'result'}->{'sites'};
    $body .= ', CFs: ' . $self->{'result'}->{'critical_errors'};
    $body .= '; No critical errors found.';
    $self->{'result'}->{'message'} = $body;

    $mailer = new Mail::Mailer $type, @args;
    $mailer->open(\%headers);
      print $mailer $body;
    $mailer->close;
    $self->_log_sms($body);

  } elsif(defined($self->{'config'}->param("global.report_by_ip")) 
      && $self->{'config'}->param("global.report_by_ip") == 1) {
      foreach my $ip (keys %{$critical_failures{'failed_tests'}{'ip'}}){
        if($critical_failures{'failed_tests'}{'ip'}{$ip}{'count'} != 0
            || $self->{'config'}->param('global.report_success') == 1) {
          $failing_domains = 0;
          $failing_domains_at_ip = "";
          foreach my $url (keys %{$critical_failures{'failed_tests'}{'ip'}{"$ip"}}){
            if($url eq 'count'){ next; }
            $failing_domains++;
            $failing_domains_at_ip .= "NOK: $url, ";
          }
          $body = "$critical_failures{'failed_tests'}{'ip'}{$ip}{'count'}";
          $body .= " critical errors at $ip; incl $failing_domains domains: ";
          $body .= $failing_domains_at_ip;
          # is(1,1,'About to send sms now about $url.');
          $mailer = new Mail::Mailer $type, @args;
          $mailer->open(\%headers);
            print $mailer $body;
          $mailer->close;
          $self->_log_sms($body);
        }
      }
  } else {
    my $i = 0;
    foreach my $url (keys %{$critical_failures{'failed_tests'}{'url'}}){
      $i++; 
      $body = "Failure: $i of $critical_failures{'count'}: $url: ";
      foreach my $test (keys %{$critical_failures{'failed_tests'}{'url'}{"$url"}}){
        $body .= "Not OK: $test, ";
      }
      # is(1,1,'About to send sms now about $url.');
      $mailer = new Mail::Mailer $type, @args;
      $mailer->open(\%headers);
        print $mailer $body;
      $mailer->close;
      $self->_log_sms($body);
    }
  }

  return 1;
}

sub _log_sms {
  my $self = shift;
  my $body = shift;

  my $header = "To: " . $self->{'config'}->param('global.sms_recipients') . "\n";
  $header .= "From: " . $self->{'config'}->param('global.MonitorSites_email') . "\n";
  $header .= "Subject:Critical Failures\n";
  my $log_msg = $header . $body;

  my @sms_log;
  if(defined($self->{'sms_log'})){
    @sms_log = @{$self->{'sms_log'}};
  } else {
    @sms_log = ();
  }

  push @sms_log, $log_msg;
  $self->{'sms_log'} = \@sms_log;
  my $count = @sms_log;

  return $count;
}

sub _test_tests {
  is(12,12,'Twelve is twelve.');
  is(12,13,'Twelve is thirteen.');
  diag("Diagnostic output from subroutine called while redirecting output.");
  return;
}

sub _test_links {
  my ($self,$mech,$url) = @_;
  $mech->get_ok($url, " . . . linked to $url");
  $mech->page_links_ok( " . . . successfully checked all links for $url" );
  return;
}

sub _test_valid_html {
  my ($self,$mech,$url) = @_;
  $mech->get_ok($url, " . . . linked to $url");
  html_tidy_ok( $mech->content(), " . . . html content is valid for $url" );
  return;
}

sub _test_site {
  my($self,$agent,$url,$expected_content) = @_;
  $agent->get("$url");
  is ($agent->success,1,"Successfully linked to $url.");
  like($agent->content,qr/$expected_content/," . . . and found expected content at $url");
  return $agent->success();
}

__END__

=head1 NAME

Test::MonitorSites - Monitor availability and function of a list of websites 

=head1 VERSION

This document describes Test::MonitorSites version 0.14

=head1 SYNOPSIS

    use Test::MonitorSites;
    my $tester = Test::MonitorSites->new({
            'config_file' => '/file/system/path/to/monitorsites.ini',
         });

    my $results = $tester->test_sites();
    print $tester->{'errors'};

    |--- now go check your email and sms pager.

    The ->test_sites() method will invoke the ->email() and ->sms() 
    methods as appropriate given the settings in the configuration file
    used in the constructor.  However, these methods are documented as
    public, and if it serves your needs to use them directly, feel free.  

    $tester->{'config'}->param('global.results_recipients','metoo@example.com');
    $tester->email($results);

    $tester->{'config'}->param('global.sms_recipients','12345559823@txt.example.com');
    if(defined($results->{'critical_failures'})){
        $tester->sms($results->{'critical_failures'});
    }

A complete list of supported base configuration options includes
the following listed in the global and critical_failure
stanza's.  Tests turned on in the critical_failure stanza
determine which tests are sufficiently critical to warrant an
sms message to a cell phone.  All tests enabled are run and
reported in the email summary report.

=over 4

    [global]
    sms_recipients = '7705552398@txt.example.net'
    results_recipients = 'admin@example.com'
    MonitorSites_subject = 'Critical Failures'
    MonitorSites_all_ok_subject = 'Servers A-OK'
    result_log = '/tmp/test_sites_output'
    send_summary = 1
    send_diagnostics = 1
    report_by_ip = 1
    report_success = 1
    test_links = 0
    test_valid_html = 0
    
    [critical_failure]
    linked_to = 1
    expected_content = 1
    all_links = 0
    valid = 0

=back

To run this module in quiet mode, set the following to '0'
or leave undefined in the configuration: report_success,
send_summary, send_diagnostics.  If configured this way,
sms messages will be sent to report critical failures, but no
email summary reports will be sent.

It is possible to test the same set of sites hourly in quiet
mode, and then using the $tester->{'config'}->param() method
(documented as the ->param() method in perldoc Config::Simple),
or an alternate ini file to run a sinle test each day with
report_success set to '1', to get a daily reminder that the
server from which these tests are run is itself up and running
and that this module is still working as expected.

In addition to any global variables which may apply to an
entire test suite, the configuration file ought to include an
ini formatted section for each website the test suite defined
by the configuration file ought to test or exercise.  For full
details on the permitted format, read perldoc Config::Simple.

For a full set of examples, take a look at the .t and .ini
files in the t/ directory.

In this first example, we'll test the cpan.org site for accessible html
markup and to ensure that the links all work.  With the perlmonks site,
we'll simply confirm that the site resolves and that its expected
content can be found on the page.

=over 4

    [site_www.cpan.org]
    ip='66.39.76.93'
    url='http://www.cpan.org'
    expected_content='Welcome to CPAN! Here you will find All Things Perl.'
    test_valid_html = 1
    test_links = 1
    
    [site_www.perlmonks.com]
    ip='66.39.54.27'
    url='http://www.perlmonks.com'
    expected_content='The Monastery Gates'

=back

In the long run, as this develops, it is anticipated that
the site definitions could take on the following structure,
imagining the ability to test the functionality of a specific
web application, and powered by an application specific module
of the form Test::MonitorSites::MyWebApplication.

Anyone interested in this functionality is urged to jump right
in and help deliver it, or to contact the author about funding
for this further development.

=over 4

    [site_www.example.com]
    ip='192.168.1.1'
    url='http://www.example.com/myapp.cgi'
    expected_content='Welcome to MyApp!'
    user_field_name='login'
    password_field_name='password'
    user='mylogin'
    password='secret'
    
    [site_civicrm.example.com]
    url='http://civicrm.example.com/index.php'
    expected_content='Welcome to MyApp!'
    application=civicrm
    
    [site_drupal.example.com]
    url='http://drupal.example.com/index.php'
    expected_content='Welcome to MyApp!'
    application=drupal
    modules='excerpt,events,local_module'

=back

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 my $tester = Test::MonitorSites->new( 'config_file' => $config_file_path,);

Create a $tester object, giving access to other module methods.
Constructor takes a hash with a single key, 'config_file'
with a path (from root or relative) to an ini formatted
configuration file.

=head2 $results = $tester->test_sites();

This method will permit a battery of tests to be run on each
site defined in the configurations file.  It returns a hash
of results, which can then be examined and tested, or used to
make reports.  $tester->{'errors'} can provide useful feedback
on show stopping errors encountered.

=head2 $tester->email($results);

or 

=head2 $tester->email($results,$recipients);

This method will email a report of test results to the
recipients defined either in the configuration file or in the
method call.

=head2 $tester->sms($results->{'critical_failures'});

or

=head2 $tester->sms($results->{'critical_failures'},$recipients);

This method will permit a notice of Critical Failures to
be delivered by SMS messaging to a cell phone or pager
device.  The message is delivered to recipients defined
in the configuration file or in the method call.  If the
global.report_by_ip configuration parameter is assigned to '1',
then a single sms message per IP address with test failures
will be sent.  Otherwise, an sms message will be sent for
each individual test failure, even for multiple failures on
a single server or domain.

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.

=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=head1 DIAGNOSTICS

=over

=item C<< No configuration data is available. >>

A configuration file was provided, but it contains no
configuration data in a valid format.  See the SYNOPSIS for
details on valid variables which ought to be defined in your
config file.  See perldoc Config::Simple for details on its
valid format.

=item C<< The config_file was not found, or was empty. >>

The config file defined in the constructor is missing from
the filesystem, or if it does exist, it is empty.

=item C<< The config_file was not set in the constructor. >>

The module's constructor, the ->new() method, was invoked
without a configuration file defined in the call.

=item C<< No sites have been identified for testing.  Please add sites to: (your config file) >>

An otherwise valid configuration file has been found, but it
does not seem to have defined any sites to be tested.

=item C<< Configuration fails to define global.MonitorSites_email >> 

Because your configuration file fails to define an email address
to be used in the From: line of email generated by this module,
the default From: line will be used instead.

=item C<< We won't send an sms, there were no critical_failures and global.report_success is not set true. >>

Although this is reported to the 'error' log, it is not an
error, so much as a report that the tests ran successfully
and a reminder that to see a report of such success, the
configuration option report_success can be set to '1'.

=item C<<We won't send an email, neither send_summary nor send_diagnostics were set to true in the configuration file >>

This error is thrown when the configuration is set to not send
email.  It serves primarily as a reminder of the configuration
settings available to control the quiet mode of operation.

=item C<< We won't send an email, there was no results_recipient defined in the configuration file. >>

This is an error.  If you are going to run these tests,
someone ought to get an occassional report of the results.
Add your email address to the configuration file.

=item C<< IP address not defined for $url. >>

This is a fatal error thrown by a private method used to analyze
the test logs for results.  After throwing this error, the
module will die.  The IP should be set by the constructor to
a default '0.0.0.0' for any site defined in the configuration
files without its own IP address.  This error message was
added to indicate when the constructor's failure to properly
set this default was about to crash the analysis method.

=item C<< Configuration file disabled email dispatch of results log. >>

Instead of adding the results log to the email report,
the module throws this warning to the error log when the
send_summary is set to false in the configuration file.

=item C<< Configuration file disabled email dispatch of diagnostic log. >>

Instead of adding the diagnostics log to the email report,
the module throws this warning to the error log when the
send_diagnostics is set to false in the configuration file.

=back


=head1 CONFIGURATION AND ENVIRONMENT

The Test::MonitorSites constructor requires a configuration
file using the ini Config::Simple format which defines global
variables and contains an .ini section for each website to be
monitored by this module.

=head1 DEPENDENCIES

This module uses the following modules, available on CPAN:
Carp, Config::Simple, WWW::Mechanize, Test::WWW::Mechanize,
Test::HTML::Tidy, HTTP::Request::Common, Test::More,
Data::Dumper, Test::Builder.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

I welcome bug reports and feature requests at both:
<http://www.campaignfoundations.com/project/issues>
as well as through the cpan hosted channels at:
"bug-test-monitorsites@rt.cpan.org", or through the web
interface at <http://rt.cpan.org>.

=head1 AUTHOR

Hugh Esco  C<< <hesco@campaignfoundations.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Hugh Esco C<<
<hesco@campaignfoundations.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the terms of the Gnu Public License. See L<gpl>.

=head1 CREDITS

Initial development of this module done with th kind support
of the Green Party of Canada.  L<http://www.greenparty.ca/>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
