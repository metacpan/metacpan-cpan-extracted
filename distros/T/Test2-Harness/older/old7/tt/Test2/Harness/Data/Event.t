use Test2::Bundle::Extended -target => 'Test2::Harness::Data::Event';

use ok $CLASS;

isa_ok($CLASS, 'Test2::Event');

my %fill = (
    test_file => 'foo.t',
    job_id    => 99,
    handle    => 'harness',
);

my $one = $CLASS->new(facet_data => {foo => {bar => 'baz'}}, %fill);
is($one->facet_data, {foo => {bar => 'baz'}, harness => T(), about => T()}, "got facet data");

like(
    dies { $CLASS->new },
    qr/'facet_data' is a required attribute/,
    "Need facet data"
);

ok(!$one->causes_fail, "No failure here");
$one = $CLASS->new(facet_data => {assert => {pass => 0}}, %fill);
ok($one->causes_fail, "Failure here");
$one = $CLASS->new(facet_data => {harness => {exit => 1}}, %fill);
ok($one->causes_fail, "Failure here as well");

done_testing;
