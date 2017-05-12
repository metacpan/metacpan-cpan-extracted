=head1 PURPOSE

Check behave nicely with using L<Try::Tiny::ByClass>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires 'Try::Tiny::ByClass';

use Try::Tiny::ByClass;
use Throwable::Factory
	A => ['-caller'],
	B => ['-environment'],
	C => ['-notimplemented'],
;

my $fail = 1;

try {
	A->throw;
}
catch_case [
	"Throwable::Taxonomy::Caller" => sub { $fail--; pass() },
],
finally {
	fail() if $fail;
};

$fail = 1;
try {
	B->throw;
}
catch_case [
	"Throwable::Taxonomy::Environment" => sub { $fail--; pass() },
],
finally {
	fail() if $fail;
};

$fail = 1;
try {
	C->throw;
}
catch_case [
	"Throwable::Taxonomy::NotImplemented" => sub { $fail--; pass() },
],
finally {
	fail() if $fail;
};

done_testing;
