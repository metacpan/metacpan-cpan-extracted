use Test2::Roo;

plan skip_all => "We just want to skip";

test 'just fail' => sub { ok(0) };

run_me;
done_testing;
