use Test2::V0;

my $result = do './t/fixtures/unhandled-attribute.t';

ok !defined $result, "unhandled-attribute.t should not compile";
like $@, qr/Invalid CODE attribute: Foo/,
    'unhandled-attribute.t should give expected compilation error';

done_testing;
