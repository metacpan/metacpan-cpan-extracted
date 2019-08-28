# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
print "1..1\n";

# マッチしないはずなのにマッチする（１）
if ("ヤカン" =~ /ポット/) {
    print qq<not ok - 1 "YAKAN" =~ /POTTO/\n>;
}
else {
    print qq<ok - 1 "YAKAN" =~ /POTTO/\n>;
}

__END__

Shift-JISテキストを正しく扱う
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
