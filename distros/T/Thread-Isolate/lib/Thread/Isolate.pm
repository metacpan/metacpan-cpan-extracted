#############################################################################
## Name:        Isolate.pm
## Purpose:     Thread::Isolate
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-29
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Thread::Isolate ;
use 5.008006 ;

use strict qw(vars);
no warnings ;

use vars qw($VERSION @ISA) ;

$VERSION = '0.05' ;

@ISA = qw(Thread::Isolate::Thread) ;

sub BEGIN {
  *CORE::GLOBAL::exit = \&EXIT ;
  *CORE::GLOBAL::die = \&DIE ;
}

#######
# DIE #
#######

sub DIE {
  my $is_exit ;
  if ( $_[0] =~ /#CORE::GLOBAL::exit#/s ) {
    my $err = shift ;
    $err =~ s/#CORE::GLOBAL::exit#/exit()/gsi ; ;
    unshift (@_, $err) ;
    $is_exit = 1 ;
  }
  
  if ( $^S ) {
    my $thi = Thread::Isolate->self ;
    $thi->add_job('SHUTDOWN') if $thi ;
    CORE::die(@_) ;
  }
  else {
    if ( $is_exit ) {
      Thread::Isolate->new_from_id( $Thread::Isolate::Thread::MOTHER_THREAD )->eval(' CORE::exit() ;') if $Thread::Isolate::Thread::MOTHER_THREAD ;
      CORE::exit ;
    }
    else { warn(@_) ;}
  }
}

########
# EXIT #
########

sub EXIT {
  my @call = caller ;
  if ( $call[1] =~ /^\(eval/ ) {
    my @call2 = caller(1) ;
    die("#CORE::GLOBAL::exit# at $call[1] (package $call[0]) line $call[2]:\n$call2[6]\n") ;
  }
  else {
    die("#CORE::GLOBAL::exit# at $call[1] (package $call[0]) line $call[2].\n") ;
  }
}

###########
# REQUIRE #
###########

  use Storable () ;
  use Thread::Isolate::Thread ;
  
  Thread::Isolate::Thread::start_mother_thread() ;

######################
# STORABLE SIGNATURE #
######################

use vars qw($STORABLE_SIGN $USE_EXTERNAL_PERL) ;

BEGIN {
  return if $STORABLE_SIGN ;
  
  ($USE_EXTERNAL_PERL , $STORABLE_SIGN) = ('','') ;

  if ( $STORABLE_SIGN eq '' ) {
    if (!$USE_EXTERNAL_PERL) {
      $STORABLE_SIGN = unpack( 'l',Storable::freeze( [] )) ;
    }
    else {
      open( my $handle,
      qq($^X -MStorable -e "print unpack('l',Storable::freeze( [] ))" | )
      ) or die "Cannot determine Storable signature\n" ;
      $STORABLE_SIGN = <$handle>;
      $USE_EXTERNAL_PERL = 'Signature obtained with an external Perl!' ;
    }
  }
}

##########
# FREEZE #
##########

sub freeze {
  if (@_) {
    foreach (@_) {
      if ( !defined() or ref() or m#\0# ) {
        my ( $stable_tree , $holder ) = make_stable_tree(\@_) ;
        my $freeze = Storable::freeze($stable_tree) ;
        make_stable_tree($stable_tree , $holder , 1) ;
        return $freeze ;
      }
    }
    return join("\0" , @_) ;
  }
  else { return ;}
}

########
# THAW #
########

sub thaw {
  return unless defined( $_[0] ) and defined( wantarray ) ;
  
  if ( (unpack('l', $_[0]) || 0) == $STORABLE_SIGN ) {
    my $thaw = Storable::thaw( $_[0] ) ;
    restore_stable_tree($thaw) ;
    return wantarray ? @$thaw : $$thaw[0] ;
  }
  else {
    if (wantarray) {
      return split("\0" , $_[0]) ;
    }
    else {
      return $1 if $_[0] =~ m#^([^\0]*)# ;
      return $_[0] ;
    }
  }

}

####################  
# MAKE_STABLE_TREE #
####################

sub make_stable_tree {
  my $ref = shift ;
  my $holder = shift(@_) || [] ;
  my $restore = shift ;
  
  if ( !ref $ref ) {
    return wantarray ? ( $ref , $holder ) : $ref ;
  }
  
  if (ref $ref eq 'GLOB') {
    push(@$holder , $ref) ;
    my $fileno = fileno($ref) || '' . *$ref ;
    $ref = bless(['GLOB' , $fileno] , 'Thread::Isolate::FREEZE') ;
  }
  elsif (ref $ref eq 'CODE') {
    push(@$holder , $ref) ;
    $ref = bless(['CODE' , undef] , 'Thread::Isolate::FREEZE') ;
  }
  
  if (ref $ref eq 'HASH') {
    foreach my $Key ( sort keys %$ref ) {
      &make_stable_tree($$ref{$Key} , $holder , $restore) if ref $$ref{$Key} ;
    }
  }
  elsif (ref $ref eq 'ARRAY') {
    foreach my $i ( @$ref ) {
      $i = &make_stable_tree($i , $holder , $restore) if ref $i ;
    }
  }
  elsif (ref $ref eq 'SCALAR' || ref $ref eq 'REF') {
    $$ref = &make_stable_tree($$ref , $holder , $restore) if ref $$ref ;
  }
  elsif (ref $ref eq 'Thread::Isolate::FREEZE') {
    if ( $restore == 1 ) {
      $ref = shift @$holder ;
    }
    elsif ( $restore == 2 ) {
      if ( $$ref[0] eq 'GLOB' ) {
        if ( $$ref[1] =~ /^\d+$/ ) {
          open(my $fh , "+<&=$$ref[1]") ;
          $ref = $fh ;
        }
        elsif ( $$ref[1] =~ /^\*(.+)/s ) {
          $ref = \*{$1} ;
        }
      }
      elsif ( $$ref[0] eq 'CODE' ) {
        $ref = eval('sub {}') ;
      }
    }
  }
  elsif (ref $ref && UNIVERSAL::isa($ref , 'UNIVERSAL')) {
    if ( UNIVERSAL::isa($ref , 'HASH') ) {
      foreach my $Key ( sort keys %$ref ) {
        $$ref{$Key} = &make_stable_tree($$ref{$Key} , $holder , $restore) if ref $$ref{$Key} ;
      }
    }
    elsif ( UNIVERSAL::isa($ref , 'ARRAY') ) {
      foreach my $i ( @$ref ) {
        $i = &make_stable_tree($i , $holder , $restore) if ref $i ;
      }
    }
    elsif ( UNIVERSAL::isa($ref , 'SCALAR') || UNIVERSAL::isa($ref , 'REF') ) {
      $$ref = &make_stable_tree($$ref , $holder , $restore) if ref $$ref ;
    }
  }

  return wantarray ? ( $ref , $holder ) : $ref ;
}

#######################
# RESTORE_STABLE_TREE #
#######################

sub restore_stable_tree {
  my $stable_tree = shift ;
  return make_stable_tree($stable_tree , undef , 2) ;
}

#######
# END #
#######

1;


__END__

=head1 NAME

Thread::Isolate - Create Threads that can be called externally and use them to isolate modules from the main thread.

=head1 DESCRIPTION

This module has the main purpose to isolate loaded modules from the main thread.

The idea is to create the I<Thread::Isolate> object and call methods, evaluate
codes and use modules inside it, with synchronized and unsynchronized calls.

Also you can have multiple Thread::Isolate objects, with different states of the
Perl interpreter (different loaded modules in each thread).

To save memory Thread::Isolate holds a cleaner version of the Perl interpreter
when it's loaded, than it uses this Mother Thread to create all the other Thread::Isolate
objects.

=head1 USAGE

Synchronized calls:

  ## Load it soon as possible to save memory:
  use Thread::Isolate ;
  
  my $thi = Thread::Isolate->new() ;

  $thi->eval(' 2**10 ') ;
  
  ...
  
  $thi->eval(q`
    sub TEST {
      my ( $var ) = @_ ;
      return $var ** 10 ;
    }
  `) ;
  
  print $thi->call('TEST' , 2) ;

  ...
  
  $thi->use('Data::Dumper') ;
  
  print $thi->call('Data::Dumper::Dumper' , [123 , 456 , 789]) ;
  
Here's an example of an unsynchronized call (detached):

  my $job = $thi->eval_detached(q`
    for(1..5) {
      print "in> $_\n" ;
      sleep(1);
    }
    return 2**3 ;
  `);
  
  $job->wait_to_start ;

  while( $job->is_running ) {
    print "." ;
  }
  
  print $job->returned ;

=head1 Creating a copy of an already existent Thread::Isolate:

  my $thi = Thread::Isolate->new() ;
  
  ## Creates a thread inside/from $thi and return it:
  $thi2 = $thi->new_internal ;

The code above can be used to make different copies of different states of the
Perl Interpreter.

=head1 Thread::Isolate METHODS

=head2 new (%OPTIONS)

Create a new Thread::Isolate object.

From version 0.02 each new Thread::Isolate object will be a copy of a Mother
Thread that holds a cleaner state of the Perl interpreter.

B<OPTIONS:>

=over 4

=item no_mother_thread

Do not use default Mother Thread as generator of the new thread.
This will create a thread usign the current Perl thread. (Normal behavior of Perl threads).

=item mother_thread

A thread to be used as the generator of the new Thread::Isolate object.

=back

=head2 new_internal

Create a new Thread::Isolate inside the current Thread::Isolate object.

This can be used to copy/clone threads from external calls.

=head2 new_from_id (ID)

Returns an already created Thread::Isolate object using the ID.

=head2 self

Returns the current Thread::Isolate object (similar to Perl threads->self call).

=head2 id

Return the ID of the thread. Same that is returned by $thread->id.

I<Thread ID is based in the Thread::Isolate creation of instances>.

=head2 tid

Return the TID of the thread. Same that is returned by $thread->tid.

I<TID is based in the OS and Perl thread implementation>.

=head2 clone

Return a cloned object. (This won't create a new Perl thread, is just a clone of the object reference).

=head2 copy

Create a copy of the thread. (Same as I<new_internal()>. Will create a new Perl thread).

=head2 use (MODULE , ARGS)

call I<'use MODULE qw(ARGS)'> inside the thread,

=head2 eval (CODE , ARGS)

Evaluate a CODE and paste ARGS inside the thread.

=head2 eval_detached (CODE , ARGS)

Evaluate detached (unsynchronous) a CODE and paste ARGS inside the thread.

Returns a I<Thread::Isolate::Job> object.

=head2 err

Return the error ($@) value of the last eval.

=head2 pack_eval (CODE , ARGS)

Evaluate the I<CODE> in the same package of the caller:

  use Class::HPLOO ;
  
  class Foo::Bar::Baz {
    use Thread::Isolate ;
    
    my $th_isolate = Thread::Isolate->new() ;
    
    $th_isolate->pack_eval(q`
      sub isolated_function {...}
    `);
    
    ## or:
    
    $th_isolate->eval(q`
      package Foo::Bar::Baz ;
      sub isolated_function {...}
    `);
  }

=head2 pack_eval_detached (CODE , ARGS)

Same as I<pack_eval()> but detached.

=head2 call (FUNCTION , ARGS)

call FUNCTION inside the thread.

=head2 call_detached (FUNCTION , ARGS)

call detached (unsynchronous) FUNCTION inside the thread.

Returns a I<Thread::Isolate::Job> object.

=head2 pack_call (FUNCTION , ARGS)

Call function in the same package of the caller. So, if you call function X from
package Foo, the result will be the same to call I<call('Foo::X')>. The idea is
to use that in classes that uses some I<"shared"> code in a I<Thread::Isolate>:

  use Class::HPLOO ;
  
  class Foo::Bar::Baz {
    use Thread::Isolate ;
    
    my $th_isolate = Thread::Isolate->new() ;
    
    $th_isolate->eval(q`
      package Foo::Bar::Baz ;
      
      open (LOG,"foo.log") ;
      
      sub write_lines {
        print LOG @_ ;
      }
    `) ;
    
    sub log {
      my ( $msg ) = @_ ;
      $th_isolate->pack_call('write_lines' , "LOG> $msg\n") ;
      ## or:
      $th_isolate->call('Foo::Bar::Baz::write_lines' , "LOG> $msg\n") ;
    }
  
  }

The code above uses a I<Thread::Isolate> to share a HANDLE (IO) to write
lines into a log file.

=head2 pack_call_detached (FUNCTION , ARGS)

Same as I<pack_call()> but detached.

=head2 shutdown

Shutdown the thread. See also I<kill()>.

=head2 kill

Kill the thread. The difference of shutdown() and kill is that kill will interrupt the current job executation.

=head2 exists

Return TRUE if the thread exists.

=head2 is_running_any_job

Return TRUE if the thread is running some job.

=head2 get_attr( KEY )

Get the value of an internal attribute of the thread.

=head2 set_attr( KEY )

Set the value of an internal attribute of the thread and return it.

=head2 get_global( KEY )

Get the value of a global attribute (shared by all the threads).

=head2 set_global( KEY )

Set the value of a global attribute (shared by all the threads) and return it.

=head1 Thread::Isolate::Job METHODS

When a deteched method is called a job is returned.
Here are the methods to use the job object:

=head2 id

Return the ID of the job.

=head2 tid

Return the TID of the thread. Same that is returned by $thread->tid.

I<TID is based in the OS and Perl thread implementation>.

=head2 th_id

Return the ID of the thread. Same that is returned by $thread->id.

I<Thread ID is based in the Thread::Isolate creation of instances>.

=head2 dump

Dump the job informations (similar to Data::Dumper).

=head2 type

Return the type of the job.

=head2 args

Return the arguments of the job.

=head2 detach

Detach the job (will not wait to finish the job).

=head2 is_detached

Return TRUE if the job is detached.

=head2 is_started

Return TRUE if the job was started.

=head2 is_running 

Return TRUE if the job is running.

=head2 is_finished  

Return TRUE if the job was finished.

=head2 time

Return the start I<time> of the job.

=head2 wait_to_start  

Wait until the job starts. (Ensure that the job was started).

=head2 wait  

Wait until the job is finished. (Ensure that the job was fully executed).

Returns the arguments returneds by the job.

=head2 wait_to_finish  

Same as I<wait()>.

Wait until the job is finished. (Ensure that the job was fully executed).

Returns the arguments returneds by the job.

=head2 returned

Returns the arguments returneds by the job. It will wait the job to finish too.

=head1 Pasting Data Between Threads

When the methods call() and eval() (and derivations) are called all the sent data
is freezed (by Storable::freeze()) and in the target thread they are thawed (by Storable::thaw()).
But Storable can't freeze GLOB and CODE, so Thread::Isolate make a work around to be possible
to send this kind of references.

For GLOB/IO Thread::Isolate paste it as fileno(), and for CODE a dum sub is paste for now.

=head1 Mapping a Thread Package to Another Thread

With L<Thread::Isolate::Map> is possible to Map the package symbols of one thread
to another, and use this package from many threads without need to load it many times.

I<See L<Thread::Isolate::Map> POD for more.>

=head1 SEE ALSO

L<Thread::Isolate::Map>, L<Thread::Isolate::Pool>.

L<Thread::Tie::Thread>, L<threads::shared>.

L<Safe::World>.

=head1 AUTHOR

Graciliano M. P. <gmpassos@cpan.org>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

This module was inspirated on L<Thread::Tie::Thread> by Elizabeth Mattijsen, <liz at dijkmat.nl>, the mistress of threads. ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

