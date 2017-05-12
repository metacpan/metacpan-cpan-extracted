use strict;
use warnings;

package Thread::IID;
BEGIN {
  $Thread::IID::VERSION = '0.04';
}

use 5.008001;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    %EXPORT_TAGS = ( 'all' => [ qw(interpreter_id) ] );
    @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
    @EXPORT = ();
}

require XSLoader;
XSLoader::load('Thread::IID', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Thread::IID - unique Interpreter IDs

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Thread::IID ':all';

  print "Hi, I am interpreter #" . interpreter_id;

=head1 DESCRIPTION

This provides an identifier to distinguish Perl interpreter instances.

In environments like L<mod_perl2|mod_perl2>, where interpreters can be
cloned and arbitrarily assigned to OS threads, the thread ID gives no
indication of which interpreter instance is actually running and hence
which corresponding set of values/data-structures is actually being
referenced.  For such situations an interpreter ID is more likely to
be what you actually want.

=head2 EXPORT

None by default.  The following function is available:

=head3 interpreter_id

Returns an (integer) ID for the Perl interpreter from which this call
is being made.  Returns 0 if the Perl was not compiled to allow
multiple interpreters.

Where multiple interpreters have been created to run in threads of the
current process and are concurrently in existence, the IDs returned
will be distinct for each interpreter, regardless of which threads are
running which interpreters.  However, once an interpreter exits and its
memory is reclaimed, nothing prevents its ID from being reused.
It is also possible for the same ID to be returned from interpreters 
in different processes (and I<likely> in the event that the processes 
were created by C<fork()>).

In the current implementation, the Interpreter ID is derived from the 
memory address of the PerlInterpreter structure.

=head1 EXAMPLE

In the following

 my @value = (0, interpreter_id, $$, time);
 sleep(1);

 sub counter {
     ++$value[0];
     return @value;
 }

C<counter()> is guaranteed to return a list value distinct from all
other invocations in all processes/threads that are running this code
on a given host.

=head1 AUTHOR

Roger Crew E<lt>crew@cs.stanford.eduE<gt>.

=head1 ACKNOWLEDGEMENTS

The original XS code for this was from a posting by ikegami at PerlMonks.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Roger Crew.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut