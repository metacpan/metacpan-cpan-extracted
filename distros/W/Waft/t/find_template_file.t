
use Test;
BEGIN { plan tests => 32 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use lib 't/find_template_file';
require Waft::Test::FindTemplateFile;

my $obj = Waft::Test::FindTemplateFile->new;

my ($template_file, $template_class);

($template_file, $template_class)
    = $obj->find_template_file('own_template1.html');
ok( $template_file eq 't/find_template_file/Waft/Test/FindTemplateFile.template/own_template1.html' );
ok( $template_class eq 'Waft::Test::FindTemplateFile' );

($template_file, $template_class)
    = $obj->find_template_file('own_template2.html');
ok( $template_file eq 't/find_template_file/Waft/Test/FindTemplateFile/own_template2.html' );
ok( $template_class eq 'Waft::Test::FindTemplateFile' );

($template_file, $template_class)
    = $obj->find_template_file('own_module1.pm');
ok( $template_file eq 't/find_template_file/Waft/Test/FindTemplateFile.template/own_module1.pm' );
ok( $template_class eq 'Waft::Test::FindTemplateFile' );

($template_file, $template_class)
    = $obj->find_template_file('own_module2.pm');
ok( not defined $template_file );
ok( not defined $template_class );

($template_file, $template_class)
    = $obj->find_template_file('base_template1.html');
ok( $template_file eq 't/find_template_file/Waft/Test.template/base_template1.html' );
ok( $template_class eq 'Waft::Test' );

($template_file, $template_class)
    = $obj->find_template_file('base_template2.html');
ok( $template_file eq 't/find_template_file/Waft/Test/base_template2.html' );
ok( $template_class eq 'Waft::Test' );

($template_file, $template_class)
    = $obj->find_template_file('base_module1.pm');
ok( $template_file eq 't/find_template_file/Waft/Test.template/base_module1.pm' );
ok( $template_class eq 'Waft::Test' );

($template_file, $template_class)
    = $obj->find_template_file('base_module2.pm');
ok( not defined $template_file );
ok( not defined $template_class );

Waft::Test::FindTemplateFile->set_allow_template_file_exts( () );

{
    local $Waft::Cache = 0;

    ($template_file, $template_class)
        = $obj->find_template_file('own_template1.html');
    ok( $template_file eq 't/find_template_file/Waft/Test/FindTemplateFile.template/own_template1.html' );
    ok( $template_class eq 'Waft::Test::FindTemplateFile' );

    ($template_file, $template_class)
        = $obj->find_template_file('own_template2.html');
    ok( $template_file eq 't/find_template_file/Waft/Test/own_template2.html' );
    ok( $template_class eq 'Waft::Test' );
}

($template_file, $template_class)
    = $obj->find_template_file('base_template2.html');
ok( $template_file eq 't/find_template_file/Waft/Test/base_template2.html' );
ok( $template_class eq 'Waft::Test' );

Waft::Test->set_allow_template_file_exts( () );

{
    local $Waft::Cache = 0;

    ($template_file, $template_class)
        = $obj->find_template_file('base_template1.html');
    ok( $template_file eq 't/find_template_file/Waft/Test.template/base_template1.html' );
    ok( $template_class eq 'Waft::Test' );

    ($template_file, $template_class)
        = $obj->find_template_file('base_template2.html');
    ok( not defined $template_file );
    ok( not defined $template_class );
}

Waft::Test::FindTemplateFile->set_allow_template_file_exts( qw( .pm ) );

{
    local $Waft::Cache = 0;

    ($template_file, $template_class)
        = $obj->find_template_file('own_module2.pm');
    ok( $template_file eq 't/find_template_file/Waft/Test/FindTemplateFile/own_module2.pm' );
    ok( $template_class eq 'Waft::Test::FindTemplateFile' );

    ($template_file, $template_class)
        = $obj->find_template_file('base_template2.html');
    ok( not defined $template_file );
    ok( not defined $template_class );
}

Waft::Test->set_allow_template_file_exts( qw( .pm ) );

{
    local $Waft::Cache = 0;

    ($template_file, $template_class)
        = $obj->find_template_file('base_module2.pm');
    ok( $template_file eq 't/find_template_file/Waft/Test/base_module2.pm' );
    ok( $template_class eq 'Waft::Test' );
}
