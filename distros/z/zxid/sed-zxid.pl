#!/usr/bin/perl
# 20100702 Sampo Kellomaki (sampo@iki.fi)
# sed dependency remover for zxid
# This program is used to perform substitutions that normal
# unix programmer would do with sed. We do it in perl to
# remove sed dependency. We need perl anyway.
# This program also avoids some Windows shell quoting problems.

$op = shift;
undef $/;
$_ = <STDIN>;

if ($op eq 'nss') {
    #s%^(\#line.*)$%/* $1 */%gm;
    s/static struct zx_ns_s/struct zx_ns_s/g;
    print;
}

if ($op eq 'attrs') {
    #s%^(\#line.*)$%/* $1 */%gm;
    s/static struct zx_at_tok/struct zx_at_tok/g;
    print;
}

if ($op eq 'elems') {
    #s%^(\#line.*)$%/* $1 */%gm;
    s/static struct zx_el_tok/struct zx_el_tok/g;
    print;
}

if ($op eq 'version') {
    $ZXIDREL = shift;
    s/^Version: .*/Version: $ZXIDREL/m;
    print;
}

if ($op eq 'license') {
    s/[ \t\r\n]+$//s;
    s/"/\\"/g;
    s/$/\\n\\/gm;
    chop; chop; chop;
    print <<LICENSE;
char* license = "\\n\\
Copyright (c) 2012-2013 Synergetics SA (sampo@synergetics.be), All Rights Reserved.\\n\\
Copyright (c) 2010-2012 Sampo Kellomaki (sampo\@iki.fi), All Rights Reserved.\\n\\
Copyright (c) 2006-2009 Symlabs (symlabs\@symlabs.com), All Rights Reserved.\\n\\
Author: Sampo Kellomaki (sampo\@iki.fi), All Rights Reserved.\\n\\
$_\\n";
LICENSE
;
}

if ($op eq 'zxidvers') {
    chop;
    $ZXIDVERSION = shift;
    $ZXIDREL = shift;
    $secs = time;
    print <<ZXIDVERS;
#ifndef _zxidvers_h
#define _zxidvers_h
#define ZXID_VERSION $ZXIDVERSION
#define ZXID_REL "$ZXIDREL"
#define ZXID_COMPILE_DATE "$secs"
#define ZXID_REV "$_"
#endif
ZXIDVERS
;

}

__END__
