package MMDS::Output::Latex::Latin9T1;

# RCS Id: $Id: Latin9T1.pm,v 1.1 2002-12-30 18:59:54+01 jv Exp $

# This file should be generated... Well, maybe later.
# It's quite static, actually.

# Map iso-8859-15 to TeX T1 encoding.
# Some entries are emulated using math mode.

require MMDS::Output::Latex::Latin1T1;

$::iso2tex{"\246"} = '\v{S}';		# Scaron
$::iso2tex{"\250"} = '\v{s}';		# scaron
$::iso2tex{"\264"} = '\v{Z}';		# Zcaron
$::iso2tex{"\270"} = '\v{z}';		# zcaron
$::iso2tex{"\274"} = '\OE';		# OE
$::iso2tex{"\275"} = '\oe';		# oe
$::iso2tex{"\276"} = '\"{Y}';		# Ydieresis

if ( $::use_ts1 ) {

    # Euro is a problem. I'm not sure if it is in TS1...

    $::iso2tex{"\244"} = '\texteuro';	# euro
}

1;
