package MMDS::Output::Latex::Latin1T1;

# RCS Id: $Id: Latin1T1.pm,v 1.1 2002-12-30 18:40:48+01 jv Exp $

# This file should be generated... Well, maybe later.
# It's quite static, actually.

# Map iso-8859-1 to TeX T1 encoding.
# Some entries are emulated using math mode.

%::iso2tex = (
    "\043",	'\char"23',
    "\044",	'\textdollar',
    "\045",	'\char"25',
    "\046",	'\char"26',
    "\047",	'\char"27',
    "\134",	'\textbackslash',
    "\136",	'\textasciicircum',
    "\137",	'\textunderscore',
    "\140",	'\char"60',
    "\173",	'\textbraceleft',
    "\174",	'\textbar',
    "\175",	'\textbraceright',
    "\176",	'\textasciitilde',
    "\240",	'~',
    "\241",	'\textexclamdown',
    "\243",	'\textsterling',
    "\247",	'\char"9F',
    "\250",	'\char"04',
    "\251",	'\copyright',
    "\253",	'\char"13',
    "\254",	'$\neg$',
    "\257",	'\char"09',
    "\261",	'$\pm$',
    "\262",	'$^{2}$',
    "\263",	'$^{3}$',
    "\264",	'\char"01',
    "\265",	'$\mu$',
    "\270",	'\char"0D',
    "\271",	'$^{1}$',
    "\273",	'\char"14',
    "\274",	'\mbox{$^{1}$\char"2F$_{4}$}',
    "\275",	'\mbox{$^{1}$\char"2F$_{2}$}',
    "\276",	'\mbox{$^{3}$\char"2F$_{4}$}',
    "\277",	'\textquestiondown',
    "\300",	'\`{A}',
    "\301",	'\\\'{A}',
    "\302",	'\^{A}',
    "\303",	'\~{A}',
    "\304",	'\"{A}',
    "\305",	'\AA',
    "\306",	'\AE',
    "\307",	'\c{C}',
    "\310",	'\`{E}',
    "\311",	'\\\'{E}',
    "\312",	'\^{E}',
    "\313",	'\"{E}',
    "\314",	'\`{I}',
    "\315",	'\\\'{I}',
    "\316",	'\^{I}',
    "\317",	'\"{I}',
    "\320",	'\DH',
    "\321",	'\~{N}',
    "\322",	'\`{O}',
    "\323",	'\\\'{O}',
    "\324",	'\^{O}',
    "\325",	'\~{O}',
    "\326",	'\"{O}',
    "\327",	'$\times$',
    "\330",	'\O',
    "\331",	'\`{U}',
    "\332",	'\\\'{U}',
    "\333",	'\^{U}',
    "\334",	'\"{U}',
    "\335",	'\`{y}',
    "\336",	'\TH',
    "\337",	'\ss',
    "\340",	'\`{a}',
    "\341",	'\\\'{a}',
    "\342",	'\^{a}',
    "\343",	'\~{a}',
    "\344",	'\"{a}',
    "\345",	'\aa',
    "\346",	'\ae',
    "\347",	'\c{c}',
    "\350",	'\`{e}',
    "\351",	'\\\'{e}',
    "\352",	'\^{e}',
    "\353",	'\"{e}',
    "\354",	'\`{\i}',
    "\355",	'\\\'{\i}',
    "\356",	'\^{\i}',
    "\357",	'\"{\i}',
    "\360",	'\dh',
    "\361",	'\~{n}',
    "\362",	'\`{o}',
    "\363",	'\\\'{o}',
    "\364",	'\^{o}',
    "\365",	'\~{o}',
    "\366",	'\"{o}',
    "\367",	'$\div$',
    "\370",	'\o',
    "\371",	'\`{u}',
    "\372",	'\\\'{u}',
    "\373",	'\^{u}',
    "\374",	'\"{u}',
    "\375",	'\\\'{y}',
    "\376",	'\th',
    "\377",	'\"{y}',
);

if ( $::use_ts1 ) {

    # When using Text Companion font encoding, we can eliminate all math
    # mode emulations.

    $::iso2tex{"\242"} = '\textcent';
    $::iso2tex{"\244"} = '\textcurrency';
    $::iso2tex{"\245"} = '\textyen';
    $::iso2tex{"\246"} = '\textbrokenbar';
    $::iso2tex{"\252"} = '\textordfeminine';
    $::iso2tex{"\254"} = '\textlnot';
    $::iso2tex{"\255"} = '\textendash';
    $::iso2tex{"\256"} = '\textregistered';
    $::iso2tex{"\260"} = '\textdegree';
    $::iso2tex{"\262"} = '\texttwosuperior';
    $::iso2tex{"\263"} = '\textthreesuperior';
    $::iso2tex{"\265"} = '\textmu';
    $::iso2tex{"\266"} = '\textparagraph';
    $::iso2tex{"\267"} = '\textperiodcentered';
    $::iso2tex{"\271"} = '\textonesuperior';
    $::iso2tex{"\272"} = '\textordmasculine';
    $::iso2tex{"\274"} = '\textonequarter';
    $::iso2tex{"\275"} = '\textonehalf';
    $::iso2tex{"\276"} = '\textthreequarters';
    $::iso2tex{"\327"} = '\texttimes';
    $::iso2tex{"\367"} = '\textdiv';
}

1;
