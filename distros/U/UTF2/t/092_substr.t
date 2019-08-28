# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
print "1..20\n";

my $__FILE__ = __FILE__;

$_ = 'あいうえおかきくけこ';
if (substr($_,15) eq 'かきくけこ') {
    print qq{ok - 1 substr(\$_,15) eq 'かきくけこ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 substr(\$_,15) eq 'かきくけこ' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,6,9) eq 'うえお') {
    print qq{ok - 2 substr(\$_,6,9) eq 'うえお' $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 substr(\$_,6,9) eq 'うえお' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,6,9,'さしすせそ') eq 'うえお') {
    if ($_ eq 'あいさしすせそかきくけこ') {
        print qq{ok - 3 substr(\$_,6,9,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 substr(\$_,6,9,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 substr(\$_,6,9,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,-9) eq 'くけこ') {
    print qq{ok - 4 substr(\$_,-9) eq 'くけこ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 substr(\$_,-9) eq 'くけこ' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,-15,9) eq 'かきく') {
    print qq{ok - 5 substr(\$_,-15,9) eq 'かきく' $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 substr(\$_,-15,9) eq 'かきく' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,-15,9,'やゆよ') eq 'かきく') {
    if ($_ eq 'あいうえおやゆよけこ') {
        print qq{ok - 6 substr(\$_,-15,9,'やゆよ') eq 'かきく' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 substr(\$_,-15,9,'やゆよ') eq 'かきく' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 substr(\$_,-15,9,'やゆよ') eq 'かきく' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,15,0) eq '') {
    print qq{ok - 7 substr(\$_,15,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 substr(\$_,15,0) eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,15,0,'やゆよ') eq '') {
    if ($_ eq 'あいうえおやゆよかきくけこ') {
        print qq{ok - 8 substr(\$_,15,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 substr(\$_,15,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 substr(\$_,15,0,'やゆよ') eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,-15,0) eq '') {
    print qq{ok - 9 substr(\$_,-15,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 substr(\$_,-15,0) eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,-15,0,'やゆよ') eq '') {
    if ($_ eq 'あいうえおやゆよかきくけこ') {
        print qq{ok - 10 substr(\$_,-15,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 substr(\$_,-15,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 substr(\$_,-15,0,'やゆよ') eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (UTF2::substr($_,5) eq 'かきくけこ') {
    print qq{ok - 11 UTF2::substr(\$_,5) eq 'かきくけこ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 UTF2::substr(\$_,5) eq 'かきくけこ' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (UTF2::substr($_,2,3) eq 'うえお') {
    print qq{ok - 12 UTF2::substr(\$_,2,3) eq 'うえお' $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 UTF2::substr(\$_,2,3) eq 'うえお' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (UTF2::substr($_,2,3,'さしすせそ') eq 'うえお') {
    if ($_ eq 'あいさしすせそかきくけこ') {
        print qq{ok - 13 UTF2::substr(\$_,2,3,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 UTF2::substr(\$_,2,3,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 UTF2::substr(\$_,2,3,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (UTF2::substr($_,-3) eq 'くけこ') {
    print qq{ok - 14 UTF2::substr(\$_,-3) eq 'くけこ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 UTF2::substr(\$_,-3) eq 'くけこ' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (UTF2::substr($_,-5,3) eq 'かきく') {
    print qq{ok - 15 UTF2::substr(\$_,-5,3) eq 'かきく' $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 UTF2::substr(\$_,-5,3) eq 'かきく' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (UTF2::substr($_,-5,3,'やゆよ') eq 'かきく') {
    if ($_ eq 'あいうえおやゆよけこ') {
        print qq{ok - 16 UTF2::substr(\$_,-5,3,'やゆよ') eq 'かきく' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 16 UTF2::substr(\$_,-5,3,'やゆよ') eq 'かきく' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 16 UTF2::substr(\$_,-5,3,'やゆよ') eq 'かきく' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (UTF2::substr($_,5,0) eq '') {
    print qq{ok - 17 UTF2::substr(\$_,5,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 UTF2::substr(\$_,5,0) eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (UTF2::substr($_,5,0,'やゆよ') eq '') {
    if ($_ eq 'あいうえおやゆよかきくけこ') {
        print qq{ok - 18 UTF2::substr(\$_,5,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 18 UTF2::substr(\$_,5,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 18 UTF2::substr(\$_,5,0,'やゆよ') eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (UTF2::substr($_,-5,0) eq '') {
    print qq{ok - 19 UTF2::substr(\$_,-5,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 UTF2::substr(\$_,-5,0) eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (UTF2::substr($_,-5,0,'やゆよ') eq '') {
    if ($_ eq 'あいうえおやゆよかきくけこ') {
        print qq{ok - 20 UTF2::substr(\$_,-5,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 20 UTF2::substr(\$_,-5,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 20 UTF2::substr(\$_,-5,0,'やゆよ') eq '' $^X $__FILE__\n};
}

__END__
