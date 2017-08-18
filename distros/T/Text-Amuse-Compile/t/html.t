#!perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use Text::Amuse;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Utils qw/read_file/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ':encoding(utf-8)';
binmode STDERR, ':encoding(utf-8)';

plan tests => 69;

my $file_no_toc = File::Spec->catfile(qw/t tex testing-no-toc.muse/);
my $file_with_toc = File::Spec->catfile(qw/t tex testing.muse/);
my $file_with_headers = File::Spec->catfile(qw/t tex headers.muse/);

test_file($file_no_toc, 0,
          qr{Testing <em>for</em> me},
          qr{Second author},
          qr{2014},
         );
test_file($file_with_toc, 1,
          qr{Testing <em>for</em> me},
          qr{Pallino <em>Pinco</em> 1},
          qr{2014},
          qr{àààà},
         );
test_file($file_with_headers, 0,
          qr{TitleT},
          qr{SubtitleT},
          qr{DateT},
          qr{SourceT},
          qr{NotesT},
         );

sub test_file {
    my ($file, $has_toc, @regexps) = @_;
    my $c = Text::Amuse::Compile->new(html => 1,
                                      extra => {
                                                mainfont => 'TeX Gyre Pagella',
                                                monofont => 'TeX Gyre Cursor',
                                                fontsize => 12
                                               },
                                      bare_html => 1);
    $c->compile($file);
    my ($full, $bare);
    if (ref($file)) {
        $full = File::Spec->catfile($file->{path}, $file->{name} . '.html');
        $bare = File::Spec->catfile($file->{path}, $file->{name} . '.bare.html');
    }
    else {
        $full = $file;
        $full =~ s/\.muse$/.html/;
        $bare = $file;
        $bare =~ s/\.muse$/.bare.html/;
    }
    my $error = 0;
    foreach my $outfile ([$full => 1],
                         [$bare => 0]) {
        my ($out, $is_full) = @$outfile;
        ok (-f $out, "$out produced");
        my $body = read_file($out);
        # print $body;
        unlike $body, qr/\[%/, "No opening template tokens found";
        unlike $body, qr/%\]/, "No closing template tokens found";
        if ($is_full) {
            foreach my $regexp (@regexps) {
                like($body, $regexp, "$regexp matches the body") or $error++;
            }
            foreach my $string ('TeX Gyre Pagella',
                                'TeX Gyre Cursor') {
                like $body, qr{\Q$string\E};
            }

            like($body, qr/div#page\s*\{\s*margin:20px;\s*padding:20px;\s*\}/s,
                 "Found the margins in the CSS");
            unlike($body, qr/\@font-face/, "\@font-face not found");
            unlike($body, qr{font-size:.*pt}, "Font side not set");
            like($body, qr/font-family:.*serif;/, "Found the serif font family");
            unlike($body, qr/\@page/, "\@page not found");
            unlike($body, qr/text-align: justify/, "No justify found in the body");
        }
        if (ref($file)) {
            my $index = 0;
            foreach my $f (@{$file->{files}}) {
                my $fullpath = File::Spec->catfile($file->{path},
                                                   $f . '.muse');
                my $muse = Text::Amuse->new(file => $fullpath);
                my $current = index($body, $muse->as_latex, $index);
                ok($current > $index, "$current is greater than $index") or $error++;;
                $index = $current;
            }
        }
        else {
            my $muse = Text::Amuse->new(file => $file);
            my $html = $muse->as_html;
            ok ((index($body, $html) > 0), "Found the body") or $error++;
            if ($is_full) {
                my $lang = $muse->language_code;
                like $body, qr{lang="$lang"}, "Found language $lang in $out";
            }
        }
        if ($has_toc) {
            like $body, qr{<div class="table-of-contents">}, "Found the ToC";
        }
        else {
            unlike $body, qr{<div class="table-of-contents">}, "ToC not found";
        }
    }
    unless ($ENV{NO_CLEANUP}) {
        foreach my $out ($full, $bare) {
            unlink $out unless $error;
        }
        my $status_file = $file;
        $status_file =~ s/\.muse$/.status/;
        unlink $status_file unless $error;
    }
}
