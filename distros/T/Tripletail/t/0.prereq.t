use Test::Exception tests => 4;

for my $info(
[ 'Unicode::Japanese', '0.43'  ],
[ 'MIME::Tools',       '5.411' ],
[ 'PadWalker',         '1.0'   ],
[ 'IO::ScalarArray',   '2.110' ],
)
{
	my ($pkg, $ver) = @$info;
	lives_ok { eval qq{require $pkg;}; $@ and die; $pkg->VERSION($ver); } "prereq: $pkg $ver";
}
