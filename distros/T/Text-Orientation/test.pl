use Test;
BEGIN { plan tests => 8 };
use Text::Orientation;
ok(1);

#########################
$text=<<'EOF';
滿紙荒唐言
一把辛酸淚
都云作者痴
誰解其中味
EOF


$o = Text::Orientation->new( TEXT => $text,   CHARSET => 'Big5');
ok($o->transpose().$/, <<'EOF');
滿一都誰
紙把云解
荒辛作其
唐酸者中
言淚痴味
EOF

ok($o->anti_transpose().$/, <<'EOF');
味痴淚言
中者酸唐
其作辛荒
解云把紙
誰都一滿
EOF

ok($o->rotate(1).$/, <<'EOF');
誰都一滿
解云把紙
其作辛荒
中者酸唐
味痴淚言
EOF

ok($o->rotate(2).$/, <<'EOF');
味中其解誰
痴者作云都
淚酸辛把一
言唐荒紙滿
EOF
ok($o->rotate(3).$/, <<'EOF');
言淚痴味
唐酸者中
荒辛作其
紙把云解
滿一都誰
EOF
ok($o->mirror('vertical').$/, <<'EOF');
誰解其中味
都云作者痴
一把辛酸淚
滿紙荒唐言
EOF
ok($o->mirror('horizontal').$/, <<'EOF');
言唐荒紙滿
淚酸辛把一
痴者作云都
味中其解誰
EOF

exit;


sub sep { $/.'-'x23,$/ };

print sep, $o->transpose();
print sep, $o->anti_transpose();
print sep, $o->rotate(1);
print sep, $o->rotate(2);
print sep, $o->rotate(3);
print sep, $o->mirror('vertical');
print sep, $o->mirror('horizontal');
print $/;
exit;



