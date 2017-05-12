
use Test;
BEGIN { plan tests => 12 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use lib 't/find_template_file';
require Waft::Test::FindTemplateFile;

my $obj = Waft::Test::FindTemplateFile->new;

my ($template_file, $template_class);

($template_file, $template_class)
    = $obj->find_template_file('own_template2.html');
ok( $template_file eq 't/find_template_file/Waft/Test/FindTemplateFile/own_template2.html' );
ok( $template_class eq 'Waft::Test::FindTemplateFile' );

($template_file, $template_class)
    = $obj->find_template_file('base_template2.html');
ok( $template_file eq 't/find_template_file/Waft/Test/base_template2.html' );
ok( $template_class eq 'Waft::Test' );

@Waft::Test::FindTemplateFile::ISA = ('Waft');

($template_file, $template_class)
    = $obj->find_template_file('own_template2.html');
ok( $template_file eq 't/find_template_file/Waft/Test/FindTemplateFile/own_template2.html' );
ok( $template_class eq 'Waft::Test::FindTemplateFile' );

($template_file, $template_class)
    = $obj->find_template_file('base_template2.html');
ok( $template_file eq 't/find_template_file/Waft/Test/base_template2.html' );
ok( $template_class eq 'Waft::Test' );

{
    local $Waft::Cache = $Waft::Cache && 0;

    ($template_file, $template_class)
        = $obj->find_template_file('own_template2.html');
    ok( $template_file eq 't/find_template_file/Waft/Test/FindTemplateFile/own_template2.html' );
    ok( $template_class eq 'Waft::Test::FindTemplateFile' );

    ($template_file, $template_class)
        = $obj->find_template_file('base_template2.html');
    ok( not defined $template_file );
    ok( not defined $template_class );
}
