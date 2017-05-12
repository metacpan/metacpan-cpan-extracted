print "1..5"
import perl
import sys;

perl.eval("""

my $sys = Python::Import("sys");
print $sys->version, "\n";
print "not " unless $sys->version eq "%s";
print "ok 1\n";

my $string = Python::Import("string");

print "not " unless $string->digits eq join("", 0..9);
print "ok 2\n";

print "not " unless $string->lower("ABC") eq "abc";
print "ok 3\n";

eval {
   $fail = Python::Import("not_existing");
};
#print $@;

print "not " unless Python::Err::ImportError($@) && $@ =~ /No module named/;
print "ok 4\n";

""" % (sys.version))

if sys.modules['string']:
    print "ok 5"

