#############################################################################
## Name:        Pool.pm
## Purpose:     Thread::Isolate::Pool
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-29
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Thread::Isolate::Pool ;

use strict qw(vars) ;
no warnings ;

  use Thread::Isolate ;

#######
# NEW #
#######

sub new {
  my $this = shift ;
  return( $this ) if ref($this) ;
  my $class = $this || __PACKAGE__ ;
  
  my $limit = shift ;

  my $pool = Thread::Isolate::Thread::share_new_ref('@') ;
  
  my $main_thr = Thread::Isolate->new() ;
  $main_thr->{clone} = 1 ;
  
  $$pool[0] = $limit || 0 ;
  $$pool[1] = $main_thr ;

  $this = bless($pool , $class) ;

  return $this ;
}

########
# COPY #
########

sub copy {
  my $this = shift ;
  
  my $pool = Thread::Isolate::Thread::share_new_ref('@') ;
  
  my $tm = $this->main_thread ;
  
  my $main_thr = $this->main_thread->new_internal ;
  $main_thr->{clone} = 1 ;
  
  $$pool[0] = $$this[0] ;
  $$pool[1] = $main_thr ;

  return bless($pool , ref($this)) ;
}

###############
# MAIN_THREAD #
###############

sub main_thread {
  my $this = shift ;
  return $this->[1] ;
}

#########
# LIMIT #
#########

sub limit {
  my $this = shift ;
  return $this->[0] ;
}

###########
# THREADS #
###########

sub threads {
  my $this = shift ;
  
  { lock( @$this ) ;
    return @$this[2 .. $#{$this}] ;
  }
}

#################
# THREADS_TOTAL #
#################

sub threads_total {
  my $this = shift ;
  
  { lock( @$this ) ;
    return($#{$this} - 1) ;
  }
}

##############
# ADD_THREAD #
##############

sub add_thread {
  my $this = shift ;
  return if $this->limit && $this->threads_total == $this->limit ;
  my $th_new = $this->main_thread->new_internal ;
  $th_new->{clone} = 1 ;
  push(@$this , $th_new) ;
  return $th_new ;
}

###################
# GET_FREE_THREAD #
###################

sub get_free_thread {
  my $this = shift ;
  
  my ($th_free , $on_limit) ;
  
  { lock( @$this ) ;
  
    my @threads = $this->threads ;
    my @threads_free ;
    
    foreach my $threads_i ( @threads ) {
      if ( $threads_i && !$threads_i->is_running_any_job ) {
        push(@threads_free , $threads_i) ;
      }
    }
    
    if ( !@threads_free ) {
      my $new_thr = $this->add_thread() ;
      if ( $new_thr ) {
        push(@threads_free , $new_thr) ;
      }
      else {
        ## Let's sort a thread from all if we can't create a new due LIMIT:
        @threads_free = @threads ;
        $on_limit = 1 ;
      }
    }
    
    $th_free = (sort { $a->{pool_use} <=> $b->{pool_use} } @threads_free)[0] ;
    
    ++$th_free->{pool_use} ;
  }

  return( $th_free , $on_limit ) if wantarray ;
  return $th_free ;
}

#######
# USE #
#######

sub use {
  my $this = shift ;
  return $this->main_thread->use(@_) ;
}

########
# EVAL #
########

sub eval_detached {
  my $this = shift ;
  my ($thf , $on_limit) = $this->get_free_thread ;
  return ( $on_limit ? $thf->eval_detached_no_lock(@_) : $thf->eval_detached(@_) ) ;
}

sub eval {
  my $this = shift ;
  my ($thf , $on_limit) = $this->get_free_thread ;
  return ( $on_limit ? $thf->eval_no_lock(@_) : $thf->eval(@_) ) ;
}

########
# CALL #
########

sub call_detached {
  my $this = shift ;
  my ($thf , $on_limit) = $this->get_free_thread ;
  return ( $on_limit ? $thf->call_detached_no_lock(@_) : $thf->call_detached(@_) ) ;
}

sub call {
  my $this = shift ;
  my ($thf , $on_limit) = $this->get_free_thread ;
  return ( $on_limit ? $thf->call_no_lock(@_) : $thf->call(@_) ) ;
}

############
# SHUTDOWN #
############

sub shutdown {
  my $this = shift ;
  
  { lock( @$this ) ;
  
    my @threads = $this->threads ;
  
    foreach my $threads_i ( @threads ) {
      next if !$threads_i ;
      $threads_i->shutdown ;
      $threads_i = undef ;
    }
  }

  return 1 ;
}

###########
# DESTROY #
###########

sub DESTROY {
  my $this = shift ;
  $this->shutdown ;
}

#######
# END #
#######

1;

__END__

=head1 NAME

Thread::Isolate::Pool - A pool of threads to execute multiple tasks.

=head1 DESCRIPTION

This module creates a pool of threads that can be used to execute simultaneously
many tasks. The interface to the pool is similar to a normal Thread::Isolate object,
so we can think that the pool is like a thread that can receive multiple calls at the same time.

=head1 USAGE

  use Thread::Isolate::Pool ;

  my $pool = Thread::Isolate::Pool->new() ;
  
  $pool->use('LWP::Simple') ; ## Loads LWP::Simple in the main thread of the pool.
  
  print $pool->main_thread->err ; ## $@ of the main thread of the pool.
  
  my $url = 'http://www.perlmonks.com/' ;
  
  my $job1 = $pool->call_detached('get' , $url) ;
  my $job2 = $pool->call_detached('get' , $url) ;
  my $job3 = $pool->call_detached('get' , $url) ;
  
  ## Print what jobs are running in the pool:
  while( $job1->is_running || $job2->is_running || $job3->is_running ) {
    print "[1]" if $job1->is_running  ;
    print "[2]" if $job2->is_running  ;
    print "[3]" if $job3->is_running  ;
  }
  
  print "\n<<1>> Size: " . length( $job1->returned ) . "\n" ;
  print "\n<<2>> Size: " . length( $job2->returned ) . "\n" ;
  print "\n<<3>> Size: " . length( $job3->returned ) . "\n" ;
  
  ## Shutdown all the thread of the pool:
  $pool->shutdown ;


The code above creates a Pool of threads and make simultaneously 3 I<LWP::Simple::get()>s.
Internally the pool has a main thread that is used to create the execution threads.

I<B<The main thread should have all the resources/modules loaded before make any call()/eval() to the pool.>>

When a call()/eval() is made, if the pool doesn't have any thread free (without be executing any job),
a new thread is created from the main thread, and is used to do the task. Note that no threads will
be removed after be created since this won't free memory, so is better to let them there until shutdown().

=head1 METHODS

=head2 new ( LIMIT )

Creates a new pool. If I<LIMIT> is defined will set the maximal number of threads inside the pool.
So, this defines the maximal number of simultaneous calls that the pool can have.

=head2 main_thread

Returns the main thread.

=head2 limit

Returns the LIMIT of threads of the pool.

=head2 get_free_thread

Return a free thread. If is not possible to get a free thread and create a new
due LIMIT, any thread in the pool will be returned.

If called in a ARRAY contest will I<return ( FREE_THREAD , ON_LIMIT )>, where
when ON_LIMIT is true indicates that was not possible to get a free thread or create a new free thread.

=head2 add_thread

Add a new thread if is not in the LIMIT.

=head2 use ( MODULE , ARGS )

Make an I<"use MODULE qw(ARGS)"> call in the main thread of the pool.

=head2 call

Get a free thread and make a I<$thi->call()> on it.

=head2 call_detached

Get a free thread and make a I<$thi->call_detached()> on it.

=head2 eval

Get a free thread and make a I<$thi->eval()> on it.

=head2 eval_detached

Get a free thread and make a I<$thi->eval_detached()> on it.

=head2 shutdown

Shutdown all the threads of the pool.

=head1 SEE ALSO

L<Thread::Isolate>, L<Thread::Isolate::Map>.

L<Thread::Pool>

=head1 AUTHOR

Graciliano M. P. <gmpassos@cpan.org>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


