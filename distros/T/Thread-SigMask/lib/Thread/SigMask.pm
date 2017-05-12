package Thread::SigMask;
$Thread::SigMask::VERSION = '0.004';
use strict;
use warnings FATAL => 'all';

use XSLoader;
use Exporter 5.57 'import';
our @EXPORT = qw/sigmask/;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

#ABSTRACT: Thread specific signal masks

__END__

=pod

=encoding UTF-8

=head1 NAME

Thread::SigMask - Thread specific signal masks

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Thread::SigMask qw/sigset/;
 use POSIX qw/SIG_BLOCK SIG_UNBLOCK/;
	
 sigmask(SIG_BLOCK, $sigset);
 ...
 sigmask(SIG_UNBLOCK, $sigset);

=head1 DESCRIPTION

This module provides per-thread signal masks. On non-threaded perls it will be effectively the same as POSIX::sigprocmask. The interface works exactly the same as sigprocmask.

=head1 FUNCTIONS

=head2 sigmask($how, $newset, $oldset = undef)

Change and/or examine calling process's signal mask. This uses C<POSIX::SigSet> objects for the newset and oldset arguments. The behavior of the call is dependent on the value of how.

=over 4

=item * SIG_BLOCK

The set of blocked signals is the union of the current set and the set argument.

=item * SIG_UNBLOCK

The signals in set are removed from the current set of blocked signals. It is permissible to attempt to unblock a signal which is not blocked.

=item * SIG_SETMASK

The set of blocked signals is set to the argument set.

=back

If oldset is defined, the previous value of the signal mask is stored in oldset. If newset is NULL, then the signal mask is unchanged (i.e., how is ignored), but the current value of the signal mask is nevertheless returned in oldset (if it is not NULL).

=head1 SEE ALSO

L<Signal::Mask>

=head1 ACKNOWLEDGEMENTS

Parts of this documentation is shamelessly stolen from L<POSIX> and Linux' L<sigprocmask(2)>.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
