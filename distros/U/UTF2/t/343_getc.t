# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
print "1..2\n";

my $__FILE__ = __FILE__;

open(FILE,">$__FILE__.txt") || die;
print FILE <DATA>;
close(FILE);

open(GETC,"<$__FILE__.txt") || die;
my @getc = ();
while (my $c = UTF2::getc(GETC)) {
    last if $c =~ /\A[\r\n]\z/;
    push @getc, $c;
}
close(GETC);

my $result = join('', map {"($_)"} @getc);
if ($result eq '(1)(2)(ｱ)(ｲ)(あ)(い)') {
    print "ok - 1 $^X $__FILE__ 12ｱｲあい --> $result.\n";
}
else {
    print "not ok - 1 $^X $__FILE__ 12ｱｲあい --> $result.\n";
}

{
    package Getc::Test;

    open(GETC2,"<$__FILE__.txt") || die;
    my @getc = ();
    while (my $c = UTF2::getc(GETC2)) {
        last if $c =~ /\A[\r\n]\z/;
        push @getc, $c;
    }
    close(GETC2);

    my $result = join('', map {"($_)"} @getc);
    if ($result eq '(1)(2)(ｱ)(ｲ)(あ)(い)') {
        print "ok - 2 $^X $__FILE__ 12ｱｲあい --> $result.\n";
    }
    else {
        print "not ok - 2 $^X $__FILE__ 12ｱｲあい --> $result.\n";
    }
}

unlink("$__FILE__.txt");

__END__
12ｱｲあい
