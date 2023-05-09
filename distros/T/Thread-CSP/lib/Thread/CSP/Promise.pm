package Thread::CSP::Promise;
$Thread::CSP::Promise::VERSION = '0.010';
use strict;
use warnings;

use 5.008001;

use Thread::CSP;

1;

#ABSTRACT: Promises for thread return values.

__END__

=pod

=encoding UTF-8

=head1 NAME

Thread::CSP::Promise - Promises for thread return values.

=head1 VERSION

version 0.010

=head1 SYNOPSIS

 my $promise = Thread::CSP->spawn('Module', 'Module::function', $input, $output);
 $promise->get;

=head1 DESCRIPTION

This represents the return value of a thread, as return by spawn. B<This class is highly experimental and may disappear in the future>.

=head1 METHODS

=head2 get()

This waits for the thread to finish, and will either return its value, or throw the exception that it died with. It may be called any number of times.

=head2 is_finished()

This returns true if the promise is finished.

=head2 finished_fh()

This returns a handle that one byte will be written to when the promise finishes (or immediately if the promise is already finished).

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
