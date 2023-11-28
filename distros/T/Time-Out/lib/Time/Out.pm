#<<<
use strict; use warnings;
#>>>

package Time::Out;

our $VERSION = '0.24';

use Exporter                    qw( import );
use Scalar::Util                qw( blessed reftype );
use Time::Out::Exception        qw();
use Time::Out::ParamConstraints qw( assert_NonNegativeNumber assert_CodeRef );
use Try::Tiny                   qw( finally try );

BEGIN {
  # if possible use Time::HiRes drop-in replacements
  for ( qw( alarm time ) ) {
    Time::HiRes->import( $_ ) if Time::HiRes->can( $_ );
  }
}

our @EXPORT_OK = qw( timeout );

sub timeout( $@ ) {
  my $context = wantarray;
  # wallclock seconds
  my $timeout   = assert_NonNegativeNumber shift;
  my $code      = assert_CodeRef pop;
  my @code_args = @_;

  my $exception;
  # in scalar context store the result in the first array element
  my @result;

  # disable previous timer and save the amount of time remaining on it
  my $remaining_time_on_previous_timer = alarm 0;
  my $start_time                       = time;

  {
# https://stackoverflow.com/questions/1194113/whats-the-difference-between-ignoring-a-signal-and-telling-it-to-do-nothing-in
# disable ALRM handling to prevent possible race condition between the end of the
# try block and the execution of alarm(0) in the finally block
    local $SIG{ ALRM } = 'IGNORE';
    try {
      local $SIG{ ALRM } = sub { die Time::Out::Exception->new( previous_exception => $@, timeout => $timeout ) }; ## no critic (RequireCarping)
      if ( $remaining_time_on_previous_timer and $remaining_time_on_previous_timer < $timeout ) {
        # a shorter timer was pending, let's use it instead
        alarm $remaining_time_on_previous_timer;
      } else {
        alarm $timeout;
      }
      defined $context
        ? $context
          ? @result = $code->( @code_args )         # list context
          : $result[ 0 ] = $code->( @code_args )    # scalar context
        : $code->( @code_args );                    # void context
      alarm 0;
    } finally {
      alarm 0;
      $exception = $_[ 0 ] if @_;
    }
  }

  my $elapsed_time = time - $start_time;
  my $new_timeout  = $remaining_time_on_previous_timer - $elapsed_time;

  if ( $new_timeout > 0 ) {
    # rearm previous timer with new timeout
    alarm $new_timeout;
  } elsif ( $remaining_time_on_previous_timer ) {
    # previous timer has already expired; send ALRM
    kill 'ALRM', $$;
  }

  # handle exceptions
  if ( defined $exception ) {
    if ( defined blessed( $exception ) and $exception->isa( 'Time::Out::Exception' ) ) {
      $@ = $exception; ## no  critic (RequireLocalizedPunctuationVars)
      return;
    }
    die $exception; ## no  critic (RequireCarping)
  }

  return
      defined $context
    ? $context
      ? return @result    # list context
      : $result[ 0 ]      # scalar context
    : ();                 # void context
}

1;
