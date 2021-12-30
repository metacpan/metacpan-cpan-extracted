package Thread::Csp::Promise;
$Thread::Csp::Promise::VERSION = '0.003';
use strict;
use warnings;

use 5.008001;

use Thread::Csp;

1;

#ABSTRACT: Promises for thread return values.

__END__

=pod

=encoding UTF-8

=head1 NAME

Thread::Csp::Promise - Promises for thread return values.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $promise = Thread::Csp->spawn('Module', 'Module::function', $input, $output);
 $promise->get;

=head1 DESCRIPTION

This represents the return value of a thread, as return by spawn. B<This class is highly experimental and may disappear in the future>.

=head1 METHODS

=head2 get()

This waits for the thread to finish, and will either return its value, or throw the exception that it died with. It may be called any number of times.

=head2 is_finished()

This returns true if the promise is finished.

=head2 set_notify($handle, $value)

This will cause C<$value> to be written to $handle when the promise finishes, unless it's already being waited upon.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
