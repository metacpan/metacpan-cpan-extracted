#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More 0.96;
use File::Spec::Functions qw(catfile);
use File::Basename qw(basename);
use Text::Markup::Cmd;
use Carp;

# Need to have at least one test outside subtests, in case no subtests are run
# at all. So it might as well be this.
BEGIN { use_ok 'Text::Markup' or die; }

sub slurp($) {
    my ($file) = @_;
    open my $fh, '<:raw', $file or die "Cannot open $file: $!\n";
    local $/;
    return <$fh>;
}

my %expected_for = (
    mediawiki => sub {
        my $html = slurp catfile('t', 'html', "mediawiki.html");
        $html =~ s/ö/CGI::escapeHTML(do { use utf8; 'ö' })/e
            if eval { CGI->VERSION >= 4.11 && CGI->VERSION < 4.14 };
        return $html;
    },
    asciidoc => sub {
        my $html = slurp catfile('t', 'html', "asciidoc.html");
        $html =~ s/ü/\\xFC/ if WIN32;
        return $html;
    },
);

my %parsed_filter_for = (
    rest => sub {
        # docutils space character before closing tag of XML declaration in Nov
        # 2022 (https://github.com/docutils/docutils/commit/f93b895), so remove
        # it when we run tests against older versions.
        $_[0] =~ s/ \?>/\?>/;
    },
);

my @loaded = Text::Markup->formats;
my %regex_for = Text::Markup->format_matchers;

while (my $data = <DATA>) {
    next if $data =~ /^#/;
    chomp $data;
    my ($name, $format, $module, $req, @exts) = split /,/ => $data;
    subtest "Testing $name format" => sub {
        do {
            local $@;
            eval "use $req; 1;";
            if ($@) {
                die $@ if $ENV{TEXT_MARKUP_TEST_ALL}
                    && !$ENV{"TEXT_MARKUP_SKIP_\U$name"};
                plan skip_all => "$req not loading: $@";
            }
        } if $req;

        plan tests => @exts + 7;
        use_ok $module or next;

        if ($format ne 'none') { # Not loaded yet; tested below.
            is_deeply [Text::Markup->formats], \@loaded,
                "$format should be loaded";
        }

        my $parser = new_ok 'Text::Markup';
        for my $ext (@exts) {
            is $parser->guess_format("foo.$ext"), $format,
                "Should guess that .$ext extension is $format";
        }

        # Parse the markup.
        my $html = $parser->parse(
            file   => catfile('t', 'markups', "$name.txt"),
            format => $format,
        );
        if (my $f = $parsed_filter_for{$name}) {
           $f->($html)
        }

        # Load the expected output.
        my $loader = $expected_for{$name} ||= sub {
            slurp catfile('t', 'html', "$name.html")
        };
        my $expect = $loader->();

        # They should be the same!
        is $html, $expect, "Parse $name file";

        is $parser->parse(
            file   => catfile('t', 'empty.txt'),
            format => $format,
        ), undef, "Parse empty $name file";

        # Try recognizing in plain text.
        is $parser->guess_format('hello.txt'), undef,
            'guess_format should not match .txt';
        $module->import(qr/txt/);
        is $parser->guess_format('hello.txt'), $format,
            'Now guess_format should match .txt';
        $module->import($regex_for{$format});

        if ($format eq 'none') {
            @loaded = sort (@loaded, 'none');
            is_deeply [Text::Markup->formats], \@loaded,
                "$format should be loaded";
        }
    }
}

done_testing;

__DATA__
# Name,Format,Format Module,Required Module,extensions
markdown,markdown,Text::Markup::Markdown,Text::Markdown::Discount 0.13,md,mkdn,mkd,mdown,markdown
commonmark,markdown,Text::Markup::CommonMark,CommonMark 0.290000,md,mkdn,mkd,mdown,markdown
html,html,Text::Markup::HTML,,html,htm,xhtml,xhtm
pod,pod,Text::Markup::Pod,Pod::Simple::XHTML 3.15,pod,pm,pl
trac,trac,Text::Markup::Trac,Text::Trac 0.10,trac,trc
textile,textile,Text::Markup::Textile,Text::Textile 2.10,textile
mediawiki,mediawiki,Text::Markup::Mediawiki,Text::MediawikiFormat 1.0,wiki,mwiki,mediawiki
multimarkdown,multimarkdown,Text::Markup::Multimarkdown,Text::MultiMarkdown 1.000033,mmd,mmkdn,mmkd,mmdown,mmarkdown
rest,rest,Text::Markup::Rest,Text::Markup::Rest,rest,rst
asciidoc,asciidoc,Text::Markup::Asciidoc,Text::Markup::Asciidoc,asciidoc,asc,adoc
asciidoctor,asciidoc,Text::Markup::Asciidoctor,Text::Markup::Asciidoctor,asciidoc,asc,adoc
bbcode,bbcode,Text::Markup::Bbcode,Parse::BBCode,bbcode,bb
creole,creole,Text::Markup::Creole,Text::WikiCreole,creole
none,none,Text::Markup::None,,
