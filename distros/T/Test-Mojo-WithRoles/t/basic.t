use Mojo::Base -strict;

use lib 't/lib';

use Test::More;
use Test::Mojo::WithRoles;

my $t = Test::Mojo::WithRoles->new;
isa_ok $t, 'Test::Mojo';
ok ! $t->does('Test::Mojo::Role::Awesome'), 'not awesome';

{
  use Test::Mojo::WithRoles 'Awesome';
  my $awesome1 = Test::Mojo::WithRoles->new;

  isa_ok $awesome1, 'Test::Mojo';
  ok $awesome1->does('Test::Mojo::Role::Awesome'), 'awesome';
  can_ok $awesome1, 'is_awesome';

  {
    use Test::Mojo::WithRoles 'Cool';
    my $cool = Test::Mojo::WithRoles->new;

    isa_ok $cool, 'Test::Mojo';
    ok $cool->does('Test::Mojo::Role::Cool'), 'cool';
    can_ok $cool, 'is_cool';
    
    ok ! $cool->does('Test::Mojo::Role::Awesome'), 'temporarily not awesome';
    ok ! $cool->can('is_awesome'), 'cant is_awesome';
  }

  my $awesome2 = Test::Mojo::WithRoles->new;

  isa_ok $awesome2, 'Test::Mojo';
  ok $awesome2->does('Test::Mojo::Role::Awesome'), 'once again awesome';
  can_ok $awesome2, 'is_awesome';
  
  ok ! $awesome2->does('Test::Mojo::Role::Cool'), 'no longer cool';
  ok ! $awesome2->can('is_cool'), 'cant is_cool';
}

my $tz = Test::Mojo::WithRoles->new;
isa_ok $tz, 'Test::Mojo';
ok ! $tz->does('Test::Mojo::Role::Awesome'), 'not awesome (again)';

done_testing;
