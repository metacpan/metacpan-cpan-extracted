#!/usr/bin/env perl

# This program is free software and is published under the same terms
# as Perl itself.

# written by Marco Pessotto <melmothx@gmail.com>

use strict;
use warnings;
use utf8;
# use FindBin qw/$Bin/;
# use lib "$Bin/../lib";
use Text::Amuse;
use Template::Tiny;
use Module::Load;
use Cwd;
use Getopt::Long;
use File::Basename;
use File::Temp;
use File::Spec::Functions qw/catfile/;
use File::Path qw/make_path/;
use Data::Dumper;
use Pod::Usage;
use Cwd;

# quick and dirty to get the stuff compiled

my $xtx = 0;
my $help;
my $template_dir;
my $gen_templates;

GetOptions (
            xtx => \$xtx,
            help => \$help,
            version => \$help,
            'tt-dir=s' => \$template_dir,
            templates => \$gen_templates
           );

if ($help) {
    pod2usage("Using Text::Amuse version " . $Text::Amuse::VERSION . "\n");
    exit;
}

=head1 NAME

muse-quick.pl -- format your muse document using Text::Amuse

=head1 SYNOPSIS

This script is B<DEPRECATED> and not maintained any more. Please look
to L<Text::Amuse::Compile> for a full-featured version.

  muse-quick.pl [-xtx] file.muse

This program uses Text::Amuse to produce usable output in HTML, EPUB,
LaTeX and PDF format.

The other options, beside --help, are:

=over 4

=item --xtx

which uses XeLaTeX instead of pdfLaTeX to generate the PDF output.

=item --tt-dir

directory where the templates should be looked up, with the following
hardcoded names: html.tt latex.tt css.tt

=item --templates

populate the tt-dir directory with the embedded templates.

=back

=head1 DEPENDENCIES

This script has additional dependencies (beside L<Text::Amuse> itself
and the core modules): L<Template::Tiny> and L<EBook::EPUB> (optional).

=cut

if ($gen_templates) {
    unless ($template_dir) {
        die "I need the tt-dir option for templates to work!\n";
    }
    my %templates = (
                     css => _embedded_css_template(),
                     latex => _embedded_latex_template(),
                     html => _embedded_html_template(),
                    );
    unless (-d $template_dir) {
        warn "Couldn't find $template_dir, creating it\n";
        make_path($template_dir);
    }
    foreach my $tmpl (keys %templates) {
        my $target = catfile($template_dir, $tmpl . ".tt");
        if (-f $target) {
            warn "$target exists, skipping...\n";
            next;
        }
        else {
            warn "Creating $target...\n";
        }
        open (my $fh, ">:encoding(utf-8)", $target)
          or die "Couldn't open $target: $!";
        my $body = $templates{$tmpl};
        print $fh $$body;
        close $fh;
    }
}

my $tt;

my $current_dir = getcwd();

foreach my $file (@ARGV) {
    print "Working on $file\n";
    # reset the dir
    chdir $current_dir or die "Cannot chdir into $current_dir";
    # reset tt
    $tt = Template::Tiny->new();
    unless ($file =~ m/\.muse$/ and -f $file) {
        warn "Skipping $file";
        next;
    }
    my ($name, $path, $suffix) = fileparse($file);
    if ($path) {
        chdir $path or die "Cannot chdir into $path\n";
        print "Working on $name in $path\n";
    }
    make_html($name);
    make_bare_html($name);
    make_latex($name);
    make_epub($name);
}

sub css_template {
    # this function returns a string, so dereference the result of the
    # embedded.
    if (my $tt = lookup_template("css.tt")) {
        return $$tt;
    }
    else {
        return ${_embedded_css_template()};
    }
}

sub html_template {
    if (my $tt = lookup_template("html.tt")) {
        return $tt;
    }
    else {
        return _embedded_html_template();
    }
}

sub latex_template {
    if (my $tt = lookup_template("latex.tt")) {
        return $tt;
    }
    else {
        return _embedded_latex_template();
    }
}

sub lookup_template {
    my $file = shift;
    if ($template_dir) {
        if (-d $template_dir) {
            my $template_file = catfile($template_dir, $file);
            if (-f $template_file) {
                my $slurped;
                open (my $fh, "<:encoding(utf-8)", $template_file)
                  or die "Couldn't open $template_file $!";
                {
                    local $/;
                    $slurped = <$fh>;
                }
                close $fh;
                # return a reference
                return \$slurped;
            }
        }
        # if we're still here, something went wrong
        warn "Couldn't find a template for $file in $template_dir!\n";
        warn "Using the embedded one!\n";
    }
    return;
}

sub _embedded_css_template {
    my $css = <<'EOF';

html,body {
	margin:0;
	padding:0;
	border: none;
 	background: transparent;
	font-family: serif;
	font-size: 10pt;
} 
div#page {
   margin:20px;
   padding:20px;
}
pre, code {
    font-family: Consolas, courier, monospace;
}
/* invisibles */
span.hiddenindex, span.commentmarker, .comment, span.tocprefix, #hitme {
    display: none
}

h1 { 
    font-size: 200%;
    margin: .67em 0
}
h2 { 
    font-size: 180%;
    margin: .75em 0
}
h3 { 
    font-size: 150%;
    margin: .83em 0
}
h4 { 
    font-size: 130%;
    margin: 1.12em 0
}
h5 { 
    font-size: 115%;
    margin: 1.5em 0
}
h6 { 
    font-size: 100%;
    margin: 0;
}

sup, sub {
    font-size: 8pt;
    line-height: 0;
}

/* invisibles */
span.hiddenindex, span.commentmarker, .comment, span.tocprefix, #hitme {
    display: none
}

.comment {
    background: rgb(255,255,158);
}

.verse {          
    margin: 24px 48px;
    overflow: auto;
} 

table, th, td {
    border: solid 1px black;
    border-collapse: collapse;
}
td, th {
    padding: 2px 5px;
}

hr {
    margin: 24px 0;
    color: #000;
    height: 1px;
    background-color: #000;
}

table {
    margin: 24px auto;
}

td, th { vertical-align: top; }
th {font-weight: bold;}

caption {
    caption-side:bottom;
}

img.embedimg {
    max-width:90%;
}
div.image, div.float_image_f {
    margin: 1em;
    text-align: center;
    padding: 3px;
    background-color: white;
}

div.float_image_r {
    float: right;
}

div.float_image_l {
    float: left;
}

div.float_image_f {
    clear: both;
    margin-left: auto;
    margin-right: auto;

}

.biblio p, .play p {
  margin-left: 1em;
  text-indent: -1em;
}

div.biblio, div.play {
  padding: 24px 0;
}

div.caption {
    padding-bottom: 1em;
}

div.center {
    text-align: center;
}

div.right {
    text-align: right;
}

div#tableofcontents{
    padding:20px;
}

#tableofcontents p {
    margin: 3px 1em;
    text-indent: -1em;
}

.toclevel1 {
	font-weight: bold;
	font-size:11pt
}	

.toclevel2 {
	font-weight: bold;
	font-size: 10pt;
}

.toclevel3 {
	font-weight: normal;
	font-size: 9pt;
}

.toclevel4 {
	font-weight: normal;
	font-size: 8pt;
}
EOF
    return \$css;
}

sub _bare_html_template {
    my $html = <<'EOF';

[%- IF doc.toc_as_html -%]
<div class="table-of-contents">
[% doc.toc_as_html %]
</div>
[%- END -%]

<div id="thework">
[% doc.as_html %]
</div>
EOF
    return \$html;
}


sub _embedded_html_template {
    my $html = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="Content-type" content="application/xhtml+xml; charset=UTF-8" />
  <title>[% doc.header_as_html.title %]</title>
  <style type="text/css">
 <!--/*--><![CDATA[/*><!--*/
[% css %]
  /*]]>*/-->
    </style>
</head>
<body>
 <div id="page">
  [% IF doc.header_as_html.author %]
  <h2>[% doc.header_as_html.author %]</h2>
  [% END %]
  <h1>[% doc.header_as_html.title %]</h1>

  [% IF doc.header_as_html.source %]
  [% doc.header_as_html.source %]
  [% END %]

  [% IF doc.header_as_html.notes %]
  [% doc.header_as_html.notes %]
  [% END %]

  [% IF doc.toc_as_html %]
  <div class="header">
  [% doc.toc_as_html %]
  </div>
  [% END %]

 <div id="thework">

[% doc.as_html %]

 </div>
</div>
</body>
</html>

EOF
    return \$html;
}

sub minimal_html_template {
    my $html = <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>[% title %]</title>
    <link href="stylesheet.css" type="text/css" rel="stylesheet" />
  </head>
  <body>
    <div id="page">
      [% text %]
    </div>
  </body>
</html>
EOF
    return \$html;
}


sub make_bare_html {
    my $file = shift;
    my $doc = Text::Amuse->new(file => $file);
    my $out = "";
    my $in = _bare_html_template();
    $tt->process($in, {
                       doc => $doc,
                      }, \$out);
    my $outfile = $file;
    $outfile =~ s/muse$/bare.html/;
    open (my $fh, ">:encoding(utf-8)", $outfile)
      or die "Couldn't open $outfile: $!";
    print $fh $out;
    close $fh;
    print "$outfile generated\n";
}


sub make_html {
    my $file = shift;
    my $doc = Text::Amuse->new(file => $file);
    my $out = "";
    my $in = html_template();
    $tt->process($in, {
                       doc => $doc,
                       css => css_template(),
                      }, \$out);
    my $outfile = $file;
    $outfile =~ s/muse$/html/;
    open (my $fh, ">:encoding(utf-8)", $outfile)
      or die "Couldn't open $outfile: $!";
    print $fh $out;
    close $fh;
    print "$outfile generated\n";
}

sub _embedded_latex_template {
    my $latex = <<'EOF';
\documentclass[DIV=9,fontsize=10pt,oneside,paper=a5]{[% IF doc.wants_toc %]scrbook[% ELSE %]scrartcl[% END %]}
[% IF xtx %]
\usepackage{fontspec}
\usepackage{polyglossia}
\setmainfont[Mapping=tex-text]{Charis SIL}
\setsansfont[Mapping=tex-text,Scale=MatchLowercase]{DejaVu Sans}
\setmonofont[Mapping=tex-text,Scale=MatchLowercase]{DejaVu Sans Mono}
\setmainlanguage{[% doc.language %]}
[% ELSE %]
\usepackage[[% doc.language %]]{babel}
\usepackage[utf8x]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{lmodern}
[% END %]
\usepackage{microtype} % you need an *updated* texlive 2012, but harmless
\usepackage{graphicx}
\usepackage{alltt}
\usepackage{verbatim}
% http://tex.stackexchange.com/questions/3033/forcing-linebreaks-in-url
\PassOptionsToPackage{hyphens}{url}\usepackage[hyperfootnotes=false,hidelinks,breaklinks=true]{hyperref}
\usepackage{bookmark}
\usepackage[stable]{footmisc}
\usepackage{enumerate}
\usepackage{tabularx}
\usepackage[normalem]{ulem}
\usepackage{wrapfig}
\usepackage{indentfirst}
% remove the numbering
\setcounter{secnumdepth}{-2}

% remove labels from the captions
\renewcommand*{\captionformat}{}
\renewcommand*{\figureformat}{}
\renewcommand*{\tableformat}{}
\KOMAoption{captions}{belowfigure,nooneline}
\addtokomafont{caption}{\centering}





% avoid breakage on multiple <br><br> and avoid the next [] to be eaten
\newcommand*{\forcelinebreak}{\strut\\{}}

\newcommand*{\hairline}{%
  \bigskip%
  \noindent \hrulefill%
  \bigskip%
}

% reverse indentation for biblio and play

\newenvironment*{amusebiblio}{
  \leftskip=\parindent
  \parindent=-\parindent
  \bigskip
  \indent
}{\bigskip}

\newenvironment*{amuseplay}{
  \leftskip=\parindent
  \parindent=-\parindent
  \bigskip
  \indent
}{\bigskip}

\newcommand*{\Slash}{\slash\hspace{0pt}}

% global style
\pagestyle{plain}
\addtokomafont{disposition}{\rmfamily}
% forbid widows/orphans
\clubpenalty=10000
\widowpenalty=10000
\frenchspacing
\sloppy

\title{[% doc.header_as_latex.title %]}
\date{[% doc.header_as_latex.date %]}
\author{[% doc.header_as_latex.author %]}
\begin{document}
\maketitle

[% IF doc.wants_toc %]

\tableofcontents
\cleardoublepage

[% END %]

[% doc.as_latex %]

\cleardoublepage

\thispagestyle{empty}
\strut
\vfill

\begin{center}

[% doc.header_as_latex.source %]

[% doc.header_as_latex.notes %]

\end{center}

\end{document}

EOF
    return \$latex;
}

sub make_latex {
    my $file = shift;
    my $doc = Text::Amuse->new(file => $file);
    my $in = latex_template();
    my $out = "";
    $tt->process($in, { doc => $doc, xtx => $xtx }, \$out);
    my $outfile = $file;
    $outfile =~ s/muse$/tex/;
    open (my $fh, ">:encoding(utf-8)", $outfile)
      or die "Couldn't open $outfile: $!";
    print $fh $out;
    close $fh;
    print "$outfile  generated\n";
    my $exec = "pdflatex";
    if ($xtx) {
        $exec = "xelatex";
    }
    my $base = $file;
    $base =~ s/muse$//;
    cleanup($base);
    # TODO unclear if 3 time is enough, maybe check the toc length?
    for (1..3) {
        my $pid = open(KID, "-|");
        defined $pid or die "Can't fork: $!";

        # parent swallows the output
        if ($pid) {
            my $shitout;
            while (<KID>) {
                my $line = $_;
                if ($line =~ m/^[!#]/) {
                    $shitout++;
                }
                if ($shitout) {
                    print $line;
                }
            }
            close KID or warn "Compilation failed\n";
            my $exit_code = $? >> 8;
            if ($exit_code != 0) {
                warn "$exec compilation failed with exit code $exit_code\n";
                if (-f $base . 'log') {
                    # if we have a .log file, this means something was
                    # produced.
                    die "Bailing out!";
                }
                else {
                    warn "Skipping PDF generation\n";
                    return;
                }
            }
        }
        else {
            open(STDERR, ">&STDOUT");
            exec($exec, '-interaction=nonstopmode', $outfile)
              || die "Can't exec $exec $!";
        }
    }
    print "${base}pdf  generated\n";
    cleanup($base);
}

sub cleanup {
    my $base = shift;
    return unless $base;
    for (qw/aux toc tuc/) {
        my $remove = $base . $_;
        if (-f $remove) {
            unlink $remove;
        }
    }
}

sub make_epub {
    my $file = shift;
    eval {
        load EBook::EPUB;
    };
    if ($@) {
        warn "Couldn't load EBook::EPUB, skipping EPUB generation\n";
        return;
    }
    my ($name, $path, $suffix) = fileparse($file, ".muse");
    my $cwd = getcwd;
    my $epubname = "${name}.epub";
    if ($path) {
        chdir $path or die "Couldn't chdir into $path $!";
    }
    my $epub = EBook::EPUB->new;
    my $text = Text::Amuse->new(file => $file);

    my @toc = $text->raw_html_toc;
    my @pieces = $text->as_splat_html;
    my $missing = scalar(@pieces) - scalar(@toc);
    # this shouldn't happen

    if ($missing > 1 or $missing < 0) {
        print Dumper(\@pieces), Dumper(\@toc);
        die "This shouldn't happen: missing pieces: $missing";
    }
    if ($missing == 1) {
        unshift @toc, {
                       index => 0,
                       level => 0,
                       string => "start body",
                      };
    }


    my $tempdir = File::Temp->newdir();
    $epub->add_stylesheet("stylesheet.css" => css_template());

    my $titlepage;
    my $header = $text->header_as_html;
    if (my $t = $header->{title}) {
        $epub->add_title(_remove_html_tags($t));
        $titlepage .= "<h1>$t</h1>\n";
    }
    else {
        $epub->add_title(_remove_html_tags($t) || "No title");
    }
    if (my $author = $header->{author}) {
        $epub->add_author(_remove_html_tags($author));
        $titlepage .= "<h2>$author</h2>\n";
    }
    if ($header->{date}) {
        if ($header->{date} =~ m/([0-9]{4})/) {
            $epub->add_date($1);
            $titlepage .= "<h3>$header->{date}</h3>"
        }
    }
    $epub->add_language($text->language_code);
    if (my $source = $header->{source}) {
        $epub->add_source($source);
        $titlepage .= "<p>$source</p>";
    }
    if (my $notes = $header->{notes}) {
        $epub->add_description($notes);
        $titlepage .= "<p>$notes</p>";
    }
    my $in = minimal_html_template;
    my $out = "";
    $tt->process($in, {
                       title => _remove_html_tags($header->{title}),
                       text => $titlepage
                      }, \$out);
    my $tpid = $epub->add_xhtml("titlepage.xhtml", $out);
    my $order = 0;
    $epub->add_navpoint(label => "titlepage",
                        id => $tpid,
                        content => "titlepage.xhtml",
                        play_order => ++$order);

    foreach my $fi (@pieces) {
        my $index = shift(@toc);
        my $xhtml = "";
        # print Dumper($index);
        my $filename = "piece" . $index->{index} . '.xhtml';
        my $title = "*" x $index->{level} . " " . $index->{string};
        $tt->process($in, { title => _remove_html_tags($title),
                            text => $fi },
                     \$xhtml);
        my $id = $epub->add_xhtml($filename, $xhtml);
        $epub->add_navpoint(label => _clean_html($index->{string}),
                            content => $filename,
                            id => $id,
                            play_order => ++$order);
    }
    foreach my $att ($text->attachments) {
        die "$att doesn't exist!" unless -f $att;
        my $mime; 
        if ($att =~ m/\.jpe?g$/) {
            $mime = "image/jpeg";
        }
        elsif ($att =~ m/\.png$/) {
            $mime = "image/png";
        }
        else {
            die "Unrecognized attachment $att!";
        }
        $epub->copy_file($att, $att, $mime);
    }
    $epub->pack_zip($epubname);
    print "$epubname generated\n";
    chdir $cwd or die "Couldn't chdir into $cwd: $!";
}

sub _remove_html_tags {
    my $string = shift;
    return "" unless defined $string;
    $string =~ s/<.+?>//g;
    return $string;
}

sub _clean_html {
    my ($string) = @_;
    return "" unless defined $string;
    $string =~ s/<.+?>//g;
    $string =~ s/&lt;/</g;
    $string =~ s/&gt;/>/g;
    $string =~ s/&quot;/"/g;
    $string =~ s/&#x27;/'/g;
    $string =~ s/&amp;/&/g;
    return $string;
}
