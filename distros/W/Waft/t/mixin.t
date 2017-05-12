
use Test;
BEGIN { plan tests => 3 + 2 + 2 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

{
    package Waft::Test::Mixin3;

    sub mixin1 { 3 }

    sub mixin2 { 3 }

    sub mixin3 { 3 }
}

use lib 't/mixin';
use Waft with => 'Waft::Test::Mixin1', '::Test::Mixin2', 'Waft::Test::Mixin3';

ok( __PACKAGE__->mixin1 == 1 );
ok( __PACKAGE__->mixin2 == 2 );
ok( __PACKAGE__->mixin3 == 3 );

my $self = __PACKAGE__->new;

my ($template_file, $template_class);

($template_file, $template_class)
    = $self->find_template_file('template.html');
ok( $template_file eq 't/mixin/Waft/Test/Mixin1/template.html' );
ok( $template_class eq 'Waft::Test::Mixin1' );

($template_file, $template_class) = $self->find_template_file('module.pm');
ok( $template_file eq 't/mixin/Waft/Test/Mixin2/module.pm' );
ok( $template_class eq 'Waft::Test::Mixin2' );
