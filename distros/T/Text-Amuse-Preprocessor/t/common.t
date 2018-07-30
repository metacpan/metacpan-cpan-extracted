#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 55;
use Text::Amuse::Preprocessor;
use File::Temp;
use File::Spec::Functions qw/catfile catdir/;

eval "use Text::Diff;";
my $use_diff;
if (!$@) {
    $use_diff = 1;
}

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";


my $input = <<'INPUT';
U+FB00	ﬀ	ef ac 80	LATIN SMALL LIGATURE FF       ﬀ
U+FB01	ﬁ	ef ac 81	LATIN SMALL LIGATURE FI       ﬁ
U+FB02	ﬂ	ef ac 82	LATIN SMALL LIGATURE FL       ﬂ
U+FB03	ﬃ	ef ac 83	LATIN SMALL LIGATURE FFI      ﬃ
U+FB04	ﬄ	ef ac 84	LATIN SMALL LIGATURE FFL      ﬄ
ruina­no gli alberi ruina­no gli alberi deve esse­ re negato esse­ re negato
hello-there
INPUT

my $expected = <<'OUT';
U+FB00    ff    ef ac 80    LATIN SMALL LIGATURE FF       ff
U+FB01    fi    ef ac 81    LATIN SMALL LIGATURE FI       fi
U+FB02    fl    ef ac 82    LATIN SMALL LIGATURE FL       fl
U+FB03    ffi    ef ac 83    LATIN SMALL LIGATURE FFI      ffi
U+FB04    ffl    ef ac 84    LATIN SMALL LIGATURE FFL      ffl
ruinano gli alberi ruinano gli alberi deve essere negato essere negato
hello-there
OUT

test_strings(ligatures => $input, $expected);

test_strings(missing_nl => "hello\nthere", "hello\nthere\n");

test_strings('garbage',
             "hello ─ there hello ─ there\r\n\t",
             "hello — there hello — there\n    \n");

test_strings('ellipsis_no_fix',
             ". . . test... . . . but here .  .  .  .",
             ". . . test... . . . but here .  .  .  .");


test_strings('ellipsis',
             ". . . test... . . . but here .  .  .  .",
             "... test...... but here .  .  .  .", 1, 1, 0);


$input =<<'INPUT';
https://anarhisticka-biblioteka.net/library/

<br>http://j12.org/spunk/ http://j12.org/spunk/<br>http://j12.org/spunk/

<br>https://anarhisticka-biblioteka.net/library/erik-satie-depesa<br>https://anarhisticka-biblioteka.net/library/erik-satie-depesa

[[http://j12.org/spunk/][j12.org]]<br>[[http://j12.org/spunk/][j12.org]]

[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]<br>[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]

http://en.wiktionary.org/wiki/%EF%AC%85

http://en.wikipedia.org/wiki/Pi_%28disambiguation%29

http://en.wikipedia.org/wiki/Pi_%28instrument%29

(http://en.wikipedia.org/wiki/Pi_%28instrument%29)

as seen in http://en.wikipedia.org/wiki/Pi_%28instrument%29.

as seen in http://en.wikipedia.org/wiki/Pi_%28instrument%29 and (http://en.wikipedia.org/wiki/Pi_%28instrument%29).
INPUT

$expected =<<'OUTPUT';
[[https://anarhisticka-biblioteka.net/library/][anarhisticka-biblioteka.net]]

<br>[[http://j12.org/spunk/][j12.org]] [[http://j12.org/spunk/][j12.org]]<br>[[http://j12.org/spunk/][j12.org]]

<br>[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]<br>[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]

[[http://j12.org/spunk/][j12.org]]<br>[[http://j12.org/spunk/][j12.org]]

[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]<br>[[https://anarhisticka-biblioteka.net/library/erik-satie-depesa][anarhisticka-biblioteka.net]]

[[http://en.wiktionary.org/wiki/%EF%AC%85][en.wiktionary.org]]

[[http://en.wikipedia.org/wiki/Pi_%28disambiguation%29][en.wikipedia.org]]

[[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]]

([[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]])

as seen in [[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]].

as seen in [[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]] and ([[http://en.wikipedia.org/wiki/Pi_%28instrument%29][en.wikipedia.org]]).
OUTPUT

my $original_input = $input;
my $original_expected = $expected;

test_strings(links => $input, $expected, 0, 1, 0);

foreach my $lang (qw/en fi es sr hr ru it mk sv de
                     fr pt sq da nl id/) {
    test_lang($lang);
}

sub test_lang {
    my $lang = shift;
    my $input = "#lang $lang\n\n" . read_file(catfile(qw/t testfiles infile.muse/));
    my $expected = read_file(catfile(qw/t testfiles/, "$lang.muse"));
    test_strings($lang, $input, $expected, 1, 1, 0);
}

test_strings("Full example",
             read_file(catfile(qw/t testfiles full.in.muse/)),
             read_file(catfile(qw/t testfiles full.out.muse/)),
             1, 1, 1, 1);

my $broken_in = <<MUSE;
#title test
#lang en

"hello" [1] 'hullo'

[1] a
[1] b
[1] c
MUSE

my $broken_out = '';
my $bpp = Text::Amuse::Preprocessor->new(input => \$broken_in,
                                         output => \$broken_out,
                                         fix_links => 1,
                                         fix_typography => 1,
                                         fix_footnotes => 1);
ok (!$bpp->process, "Failure");
is ($broken_out, '', "No output");
is_deeply ($bpp->error, {
                         footnotes => 3,
                         references => 1,
                         footnotes_found => '[1] [1] [1]',
                         references_found => '[1]',
                         differences => '@@ -1,3 +1 @@
 [1]
-[1]
-[1]
'
                        });

{
    my $quotes =<<'MUSE';
#lang fr

' Begin, End '           

" Begin, End "              

' Begin, End '

" Begin, End "

MUSE
    my $expected_muse =<<'MUSE';
#lang fr

‘ Begin, End ’

«  Begin, End  »

‘ Begin, End ’

«  Begin, End  »

MUSE
    test_strings("Quote", $quotes, $expected_muse, 1, 1, 1, 1);
}

{
    my $da_in = <<'MUSE';
#lang da

"Outer quotation 'inner' hyphen-for-words - and a dash"
MUSE

    my $da_out = <<'MUSE';
#lang da

»Outer quotation ’inner’ hyphen-for-words – and a dash«
MUSE
    test_strings("Quote", $da_in, $da_out, 1, 1, 1, 1);
}

{
    my $nl_in = <<'MUSE';
#lang nl

"this and 'that' - and a dash."
MUSE

    my $nl_out = <<'MUSE';
#lang nl

“this and ‘that’ – and a dash.”
MUSE
    test_strings("Nl quotation", $nl_in, $nl_out, 1, 1, 1, 1);
}




sub test_strings {
    my ($name, $input, $expected, $typo, $links, $nbsp, $fn) = @_;

    my $input_string = $input;
    my $output_string = '';

    my $pp = Text::Amuse::Preprocessor->new(input => \$input_string,
                                            output => \$output_string,
                                            fix_links => $links,
                                            fix_typography => $typo,
                                            fix_footnotes => $fn,
                                            fix_nbsp => $nbsp,
                                            debug => 0,
                                           );
    $pp->process;
    is_deeply([ split /\n/, $output_string ],
              [ split /\n/, $expected ],
              "$name with reference works") or show_diff($output_string, $expected);
    
    # and the file variant
    my $dir = File::Temp->newdir(CLEANUP => 1);
    my $wd = $dir->dirname;
    my $infile = catfile($wd, 'in.muse');
    my $outfile = catfile($wd, 'out.muse');
    diag "Using $wd for $name";
    write_file($infile, $input);

    my $pp_file = Text::Amuse::Preprocessor->new(input => $infile,
                                                 output => $outfile,
                                                 fix_links => $links,
                                                 fix_typography => $typo,
                                                 fix_footnotes => $fn,
                                                 fix_nbsp => $nbsp,
                                                 debug => 0,
                                                );
    $pp_file->process;
    my $from_file = read_file($outfile);
    is_deeply([ split /\n/, $from_file ],
              [ split /\n/, $expected ],
              "$name with files works") or show_diff($from_file, $expected);
}

sub read_file {
    return Text::Amuse::Preprocessor->_read_file(@_);
}

sub write_file {
    return Text::Amuse::Preprocessor->_write_file(@_);
}

sub show_diff {
    my ($got, $exp) = @_;
    if ($use_diff) {
        diag diff(\$exp, \$got, { STYLE => 'Unified' });
    }
    else {
        diag "GOT:\n$got\n\nEXP:\n$exp\n\n";
    }
}
