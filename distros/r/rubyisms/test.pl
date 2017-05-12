use Test::More tests => 17;

package Foo; 
use rubyisms;
import Test::More;

sub initialize { isa_ok(self, "Foo"); 
                 is($_[1], "X", "Passing arguments to constructor");
}

sub check_1 { isa_ok(self, "Foo"); check_2("xxx"); self->check_3("yyy") }
sub check_2 { isa_ok(self, "Foo"); is($_[0], "xxx", "Passing args to methods") }
sub check_3 { isa_ok(self, "Foo"); 
              is($_[0], self, "\$_[0] is the object"); 
              is($_[1], "yyy", "Passing args to methods called as methods");
              _deeper();
        }
sub _deeper { __deeper_yet(); }
sub __deeper_yet { isa_ok(self, "Foo") }

package main;
ok(Foo->isa("Class"), "Foo inherits from Class");
my $x = new Foo ("X");
isa_ok($x, "Foo");
$x->check_1;

# Now test yield
import rubyisms;

sub each_arr (&@) { yield() for @_ }

my $first = 0;
my @result;
each_arr { push @result, $_,"X" } 10,20,30;

is_deeply(\@result, [qw(10 X 20 X 30 X)], "yield yielded OK");

# and test super
package Daddy;
import Test::More;
sub new { bless {}, shift }
sub foo { my $self = shift; 
          isa_ok($self, "Kid"); 
          is($_[0], 123, "Arguments passed OK")  
      }

package Kid;
import Test::More;
@ISA=qw(Daddy);

import rubyisms;
sub foo { my $self = shift;
    if ($_[0] > 100) { super }
    else { is($_[0], 50, "Arguments retained OK") }
}

$a = new Kid;
$a->foo(123);
$a->foo(50);

is($a->super("new"), \&Daddy::new, "Kid's new is inherited from Daddy");
is($a->super("foo"), \&Daddy::foo, 
    "... as is its foo, even though that's overriden");
is(rubyisms->super("import"), \&Exporter::import, 
    "my import comes from Exporter");
is(Test::More->super("import"), \&Exporter::import, 
    "... and so does Test::More's");


