=pod

=encoding utf-8

=head1 PURPOSE

Test a few datetime-related types.

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

should_pass('2009-02-12T03:54:00Z', DateTime);
should_pass('2009-02-12T03:54:00Z', DateTimeStamp);
should_pass('2009-02-12T03:54:00Z', DateTime[explicitTimezone => "optional"]);
should_pass('2009-02-12T03:54:00Z', DateTime[explicitTimezone => "required"]);
should_fail('2009-02-12T03:54:00Z', DateTime[explicitTimezone => "prohibited"]);

should_pass('2009-02-12T03:54:00+00:00', DateTime);
should_pass('2009-02-12T03:54:00+00:00', DateTimeStamp);
should_pass('2009-02-12T03:54:00+00:00', DateTime[explicitTimezone => "optional"]);
should_pass('2009-02-12T03:54:00+00:00', DateTime[explicitTimezone => "required"]);
should_fail('2009-02-12T03:54:00+00:00', DateTime[explicitTimezone => "prohibited"]);

should_pass('2009-02-12T03:54:00', DateTime);
should_fail('2009-02-12T03:54:00', DateTimeStamp);
should_pass('2009-02-12T03:54:00', DateTime[explicitTimezone => "optional"]);
should_fail('2009-02-12T03:54:00', DateTime[explicitTimezone => "required"]);
should_pass('2009-02-12T03:54:00', DateTime[explicitTimezone => "prohibited"]);

should_pass('2009-02-12T03:54:00', DateTime[assertions => [sub { m/^2009/ }]]);
should_pass('2009-02-12T03:54:00', DateTime[assertions => 'm/^2009/']);
should_fail('2010-02-12T03:54:00', DateTime[assertions => [sub { m/^2009/ }]]);
should_fail('2010-02-12T03:54:00', DateTime[assertions => 'm/^2009/']);

should_pass('2009-02-12T03:54:00', DateTime[assertions => [sub { m/^2009/ }, 'm/-02-/']]);

done_testing;

