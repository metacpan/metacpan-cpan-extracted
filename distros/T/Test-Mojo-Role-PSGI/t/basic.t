use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->with_roles('+PSGI')->new('t/script/app.psgi');

isa_ok $t, 'Test::Mojo', 'correct inheritance';
ok $t->does('Test::Mojo::Role::PSGI'), 'applied role';

$t->get_ok('/')
  ->status_is(200)
  ->text_is('title' => 'Hello world!')
  ->text_like('p#phrase' => qr/Zoidberg/);

done_testing;

