print "1..14"

class Foo:
    plain = 34
    def list(self):
        return [1,2,3]

    

foo = Foo()
foo.plain_list = [3, 2, 1]

import perl
perl.eval("""
# Test access to object from perl

use Python qw(getattr hasattr setattr getitem);

sub foo {
   my $foo = shift;
   print "$foo\n";

   print "not " unless hasattr($foo, "plain") && getattr($foo, "plain") == 34;
   print "ok 1\n";
   setattr($foo, plain => 42);
   print "not " unless getattr($foo,  "plain") eq "42";
   print "ok 2\n";
   Python::delattr($foo, "plain");
   print "not " unless Python::getattr($foo, "plain") eq "34";
   print "ok 3\n";

   print "not " unless $foo->plain eq 34;
   print "ok 4\n";

   $foo->plain2(72);
   print "not " unless getattr($foo, "plain2") eq 72;
   print "ok 5\n";

   print "not " unless $foo->plain2 eq 72;
   print "ok 6\n";

   print "not " unless $foo->plain2("bar") eq 72 && $foo->plain2 eq "bar";
   print "ok 7\n";

   my $list = $foo->plain_list;
   print "not " unless Python::len($list) == 3 && getitem($list, 0) == 3;
   print "ok 8\n";

   $list->append(0);
   print "not " unless Python::len($list) == 4 && $list->[-1] == 0;
   print "ok 9\n";

   my @list = $foo->plain_list;
   print "not " unless "@list" eq "3 2 1 0";
   print "ok 10\n";

   # try method call
   $list = $foo->list;
   @list = $foo->list;
   print "not " unless "$list" eq "[1, 2, 3]" && "@list" eq "1 2 3";
   print "ok 11\n";

   # try access to non-existing attribute
   eval {
       $foo->not_there;
   };
   print "not " unless $@ && Python::Err::AttributeError($@->type);
   print "ok 12\n";

   # try calling something which is not callable
   eval {
       $foo->plain_list("foo", "bar");
   };
   print "not " unless $@ && $@ =~ /^Can't call a non-callable object/;
   print "ok 13\n";

   # Strings are a sequences too, but they are not unwrapped.
   $foo->string("string");
   @list = $foo->string;
   print "not " if "@list" ne "string";
   print "ok 14\n";
}

""")

perl.call("foo", foo)



