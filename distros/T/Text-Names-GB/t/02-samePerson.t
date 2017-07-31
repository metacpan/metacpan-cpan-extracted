use Text::Names::GB qw/samePerson/;
use Test::More;

ok(samePerson('Dave Bourget','David Bourget'),'Dave Bourget -> David Bourget');
ok(samePerson('Dave J. Bourget','David John Bourget'),'Dave J. Bourget -> David John Bourget');
ok(samePerson('D J Bourget','David John Bourget'),'D J Bourget -> David John Bourget');
ok(samePerson('D Bourget','David John Bourget'),'D Bourget -> David John Bourget');
ok(samePerson('Bourget, David', 'Dave Bourget Jr'), 'Bourget, David -> Dave Bourget Jr');
ok(samePerson('Dave Bourget','Bourget, David F.'),'Dave Bourget -> Bourget, David F.');
ok(!samePerson('J Bourget','David John Bourget'),'J Bourget !> David John Bourget');
ok(!samePerson('D F Bourget','David John Bourget'),'D F Bourget !> David John Bourget');
ok(!samePerson('John Doe','David John Bourget'),'John Doe !> David John Bourget');
is( samePerson("Bourget, David J.","Bourget, David"), "Bourget, David J.", "Bourget, David J as return value");
is( samePerson("Bourget, David J.","Bourget, David X."), undef, "Not compatible = undef");
ok(samePerson('Fredrik Björklund','F Bjorklund'),'Björklund, Fredrik');
ok( samePerson("Bourget, David", "David, Bourget", "loose" =>1 ) );

done_testing;
