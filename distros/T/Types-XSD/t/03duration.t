=pod

=encoding utf-8

=head1 PURPOSE

Test that negative durations work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Test::TypeTiny;

use Types::XSD -types;

should_pass('P4YT5S', Duration);
should_pass('-P4YT5S', Duration);
should_fail('+P4YT5S', Duration);

should_pass('P4Y', YearMonthDuration);
should_pass('P4Y6M', YearMonthDuration);
should_pass('-P4Y', YearMonthDuration);
should_pass('-P4Y6M', YearMonthDuration);
should_fail('+P4Y', YearMonthDuration);
should_fail('+P4Y6M', YearMonthDuration);
should_fail('P4YT5S', YearMonthDuration);
should_fail('-P4YT5S', YearMonthDuration);
should_fail('+P4YT5S', YearMonthDuration);

should_pass('P3DT6H0M0S', DayTimeDuration);
should_pass('-P3DT6H0M0S', DayTimeDuration);
should_fail('+P3DT6H0M0S', DayTimeDuration);
should_pass('PT6H0M0S', DayTimeDuration);
should_pass('-PT6H0M0S', DayTimeDuration);
should_fail('+PT6H0M0S', DayTimeDuration);
should_fail('P4Y', DayTimeDuration);
should_fail('P4Y6M', DayTimeDuration);
should_fail('-P4Y', DayTimeDuration);
should_fail('-P4Y6M', DayTimeDuration);
should_fail('+P4Y', DayTimeDuration);
should_fail('+P4Y6M', DayTimeDuration);
should_fail('P4YT5S', DayTimeDuration);
should_fail('-P4YT5S', DayTimeDuration);
should_fail('+P4YT5S', DayTimeDuration);

done_testing;

