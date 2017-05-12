import sys

try:
    import thread
except:
    print "1..0"
    sys.exit(0)

import perl
if not perl.MULTI_PERL:
    print "1..0"
    sys.exit(0)

# This tests behaviour of perl objects passed from one
# thread (and perl interpreter) to the next one and that
# it is still destructed properly.

print "1..5"

perl_obj = perl.eval("""

sub Foo::hello {
   return "Hello";
}

sub Foo::DESTROY
{
   my $self = shift;
   print "$self DESTROY\n";
   print "ok 2\n";
}

bless {}, "Foo";

""")

print perl_obj.hello();
print perl_obj

def t1():
    global perl_obj
    print perl_obj
    try:
        print perl_obj.hello();
        print "not "
    except ValueError, v:
        print "ok 1"
        print v

    perl.eval("""sub Foo::DESTROY { $|=1; print "ok 4\n"; }""");

    perl_obj = perl.get_ref("@")
    perl_obj.__class__ = "Foo";
    print perl_obj
    print "ok 3"
    sys.stdout.flush();

thread.start_new_thread(t1, ())

import time
time.sleep(2)
print perl_obj
perl_obj = None

print "ok 5"



