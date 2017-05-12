#############################################################################
## Name:        Job.pm
## Purpose:     Thread::Isolate::Job
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-29
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Thread::Isolate::Job ;

use strict qw(vars) ;
no warnings ;

#######
# NEW #
#######

sub new {
  my $this = shift ;
  return( $this ) if ref($this) ;
  my $class = $this || __PACKAGE__ ;

  my $thi = shift ;
  my $job_type = shift ;

  my $the_job = Thread::Isolate::Thread::share_new_ref('@') ;

  $this = bless($the_job , $class) ;
  
  my ($job_id) = @$thi{qw(job_id)} ;
  
  my $id ;
  
  { lock( $$job_id ) ; 
    $id = ++$$job_id ;
  }
  
  @$the_job = ( $thi->{id} , $id , undef , $job_type , Thread::Isolate::freeze(@_) , time() ) ;

  return $this ;
}

###############
# SET_NO_LOCK #
###############

sub set_no_lock {
  my $this = shift ;
  $$this[6] = 1 ;
}

#################
# UNSET_NO_LOCK #
#################

sub unset_no_lock {
  my $this = shift ;
  $$this[6] = 0 ;
}

##############
# IS_NO_LOCK #
##############

sub is_no_lock {
  my $this = shift ;
  return 1 if $$this[6] ;
  return ;
}

##########
# DETACH #
##########

sub detach {
  my $this = shift ;
  $$this[7] = $_[0] || 1 ;
}

###############
# IS_DETACHED #
###############

sub is_detached {
  my $this = shift ;
  return 1 if $$this[7] ;
  return ;
}

#########
# CLONE #
#########

sub clone {
  my $this = shift ;
  
  my $the_job = Thread::Isolate::Thread::share_new_ref('@') ;
  
  my $clone = bless($the_job , ref($this)) ;
  
  @$the_job = @$this ;
  
  return $clone ;
}

############
# _THI_OBJ #
############

sub _thi_obj {
  my $this = shift ;
  return Thread::Isolate::Thread::new_from_id( $$this[0] ) ;
}

######
# ID #
######
 
sub id {
  my $this = shift ;
  return $$this[1] * 1 ;
}

#######
# TID #
#######

sub tid {
  my $this = shift ;
  return $Thread::Isolate::Thread::THI_SHARE_TABLE{tid}{$$this[0]} * 1
}

#########
# TH_ID #
#########

sub th_id {
  my $this = shift ;
  return $$this[0] * 1 ;
}

###########
# ALIASES #
###########

sub is_started {
  my $this = shift ;
  $this->_thi_obj->is_job_started($this) ;
}

sub is_running {
  my $this = shift ;
  $this->_thi_obj->is_job_running($this) ;
}

sub is_finished {
  my $this = shift ;
  $this->_thi_obj->is_job_finished($this) ;
}

sub wait_to_start {
  my $this = shift ;
  $this->_thi_obj->wait_job_to_start($this) ;
}

sub wait {
  my $this = shift ;
  $this->_thi_obj->wait_job($this) ;
}

sub wait_to_finish {
  my $this = shift ;
  $this->_thi_obj->wait_job($this) ;
}

sub returned {
  my $this = shift ;
  $this->_thi_obj->wait_job($this) ;
}

########
# TYPE #
########

sub type {
  my $this = shift ;
  return if $$this[2] == 2 ;
  return $$this[3] ;
}

########
# ARGS #
########

sub args {
  my $this = shift ;
  return if $$this[2] == 2 ;
  my @args = Thread::Isolate::thaw( $$this[4] ) ;
  return @args ;
}

########
# TIME #
########

sub time {
  my $this = shift ;
  return if $$this[2] == 2 ;
  return $$this[5] ;
}

########
# DUMP #
########

sub dump {
  my $this = shift ;
  my $dump ;
  
  my $tid = $$this[0] ;
  my $id = $$this[1] ;
  my $done = $$this[2] ;
  my $job_type = $$this[3] ;
  my @args = Thread::Isolate::thaw( $$this[4] ) ;
  my $no_lock = $$this[6] ;
  my $detached = $$this[7] ;
  
  $dump .= "JOB[$tid:$id][$done] TYPE[$job_type] NO_LOCK[$no_lock] DETACHED[$detached]" ;
  
  $dump .= " ARGS[". join (' ', @args) ."]" if @args ;
  
  $dump .= "\n" ;  
  
  return $dump ;
}

###########
# DESTROY #
###########

sub DESTROY {
  my $this = shift ;
  
  return if $this->tid == threads->self->tid ;
  
  { lock( @$this ) ;
    if ( !$$this[2] && !$$this[7] && $$this[3] ne 'SHUTDOWN' ) {
      $this->wait ;
      $$this[2] = 2 ;
      $$this[4] = '' ;
    }
  }

  return ;
}

#######
# END #
#######

1;


__END__


