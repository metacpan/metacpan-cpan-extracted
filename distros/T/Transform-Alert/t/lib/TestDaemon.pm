package TestDaemon;

use sanity;
use Devel::SimpleTrace;

use Transform::Alert;

use Log::Log4perl;
use Config::General;
use Path::Class;
use File::Slurp 'read_file';

use lib dir('lib')->absolute->stringify;  # paths keep changing...

sub new {
   my ($class, $dir, $name, $conf_insert) = @_;

   my $conf_file = dir()->file('corpus', $dir, "$name.conf")->resolve->absolute;
   my $log_file  = $conf_file->dir->file("$name.log");
   
   # init the logger...
   $log_file->remove;
   Log::Log4perl->init(\ qq{
      log4perl.logger = TRACE, FileApp
      log4perl.appender.FileApp = Log::Log4perl::Appender::File
      log4perl.appender.FileApp.filename = $log_file
      log4perl.appender.FileApp.layout   = PatternLayout::Multiline
      log4perl.appender.FileApp.layout.ConversionPattern = [%d{ISO8601}] [%-5p] {%-25M{2}} %m%n
   });
   my $log = Log::Log4perl->get_logger();

   # ...and start using it immediately
   $SIG{__DIE__} = sub {
      # We're in an eval {} and don't want log
      # this message but catch it later
      return if ($^S);

      local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
      $log->logdie(@_);
   };

   # config file loading
   my $conf = {
      Config::General->new(
         -ConfigFile     => $conf_file->stringify,
         -LowerCaseNames => 1,
      )->getall
   };

   # configuration inserts, if any
   if ($conf_insert) {
      foreach my $path (keys %$conf_insert) {
         my $val = $conf_insert->{$path};
         eval "\$conf->$path = \$val;";
      }
   }

   # change the working directory to the configuration file,
   # so that BaseDir can use relative paths
   chdir $conf_file->dir->stringify;

   my $ta = Transform::Alert->new(
      config => $conf,
      log    => $log,
   );
   
   return ($ta, $log_file);
}

use Test::Most;
use JSONY;
use Path::Class;
use Time::HiRes 'sleep';

sub email_test {
   my ($class, $email_type) = @_;
   
   # JSONY parse
   my $inbox_conf = decode_jsony $ENV{'TATEST_'.uc($email_type).'_JSONY'};
   my $smtp_conf  = decode_jsony $ENV{TATEST_SMTP_JSONY};
   my $email_addy = $ENV{TATEST_EMAIL_ADDY};

   $inbox_conf = { @$inbox_conf } if (ref $inbox_conf eq 'ARRAY');
   $smtp_conf  = { @$smtp_conf  } if (ref $smtp_conf  eq 'ARRAY');

   # extra defaults
   $inbox_conf->{timeout} //= 20;
   $smtp_conf->{timeout}  //= 20;

   my ($ta, $log_file) = TestDaemon->new('email', $email_type, {
      '{input}{'.$email_type.'}{connopts}' => $inbox_conf,
      '{output}{email}{connopts}' => $smtp_conf,
   });

   # Let's start the loop with a message
   my $t;

   # first, clean out the inbox
   my $in = $ta->inputs->{$email_type}->input;
   $t = $in->open;
   ok($t, 'open input (for zeroing)')  || explain $t;
   until ($in->eof) { $in->get; }
   $t = $in->close;
   ok($t, 'close input (for zeroing)') || explain { out => $t, err => $@ };

   # (use TA's own output object to compose the email)
   my $out = $ta->outputs->{email};
   my $tt = Template->new();
   my $out_str = '';
   my $vars = {
      subject => 'Test Problem 0',
      name    => 'dogbert'.int(rand(44444)).'q',
      problem => 'It broke!',
      ticket  => 'TT0000000000',
   };

   $tt->process($out->template, $vars, \$out_str);

   $t = $out->open;
   ok($t, 'open output') || explain $t;
   $t = $out->send(\$out_str);
   ok($t, 'send output') || explain { out => $t, err => $@ };

   lives_ok {
      for (1..3) {
         my $wait = $ta->heartbeat;
         sleep $wait if ($wait > 0);
      };
   } '3 heartbeats';
   
   # check the log for the right phrases
   my $log = $log_file->slurp;

   my $qm_email_addy = $email_addy;
   $qm_email_addy =~ s/\@/\\\@/g;
   foreach my $re (
      qr/"BODY"        \s+=> "We found a problem on this device:(?:\\[nr])+Name    : dogbert\d+q(?:\\[nr])+Problem : It broke!(?:\\[nr])+Ticket #: TT0000000000(?:\\[nr])+",/,
      qr/"Content-Type"\s+=> "text\/plain/,
      qr/"From"        \s+=> ".*\Q$qm_email_addy\E/,
      qr/"To"          \s+=> ".*\Q$qm_email_addy\E/,
      qr/"Message-ID"  \s+=> /,
      qr/"Subject"     \s+=> "Email Alert - Test Problem 0",/,
      qr/name\s+=> "dilbert\d+m",/,
   ) {
      ok($log =~ $re, "Found RE - $re");
   }

   foreach my $str (
      'problem => "It still broke!",',
      'subject => "Test Problem 1",',
      'ticket  => "TT0000000001",',
      'Found message: ',
      'Closing all I/O for this group',
      'END Heartbeat',
      'Finish time marker',
      'Looking at Input "'.$email_type.'"...',
      'Looking at Output "email"...',
      'Opening input connection',
      'Processing input...',
      'Processing outputs...',
      'START Heartbeat',
      'Sending alert for "email"',
      'Variables (post-munge):',
      'Variables (pre-munged):',
   ) {
      ok($log =~ qr/\Q$str\E/, "Found - $str");
   }

   foreach my $str (
      'name    => "dogbert',
      'Munger cancelled output',
      'Error ',
      'failed: ',
   ) {
      ok($log !~ qr/\Q$str\E/, "Didn't find - $str");
   }

   # these sometimes take too long, so we set these as TODOs
   TODO: {
      local $TODO = 'Second message is optional';
      
      foreach my $re (
         qr/"BODY"        \s+=> "We found a problem on this device:(?:\\[nr])+Name    : dilbert\d+m(?:\\[nr])+Problem : It still broke!(?:\\[nr])+Ticket \#: TT0000000001(?:\\[nr])+",/,
         qr/"Subject"     \s+=> "Email Alert - Test Problem 1",/,
      ) {
         ok($log =~ $re, "Found RE - $re");
      }

      foreach my $str (
         'subject => "Test Problem 2",',
         'ticket  => "TT0000000002",',
      ) {
         ok($log =~ qr/\Q$str\E/, "Found - $str");
      }
   };

   my $is_pass = Test::More->builder->is_passing;
   $log_file->remove if ($is_pass);
   explain $log unless ($is_pass);
}

42;
