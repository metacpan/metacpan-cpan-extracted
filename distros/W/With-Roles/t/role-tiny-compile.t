use strict;
use warnings;
use Test::Needs 'Role::Tiny';
use Test::More;

use With::Roles;

BEGIN {
  package My::Class;
  sub new { bless {}, $_[0] }
}

BEGIN {
  package My::Role;
  use Role::Tiny;
  sub method { 'method' }
}

my @warnings;

BEGIN {
  $SIG{__WARN__} = sub { push @warnings, @_ };
  my $c = My::Class->with::roles('My::Role');
  my $o = $c->new;
  is $o->method, 'method',
    'role application works at compile time';

}

is join('', @warnings), '',
  ' ... without warnings';

done_testing;
