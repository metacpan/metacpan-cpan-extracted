package Thread::CriticalSection;

use warnings;
use strict;
use Thread::Semaphore;

our $VERSION = '0.02';


sub new {
  my $class = shift;
  
  return bless {
    sem => Thread::Semaphore->new,
  }, $class;
}


sub execute {
  my ($self, $sub) = @_;
  my $sem = $self->{sem};
  
  my $wantarray = wantarray;
  my @result;
  
  $sem->down;
  
  eval {
    if ($wantarray) { @result    = $sub->() }
    else            { $result[0] = $sub->() }
  };

  my $e = $@;
  $sem->up;
  
  die $e if $e;
  
  return @result if $wantarray;
  return $result[0];
}


42; # End of Thread::CriticalSection


=head1 NAME

Thread::CriticalSection - Run a coderef inside a critical section

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use threads;
    use Thread::CriticalSection;
    
    my $cs = Thread::CriticalSection->new;
    
    $cs->execute(sub {
      # your code is protected by $cs
    });
    
    # you can also return stuff
    my $result = $cs->execute(sub {
      # do work in a cosy critical section
      return $result;
    });
    
    # and you can even use wantarray
    my @victims = $cs->execute(sub {
      # do work in a cosy critical section
      return wantarray? @result : \@result;
    });


=head1 STATUS

As of 2008/06/18, this module is considered beta quality. The interface
should not suffer any changes but its a young module with very little use.

You'll still see "Scalars leaked" in the test suite, and I would like to
get rid of them before declaring the code as stable.

The abnormal thread terminations I get when running the test suite are
in the unsafe tests, so I think I'm getting into perl threads issues,
not bugs in this module. Prof of the opposite (in the form of failing
tests) are most welcome.


=head1 DESCRIPTION

The Thread::CriticalSection module allows you to run a coderef inside a
critical section.

All the details of entering and leaving the critical section are taken care
of by the C<execute()> method.

You can have several critical sections simultaneously inside your program.
The usual care and feeding regarding deadlocks should be taken when calling
C<execute()> recursively.


=head1 METHODS

=over 4

=item * $cs = new()

Creates and returns a new critical section. Requires no parameters.


=item * [$return|@return] = $cs->execute(sub {}|$coderef)

Executes the given $coderef inside the critical section. The $coderef
can use wantarray to inspect the context of the call and react
accordingly.


=back


=head1 AUTHOR

Pedro Melo, C<< <melo at cpan.org> >>


=head1 DEVELOPMENT

You can find the source for this module at
L<http://github.com/melo/thread--criticalsection/>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-thread-criticalsection at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Thread-CriticalSection>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Thread::CriticalSection


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Thread-CriticalSection>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Thread-CriticalSection>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Thread-CriticalSection>

=item * Search CPAN

L<http://search.cpan.org/dist/Thread-CriticalSection>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008 Pedro Melo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
