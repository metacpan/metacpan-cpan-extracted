# encoding: Windows1250
# This file is encoded in Windows-1250.
die "This file is not encoded in Windows-1250.\n" if q{‚ } ne "\x82\xa0";

use Windows1250;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('‚ ‚¢q' =~ /(‚ ‚¢+‚¢‚¤)/) {
    print "not ok - 1 $^X $__FILE__ not ('‚ ‚¢q' =~ /‚ ‚¢+‚¢‚¤/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('‚ ‚¢q' =~ /‚ ‚¢+‚¢‚¤/).\n";
}

__END__
