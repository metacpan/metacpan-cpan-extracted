package Apache2::LogUtil;
use strict;
our $VERSION = 0.1;

use Apache2::Const -compile => qw(:log);
use APR::Const -compile => qw(SUCCESS);
use APR::OS;
use Apache2::ServerUtil;
use Apache2::Log;
use Apache2::MPM;

# ------------------------------------------------------------------------------
# new - Construct a new instance
# new
# new $stopwatch
# new $stopwatch $request
# where:
#   $stopwatch isa Misc::Stopwatch
#   $request isa Apache2::RequestRec
# ------------------------------------------------------------------------------

sub new {
  my $class = ref($_[0]) ? ref(shift) : shift;
  bless [@_], $class;
}

sub set_stopwatch   { $_[0]->[0] = $_[1]; }
sub get_stopwatch   { $_[0]->[0]; }
sub set_request     { $_[0]->[1] = $_[1]; }
sub get_request     { $_[0]->[1]; }

# ------------------------------------------------------------------------------
# debug - Write a debug message to the apache log
# debug $message
# ------------------------------------------------------------------------------

sub debug { shift->message(Apache2::Const::LOG_DEBUG, @_); }

# ------------------------------------------------------------------------------
# warn - Write a warning to the apache log
# warn $warn
# ------------------------------------------------------------------------------

sub warn { shift->message(Apache2::Const::LOG_WARNING, @_); }

# ------------------------------------------------------------------------------
# error - Write an error to the apache log
# error $error
# ------------------------------------------------------------------------------

sub error { shift->message(Apache2::Const::LOG_ERR, @_); }

# ------------------------------------------------------------------------------
# notice - Write a notice to the apache log
# notice $notice
# ------------------------------------------------------------------------------

sub notice { shift->message(Apache2::Const::LOG_NOTICE, @_); }

# ------------------------------------------------------------------------------
# info - Write an informational message to the apache log
# info $message
# ------------------------------------------------------------------------------

sub info { shift->message(Apache2::Const::LOG_INFO, @_); }

# ------------------------------------------------------------------------------
# message - Write to the apache log
# message $LOG_TYPE, $message
# ------------------------------------------------------------------------------

sub message {
  my $self = shift;
  my $type = shift;
  my $phase = ModPerl::Util::current_callback();
  $phase =~ s/^Perl|Handler$//g;
  my $r = $self->get_request;
  my $sw = $self->get_stopwatch;
  my $elapsed = $sw ? $sw->elapsed : 0;
  my $depth = $r ? $r->is_initial_req() ? '1' : '2' : '0';
  my $tid = Apache2::MPM->is_threaded ? APR::OS::current_thread_id : 0;
  my $fmt = '<%s> [%d-%d.%d:%.4f] %s';
  my $msg = sprintf($fmt, $phase, $$, $tid, $depth, $elapsed, join('', @_));
  my @caller = caller(1);
  my @err_args = ($caller[1], $caller[2], $type, APR::Const::SUCCESS, $msg);
  my $result = undef;
  if ($r) {
    $result = $r->log_rerror(@err_args);
  } else {
    my $s = Apache2::ServerUtil->server;
    $result = $s->log_serror(@err_args);
  }
  $result;
}

1;

__END__

=pod:summary Simple logging API with run-time context

=pod:synopsis

  use Apache2::LogUtil;
  my $log = Apache2::LogUtil->new();

Or, to capture elapsed time:

  use Apache2::LogUtil;
  use Misc::Stopwatch;
  my $sw = Misc::Stopwatch->new;
  my $log = Apache2::LogUtil->new($sw);

In a perl handler, initialize the objects on each request:

  $sw->reset->start();      # Elapsed time starts now

  $log->set_request();      # Will use $s-log_serror> (Server log file)
  $log->set_request($r);    # Will use $r-log_rerror> (VirtualHost log file)

Call logging methods:

  $log->error('The code is smoking');
  $log->warn('The code is hot');
  $log->notice('The code is warm');
  $log->info('The code is lighting up');
  $log->debug('The code is doing what?');

=pod:description

Calls C<$s-E<gt>log_serror> or C<$r-E<gt>log_rerror> if a C<$r> has been passed to 
L</set_request>. Log-file entries are formatted as:

  Fieldset 1 - Inserted by Apache
  Fieldset 2 - Inserted by this module
  Fieldset 3 - Inserted by this module
  Fieldset 4 - The log message

   .----------------------------------------- 1a) Apache date/time stamp
   |     .----------------------------------- 1b) Logging level
   |     |
   |     |      .---------------------------- 2)  HTTP Request Cycle Phase
   |     |      |         .------------------ 3a) Process ID, i.e., $$
   |     |      |         |     .------------ 3b) Thread ID (for threaded perl), or 0
   |     |      |         |     | .---------- 3c) Elapsed time, or 0
   |     |      |         |     | |       .-- 4)  Log Message
   |     |      |         |     | |       |
   |     |      |         |     | |       |
   v     v      v         v     v v       v
  [...] [warn] <Cleanup> [22933-0:0.0229] ...
               ^------------------------^
                (inserted by this module)

  1) Log prefix as per your Apache configuration, normally these values are:

  1a) The date and time of the request.

  1b) The log level of the message. The Apache directive LogLevel determines 
  which messages are displayed.

  2) The phase name is a shortened form of the current callback name.  As in the 
  above example, the callback name PerlCleanupHandler is trimmed by removing
  the and the leading Perl and trailing Handler.

  3) Process information

  3a) As in $$

  3b) ID of the child thread of $$.  If not running with threads, zero.

  3c) Elapsed time if a Misc::Stopwatch has been set up, otherwise zero.

  4) The message which we're here to log

=pod:seealso

  Apache2::Testing::LogUtil

  Apache2::Trace

  Misc::Stopwatch

  http://perl.apache.org/docs/2.0/user/handlers/http.html#HTTP_Request_Cycle_Phases

=cut
