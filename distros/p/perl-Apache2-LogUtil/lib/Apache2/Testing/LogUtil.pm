package Apache2::Testing::LogUtil;
use strict;
use warnings FATAL => 'all';
use Apache2::RequestRec ();
use Apache2::Const -compile => qw(DECLINED);
use Apache2::LogUtil;
use Misc::Stopwatch;

our $Stopwatch = Misc::Stopwatch->new; # For performance timing
our $Log = Apache2::LogUtil->new($Stopwatch); # Formatted apache log messages

sub handler {
  my $r = ref($_[0]) ? $_[0] : $_[1];
  $Stopwatch->reset->start();
  $Log->set_request($r); # Use the VirtualHost's error-log if applicable

  $Log->error('The code is smoking');
  $Log->warn('The code is hot');
  $Log->notice('The code is warm');
  $Log->info('The code is lighting up');
  $Log->debug('The code is doing what?');

  Apache2::Const::DECLINED;
}

1;

__END__

=pod:summary Test the methods of Apache2::LogUtil

=pod:synopsis

  PerlInitHandler +Apache2::Testing::LogUtil

=pod:description

This is a simple test handler which demonstrates the usage of Apache2::LogUtil.
If you are not seeing the output you expect:

  * Ensure you are looking at correct log file as your VirtualHost me be 
    writing to its own location.

  * Check the LogLevel directive (try 'debug')

=cut
