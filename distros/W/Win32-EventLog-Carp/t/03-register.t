#-*- mode: perl;-*-

use strict;
# use warnings;

# WARNING: This test will write 7*NUM_ROUNDS events to the Windows NT
# event log.  (We test multiple rounds to verify that we are reading
# the record for that specific round.)

use constant NUM_ROUNDS => 2;

use constant SOURCE     => "Win32EventLogCarp RegTest";
use constant LOG        => "System";

BEGIN {

  eval {
    require Win32::EventLog::Message;
    import Win32::EventLog::Message;
  };

  my $has_it = ($@) ? 0 : 1;

  my $mode   = ($has_it) ? "tests => 12+(25*NUM_ROUNDS)"
    : "skip_all => \"Win32::EventLog::Message not found\"";
  
  eval "use Test::More $mode;";
}

use File::Spec;
use Win32;

my $hnd;
my ($cnt1, $cnt2, $cnt3);

sub open_log {
  $hnd = new Win32::EventLog(LOG, Win32::NodeName);
}

sub close_log {
  if ($hnd) { $hnd->Close; }
  $hnd = undef;
}

sub get_number {
  my $cnt = -1;
  $hnd->GetNumber($cnt);
  return $cnt;
}


sub get_last_event {
  my $event = { };
  if ($hnd->Read(
    EVENTLOG_BACKWARDS_READ() | EVENTLOG_SEQUENTIAL_READ(), 0, $event)) {
    return $event;
  } else {
    diag( "WARNING: Unable to read event log" );
    return;
  }
}


BEGIN {
  ok( Win32::IsWinNT(), "Win32::IsWinNT?" );
  use_ok('Win32::EventLog');

  ok($Win32::EventLog::GetMessageText = 1,
     "Set Win32::EventLog::GetMessageText");

  open_log();

  ok(defined $hnd, "EventLog Handle defined");

  # We need to verify that the just loading Win32::EventLog::Carp does
  # not cause errors or warnings that add tothe event log!

  $cnt1 = get_number();
  ok(defined $cnt1, "Get size of event log");

  use_ok('Win32::EventLog::Carp', { Source => SOURCE, Register => LOG, } );

  ok(!$Win32::EventLog::Carp::LogEvals, "Check LogEvals");
  $Win32::EventLog::Carp::LogEvals = 1;
  ok($Win32::EventLog::Carp::LogEvals,  "Set LogEvals");


  $cnt2 = get_number();
  ok(defined $cnt2, "Get size of event log");

  is($cnt2, $cnt1, "Check against rt.cpan.org issue \x235408");
};


my %Events = ( );

my $time = time();

for my $tag (1..NUM_ROUNDS) {
  $cnt1 = $cnt2;

  Win32::EventLog::Carp::click "test,click,$tag,$time";

  $cnt2 = get_number();
  ok(defined $cnt2, "Get size of event log");
  {
    local $TODO = "log size might be maxed out";
    cmp_ok($cnt2, '>', $cnt1, "Event log grown from click");
  }
  $Events{"click,$tag,$time"} = EVENTLOG_INFORMATION_TYPE;

  $cnt1 = $cnt2;

  warn "test,warn,$tag,$time";

  $cnt2 = get_number();
  ok(defined $cnt2, "Get size of event log");
  {
    local $TODO = "log size might be maxed out";
    cmp_ok($cnt2, '>', $cnt1, "Event log grown from warn");
  }
  $Events{"warn,$tag,$time"} = EVENTLOG_WARNING_TYPE;

  $cnt1 = $cnt2;

  carp "test,carp,$tag,$time";

  $cnt2 = get_number();
  ok(defined $cnt2, "Get size of event log");
  {
    local $TODO = "log size might be maxed out";
    cmp_ok($cnt2, '>', $cnt1, "Event log grown from carp");
  }
  $Events{"carp,$tag,$time"} = EVENTLOG_WARNING_TYPE;

  $cnt1 = $cnt2;

  Win32::EventLog::Carp::cluck "test,cluck,$tag,$time";

  $cnt2 = get_number();
  ok(defined $cnt2, "Get size of event log");
  {
    local $TODO = "log size might be maxed out";
    cmp_ok($cnt2, '>', $cnt1, "Event log grown from cluck");
  }
  $Events{"cluck,$tag,$time"} = EVENTLOG_WARNING_TYPE;

  $cnt1 = $cnt2;
  $Win32::EventLog::Carp::LogEvals = 0;
  ok(!$Win32::EventLog::Carp::LogEvals, "Unset LogEval");
  eval {
    die "test,evaldie,$tag,$time";
  };

  $cnt2 = get_number();
  ok(defined $cnt2, "Get size of event log");
  is($cnt2, $cnt1, "Event log did not grow from eval die");

  $cnt1 = $cnt2;
  $Win32::EventLog::Carp::LogEvals = 1;
  ok($Win32::EventLog::Carp::LogEvals, "Set LogEval");
  eval {
    die "test,die,$tag,$time";
  };

  $cnt2 = get_number();
  ok(defined $cnt2, "Get size of event log");
  {
    local $TODO = "log size might be maxed out";
    cmp_ok($cnt2, '>', $cnt1, "Event log grown from die");
  }
  $Events{"die,$tag,$time"} = EVENTLOG_ERROR_TYPE;

  $cnt1 = $cnt2;
  eval {
    croak "test,croak,$tag,$time";
  };

  $cnt2 = get_number();
  ok(defined $cnt2, "Get size of event log");
  {
    local $TODO = "log size might be maxed out";
    cmp_ok($cnt2, '>', $cnt1, "Event log grown from croak");
  }
  $Events{"croak,$tag,$time"} = EVENTLOG_ERROR_TYPE;

  $cnt1 = $cnt2;
  eval {
    confess "test,confess,$tag,$time";
  };

  $cnt2 = get_number();
  ok(defined $cnt2, "Get size of event log");
  {
    local $TODO = "log size might be maxed out";
    cmp_ok($cnt2, '>', $cnt1, "Event log grown from confess");
  }
  $Events{"confess,$tag,$time"} = EVENTLOG_ERROR_TYPE;
}

# In order to verify all of the events, we read through the event log
# until we've found all the tests that we saved for verification.  We
# do this because another application might have written to the event
# log while the tests were running.

# use YAML 'Dump';

open_log();

{

  ok((keys %Events) == (7*NUM_ROUNDS), "Events stacked to verify");

  my $pathname = File::Spec->rel2abs($0);
  my $filename = $0;
  $filename =~ s/\\/\\\\/g; # escape backslashes


    while ((keys %Events) && (my $event = get_last_event())) {

#    print STDERR YAML->Dump($event);

      my $string = $event->{Strings};

      if ( ($string =~ /$filename\: test\,(\w+)\,(\d+),(\d+) at $filename/) &&
           ($event->{Source} eq SOURCE) ) {
        if( $3 == $time) {
          my $key = "$1,$2,$3";
          is((delete $Events{$key}), $event->{EventType},
             "verified event $key");
        }
      }
      else {
         exists $ENV{PERL_WIN32_EVENTLOG_CARP_TEST_VERBOSE}
            and diag "Ignoring event: $string";
      }
      
  }

  is((keys %Events), 0, "All events verified");
}



END {
  close_log();

  eval {
    Win32::EventLog::Message::UnRegisterSource(
      LOG, SOURCE
    );
  };

}

__END__
