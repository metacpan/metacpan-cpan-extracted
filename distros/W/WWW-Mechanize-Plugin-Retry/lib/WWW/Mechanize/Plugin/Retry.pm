package WWW::Mechanize::Plugin::Retry;

use warnings;
use strict;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(retry_failed _retry_check_sub 
                             _method_to_retry
                             _delays _delay_index));

our $VERSION = '0.04';

sub init {
  my($class, $pluggable) = @_;
  no strict 'refs';
  local $_;
  eval "*WWW::Mechanize::Pluggable::$_ = \\&$_"
    for qw(retry retry_if _method_to_retry _retry_fib
           _retry_check_sub _delays _delays_max _delay_index retry_failed);  

  $pluggable->pre_hook('get', sub { prehook(@_) } );
  $pluggable->pre_hook('submit_form', sub { prehook(@_) } );
  $pluggable->post_hook('get', sub { posthook(@_) } );
  $pluggable->post_hook('submit_form', sub { posthook(@_) } );
}

sub retry_if {
  my($self, $sub, $times) = @_;

  if (defined $sub) {  
    $self->_retry_check_sub($sub);
    $self->_delays($times);
    $self->_delay_index(0);
    $self->retry_failed(0);
  }
  else {
    $sub;
  }
}

sub retry {
  my($self, $times) = @_;
  $self->retry_if(sub {$self->success}, $times);
}

sub prehook {
  my($pluggable, $mech, @args) = @_;
  $pluggable->_method_to_retry($pluggable->last_method);
  
  # Don't skip the actual method call.
  0;
}

sub posthook {
  my($pluggable, $mech, @args) = @_;

  # just leave if we have no retry check, or the check passes.
  my $sub = $pluggable->_retry_check_sub;
  if (!defined($sub) or $sub->()) {
    # Ensure that the delay works next time round, and
    # note that we did not fail retry.
    $pluggable->_delay_index(-1);
    $pluggable->retry_failed(0);
    return;
  }

  # Retry needed (check failed). Are we out of delays?
  my $delay_index = $pluggable->_delay_index;
  if ($delay_index == $pluggable->_delays) {
    # Ran out this time.
    $pluggable->_delay_index(-1);
    $pluggable->retry_failed(1);
  }
  else {
    my $current_delay = _retry_fib($delay_index);
    $pluggable->_delay_index($pluggable->_delay_index+1);
    sleep $current_delay;
    my $method = $pluggable->_method_to_retry();
    eval "\$pluggable->$method->(\@args)";
  }
}

# initial values in Fibonacci sequence
my @fib_for = (1,1);

# Extend and cache as needed
sub _retry_fib_for {
  my($n) = @_;
  # walk up cache from last known value, applying F(n) = F(n-1)+F(n-2)
  for my $i (@fib_for..$n) {
    $fib_for[$i] = $fib_for[$i-1]+$fib_for[$i-2];
  }
  return;
}

# Fibonacci # N
sub _retry_fib {
  my($n) = @_;
  if (!defined $fib_for[$n]) {
    _retry_fib_for($n);
  }
  return $fib_for[$n];
}


1; # End of WWW::Mechanize::Plugin::Retry
__END__

=head1 NAME

WWW::Mechanize::Plugin::Retry - programatically-controlled fetch retry

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use WWW::Mechanize::Pluggable;
    my $foo = WWW::Mechanize::Plugin::Retry->new();
    my $foo->retry_if(\&test_sub, 5, 10, 30, 60);

    # Will run test_sub with the Mech object after the get.
    # If the test_sub returns false, shift off one wait interval
    # from the list, wait that long, and repeat. Give up if
    # unsuccessful every time.

    $foo->get("http://wobbly.site.net");
    if ($mech->retry_failed) {
      # used to detect that the retries all failed
      ...
    }

=head1 DESCRIPTION

The Retry plugin allows you to establish a criterion by which you
determine whether a page fetch or submit has worked successfully;
if so, the plugin returns control to the caller. If not, the last
operation is retried. This is repeated once for every item in the
delay list until either we run out of delays or the transaction 
succeeds.

=head1 METHODS

=head2 init

Establish methods in Pluggable's namespace and set up hooks.

=head2 retry_if

Sets up the subroutine to call to see if this is a failure or not.

This subroutine should return B<true> if the get or submit_form
succeeded, and B<false> if it did not.

=head2 retry

Sets up like C<retry_if>, but assigns a default test ( sub { $self->success } ).
If the transaction was deemed successful by C<WWW::Mechanize>, then it's a 
success.

=head2 prehook

Record the method that we're going to retry if necessary. This 
must be done here because we don't want to be dependent on
C<WWW::Mechanize> and C<WWW::Mechanize::Pluggable> not calling
methods in C<WWW::Mechanize::Pluggable>, which would reset the
method in C<last_method>. (Notably, Mech calls Mech::success
internally.)

=head2 posthook

Handles the actual retry, waiting and recursively calling the 
originally-called method as needed.

=head1 AUTHOR

Joe McMahon, C<< <mcmahon@yahoo-inc.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-mechanize-plugin-retry@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Mechanize-Plugin-Retry>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Joe McMahon, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

