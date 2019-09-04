# encoding: Windows1252
# This file is encoded in Windows-1252.
die "This file is not encoded in Windows-1252.\n" if q{あ} ne "\x82\xa0";

use Windows1252;
print "1..4\n";

my $__FILE__ = __FILE__;

# メタ文字 C<\U>, C<\L>, C<\Q>, C<\E> および変数展開は考慮されておりません。
# 必要なら、C<""> (or C<qq//>) 演算子を使ってください。

if ('ABC' =~ /\Uabc\E/) {
    print "ok - 1 $^X $__FILE__ ('ABC' =~ /\\Uabc\\E/)\n";
}
else {
    print "not ok - 1 $^X $__FILE__ ('ABC' =~ /\\Uabc\\E/)\n";
}

if ('def' =~ /\LDEF\E/) {
    print "ok - 2 $^X $__FILE__ ('def' =~ /\\LDEF\\E/)\n";
}
else {
    print "not ok - 2 $^X $__FILE__ ('def' =~ /\\LDEF\\E/)\n";
}

if ('({[' =~ /\Q(\{\[\E/) {
    print "ok - 3 $^X $__FILE__ ('({[' =~ /\\Q({[\\E/)\n";
}
else {
    print "not ok - 3 $^X $__FILE__ ('({[' =~ /\\Q({[\\E/)\n";
}

my $var = 'GHI';
if ('GHI' =~ /GHI/) {
    print "ok - 4 $^X $__FILE__ ('GHI' =~ /GHI/)\n";
}
else {
    print "not ok - 4 $^X $__FILE__ ('GHI' =~ /GHI/)\n";
}

__END__
