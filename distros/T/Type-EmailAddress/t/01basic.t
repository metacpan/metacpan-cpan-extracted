use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;
use Type::EmailAddress qw( EmailAddress );

should_pass('whatever@cpan.org', EmailAddress);
should_fail('whatever.@cpan.org', EmailAddress);
should_fail('123', EmailAddress);

done_testing;
