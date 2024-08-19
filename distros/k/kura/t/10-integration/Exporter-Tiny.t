use Test2::V0;
use Test2::Require::Module 'Exporter::Tiny', '1.006002';
use Test2::Require::Module 'Type::Tiny', '2.000000';

use FindBin qw($Bin);;
use lib "$Bin/Exporter-Tiny";

subtest 'Test `kura` with Exporter::Tiny' => sub {
    use mykura Foo => sub { $_ eq 'foo' };

    isa_ok __PACKAGE__, 'Exporter::Tiny';

    ok !Foo->check('');
    ok Foo->check('foo');

    # Exporter::Tiny accepts the `-as` option
    use MyFoo Foo => { -as => "Foo2" };

    ok !Foo2->check('');
    ok Foo2->check('foo');
};

done_testing;
