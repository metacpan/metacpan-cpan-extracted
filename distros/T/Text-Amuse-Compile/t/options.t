#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 217;
use Text::Amuse::Compile;
use Text::Amuse::Functions qw/muse_to_object/;
use File::Spec;
use Text::Amuse::Compile::File;
use Text::Amuse::Compile::Merged;
use Text::Amuse::Compile::Templates;
use Text::Amuse::Compile::Utils qw/read_file/;
use Text::Amuse::Compile::TemplateOptions;
use Text::Amuse::Compile::Fonts::Family;
use Text::Amuse::Compile::Fonts::Selected;
use Cwd;

my $templates = Text::Amuse::Compile::Templates->new;

my $basepath = getcwd();

my $extra = {
             site => "Test site",
             mainfont => "TeX Gyre Pagella",
             siteslogan => "Hello there!",
             site => "http:mysite.org",
             sitename => "Another crappy test site",
             papersize => "a4paperwithears",
             division => 9,
             fontsize => 14,
             twoside => 1,
             bcor => "23",
             logo => "pallinopinco",
             cover => "mycover.pdf",
             coverwidth => "\\0.5", # validation here will fail, so 1
            };

my $compile = Text::Amuse::Compile->new(
                                        extra => $extra,
                                        standalone => 0,
                                        tex   => 1,
                                        cleanup => 1,
                                       );

my $extracopy = { %$extra };
is $compile->selected_font_main, delete $extracopy->{mainfont};
is $compile->selected_font_size, delete $extracopy->{fontsize};
is_deeply({ $compile->extra }, $extracopy, "extra options stored" );
ok ($compile->cleanup);

my $returned = { $compile->extra };

diag "Added key to passed ref";
$extra->{ciao} = 1;

is_deeply({ $compile->extra }, $returned );

$returned = {
             $compile->extra,
             papersize => '210mm:11in',
             fontsize => 10,
             bcor => '0mm',
             coverwidth => '1',
             selected_font_main => $compile->selected_font_main,
            };

my @targets;
my @results;
my @statusfiles;
foreach my $i (qw/1 2/) {
    my $target = File::Spec->catfile('t','options-f', 'dir' . $i, $i,
                                     'options' . $i);
    push @results, $target . '.tex';
    push @targets, $target . '.muse';
    push @statusfiles, $target . '.status';
}




foreach my $f (@results) {
    if (-f $f) {
        unlink $f or die $!;
    }
}


# twice to check the option persistence
for (1..2) {
    diag "Run $_";
    $compile->compile(@targets);
    diag "Compilation finished";
    foreach my $f (@results) {
        ok ((-f $f), "produced $f");
        my $c = read_file($f);
        # diag substr($c, 0, 200);
        my %tests = %$returned;
        delete $tests{bcor};
        delete $tests{twoside};
        foreach my $string (values %tests) {
            like $c, qr/\Q$string\E/, "Found $string";
        }
        like $c, qr/DIV=9/, "Found the div factor";
        like $c, qr/fontsize=14pt/, "Found the fontsize";
        unlike $c, qr/twoside/, "oneside enforced";
        like $c, qr/oneside/, "oneside enforced on single pdf";
        like $c, qr/BCOR=0mm/, "BCOR validated and enforced";
        unlike $c, qr/\\maketitle/;
        like $c, qr/includegraphics\[\S*width=1\\textwidth\]\{mycover.pdf\}/;
        like $c, qr/\\tableofcontents/;
    }

    foreach my $f (@results) {
        if (-f $f) {
            unlink $f or die $!;
        }
    }
    foreach my $f (@statusfiles) {
        ok ((! -e $f), File::Spec->rel2abs($f) . " was removed!");
    }
}


my $targetdir = File::Spec->catfile('t', 'testfile');
chdir $targetdir or die $!;
my $tt = Text::Amuse::Compile::Templates->new;
my $file = Text::Amuse::Compile::File->new(name => 'test',
                                           suffix => '.muse',
                                           cleanup => 1,
                                           fonts => Text::Amuse::Compile::Fonts::Selected
                                           ->new(mono => Text::Amuse::Compile::Fonts::Family
                                                 ->new(
                                                       name => $returned->{selected_font_main},
                                                       desc => $returned->{selected_font_main},
                                                       type => 'mono',
                                                      ),
                                                 sans => Text::Amuse::Compile::Fonts::Family
                                                 ->new(
                                                       name => $returned->{selected_font_main},
                                                       desc => $returned->{selected_font_main},
                                                       type => 'sans',
                                                      ),
                                                 main => Text::Amuse::Compile::Fonts::Family
                                                 ->new(
                                                       name => $returned->{selected_font_main},
                                                       desc => $returned->{selected_font_main},
                                                       type => 'serif',
                                                      ),
                                                 size => 14,
                                                ),
                                           templates => $tt);

foreach my $ext (qw/.html .tex .pdf .bare.html .epub/) {
    my $f = $file->name . $ext;
    if (-f $f) {
        unlink $f or die $!;
    }
}

diag "Working in $targetdir";

for (1..2) {
    $file->tex(%$returned);
    my $texfile = $file->name . '.tex';
    ok ((-f $texfile), "produced $texfile");
    my $c = read_file($texfile);
    # diag substr($c, 0, 200);
    my %tests = %$returned;
    foreach my $string (values %tests) {
        like $c, qr/\Q$string\E/, "Found $string";
    }
    like $c, qr/DIV=9/, "Found the div factor";
    like $c, qr/fontsize=14pt/, "Found the fontsize";
    like $c, qr/twoside/, "oneside not enforced";
    unlike $c, qr/oneside/, "oneside not enforced";
    like $c, qr/BCOR=0mm/, "BCOR enforced";
    unlike $c, qr/\\maketitle/;
    like $c, qr/includegraphics\[\S*width=1\\textwidth\]\{mycover.pdf\}/;
    like $c, qr/\\tableofcontents/;
    unlink $texfile or die $!;
}

my $merged = Text::Amuse::Compile::Merged->new(files => [qw/test.muse/]);

my $dummy = Text::Amuse::Compile::File->new(
                                            name => 'dummy',
                                            suffix => '.muse',
                                            templates => $templates,
                                            document => $merged,
                                            options => {
                                                        pippo => '[[http://test.org][test]]',
                                                        prova => 'hello *there* & \stuff',
                                                        ciao => 1,
                                                        test => "Another great thing!",
                                                       },
                                            virtual => 1,
                                           );

diag "Loading options from dummy file";
my $html_options = $dummy->html_options;
diag "Done";
my $latex_options = $dummy->tex_options;

is_deeply($html_options, {
                          pippo => '<a class="text-amuse-link" href="http://test.org">test</a>',
                          prova => 'hello <em>there</em> &amp; \stuff',
                          ciao => 1,
                          test => "Another great thing!",
                          nofinalpage => 0,
                          nocoverpage => 0,
                          notoc => 0,
                          coverwidth => 1,
                          impressum => 0,
                          continuefootnotes => 0,
                          centerchapter => 0,
                          centersection => 0,
                         }, "html escaped and interpreted ok");
is_deeply($latex_options, {
                           prova => 'hello \emph{there} \& \textbackslash{}stuff',
                           pippo => '\href{http://test.org}{test}',
                           ciao => 1,
                           test => "Another great thing!",
                           notoc => 0,
                           nofinalpage => 0,
                           nocoverpage => 0,
                           coverwidth => 1,
                           impressum => 0,
                           continuefootnotes => 0,
                           centerchapter => 0,
                           centersection => 0,
                          }, "latex escaped and interpreted ok");

is_deeply($dummy->tex_options, $latex_options);

eval {
    my $die = $dummy->options('garbage');
};
ok ($@, "Incorrect usage leads to exception");

chdir $basepath or die $!;

$dummy = Text::Amuse::Compile::File->new(
                                         name => 'dummy',
                                         suffix => '.muse',
                                         templates => $templates,
                                         document => $merged,
                                         options => {
                                                     cover => 'prova.pdf',
                                                     logo => 'c-i-a',
                                                    },
                                         virtual => 1,
                                           );

is $dummy->tex_options->{cover}, 'prova.pdf';
is $dummy->tex_options->{logo}, 'c-i-a';

my $testfile = File::Spec->rel2abs(File::Spec->catfile(qw/t manual logo.png/));
ok (-f $testfile, "$testfile exists");

SKIP: {
    skip "Testfile $testfile doesn't look sane", 6
      unless $testfile =~ m/^[a-zA-Z0-9\-\:\/\\]+\.(pdf|jpe?g|png)$/s;
    $testfile =~ s/\\/\//g; # for tests on windows.
    my $wintestfile = $testfile;
    $wintestfile =~ s/\//\\/g;
    $dummy = Text::Amuse::Compile::File->new(
                                             name => 'dummy',
                                             suffix => '.muse',
                                             templates => $templates,
                                             document => $merged,
                                             options => {
                                                         cover => $testfile,
                                                         logo => $wintestfile,
                                                        },
                                             virtual => 1,
                                            );

    ok $dummy->_looks_like_a_sane_name($testfile), "$testfile is valid";
    ok $dummy->_looks_like_a_sane_name($wintestfile), "$wintestfile is valid";

    is $dummy->tex_options->{cover}, $testfile, "cover is $testfile";
    is $dummy->tex_options->{logo}, $testfile, "logo is $testfile";

    $dummy = Text::Amuse::Compile::File->new(
                                             name => 'dummy',
                                             suffix => '.muse',
                                             templates => $templates,
                                             options => {
                                                         cover => 'a bc.pdf',
                                                         logo => 'c alsdkfl',
                                                        },
                                             document => $merged,
                                             virtual => 1,
                                            );
    is $dummy->tex_options->{cover}, undef, "cover with spaces doesn't validate";
    is $dummy->tex_options->{logo}, undef, "logo with spaces doesn't validate";
}

my $opts = Text::Amuse::Compile::TemplateOptions->new(twoside => 1);
is $opts->paging, 'twoside', "paging ok twoside";
$opts->oneside(1);
is $opts->paging, 'oneside', "paging ok oneside";
$opts->twoside(0);
is $opts->paging, 'oneside', "paging ok oneside";;
$opts = Text::Amuse::Compile::TemplateOptions->new;
is $opts->paging, 'oneside', "paging ok oneside";;
foreach my $method (qw/mainfont sansfont monofont/) {
    my $last;
    for my $good_font ('PT Sans', 'CMU Serif') {
        $opts->$method($good_font);
        is $opts->$method, $good_font, "$good_font is ok";
        $last = $good_font;
    }
    eval {
        $opts->$method("Random font / name");
    };

    ok $@, "random font name doesn't pass the validation";
    is $opts->$method, $last, "font is still $last";
}
foreach my $test ({ name => 'fontsize',
                    good => 11,
                    bad => 10.5 },
                  {
                   name => 'division',
                   good => 9,
                   bad => 'asdf',
                  },
                  {
                   name => 'coverwidth',
                   good => 0.91,
                   bad => 'asdf',
                  },
                  {
                   name => 'coverwidth',
                   good => 1,
                   bad => 1.01,
                  },
                  {
                   name => 'coverwidth',
                   good => 0.2,
                   bad => -1,
                  },
                  {
                   name => 'papersize',
                   good => 'a4',
                   bad => 'random',
                  },
                  {
                   name => 'papersize',
                   good => 'half-lt',
                   bad => 'half-a6',
                  },
                  {
                   name => 'papersize',
                   good => '16cm:12in',
                   bad => '16mx15cm',
                  },
                  {
                   name => 'bcor',
                   good => '16cm',
                   bad => '16m',
                  },
                  {
                   name => 'beamertheme',
                   bad => 'Pula',
                   good => 'Copenhagen',
                  },
                  {
                   name => 'beamercolortheme',
                   bad => 'vrabac',
                   good => 'seagull',
                  },
                 ) {
    my $method = $test->{name};
    eval {
        $opts->$method($test->{good});
    };
    ok !$@, "Setting $method to $test->{good} is fine";
    is $opts->$method, $test->{good}, "Option picked up";
    eval {
        $opts->$method($test->{bad});
    };
    ok ($@, "Setting $method to $test->{bad} raises an exception") and diag $@;
    is $opts->$method, $test->{good}, "Option still the $test->{good}";
}
  
foreach my $method (qw/logo cover/) {
    eval {
        $opts->$method($testfile);
    };
    ok !$@, "$method set to $testfile";
    is $opts->$method, $testfile, "$method set to $testfile";

    eval {
        $opts->$method('/lakl/laksdjf/alksdfl\alksdjf/');
    };
    ok $@, "Random filename for $method fails";
    eval {
        $opts->$method('prova.pdf');
    };
    ok !$@, "$method for prova.pdf is ok";
}

$opts->papersize('half-a4');
is $opts->tex_papersize, 'a5', "half-a4 papersize is fine";
$opts->papersize('');
is $opts->tex_papersize, '210mm:11in', "false papersize is fine";
$opts->papersize('a4');
is $opts->tex_papersize, 'a4', "tex papersize is fine";
$opts->papersize('15cm:10in');
is $opts->tex_papersize, '15cm:10in', "custom tex papersize is fine";

my $default = Text::Amuse::Compile::TemplateOptions->new;
foreach my $method (qw/mainfont sansfont monofont beamertheme beamercolortheme/) {
    my $default_method = "default_" . $method;
    is ($default->$method, $default->$default_method, "$method ok")
      and diag $default->$method;
}
