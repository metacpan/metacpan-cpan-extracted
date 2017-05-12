package Test::Mock::Class::MockTestRole;

use Moose::Role;

with 'Test::Mock::Class::MockBaseTestRole';
with 'Test::Mock::Class::MockTallyTestRole';

1;
