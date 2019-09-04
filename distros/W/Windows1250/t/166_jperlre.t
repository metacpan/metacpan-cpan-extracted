# encoding: Windows1250
use Windows1250;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('1' =~ /(\D)/) {
    print "not ok - 1 $^X $__FILE__ not ('1' =~ /\\D/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('1' =~ /\\D/).\n";
}

__END__

