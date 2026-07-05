die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# Test for mb::detect_system_encoding().
#
# The function inspects $OSNAME (settable via mb::set_OSNAME for testing)
# and LC_ALL / LC_CTYPE / LANG (in that priority) and returns one of:
# big5, big5hkscs, eucjp, euctw, gb18030, gbk, sjis, uhc, utf8.
#
# The euctw entries were added after verifying the vendor documentation:
# - Oracle Solaris: the zh_TW locale uses the EUC scheme to encode the
#   CNS11643.1992 codeset (Solaris 7), and zh_TW.EUC is its explicit
#   name from Solaris 9 on.
#   https://docs.oracle.com/cd/E19620-01/805-4123/new-71/index.html
#   https://docs.oracle.com/cd/E19683-01/806-6642/6jfipqu66/index.html
# - IBM AIX: locale zh_TW, alias zh_TW.IBM-eucTW, code set IBM-eucTW
#   (Zh_TW with capital Z stays big-5).
#   https://www.ibm.com/docs/en/aix/7.2.0?topic=globalization-supported-languages-locales
# - HP-UX: locale zh_TW.eucTW (Taiwanese EUC), listed in "Configuring
#   HP-UX for Different Languages" (UXL10N-90302), Table A-1 Locale Names.
#   https://community.hpe.com/hpeb/attachments/hpeb/itrc-156/211158/1/198250.pdf
# - glibc (Linux and others): zh_TW.EUC-TW/EUC-TW in localedata/SUPPORTED
#   (a bare zh_TW is BIG5 there, so the generic branch must not map it).
#   https://github.com/bminor/glibc/blob/master/localedata/SUPPORTED
# The generic branch also gained the glibc SUPPORTED spellings for the
# other encodings (ja_JP.EUC-JP, ko_KR.EUC-KR, zh_CN.GBK, zh_CN.GB18030,
# zh_SG, zh_SG.GBK, zh_HK, zh_HK.BIG5-HKSCS) and the HP-UX branch gained
# zh_HK.hkbig5 (HP-UX 11i, patch PHCO_26453 and later).
#
# This file runs on every perl from 5.005_03 up: closure-array TAP with a
# dynamic plan, no source filter, no version-specific feature, US-ASCII.

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

# call detect_system_encoding() as if running on $osname with LANG=$lang
# (LC_ALL and LC_CTYPE are cleared so LANG is the deciding variable)
sub detect {
    my($osname, $lang) = @_;
    my $save_osname = mb::get_OSNAME();
    local $ENV{'LC_ALL'};   delete $ENV{'LC_ALL'};
    local $ENV{'LC_CTYPE'}; delete $ENV{'LC_CTYPE'};
    local $ENV{'LANG'} = $lang;
    mb::set_OSNAME($osname);
    my $encoding = mb::detect_system_encoding();
    mb::set_OSNAME($save_osname);
    return $encoding;
}

# same, but the deciding variable is LC_ALL (highest priority)
sub detect_lc_all {
    my($osname, $lc_all) = @_;
    my $save_osname = mb::get_OSNAME();
    local $ENV{'LC_ALL'} = $lc_all;
    local $ENV{'LC_CTYPE'}; delete $ENV{'LC_CTYPE'};
    local $ENV{'LANG'};     delete $ENV{'LANG'};
    mb::set_OSNAME($osname);
    my $encoding = mb::detect_system_encoding();
    mb::set_OSNAME($save_osname);
    return $encoding;
}

@test = (
# 1 -- Oracle Solaris: zh_TW and zh_TW.EUC are EUC-encoded CNS11643 (euctw)
    sub { detect('solaris', 'zh_TW')           eq 'euctw'     },
    sub { detect('solaris', 'zh_TW.EUC')       eq 'euctw'     },
# 3 -- Oracle Solaris: the Big5 and pre-existing locales are unchanged
    sub { detect('solaris', 'zh_TW.BIG5')      eq 'big5'      },
    sub { detect('solaris', 'zh_HK.BIG5HK')    eq 'big5hkscs' },
    sub { detect('solaris', 'ja_JP.PCK')       eq 'sjis'      },
    sub { detect('solaris', 'ja')              eq 'eucjp'     },
    sub { detect('solaris', 'zh_CN.GB18030')   eq 'gb18030'   },
    sub { detect('solaris', 'ko')              eq 'uhc'       },
    sub { detect('solaris', 'nosuchlocale')    eq 'utf8'      },
    sub {1},
# 11 -- IBM AIX: zh_TW and zh_TW.IBM-eucTW are IBM-eucTW (euctw)
    sub { detect('aix', 'zh_TW')               eq 'euctw'     },
    sub { detect('aix', 'zh_TW.IBM-eucTW')     eq 'euctw'     },
# 13 -- IBM AIX: Zh_TW (capital Z) stays big-5, case must not be folded
    sub { detect('aix', 'Zh_TW')               eq 'big5'      },
    sub { detect('aix', 'Zh_TW.big-5')         eq 'big5'      },
    sub { detect('aix', 'ja_JP.IBM-eucJP')     eq 'eucjp'     },
    sub { detect('aix', 'Ja_JP.IBM-943')       eq 'sjis'      },
    sub { detect('aix', 'nosuchlocale')        eq 'utf8'      },
    sub {1},
# 19 -- HP HP-UX: zh_TW.eucTW is Taiwanese EUC (euctw)
    sub { detect('hpux', 'zh_TW.eucTW')        eq 'euctw'     },
# 20 -- HP HP-UX: the Big5 and pre-existing locales are unchanged
    sub { detect('hpux', 'zh_TW.big5')         eq 'big5'      },
    sub { detect('hpux', 'zh_HK.big5')         eq 'big5hkscs' },
    sub { detect('hpux', 'zh_HK.hkbig5')       eq 'big5hkscs' },
    sub { detect('hpux', 'ja_JP.SJIS')         eq 'sjis'      },
    sub { detect('hpux', 'zh_CN.hp15CN')       eq 'gbk'       },
    sub { detect('hpux', 'nosuchlocale')       eq 'utf8'      },
    sub {1},
# 25 -- LC_ALL has priority over LANG and reaches the same euctw entries
    sub { detect_lc_all('solaris', 'zh_TW.EUC')       eq 'euctw' },
    sub { detect_lc_all('aix',     'zh_TW.IBM-eucTW') eq 'euctw' },
    sub { detect_lc_all('hpux',    'zh_TW.eucTW')     eq 'euctw' },
    sub {1},
# 29 -- other systems (glibc and friends): euctw via the explicit spellings
    sub { detect('linux', 'zh_TW.eucTW')       eq 'euctw'     },
    sub { detect('linux', 'zh_TW.EUC-TW')      eq 'euctw'     },
# 31 -- other systems: the glibc SUPPORTED spellings for the other encodings
    sub { detect('linux', 'ja_JP.EUC-JP')      eq 'eucjp'     },
    sub { detect('linux', 'ja_JP')             eq 'eucjp'     },
    sub { detect('linux', 'ko_KR.EUC-KR')      eq 'uhc'       },
    sub { detect('linux', 'zh_CN')             eq 'gbk'       },
    sub { detect('linux', 'zh_CN.GBK')         eq 'gbk'       },
    sub { detect('linux', 'zh_SG')             eq 'gbk'       },
    sub { detect('linux', 'zh_SG.GBK')         eq 'gbk'       },
    sub { detect('linux', 'zh_CN.GB18030')     eq 'gb18030'   },
    sub { detect('linux', 'zh_HK')             eq 'big5hkscs' },
    sub { detect('linux', 'zh_HK.BIG5-HKSCS')  eq 'big5hkscs' },
# 41 -- other systems: pre-existing entries are unchanged, and a bare zh_TW
#       is intentionally NOT mapped (Big5 on glibc, EUC-TW on Solaris lineage)
    sub { detect('linux', 'zh_TW.Big5')        eq 'big5'      },
    sub { detect('linux', 'zh_TW.big5')        eq 'big5'      },
    sub { detect('linux', 'ja_JP.eucJP')       eq 'eucjp'     },
    sub { detect('linux', 'zh_TW')             eq 'utf8'      },
    sub { detect('linux', 'nosuchlocale')      eq 'utf8'      },
    sub {1},
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } for my $t (@test) { ok($t->()); }

__END__
