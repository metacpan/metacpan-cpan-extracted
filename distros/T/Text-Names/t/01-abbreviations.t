use Text::Names qw/abbreviationOf/;
use Test::More;

ok(abbreviationOf('Dave','David'),'Dave -> David');
ok(abbreviationOf('Mike','Michael'),'Mike -> Michael');
ok(abbreviationOf('Bella','Belinda'),'Bella -> Belinda');
ok(!abbreviationOf('John','Bob'),'John !> Bob');


done_testing;
