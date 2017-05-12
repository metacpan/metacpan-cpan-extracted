
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

            $library->compile( output_engine => 'String', bundle => $bundle );

            my $js  = $bundle->as_html( type => 'js' );
            my $css = $bundle->as_html( type => 'css' );

            $self->log->info($js);
            $self->log->info($css);
        }
        "exports bundle using String output engine";

    }

    1;
}
