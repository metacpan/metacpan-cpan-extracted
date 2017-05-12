package Timeout::Queue;
use strict;
use warnings;

our $VERSION = '1.02';

=head1 NAME

Timeout::Queue - A priority queue made for handling timeouts

=head1 DESCRIPTION

This module is a simple priority queue based on perl's own array structures.
The actual sleeping is not done by this module as it is ment for integration
with a IO::Select based event loop or similar.

Inserts are handled by using splice, deletes are done by marking and later 
shifting off when it is posible.

=head1 SYNOPSIS
  
  #
  # Use as an object
  #

  use Timeout::Queue;

  my $timeouts = new Timeout::Queue(Time => sub { return time; });
  $timeouts->queue(
    timeout => 1, # time out in 1 seconds.
    callme => sub {
        print "I timed out!!\n";
    }
  );
  sleep $timeouts->timeout();

  foreach my $item ($timeouts->handle()) {
    $item->{callme}->();
  }

  #
  # Use with functions and own array
  # 

  use Timeout::Queue qw(queue_timeout handle_timeout, get_timeout);

  my @timeouts;
  my $timeout;
  my $timeout_id = 1;

  queue_timeout(\@timeouts, time,
    timeout_id = ++$timeout_id,
    timeout => 1, # time out in 1 seconds.
    callme => sub {
        print "I timed out!!\n";
    }
  );

  # Get the first timeout
  $timeout = get_timeout(\@timeouts, time);

  sleep $timeout;

  foreach my $item (handle_timeout(\@timeouts, time)) {
    $item->{callme}->();
  }

  # Get the next timeout 
  $timeout = get_timeout(\@timeouts, time);


=head1 METHODS

=over

=cut

use base "Exporter";

our @EXPORT_OK = qw(queue_timeout delete_timeout handle_timeout get_timeout);

=item new()

Creates a new Timeout::Queue object.

You can optionally add a a "Time" option if you would like to use something 
else than the build in time function. This can be usefull if your sleeping 
mechanism supports sub second precision.
    
The default works like this if nothing is given:

  $timeouts->new(Time => sub { return time; });

=cut

sub new {
    my ($class, %opts) = @_;

    my %self = (
        timeouts   => [],
        timeout    => undef,
        timeout_id => 0,
        time       => sub { return time; },
        last_time  => 0, 
    );
    
    $self{time} = $opts{Time} if exists $opts{Time};

    return bless \%self, (ref $class || $class);
}

=item queue(timeout => $timeout)

Queue a new timeout item, only the timeout values is used from the list. The
rest will be returned later in a hash reference by C<handle()>.

Returns the timeout id or an array with timeout id and the next timeout in the queue. 

=cut

sub queue {
    my ($self, @item) = @_;
   
    my $timeout = queue_timeout($self->{timeouts}, $self->{time}->(), @item, 
        timeout_id => ++$self->{timeout_id});
    
    if(wantarray) {
        return ($self->{timeout_id}, $timeout);
    } else {
        return $self->{timeout_id};
    }
}

=item delete($key, $value)

Delete the item's where key and value are equal to what is given.

Returns the next timeout in the queue.

=cut

sub delete {
    my ($self, $key, $value) = @_;
    return delete_timeout($self->{timeouts}, $self->{time}->(), $key, $value);
}

=item handle()

Returns all the items that have timed out so far. 

=cut

sub handle {
    my ($self) = @_;
    return handle_timeout($self->{timeouts}, 
                          $self->{time}->());
}

=item timeout()

Return the next timeout on the queue or undef if it's empty.

=cut

sub timeout {
    my ($self) = @_;
    return get_timeout($self->{timeouts}, $self->{time}->());
}


=item timeouts()

Return array refrence with queued timeouts.

=cut

sub timeouts {
    my ($self) = @_;
    return $self->{timeouts};
}

=item queue_timeout(\@timeouts, timeout => $timeout)

Queue a new timeout item, only the timeout values is used from the list. The
rest will be returned later in a hash reference by C<handle_timeout()>.

Returns the next timeout or -1 if it was not change by the queueing.

=cut

sub queue_timeout {
    my ($timeouts, $time, %item) = @_;
    
    my $timeout = -1;
    $item{expires} = $time + $item{timeout};
    
    #print "expires: $item{expires}\n";

    # Optimize by adding from the end as this will be the case 
    # when we have a default timeout that never changes.
    if(@{$timeouts} == 0) {
        # The queue is empty
        push(@{$timeouts}, \%item); 
        $timeout = $item{expires} - $time;
    } elsif ($item{expires} > $timeouts->[-1]{expires}) {
        # The item is bigger than anything else
        push(@{$timeouts}, \%item); 
    } else {
        # Insert the timeout in the right place in the timeout queue
        for(my $i=int(@{$timeouts})-1; $i >= 0; $i--) {
            if($timeouts->[$i]{expires} == 0) {
                # Deleted item, ignore.
            } elsif($item{expires} >= $timeouts->[$i]{expires}) {
                # The item fits somewhere in the middle
                splice(@{$timeouts}, $i+1,0, \%item);
                last;
            } elsif ($i == 0) {
                # The item was small than anything else
                unshift (@{$timeouts}, \%item);
                $timeout = $item{expires} - $time;
            }
        }
    }

    return $timeout;
}

=item delete_timeout(\@timeouts, $key, $value)

Delete the item's where key and value are equal to what is given.

Returns the next timeout.

=cut

sub delete_timeout {
    my ($timeouts, $time, $key, $value) = @_;
    my $timeout;
    
    # Make item as delete.
    for(my $i=0; $i < int(@{$timeouts}); $i++) {
        if(exists $timeouts->[$i]{$key} and $value eq $timeouts->[$i]{$key}) {
            $timeouts->[$i]{expires} = 0;
        }
    }

    # Trim @timeouts queue and set timeout
    while(my $item = shift(@{$timeouts})) {
        if($item->{expires} != 0) {
            unshift(@{$timeouts}, $item);
            $timeout = $item->{expires} - $time;
            last;
        }
    }

    # Trim @timeouts queue from behind.
    while(my $item = pop(@{$timeouts})) {
        if($item->{expires} != 0) {
            push(@{$timeouts}, $item);
            last;
        }
    }

    return $timeout;
}


=item handle_timeout(\@timeouts, time())

Returns all the items that have timed out so far. 

=cut

sub handle_timeout {
    my ($timeouts, $time) = @_; 
    
    my @items;
    while(my $item = shift @{$timeouts}) {
        if($item->{expires} == 0) {
           next; # Remove item from queue
        
        } elsif($item->{expires} <= $time) {
            push(@items, $item);
        
        } else {
            # No more items timed out, put back on queue.
            unshift(@{$timeouts}, $item);
            last;
        }
    }

    return @items;
}

=item get_timeout(\@timeouts, time())

Return the next timeout on the queue or undef if it's empty.

=cut

sub get_timeout {
    my ($timeouts, $time) = @_;

    if(@{$timeouts} > 0) {
        my $timeout = ($timeouts->[0]{expires}-$time);
        return $timeout >= 0 ? $timeout : 0;
    } else {
        return;
    }
}

=back

=head1 AUTHOR

Troels Liebe Bentsen <tlb@rapanden.dk> 

=head1 COPYRIGHT

Copyright(C) 2005-2007 Troels Liebe Bentsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
