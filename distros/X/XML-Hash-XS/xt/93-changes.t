# test for recommendations from "Perl Best Practices"

use strict;
use warnings;
use Test::More;
use XML::Hash::XS;

eval {
    require Test::CPAN::Changes;
    Test::CPAN::Changes->import();
    1;
} or plan skip_all => 'Test::CPAN::Changes required for this test';

changes_file_ok(undef, { version => $XML::Hash::XS::VERSION });

done_testing();
