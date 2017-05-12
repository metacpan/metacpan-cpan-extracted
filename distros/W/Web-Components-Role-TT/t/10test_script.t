use t::boilerplate;

use Test::More;
use English qw( -no_match_vars );
use File::Spec::Functions qw( catdir );

{  package TestConfig;

   use File::DataClass::IO;
   use Moo;

   has 'layout'  => is => 'ro', default => 'standard';
   has 'root'    => is => 'ro', builder => sub { io[ 't', 'root' ] };
   has 'skin'    => is => 'ro', default => 'default';
   has 'tempdir' => is => 'ro', builder => sub { io[ 't' ] };
}

{  package Test;

   use Moo;

   has 'config' => is => 'ro', builder => sub { TestConfig->new };

   with 'Web::Components::Role::TT';
}

my $test = Test->new;

can_ok $test, 'render_template';

is $test->templates, catdir( 't', 'root', 'templates' ), 'Template directory';

my $rendered = $test->render_template( {} ); chomp $rendered;

is $rendered, '<!-- Layout standard -->', 'Renders template';

eval { $test->render_template( { page => { layout => 'not_found' } } ) };

is $EVAL_ERROR->class, 'PathNotFound', 'Throws on missing template';

my $layout = '[% test %]';

$rendered = $test->render_template( { page => { layout => \$layout },
                                      test => 'dummy', } );

is $rendered, 'dummy', 'Renders from scalar ref';

$layout = '[% ] %]';

eval { $test->render_template( { page => { layout => \$layout },
                                 test => 'dummy', } ) };

like $EVAL_ERROR, qr{ \Qparse error\E }mx, 'Parse error';

{  package TestConfig2;

   use File::DataClass::IO;
   use Moo;

   has 'layout'  => is => 'ro', default => 'standard';
   has 'skin'    => is => 'ro', default => 'default';
   has 'tempdir' => is => 'ro', builder => sub { io[ 't' ] };
   has 'vardir'  => is => 'ro', builder => sub { io[ 't' ] };
}

{  package Test2;

   use Moo;

   has 'config' => is => 'ro', builder => sub { TestConfig2->new };

   with 'Web::Components::Role::TT';
}

$test = Test2->new;

can_ok $test, 'render_template';

is $test->templates, catdir( 't', 'templates' ), 'Template directory 2';

$rendered = $test->render_template( {} ); chomp $rendered;

is $rendered, '<!-- Layout standard -->', 'Renders template';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
