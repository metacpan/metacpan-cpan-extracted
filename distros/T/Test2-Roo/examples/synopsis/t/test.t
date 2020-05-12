use Test2::Roo; # loads Moo and Test2::V0
use lib 't/lib';

# provide the fixture
has class => (
    is      => 'ro',
    default => sub { "Digest::MD5" },
);

# specify behaviors to test 
with 'ObjectCreation';

# give our subtests a label
sub _build_description { "Testing " . shift->class }

# run the tests
run_me;
run_me( { class => "Digest::SHA1" } );

done_testing;
