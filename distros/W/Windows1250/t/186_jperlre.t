# encoding: Windows1250
# This file is encoded in Windows-1250.
die "This file is not encoded in Windows-1250.\n" if q{あ} ne "\x82\xa0";

use Windows1250;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あAい' =~ /あ[^-]い/) {
    print "ok - 1 $^X $__FILE__ ('あAい' =~ /あ[^-]い/)\n";
}
else {
    print "not ok - 1 $^X $__FILE__ ('あAい' =~ /あ[^-]い/)\n";
}

__END__
