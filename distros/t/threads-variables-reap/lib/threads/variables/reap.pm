package threads::variables::reap;

use strict;
use warnings;

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(reap);
our @EXPORT_OK = qw(reap reapref);

our $VERSION = '0.06';

use Scalar::Util qw(weaken reftype);
my @reapem;

sub reap(\[$@%]) { my $ref = $_[0]; weaken($ref); push( @reapem, $ref ); }
sub reapref { my $ref = $_[0]; weaken($ref); push( @reapem, $ref ); }

sub CLONE
{
    foreach my $ref (@reapem)
    {
        if ( reftype($ref) eq "SCALAR" || reftype($ref) eq "REF" ) { $$ref = undef; }
        if ( reftype($ref) eq "ARRAY" )  { @$ref = (); }
        if ( reftype($ref) eq "HASH" )   { %$ref = (); }
    }
}

=pod

=head1 NAME

threads::variables::reap - reap variables in new threads

=head1 SYNOPSIS

    use threads::variables::reap;

    my $bigObj = SomeBigObj->new();	# create some real big object
    reap($bigObj);			# force $bigObj being reaped in each other thread
    					# created after this line is passed

=head1 DESCRIPTION

This module provides a helper to ensure threads can/must have own instances
of some variables. It ensures that all variables marked to get C<reap>ed are
C<undef> in a new thread (instead being a clone like default behaviour).

=head1 MOTIVATION

I became inspired to create C<threads::variables::reap> when I was trying
to switch a logging framework in a multi-threaded application, which logged
to a database table, to L<Log::Log4perl>. I read often, L<DBI> wasn't made
for threaded environments and here I was going to learn what it means in
real life. So I found myseld in the situation, Joshua described for me:
I<I have an object which can't persist into other threads or children. Reap
it when that happen.>

Another reason was to read about optimization effort in large applications,
when they're going to be split in several threads. In those cases, all
unnecessary objects for worker threads (or attributes of some objects which
doesn't need to be available in other threads) could be marked with C<:reap>
and so new threads start with a small memory overhead.

=head1 EXPORT

This module exports only one function: C<reap>.

=head1 SUBROUTINES/METHODS

=head2 reap(\[$@%])

Marks a given variable to get reaped in each other thread except the current.
This could either help saving memory or increase safety when using modules
which are known being not thread-safe.

Be careful about the calling convention of this function: it's taking the
reference of the variable you'll give to it. So using C<reap(\@myarray)>
will abort with compilation errors and is not intended to work. Use I<reapref>
in those cases.

=head2 reapref

Marks the variable to get reaped in each new thread where the reference
points to. This function isn't exported by default and shouldn't be used
unless you're familiar with references and how cloning for new threads
work.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-threads-variables-reap at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=threads-variables-reap>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 LIMITATIONS

I wonder if variables could be marked as shared (using L<threads::shared>)
and for reaping seamless. This makes it impossible to give parameter objects
for threads attributes that will be reaped for new threads, especially when
used in common with L<Thread::Queue>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc threads::variables::reap

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=threads-variables-reap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/threads-variables-reap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/threads-variables-reap>

=item * Search CPAN

L<http://search.cpan.org/dist/threads-variables-reap/>

=back

=head1 ACKNOWLEDGEMENTS

Larry Wall for giving us Perl - all our modules provide on his work.
David Golden for his great contribution about Perl and threads on PerlMonks
(see http://www.perlmonks.org/?node_id=483162).
Steffen Mueller for Attribute::Handlers and the helpful explanantion there.
Andrew Main, Adam Kennedy and Joshua ben Jore helping me pointing my problem
I'm going to solve with this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of threads::variables::reap
