use Test2::V0;
use Test2::Require::Module 'Exporter::Tiny', '1.006002';
use Test2::Require::Module 'Type::Tiny', '2.000000';

use FindBin qw($Bin);;
use lib "$Bin";

use TestExporterTiny qw(Foo);

# Exporter::Tiny accepts the `-as` option
use TestExporterTiny Foo => { -as => "Foo2" };

subtest 'Test `kura` with Exporter::Tiny' => sub {

    ok +TestExporterTiny->isa('Exporter::Tiny');

    ok !Foo->check('');
    ok Foo->check('foo');

    ok !Foo2->check('');
    ok Foo2->check('foo');
};

done_testing;
