# encoding: Windows1258
use Windows1258;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('1' =~ /(\d)/) {
    if ("-" eq "-") {
        print "ok - 1 $^X $__FILE__ ('1' =~ /\\d/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('1' =~ /\\d/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('1' =~ /\\d/).\n";
}

__END__
