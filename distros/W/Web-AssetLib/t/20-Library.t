
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

        my $bundle;
        lives_ok {
            $bundle = Web::AssetLib::Bundle->new();

            $bundle->addAsset( $library->testjs_local );
            $bundle->addAsset( $library->testcss_local );
        }
        "creates bundle and adds assets";

        lives_ok {
            $library->compile(
                bundle          => $bundle,
                minifier_engine => 'Standard'
            );
        }
        "compiles bundle";

        lives_ok {
            $bundle = Web::AssetLib::Bundle->new();

            $bundle->addAsset( $library->testjs_local );
            $bundle->addAsset( $library->testcss_local );
            $bundle->addAsset( $library->testcss_local );

            $library->compile(
                bundle          => $bundle,
                minifier_engine => 'Standard'
            );

            die unless $bundle->countAssets == 2;
        }
        "prevents adding same asset twice";
    }

    1;
}
