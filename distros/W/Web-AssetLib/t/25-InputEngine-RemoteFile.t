
my $test = unit_test->new();
$test->main();

BEGIN {

    package unit_test;

    use Moose;
    use Test::Most qw(no_plan -Test::Deep);
    use Try::Tiny;
    use FindBin qw($Bin);
    use lib "$Bin/lib";
    use Carp;

    use Web::AssetLib::Bundle;
    use Test::Web::AssetLib::TestLibrary;

    with qw/Test::Web::AssetLib::TestRole/;

    sub do_tests {
        my ($self) = @_;

        my $library = Test::Web::AssetLib::TestLibrary->new();

        lives_ok {
            my $bundle = Web::AssetLib::Bundle->new();

            $bundle->addAsset( $library->testjs_remote );
            $bundle->addAsset( $library->testcss_remote );

            $library->compile( bundle => $bundle );
        }
        "compiles bundle using RemoteFile input engine";

        dies_ok {
            my $bundle = Web::AssetLib::Bundle->new();

            $bundle->addAsset( $library->missingjs_remote );
            $bundle->addAsset( $library->testcss_remote );

            $library->compile( bundle => $bundle );
        }
        "dies on missing resource";

    }

    1;
}
