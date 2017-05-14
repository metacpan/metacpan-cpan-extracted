# $Id: test.t,v 1.5 2006/05/16 11:03:54 dk Exp $
# yes, this is somewhat strange -- but if this fails, everything will as well
1..23
#if $global{num} = 1;
#endif

#perldef test($a,$b) \
	my $ret = ($a eq $b) ? "ok $global{num}\n" : "fail $global{num} ('$a' vs '$b', line $context->{line})\n";\
	$global{num}++;\
	$ret;
#perldef ok \
	sprintf "ok %d\n", $global{num}++;
#perldef fail \
	sprintf "fail %d ( line %d )\n", $global{num}++, $context->{line};

# -- 1
#define a
#ifdef a
ok
#else
fail
#endif

# -- 2
#ifndef a
fail
#else
ok
#endif

# -- 3
#undef a
#ifdef a
fail
#else
ok
#endif

# -- 4
#ifndef a
ok
#else
fail
#endif

# -- 5
#ifdef b
fail
#else
ok
#endif

# -- 6
#ifndef b
ok
#else
fail
#endif

# -- 7
#define p00()
test( p00(), )

# -- 8
#define p01() p01
test( p01(), p01)

# -- 9
# check if a single-line define is not mistaken for a multi-line
#define p_line_a line_a
#define p_line_b line_b
test(p_line_b, line_b)
#undef p_line_a
#undef p_line_b

# -- 10
#define p10(a) a+1
#define p11(a) 1+p10(a)
test(p11(3), 1+3+1)

# -- 11
test(p11((1,2)), 1+(1,2)+1)

# -- 12
#define p20(a,b) a+b
#define p21(a,b,c) p20(a,b)+c
test(p21(1,2,3), 1+2+3)

# -- 13
# check joins
#define j01(a) k ## a ## m
#define j02(a) j ## j01(a)
test(j02(l), jklm)

# -- 14
# check stringification
#define s01(a) # a
#define s02(a) s01(a)
test(s02(l), 'l')

# -- 15
#perldef x3(...) sprintf '%s', join('', @_, @_, @_)
test(x3(1,2), 121212)

# -- 16
#perldef abc "1\n2\n3\n"
#define <<heredoc
1
2
3
heredoc
test( heredoc, abc)

# -- 17
#perldef <<hereperl($a,$b,$c)
"$a\n$b\n$c\n"
hereperl
test( hereperl(1,2,3), abc)

# -- 18
test( hereperl    (1,2,3), abc)

# -- 19
#define A B--comment that should be stripped
test(A,B)
#undef A

#pragma comment(leave)

# -- 20
#define A B--C
test(A,B--C)
#undef A

# -- 21
#perldef A 'B#C'
test(A,B#C)
#undef A

# -- 22
#define A 1
#define B 0
#if 0
#elif A
ok
#elif A
fail
#else
fail
#endif

# --23
#if 0
#elif B
fail
#elif B
fail
#elif B
fail
#else
ok
#endif

#pragma comment(strip)
