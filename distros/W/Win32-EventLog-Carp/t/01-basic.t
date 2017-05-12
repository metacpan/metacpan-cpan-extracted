use strict;
# use warnings;

# WARNING: This test will write 7*NUM_ROUNDS events to the Windows NT
# event log.  (We test multiple rounds to verify that we are reading
# the record for that specific round.)

use constant NUM_ROUNDS      => 2;
use constant TESTS_IN_ROUNDS => 26 * NUM_ROUNDS;
use constant SOURCE          => "Application"; # "Win32EventLogCarp Test";

use Test::More tests => 10 + TESTS_IN_ROUNDS;

use File::Spec;
use Win32;

my ($hnd, $before, $after);

sub open_log {
  $hnd = Win32::EventLog->new(SOURCE, Win32::NodeName);
}

END {
  $hnd and $hnd->Close;
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
  }
  else {
    diag "WARNING: Unable to read event log";
    return;
  }
}


BEGIN {
  ok( Win32::IsWinNT(), "Win32::IsWinNT?" );
  use_ok('Win32::EventLog');

  ok($Win32::EventLog::GetMessageText = 1, "Set Win32::EventLog::GetMessageText");

  open_log();
  ok(defined $hnd, "EventLog Handle defined");

  # We need to verify that the just loading Win32::EventLog::Carp does
  # not cause errors or warnings that add tothe event log!

  $before = get_number();
  ok(defined $before, "Get size of event log");

  use_ok('Win32::EventLog::Carp', { Source => SOURCE } );

  ok(!$Win32::EventLog::Carp::LogEvals, "Check LogEvals");
  $Win32::EventLog::Carp::LogEvals = 1;
  ok($Win32::EventLog::Carp::LogEvals,  "Set LogEvals");

  $after = get_number();
  ok(defined $after, "Get size of event log");
  is($after, $before, "Check against rt.cpan.org issue \x235408");
};

$before = get_number();
carp( "test Win32::EventLog::Carp\n" );
$after = get_number();

SKIP: {
    skip "log size might be maxed out", TESTS_IN_ROUNDS
        unless $after > $before;
 
    my %Events = ( );
    my $time = time();
   
    for my $tag (1..NUM_ROUNDS) {
        $before = $after;
        Win32::EventLog::Carp::click( "test,click,$tag,$time" );
        $after = get_number();
        
        ok(defined $after, "Get size of event log $tag");
        cmp_ok($after, '>', $before, "Event log grown from click $tag");
        $Events{"click,$tag,$time"} = EVENTLOG_INFORMATION_TYPE;
        
        $before = $after;
        warn "test,warn,$tag,$time";
        $after = get_number();
        
        ok(defined $after, "Get size of event log $tag");
        cmp_ok($after, '>', $before, "Event log grown from warn $tag");
        $Events{"warn,$tag,$time"} = EVENTLOG_WARNING_TYPE;
        
        $before = $after;
        carp( "test,carp,$tag,$time" );
        $after = get_number();
        
        ok(defined $after, "Get size of event log $tag");
        cmp_ok($after, '>', $before, "Event log grown from carp $tag");
        $Events{"carp,$tag,$time"} = EVENTLOG_WARNING_TYPE;
        
        $before = $after;
        Win32::EventLog::Carp::cluck( "test,cluck,$tag,$time" );
        $after = get_number();
        
        ok(defined $after, "Get size of event log $tag");
        cmp_ok($after, '>', $before, "Event log grown from cluck $tag");
        $Events{"cluck,$tag,$time"} = EVENTLOG_WARNING_TYPE;
        
        $before = $after;
        $Win32::EventLog::Carp::LogEvals = 0;
        ok(!$Win32::EventLog::Carp::LogEvals, "Unset LogEval $tag");
        
        eval {
            die "test,evaldie,$tag,$time $tag";
        };
        $after = get_number();
        
        ok(defined $after, "Get size of event log $tag");
        is($after, $before, "Event log did not grow from eval die $tag");
        
        $before = $after;
        $Win32::EventLog::Carp::LogEvals = 1;
        ok($Win32::EventLog::Carp::LogEvals, "Set LogEval $tag");
        eval {
            die "test,die,$tag,$time $tag";
        };
        $after = get_number();
        
        ok(defined $after, "Get size of event log $tag");
        cmp_ok($after, '>', $before, "Event log grown from die $tag");
        $Events{"die,$tag,$time"} = EVENTLOG_ERROR_TYPE;
        
        $before = $after;
        eval {
            croak( "test,croak,$tag,$time $tag" );
        };
        $after = get_number();
        
        ok(defined $after, "Get size of event log $tag");
        cmp_ok($after, '>', $before, "Event log grown from croak $tag");
        $Events{"croak,$tag,$time"} = EVENTLOG_ERROR_TYPE;
        
        $before = $after;
        eval {
            confess( "test,confess,$tag,$time $tag" );
        };
        $after = get_number();
        
        ok(defined $after, "Get size of event log $tag");
        cmp_ok($after, '>', $before, "Event log grown from confess $tag");
        $Events{"confess,$tag,$time"} = EVENTLOG_ERROR_TYPE;
    }

    # In order to verify all of the events, we read through the event log
    # until we've found all the tests that we saved for verification.  We
    # do this because another application might have written to the event
    # log while the tests were running.
    
    open_log();
    
    is(scalar(keys %Events), (7*NUM_ROUNDS), "Events stacked to verify");
    
    my $pathname = File::Spec->rel2abs($0);
    my $filename = $0;
    $filename =~ s/\\/\\\\/g; # escape backslashes

    while ((keys %Events) && (my $event = get_last_event())) {
    
        my $string = $event->{Strings};
        
        if ( ($string =~ /$filename\: test\,(\w+)\,(\d+),(\d+) (?:\d+ )?at $filename/) &&
        ($event->{Source} eq SOURCE) ) {
            if( $3 == $time) {
                my $key = "$1,$2,$3";
                is(delete($Events{$key}), $event->{EventType}, "verified event $key");
            }
        }
        else {
            diag "Ignoring event: $string";
        }
    }
    
    is((keys %Events), 0, "All events verified")
        or diag join( "\n", sort keys %Events );
}
