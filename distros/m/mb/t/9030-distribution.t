######################################################################
# 9030-distribution.t  Distribution integrity.
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use vars qw($VERSION); $VERSION = $VERSION;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

plan_skip('MANIFEST not found') unless -f "$ROOT/MANIFEST";

plan_tests(count_A($ROOT) + count_B($ROOT) + count_C($ROOT) + count_F()
         + count_H()      + count_I()      + count_J($ROOT));

# t/NNN, doc/, eg/ja/ (and the localized eg/<lang>/ mother-tongue dirs that
# use a non-Latin native script), lib/mb.pm, README are intentionally UTF-8
# encoded.  Those eg/ dirs carry native-language POD/comments for students
# (their multibyte DATA is still \xHH byte escapes).  The non-Latin native
# scripts now include eg/tr eg/fr (Latin with diacritics), eg/ko (Hangul) and
# eg/tw (Han); eg/en/, eg/mb_length.pl, and the strictly ASCII Latin/romanized
# dirs (eg/id eg/tl eg/ur, plus eg/uz eg/bm added here) stay strictly US-ASCII,
# so they are deliberately NOT listed below.
my $utf8_ok = '^(?:t/[1-8]|doc/|eg/(?:ja|ne|bn|vi|si|my|zh|hi|th|km|mn|tr|fr|ko|tw)/|lib/mb\.pm$|README$)';

check_A($ROOT);
check_B($ROOT);
check_C($ROOT, utf8_ok => $utf8_ok);
check_F($ROOT);
check_H($ROOT);
check_I($ROOT);
check_J($ROOT);

END { end_testing() }
