#!/usr/bin/env perl
# Copyright (c) 2014, 2015 Yon <anaseto@bardinflor.perso.aquilenet.fr>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Main Processing
#
package Text::Frundis::Processing;

use utf8;
use v5.12;
use strict;
use warnings;
use open qw(:std :utf8);

use Carp;
use Encode;
use File::Spec::Functions;
use File::Copy;
use File::Basename;
use URI;
use Text::Frundis::Object qw(@Arg);
use Text::Frundis::PerlEval;

# Global Constants and Variables [[[
our @Arg;

my %Opts;
my @FrundisINC;
my %FileParse;

# Regexes
my %Rx;

# Phase
my $Process = 0;    # whether in Processing Phase.

# State information
my %Count;            # counters
my %Flag;             # state flags
my %Filters;          # filters for "Bf -t"
my %Macro;            # user defined macros with `.#de' macro
my %BfMacro;          # "Bf" macro state
my %DeMacro;          # "#de" macro state
my %UserMacroCall;    # user macro call state
my %Scope;            # scope state information
my %State;            # miscellaneous state information

# Permissions
my @Phrasing          = qw(Bm Em Sm Bf Ef Ft Lk Sx Im);
my @ProcessDirectives = ("#fl", "#if", "#;", "#de", "#.", "#dv");
my %AllowedInBl       = map { $_ => 1 } qw(Bl It El If Ta), @Phrasing,
  @ProcessDirectives;
my %HtmlPhrasing = map { $_ => 1 }
  qw(a abbr area audio b bdi bdo br button canvas cite code data datalist del
  dfn em embed i iframe img input ins kbd keygen label link map mark math
  meta meter noscript object output progress q ruby s samp script select
  small span strong sub sup svg template textarea time u var video wbr text);
my %HtmlContainingFlow = map { $_ => 1 }
  qw(article blockquote div header figure footer main pre section);

# "pre" is an exception in that it can be useful as a "Bd", but can contain
# only phrasing elements

my %AllowedParam;
my %AllowedFlag;

# Macro handlers
my %BuiltinMacroHandler = (
    Bd    => \&handle_Bd_macro,
    Bf    => \&handle_Bf_macro,
    Bl    => \&handle_Bl_macro,
    Bd    => \&handle_Bd_macro,
    Bm    => \&handle_Bm_macro,
    Pt    => \&handle_header_macro,
    Ch    => \&handle_header_macro,
    Sh    => \&handle_header_macro,
    Ss    => \&handle_header_macro,
    P     => \&handle_P_macro,
    D     => \&handle_P_macro,
    Ed    => \&handle_Ed_macro,
    Ef    => \&handle_Ef_macro,
    El    => \&handle_El_macro,
    Em    => \&handle_Em_macro,
    Ft    => \&handle_Ft_macro,
    If    => \&handle_If_macro,
    Im    => \&handle_Im_macro,
    It    => \&handle_It_macro,
    Lk    => \&handle_Lk_macro,
    Sm    => \&handle_Sm_macro,
    Sx    => \&handle_Sx_macro,
    Ta    => \&handle_Ta_macro,
    Tc    => \&handle_Tc_macro,
    X     => \&handle_X_macro,
    '#de' => \&handle_de_macro,
    '#dv' => \&handle_dv_macro,
    '#fl' => \&handle_fl_macro,
    '#.'  => \&handle_end_macro,
    '#;'  => \&handle_if_end_macro,
    '#if' => \&handle_if_macro,
);

my %BlockEnd = (
    '#de' => '#.',
    '#if' => '#;',
    Bd    => 'Ed',
    Bl    => 'El',
    Bm    => 'Em',
);

# Information collecting variables
my %loXstack;
my %InfosFlag;
my %ID;       # label/id in Sm and Bd
my %Param;    # Global Parameters
my @Image;    # For collecting image names to copy images in epub dir
my %Xmtag;
my %Xdtag;

# Input/output variables
my $FH;            # global main source filehandle
our $File;         # current input file
my $SourceText;    # main source text

my %Lang_mini = (  # [[[
    af => "afrikaans",
    bg => "bulgarian",
    br => "breton",
    ca => "catalan",
    cs => "czech",
    cy => "welsh",
    da => "danish",
    de => "german",
    el => "greek",
    en => "english",
    eo => "esperanto",
    es => "spanish",
    et => "estonian",
    eu => "basque",
    fi => "finnish",
    fr => "french",
    ga => "irish",
    gd => "scottish",
    gl => "galician",
    he => "hebrew",
    hr => "croatian",
    hu => "magyar",
    ia => "interlingua",
    is => "icelandic",
    it => "italian",
    la => "latin",
    nl => "dutch",
    no => "norsk",
    pl => "polish",
    pt => "portuges",
    ro => "romanian",
    ru => "russian",
    se => "samin",
    sk => "slovak",
    sl => "slovene",
    sr => "serbian",
    sv => "swedish",
    tr => "turkish",
    uk => "ukrainian",
);    # ]]]

my %Lang_babel = %Lang_mini;
$Lang_babel{de} = "ngerman";
$Lang_babel{fr} = "frenchb";

# some traductions of "Index"
my %IndexTraductions = (
    de => "Index",
    en => "Index",
    eo => "Indekso",
    es => "Índice",
    fr => "Index",
);

# Escapes [[[

my %Latex_escapes = (
    '{'      => '\{',
    '}'      => '\}',
    '['      => '[',
    ']'      => ']',
    '%'      => '\%',
    '&'      => '\&',
    '$'      => '\$',
    '#'      => '\#',
    '_'      => '\_',
    '^'      => '\^{}',
    "\\"     => '\textbackslash{}',
    '~'      => '\~{}',
    "\x{a0}" => '~',
);

my %Xhtml_escapes = (
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    '"' => '&quot;',
    "'" => '&apos;',
);

my %Frundis_escapes = (
    '\e' => "\\",
    '\&' => '',
    '\~' => "\x{a0}",
);

# ]]]

# Frundis main object (for exposed api, mainly)
my $Self;

# ]]]

# Collecting and Processing [[[

sub init_global_variables {

    diag_fatal("invalid format argument:$Opts{target_format}")
      unless $Opts{target_format} =~ /^(?:latex|xhtml|epub)$/;

    if ($Opts{target_format} eq "xhtml") {
        $Opts{standalone} = 1
          unless $Opts{all_in_one_file};   # Always do -s unless -a is specified
    }

    %Rx = (
        xhtml_or_epub => qr{\b(?:xhtml|epub)\b},
        format        => qr{\b$Opts{target_format}\b},
        valid_format  => qr{^(?:epub|latex|xhtml)(?:,(?:epub|latex|xhtml))*$},
    );

    %AllowedParam = map { $_ => 1 }
      qw(dmark document-author document-date document-title encoding
      epub-cover epub-css epub-metadata epub-subject epub-uuid epub-version
      lang latex-preamble nbsp title-page xhtml-bottom xhtml-css
      xhtml-index xhtml-top xhtml5);
    %AllowedFlag = map { $_ => 1 } qw(ns fr-nbsp-auto);

    $Self = Text::Frundis::Object->new(
        {
            allowed_params => \%AllowedParam,
            allowed_flags  => \%AllowedFlag,
            ID             => \%ID,
            file           => \$File,
            filters        => \%Filters,
            flags          => \%Flag,
            format         => $Opts{target_format},    # it doesn't change
            loX            => {},
            loXstack       => \%loXstack,
            macros         => \%Macro,
            params         => \%Param,
            process        => \$Process,
            state          => \%State,
            vars           => {},
            ivars          => {},
        }
    );

    %FileParse = ();

    if ($ENV{FRUNDISLIB}) {
        if ($^O eq "MSWin32") {
            @FrundisINC = split /;/, $ENV{FRUNDISLIB};
        }
        else {
            @FrundisINC = split /:/, $ENV{FRUNDISLIB};
        }
    }
}

sub process_frundis_source {
    my ($opts) = @_;
    %Opts = %$opts;

    open(my $stdout_copy, '>&', select);
    open(my $stderr_copy, '>&', STDERR);
    local *STDOUT;
    local *STDERR;
    open(STDOUT, '>&', $stdout_copy) or die diag_fatal("redirecting stdout:$!");
    open(STDERR, '>&', $stderr_copy) or die diag_fatal("redirecting stderr:$!");

    if ($Opts{input_file}) {

        diag_warning("useless use of 'input_string' parameter")
          if $Opts{input_string};

        # read from a file
        $File = $Opts{input_file};
        open($FH, '< :bytes', $File) or diag_fatal("$File:$!");
        {
            local $/;
            $SourceText = <$FH>;
            close $FH;
        }
    }
    elsif ($Opts{input_string}) {
        $File       = "string";
        $SourceText = Encode::encode_utf8($Opts{input_string});
    }
    else {
        # read from stdin
        $File = "stdin";
        {
            local $/;
            binmode STDIN, ":bytes";
            $SourceText = <STDIN>;
            binmode STDIN, ":encoding(utf-8)";
        }
    }

    init_global_variables();

    # FIRST PASS : Collecting Phase
    init_state();
    init_infos();
    open($FH, '<', \$SourceText) or diag_fatal($!);

    # For testing purposes, redirect stderr to output file if requested
    if (
        $Opts{redirect_stderr}
        and (  $Opts{all_in_one_file} && $Opts{target_format} eq "xhtml"
            or $Opts{target_format} eq "latex")
      )
    {
        open(STDERR, '>', $Opts{output_file}) or diag_fatal($!);
    }
    $FileParse{$File} = parse_file($FH);
    close $FH;
    collect_source_infos($FileParse{$File});

    # SECOND PASS : Processing Phase
    init_state();
    if ($Opts{target_format} eq "latex") {
        open($FH, '<', \$SourceText) or diag_fatal($!);
        if (defined $Opts{output_file}) {
            redirect_stds();
        }

        if ($Opts{standalone}) {
            latex_document_begin($FH);
            process_whole_source();
            latex_document_end();
        }
        else {
            process_whole_source();
        }
    }
    elsif ($Opts{target_format} eq "xhtml") {
        open($FH, '<', \$SourceText) or diag_fatal($!);
        if (defined $Opts{output_file} and $Opts{all_in_one_file}) {
            redirect_stds();
        }
        elsif (defined $Opts{output_file}) {
            unless (-d $Opts{output_file}) {
                mkdir $Opts{output_file} or diag_fatal("$Opts{output_file}:$!");
            }
            open(STDOUT, '>', catfile($Opts{output_file}, "index.html"))
              or diag_fatal("$Opts{output_file}:$!");
        }

        if ($Opts{standalone}) {
            my $title = $Param{'document-title'} // "";
            xhtml_document_header($title);
            xhtml_titlepage();
            unless ($Opts{all_in_one_file}) {
                if ($Param{'xhtml-index'} eq "full") {
                    xhtml_toc("xhtml");
                }
                elsif ($Param{'xhtml-index'} eq "summary") {
                    xhtml_toc("xhtml", { summary => 1 });
                }
            }
            process_whole_source();
            if ($State{_xhtml_navigation_text}) {

                # bottom navigation bar in last file
                print $State{_xhtml_navigation_text};
            }
            xhtml_document_footer();
        }
        else {
            process_whole_source();
        }
    }
    elsif ($Opts{target_format} eq "epub") {
        unless (-d $Opts{output_file}) {
            mkdir $Opts{output_file} or diag_fatal("$Opts{output_file}:$!");
        }
        my $EPUB = catdir($Opts{output_file}, "EPUB");
        unless (-d $EPUB) {
            mkdir $EPUB or diag_fatal("$EPUB:$!");
        }
        my $META_INF = catdir($Opts{output_file}, "META-INF");
        unless (-d $META_INF) {
            mkdir $META_INF
              or diag_fatal("$META_INF:$!");
        }
        epub_gen();
        open($FH, '<', \$SourceText) or diag_fatal($!);
        my $index_xhtml = catfile($EPUB, "index.xhtml");
        open(STDOUT, '>', $index_xhtml)
          or diag_fatal("$index_xhtml:$!");
        my $title = $Param{'document-title'} // "";
        xhtml_document_header($title);
        xhtml_titlepage();
        process_whole_source();
        xhtml_document_footer();
    }

}

sub redirect_stds {    # [[[
    my $mode = $Opts{redirect_stderr} ? '>>' : '>';
    open(STDOUT, $mode, $Opts{output_file})
      or diag_fatal("$Opts{output_file}:$!");
    if ($Opts{redirect_stderr}) {
        open(STDERR, '>&', STDOUT) or diag_fatal($!);
    }
}    # ]]]

# ]]]

################################################################################
# Main program source process functions

sub collect_source_infos {    # [[[
    my $parse = shift;

    $Process = 0;

    BLOCK: foreach my $block (@$parse) {

        if ($Scope{de} and not(@$block == 3 and $block->[0] eq "#.")) {
            unless ($DeMacro{ignore}) {
                push @{ $Macro{ $DeMacro{name} }{parse} }, $block;
            }
            next BLOCK;
        }
        elsif ($Count{if_ignore}
            and not(@$block == 3 and $block->[0] =~ /^(?:#;|#if)$/))
        {
            next BLOCK;
        }

        next unless @$block == 3;

        $State{macro} = $block->[0];
        $State{lnum}  = $block->[2];
        @Arg = map { interpolate_vars($_) } @{ $block->[1] };

        collect_macro_infos();
    }
}    # ]]]

sub collect_macro_infos {    # [[[
    my $macro = $State{macro};
    if ($Macro{$macro}) { handle_user_macro(); }
    elsif (exists $BuiltinMacroHandler{$macro}) {
        $BuiltinMacroHandler{$macro}->();
    }
}    # ]]]

sub process_whole_source {    # [[[
    process_source($FileParse{$File});
    $State{macro} = "End Of File";
    close_unclosed_blocks("Bm");
    close_unclosed_blocks("Bl");
    close_unclosed_blocks("Bd");
    test_for_unclosed_block("#if");
    test_for_unclosed_format_block();
    test_for_unclosed_de();
    $State{wanted_space} = 1 if $State{text} and $State{wants_space};
    close_eventual_final_paragraph();
    diag_warning(
        "ns flag set to 1 at end of file, perhaps you forgot a '.#fl ns 0'")
      if $Flag{ns};
}    # ]]]

sub parse_file {    # [[[
    my $fh = shift;

    my $text      = "";    # to collect consecutives lines of text
    my $text_lnum = 0;     # text position
    my @parse;

    LINE: while (<$fh>) {
        $State{lnum} = $.;
        diag_warning("trailing space") if /\h$/;
        s/\\".*//;         # comments
        next LINE if /^\.\s*$/;    # comment line

        if (/^\.\s*(.*)/) {
            my $macro_line = $1;

            chomp $macro_line;
            while ($macro_line =~ m{\\$}) {

                # prolonged line
                $macro_line =~ s/\\$/ /;
                $macro_line .= <$fh>;
                chomp $macro_line;
            }

            my ($macro, $args) = parse_macro_line($macro_line);

            unless (defined $macro) {
                diag_error(
                    "a macro line should start by the name of a valid macro");
                next LINE;
            }

            if ($text) {
                push @parse, [ $text, $text_lnum ];
                $text      = "";
                $text_lnum = 0;
            }

            push @parse, [ $macro, $args, $State{lnum} ];
        }
        else {
            $text .= $_;
            unless ($text_lnum) {
                $text_lnum = $State{lnum};
            }
        }
    }

    if ($text) {
        push @parse, [ $text, $text_lnum ];
    }

    # A block is [ $text, $lnum ] or [ $macro, $args, $lnum ].
    return \@parse;
}    # ]]]

sub process_source {    # [[[
    my $parse = shift;

    $Process = 1;

    BLOCK: foreach my $block (@$parse) {

        if ($Scope{de} and not(@$block == 3 and $block->[0] eq "#.")) {
            unless ($DeMacro{ignore}) {
                push @{ $Macro{ $DeMacro{name} }{parse} }, $block;
            }
            next BLOCK;
        }
        elsif ($Count{if_ignore}
            and not(@$block == 3 and $block->[0] =~ /^(?:#;|#if)$/))
        {
            next BLOCK;
        }

        if (@$block == 3) {
            $State{macro} = $block->[0];
            $State{lnum}  = $block->[2];
            @Arg = map { interpolate_vars($_) } @{ $block->[1] };
            $State{wanted_space} = $State{text} ? $State{wants_space} : 0;
            process_macro();
        }
        else {
            unless ($Flag{_ignore_text}) {
                $State{lnum} = $block->[1];
                if ($Flag{_verbatim}) {
                    $State{text} .=
                      escape_verbatim(interpolate_vars($block->[0]));
                }
                else {
                    $State{text} .= escape_text(interpolate_vars($block->[0]));
                }
            }
        }
    }

    return;
}    # ]]]

sub process_macro {    # [[[
    my $macro = $State{macro};
    if ((not $Macro{$macro}) and test_if_not_allowed_macro($macro)) {
        return;
    }
    if ($Macro{$macro}) { handle_user_macro(); }
    elsif (exists $BuiltinMacroHandler{$macro}) {
        $BuiltinMacroHandler{$macro}->();
    }
    else {
        diag_error(
            "undefined macro `.$macro' (at least for '$Opts{target_format}' output format)"
        );
    }
}    # ]]]

################################################################################
# Macro specific functions, in alphabetic order (almost).

sub handle_Bd_macro {    # [[[
    my %opts = parse_options({ t => "s", id => "s" });

    $opts{id} //= "";
    $opts{t}  //= "";

    $opts{id} = escape_text($opts{id});
    unless ($Process) {
        $ID{ $opts{id} } = xhtml_gen_href("", $opts{id}) if $opts{id};
        return;
    }
    if ($opts{id} =~ /\s/) {
        diag_error("id identifier should not contain spaces");
    }

    if (@Arg) {
        diag_error("`.Bd' macro has useless arguments");
    }

    close_unclosed_blocks("Bm");
    close_unclosed_blocks("Bl");

    my $last = $opts{t} ? $Xdtag{ $opts{t} }{cmd} : 0;

    if (@{ $Scope{Bd} } and $Scope{Bd}->[0]->{t} eq "literal") {
        diag_error(
            "display block of type '$Scope{Bd}->[0]->{t}' cannot contain nested blocks"
        );
        return;
    }
    else {
        close_eventual_final_paragraph($last);
    }

    scope_stack_push("Bd", $opts{t}, $opts{id});

    if ($opts{t} eq "literal") {
        $Flag{_fr_nbsp_auto} = $Flag{'fr-nbsp-auto'};
        $Flag{'fr-nbsp-auto'} = 0;
        if ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
            print enclose_begin("pre", { id => $opts{id} }), "\n";
        }
        elsif ($Opts{target_format} eq "latex") {
            print enclose_begin("verbatim", { env => 1, id => $opts{id} }),
              "\n";
            $Flag{_verbatim} = 1;
        }
    }
    else {
        if ($opts{t}) {
            diag_error("`.Bd' invocation: unknown tag")
              unless defined $Xdtag{ $opts{t} };
            my $cmd = $Xdtag{ $opts{t} }{cmd};
            if ($cmd) {
                print enclose_begin(
                    $cmd,
                    { class => $opts{t}, env => 1, id => $opts{id} }
                  ),
                  "\n";
            }
            elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
                print enclose_begin(
                    "div",
                    { class => $opts{t}, id => $opts{id} }
                  ),
                  "\n";
            }
        }
        elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
            print enclose_begin("div", { id => $opts{id} }), "\n";
        }
    }
    if ($opts{id}) {
        print "\\hypertarget{$opts{id}}{}\n" if $Opts{target_format} eq "latex";
    }

    $State{wants_space} = 0;
    $Scope{paragraph}   = 0;
}    # ]]]

sub handle_Bf_macro {    # [[[
    return unless $Process;

    my %opts = parse_options(
        {
            f      => "s",
            ns     => "b",
            filter => "s",
            t      => "s",
        }
    );
    $Scope{format} = $opts{f} // "";
    $BfMacro{begin_lnum} = $State{lnum};
    $BfMacro{begin_file} =
      $UserMacroCall{depth} > 0 ? $UserMacroCall{file} : $File;
    $BfMacro{in_macro} = $UserMacroCall{depth} > 0 ? 1 : 0;
    $Flag{_verbatim} = 1;
    if (defined $opts{filter}) {
        $opts{filter} = escape_verbatim($opts{filter});
    }
    $BfMacro{filter}     = $opts{filter};
    $BfMacro{filter_tag} = $opts{t};

    unless (defined $opts{f} or $opts{t}) {
        diag_error(
            "`.Bf' macro:you should specify a -f option or -t option at least");
        $Flag{_ignore_text} = 1;
        return;
    }
    if ($opts{t}) {
        unless (defined $Filters{ $opts{t} }) {
            diag_error("undefined filter tag '$opts{t}' in `.Bf' invocation");
            $Flag{_ignore_text} = 1;
            return;
        }
        if (defined $BfMacro{filter}) {
            diag_error("-t and -filter should not be used simultaneously");
        }
        $BfMacro{filter} = $Filters{ $opts{t} }{shell};
    }

    if (defined $opts{f} and $opts{f} !~ /$Rx{format}/) {
        $Flag{_ignore_text} = 1;
    }
    elsif ($State{text}) {
        phrasing_macro_begin($opts{ns});
    }

    $State{wants_space} = 0;
}    # ]]]

sub handle_Bl_macro {    # [[[
    if ($Process) {
        handle_Bl_macro_process();
    }
    else {
        handle_Bl_macro_infos();
    }
}    # ]]]

sub handle_Bl_macro_infos {    # [[[
    my %opts = parse_options(
        {
            t       => "s",
            columns => "s",
        }
    );

    if (defined $opts{t} and $opts{t} eq "verse") {
        $InfosFlag{use_verse} = 1;
        my $title = escape_text(args_to_text(\@Arg));
        return unless $title;
        $Count{poem}++;
        loX_entry_infos(
            {
                title       => $title,
                count       => $Count{poem},
                class       => "lop",
                href_prefix => "poem",
            }
        );
    }
    elsif (defined $opts{t} and $opts{t} eq "table") {

        # Self->{lot}
        my $title = escape_text(args_to_text(\@Arg));
        return unless $title;
        $Count{table}++;
        loX_entry_infos(
            {
                title       => $title,
                count       => $Count{table},
                class       => "lot",
                href_prefix => "tbl",
            }
        );
    }
}    # ]]]

sub handle_Bl_macro_process {    # [[[
    return unless $Process;
    close_unclosed_blocks("Bm");

    my %opts = parse_options(
        {
            t       => "s",
            columns => "s",
        }
    );

    $opts{t} //= "item";

    unless ($opts{t} =~ /^(?:item|enum|desc|verse|table)$/) {
        diag_error("invalid `-t' argument to `.Bl' macro: $opts{t}");
        return;
    }

    if (@{ $Scope{Bl} }) {
        if ($Scope{Bl}->[0]->{t} !~ /^(?:item|enum)$/) {
            diag_error(
                "`.Bl' macro of type '$Scope{Bl}->[0]->{t}' cannot be nested");
            return;
        }
        if ($State{text}) {
            give_wanted_space();
            flush_normal_text();
        }
    }
    else {
        close_eventual_final_paragraph(1);
    }

    scope_stack_push("Bl", $opts{t});

    if ($opts{t} eq "verse") {
        handle_Bl_verse_macro_process();
    }
    elsif ($opts{t} eq "desc") {
        print enclose_begin($Param{_list_desc}, { env => 1 }), "\n";
    }
    elsif ($opts{t} eq "item") {
        print enclose_begin($Param{_list_item}, { env => 1 }), "\n";
    }
    elsif ($opts{t} eq "enum") {
        print enclose_begin($Param{_list_enum}, { env => 1 }), "\n";
    }
    elsif ($opts{t} eq "table") {
        handle_Bl_table_macro_process($opts{columns});
    }

    $State{wants_space} = 0;
    $Scope{item}        = 0;
}    # ]]]

sub handle_Bl_table_macro_process {    # [[[
    my $columns = shift;
    if (@Arg) {
        $Count{table}++;
        $State{_table_title} = escape_text(args_to_text(\@Arg));
        if ($Opts{target_format} eq "latex") {
            print "\\begin{table}[htbp]\n";
        }
        else {
            print qq{<div id="tbl$Count{table}" class="table">\n};
        }
    }
    print enclose_begin($Param{_list_table}, { env => 1 });
    if ($Opts{target_format} eq "latex") {
        unless (defined $columns) {
            diag_error("-columns option is required for LaTeX");
            $columns = "2";
        }
        if ($columns =~ /^\d+$/) {
            print "{", "l" x $columns, "}";
        }
        else {
            print "{", $columns, "}";
        }
    }
    print "\n";
    $State{under_table_scope} = 1;
}    # ]]]

sub handle_Bl_verse_macro_process {    # [[[
    my $title;
    if (@Arg) {
        $title = escape_text(args_to_text(\@Arg));
    }
    if ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
        print qq{<div class="verse">\n};
    }
    if (defined $title) {
        $Count{poem}++;
        print enclose_begin(
            $Param{_poemtitle},
            { id => "poem$Count{poem}" }
        );
        print $title;
        print enclose_end($Param{_poemtitle}), "\n";
        print "\\label{poem:$Count{poem}}\n" if $Opts{target_format} eq "latex";
    }
    if ($Opts{target_format} eq "latex") {
        print enclose_begin($Param{_verse}, { env => 1 }), "\n";
    }
}    # ]]]

sub handle_Bm_macro {    # [[[
    my %opts = parse_options(
        {
            t  => "s",
            ns => "b",
            id => "s",
        }
    );
    $opts{id} //= "";
    $opts{id} = escape_text($opts{id});
    unless ($Process) {
        $ID{ $opts{id} } = xhtml_gen_href("", $opts{id}) if $opts{id};
        return;
    }
    if ($opts{id} =~ /\s/) {
        diag_error("id identifier should not contain spaces");
    }

    phrasing_macro_begin($opts{ns});
    $State{wants_space} = 0;

    if (defined $opts{t} and not defined $Xmtag{ $opts{t} }) {
        diag_error("in `.Bm' macro invalid tag argument to `-t' option");
        $opts{t} = undef;
    }

    scope_stack_push("Bm", $opts{t}, $opts{id});

    my $begin;
    if (defined $opts{t}) {

        $begin = enclose_begin(
            $Xmtag{ $opts{t} }{cmd},
            { class => $opts{t}, id => $opts{id} }
        );
        if (defined $Xmtag{ $opts{t} }{begin}) {
            $begin .= $Xmtag{ $opts{t} }{begin};
        }
    }
    $begin //= enclose_begin($Xmtag{_default}{cmd}, { id => $opts{id} });
    if ($opts{id}) {
        if ($Opts{target_format} eq "latex") {
            $begin = "\\hypertarget{$opts{id}}{" . $begin;
        }
    }
    print $begin;

    if (@Arg) {
        if (!$State{inline}) {
            diag_error("useless arguments to `.Bm' macro");
        }
        else {
            print escape_text(args_to_text(\@Arg));
        }
    }
}    # ]]]

sub handle_Ed_macro {    # [[[
    return unless $Process;
    unless (@{ $Scope{Bd} }) {
        diag_error("unexpected `.Ed' macro without corresponding `.Bd'");
        return;
    }
    my $st = pop @{ $Scope{Bd} };

    if ($st->{t} eq "literal") {
        if ($State{text}) {
            print $State{text};
            $State{text} = "";
        }
        if ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
            print enclose_end("pre"), "\n";
        }
        elsif ($Opts{target_format} eq "latex") {
            print enclose_end("verbatim", { env => 1 }), "\n";
            $Flag{_verbatim} = 0;
        }
        $Flag{'fr-nbsp-auto'} = $Flag{_fr_nbsp_auto} // 1;
    }
    else {
        close_eventual_final_paragraph(1);

        if ($st->{t}) {
            my $cmd = $Xdtag{ $st->{t} }{cmd};
            if ($cmd) {
                print enclose_end($cmd, { env => 1 }), "\n";
            }
            elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
                print enclose_end("div"), "\n";
            }
            elsif ($Opts{target_format} eq "latex") {
                print "\n";
            }
        }
        elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
            print enclose_end("div"), "\n";
        }
        elsif ($Opts{target_format} eq "latex") {
            print "\n";
        }
    }
    $State{wants_space} = 0;
}    # ]]]

sub handle_Ef_macro {    # [[[
    return unless $Process;
    unless (defined $Scope{format}) {
        diag_error("unexpected `.Ef' without corresponding `.Bf' invocation");
        return;
    }
    if (!$Scope{format} or $Scope{format} =~ /$Rx{format}/) {
        if ($BfMacro{filter}) {
            print_filter($BfMacro{filter}, $State{text});
        }
        elsif ($BfMacro{filter_tag}
            and defined $Filters{ $BfMacro{filter_tag} }{code})
        {
            $Flag{_perl} = 1;
            $Filters{ $BfMacro{filter_tag} }{code}->($Self);
            $Flag{_perl} = 0;
        }
        else {
            print $State{text};
        }
        $State{text} = "";
    }

    $State{wants_space} = 0;
    $Scope{format}      = "";
    $Flag{_verbatim}    = 0;
    $Flag{_ignore_text} = 0;
}    # ]]]

sub handle_El_macro {    # [[[
    return unless $Process;
    unless (@{ $Scope{Bl} }) {
        diag_error("unexpected `.El' macro without corresponding `.Bl'");
        return;
    }
    my $st = pop @{ $Scope{Bl} };

    unless ($Scope{item}) {
        if ($st->{t} eq "desc") {
            diag_error(
                "unexpected `.El' macro without previous `.It' in 'desc' list");
            print $Param{_desc_value_begin};
        }
        elsif ($st->{t} eq "enum" or $st->{t} eq "item") {
            diag_error("unexpected `.El' macro without previous `.It'");
            print $Param{_item_begin};
        }
        elsif ($State{text}) {
            diag_error(
                "`.El' invocation:unexpected accumulated text outside item scope"
            );
        }
    }

    if ($st->{t} eq "verse") {
        handle_paragraph_end();
        if ($Opts{target_format} eq "latex") {
            print enclose_end($Param{_verse}, { env => 1 }), "\n";
        }
        print qq{</div>\n} if $Opts{target_format} =~ /$Rx{xhtml_or_epub}/;
    }
    elsif ($st->{t} eq "desc") {
        chomp $State{text};
        give_wanted_space();
        $State{text} .= $Param{_desc_value_end};
        flush_normal_text();
        print enclose_end($Param{_list_desc}, { env => 1 }), "\n";
    }
    elsif ($st->{t} eq "enum") {
        chomp $State{text};
        give_wanted_space();
        flush_normal_text();
        print $Param{_item_end};
        print enclose_end($Param{_list_enum}, { env => 1 }), "\n";
    }
    elsif ($st->{t} eq "item") {
        chomp $State{text};
        give_wanted_space();
        flush_normal_text();
        print $Param{_item_end};
        print enclose_end($Param{_list_item}, { env => 1 }), "\n";
    }
    elsif ($st->{t} eq "table") {
        handle_El_table_macro();
    }
    else {
        diag_fatal("internal error:handle_El_macro");
    }

    $Scope{item} = @{ $Scope{Bl} } ? 1 : 0;
    $State{wants_space} = 0;
}    # ]]]

sub handle_El_table_macro {    # [[[
    chomp $State{text};
    give_wanted_space();
    flush_normal_text();
    if ($Scope{item}) {
        print $Param{_table_cell_end};
        print $Param{_table_row_end};
    }
    print enclose_end($Param{_list_table}, { env => 1 }), "\n";
    if (defined $State{_table_title}) {
        if ($Opts{target_format} eq "latex") {
            print "\\caption\{$State{_table_title}\}\n";
            print "\\label\{tbl:$Count{table}\}\n";
            print "\\end{table}\n";
        }
        else {
            print qq{<p class="table-title">$State{_table_title}</p>\n};
            print "</div>\n";
        }
        $State{_table_title} = undef;
    }
    $State{under_table_scope} = 0;
}    # ]]]

sub handle_Em_macro {    # [[[
    return unless $Process;
    unless (@{ $Scope{Bm} }) {
        diag_error("unexpected `.Em' macro without corresponding `.Bm'");
        return;
    }
    phrasing_macro_end();

    my $st = pop @{ $Scope{Bm} };

    my $end = "";
    if (defined $st->{t}) {
        if (defined $Xmtag{ $st->{t} }{end}) {
            $end .= $Xmtag{ $st->{t} }{end};
        }
        $end .= enclose_end($Xmtag{ $st->{t} }{cmd});
    }
    $end ||= enclose_end($Xmtag{_default}{cmd});

    print $end;
    if (@Arg) {
        my $close_delim = shift @Arg;
        print escape_text($close_delim);
    }
    if ($st->{id} and $Opts{target_format} eq "latex") {
        print "}";
    }

    if (@Arg) {
        if (!$State{inline}) {
            diag_error("useless args in macro `.Em'");
        }
        else {
            my $sep = $Flag{ns} ? "" : " ";
            print $sep, escape_text(args_to_text(\@Arg));
        }
    }
}    # ]]]

sub handle_Ft_macro {    # [[[
    return unless $Process;
    my %opts = parse_options(
        {
            f      => "s",
            ns     => "b",
            filter => "s",
        }
    );

    unless (defined $opts{f}) {
        diag_error("`.Ft' macro invocation: you should specify a -f option");
        return;
    }

    if (@{ $Scope{Bl} } and not $Scope{item}) {
        diag_error("`.Ft' macro invocation in `.Bl' list outside `.It' scope");
        return;
    }

    if ($opts{f} =~ /$Rx{format}/) {
        if ($State{text}) {
            phrasing_macro_begin($opts{ns});
        }
        if (defined $opts{filter}) {
            print_filter(
                escape_verbatim($opts{filter}),
                escape_verbatim(args_to_text(\@Arg))
            );
        }
        else {
            print escape_verbatim(args_to_text(\@Arg));
        }
    }
    $State{wants_space} = 0;
}    # ]]]

sub handle_If_macro {    # [[[
    my %opts = parse_options(
        {
            f       => "s",
            'as-is' => "b",
            filter  => "s",
            t       => "s",
        }
    );
    if (defined $opts{f} and $opts{f} !~ /$Rx{format}/) {
        return;
    }
    unless (@Arg) {
        diag_error("The `.If' macro expects a path argument")
          if $Process;
        return;
    }

    if ($opts{'as-is'}) {
        return unless $Process;
        my $file = escape_verbatim(shift @Arg);
        chomp $State{text};
        print "\n" if $State{wants_space} and not $Flag{ns};    # XXX
        flush_normal_text();
        if (defined $opts{filter}) {
            my $text = slurp_file($file);
            print_filter(escape_verbatim($opts{filter}), $text);
        }
        elsif (defined $opts{t}) {
            unless (defined $Filters{ $opts{t} }) {
                diag_error("`If' invocation:undefined tag '$opts{t}'");
                return;
            }
            $State{text} = slurp_file($file);
            if (defined $Filters{ $opts{t} }{code}) {
                $Filters{ $opts{t} }{code}->($Self);
            }
            elsif (defined $Filters{ $opts{t} }{shell}) {
                print_filter(
                    escape_verbatim($Filters{ $opts{t} }{shell}),
                    $State{text}
                );
            }
            $State{text} = "";
        }
        else {
            print_file($file);
        }
    }
    else {
        my $file = escape_verbatim(shift @Arg);
        if ($file =~ /::/) {
            if ($file =~ /\./) {
                diag_error(
                    "`.If' invocation:path specified with :: notation should not contain periods:'$file'"
                );
                return;
            }
            $file = catfile(split /::/, $file);
            $file .= ".frundis";
        }
        elsif ($file !~ m{[/\.]}) {
            $file .= ".frundis" unless -f $file;
        }
        unless (-f $file) {
            $file = search_inc_file($file);
        }
        unless ($FileParse{$file}) {
            open(my $fh, '<', $file) or diag_fatal("$file:$!");
            $FileParse{$file} = parse_file($fh);
            close $fh;
        }
        local $File = $file;
        if ($Process) {
            process_source($FileParse{$File});
        }
        else {
            collect_source_infos($FileParse{$File});
        }
    }
}    # ]]]

sub handle_Im_macro {    # [[[
    if ($Process) {
        handle_Im_macro_process();
    }
    else {
        handle_Im_macro_infos();
    }
}    # ]]]

sub handle_Im_macro_infos {    # [[[
    $InfosFlag{use_graphicx} = 1;
    my %opts = parse_options(
        {
            ns   => "b",
            link => "s",
        }
    );
    if (@Arg) {
        my $image = escape_verbatim($Arg[0]);
        push @Image, $image;
    }
    if (@Arg >= 2) {
        my $caption = escape_text($Arg[1]);
        $Count{fig}++;
        loX_entry_infos(
            {
                title       => $caption,
                count       => $Count{fig},
                class       => "lof",
                href_prefix => "fig",
            }
        );
    }
}    # ]]]

sub handle_Im_macro_process {    # [[[
    my $close_delim = @Arg > 1 ? get_close_delim() : "";
    my %opts = parse_options(
        {
            ns   => "b",
            link => "s",
        }
    );
    if (@Arg == 1) {
        handle_Im_inline_macro_process($close_delim, %opts);
    }
    elsif (@Arg >= 2) {
        handle_Im_figure_macro_process(%opts);
    }
}    # ]]]

sub handle_Im_figure_macro_process {    # [[[
    my %opts = @_;
    $Count{fig}++;
    my $image = $Arg[0];
    my $label = escape_text($Arg[1]);
    if (@Arg > 2) {
        diag_error("too many arguments in `.Im' macro");
    }
    if ($image =~ /[{}]/ or $label =~ /[{}]/) {
        diag_error(
            q{in `.Im' macro, path argument and label should not contain the characters `{', or `}'}
        );
        return;
    }
    close_unclosed_blocks("Bm");
    close_unclosed_blocks("Bl");

    close_eventual_final_paragraph();

    if ($Opts{target_format} eq "latex") {
        $image = escape_verbatim($image);
        $image = escape_latex_percent($image);
        print "\\begin{center}\n";
        print "\\begin{figure}[htbp]\n";
        print "\\includegraphics{$image}\n";
        print "\\caption{$label}\n";
        print "\\label\{fig:$Count{fig}\}\n";
        print "\\end{figure}\n";
        print "\\end{center}\n";
    }
    elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
        print qq{<div id="fig$Count{fig}" class="figure">\n};
        if ($Opts{target_format} eq "epub") {
            $image =~ s|.*/||;
            $image = escape($image);
            my $u = URI->new($image);
            $u     = escape_xhtml_text($u);
            $image = escape_xhtml_text($image);
            my $path = catfile('images', $u);
            print qq|  <img src="$path" alt="$image" />\n|;
        }
        else {
            $image = escape($image);
            my $u = URI->new($image);
            $u     = escape_xhtml_text($u);
            $image = escape_xhtml_text($image);
            if (defined $opts{link}) {
                my $link = URI->new(escape($opts{link}));
                $link = escape_xhtml_text($link);
                print qq|  <a href="$link"><img src="$u" alt="$image" /></a>\n|;
            }
            else {
                print qq|  <img src="$u" alt="$image" />\n|;
            }
        }
        print qq|  <p class="caption">$label</p>\n|;
        print "</div>\n";
    }

}    # ]]]

sub handle_Im_inline_macro_process {    # [[[
    my ($close_delim, %opts) = @_;

    my $image = $Arg[0];
    if ($image =~ /[\{\}]/) {
        diag_error(
            q{in `.Im' macro, path argument should not contain the characters `{', or `}'}
        );
        return;
    }
    phrasing_macro_begin($opts{ns});
    if ($Opts{target_format} eq "latex") {
        $image = escape_latex_percent(escape_verbatim($image));
        print "\\includegraphics{$image}$close_delim";
    }
    elsif ($Opts{target_format} eq "epub") {
        $image =~ s|.*/||;
        $image = escape($image);
        my $u = URI->new($image);
        $u     = escape_xhtml_text($u);
        $image = escape_xhtml_text($image);
        my $path = catfile('images', $u);
        print qq|<img src="$path" alt="$image" />$close_delim|;
    }
    elsif ($Opts{target_format} eq "xhtml") {
        $image = escape($image);
        my $u = URI->new($image);
        $u     = escape_xhtml_text($u);
        $image = escape_xhtml_text($image);
        if (defined $opts{link}) {
            my $link = URI->new(escape($opts{link}));
            $link = escape_xhtml_text($link);
            print
              qq|<a href="$link"><img src="$u" alt="$image" /></a>$close_delim|;
        }
        else {
            print qq|<img src="$u" alt="$image" />$close_delim|;
        }
    }
}    # ]]]

sub handle_It_macro {    # [[[
    return unless $Process;

    unless (@{ $Scope{Bl} }) {
        diag_error("unexpected `.It' macro outside a `.Bl' macro scope");
        return;
    }
    close_unclosed_blocks("Bm");

    my $st = $Scope{Bl}->[0];

    if ($st->{t} eq "desc") {
        handle_It_desc_macro();
    }
    elsif ($st->{t} =~ /^(?:item|enum)$/) {
        handle_It_itemenum_macro();
    }
    elsif ($st->{t} eq "table") {
        handle_It_table_macro();
    }
    elsif ($st->{t} eq "verse") {
        handle_It_verse_macro();
    }

    $State{wants_space} = 0;
    $Scope{item}        = 1;    # following text belongs to an item
}    # ]]]

sub handle_It_desc_macro {    # [[[
    if ($Scope{item}) {
        end_any_previous_item();
        print $Param{_desc_value_end};
    }
    unless (@Arg) {
        diag_warning("description item of `.It' without name");
    }
    my $name = process_inline_macros();
    print $Param{_desc_name_begin}, $name,
      $Param{_desc_name_end}, $Param{_desc_value_begin};
}    # ]]]

sub handle_It_itemenum_macro {    # [[[
    if ($Scope{item}) {
        end_any_previous_item();
        print $Param{_item_end};
    }
    print $Param{_item_begin};
    if (@Arg) {
        my $space = $Flag{ns} ? "" : "\n";
        print escape_text(args_to_text(\@Arg)), $space;
    }
}    # ]]]

sub handle_It_table_macro {    # [[[
    if ($Scope{item}) {
        end_any_previous_item();
        print $Param{_table_cell_end};
        print $Param{_table_row_end};
    }
    print $Param{_table_row_begin};
    unless ($Opts{target_format} eq "latex") {
        print $Param{_table_cell_begin};
    }
    if (@Arg) {
        my $space = $Flag{ns} ? "" : "\n";
        print escape_text(args_to_text(\@Arg)), $space;
    }
}    # ]]]

sub handle_It_verse_macro {    # [[[
    if (not $Scope{paragraph}) {
        print $Param{_paragraph_begin};
        $Scope{paragraph} = 1;
    }
    elsif ($Scope{item}) {
        give_wanted_space();
        flush_normal_text();
        print $Param{_line_break};
    }
    if (@Arg) {
        print escape_text(args_to_text(\@Arg));
    }
}    # ]]]

sub handle_Lk_macro {    # [[[
    return unless $Process;
    my $close_delim = get_close_delim();
    my %opts        = parse_options(
        {
            ns => "b",
        }
    );
    unless (@Arg) {
        diag_error("`.Lk' macro requires arguments");
        return;
    }

    phrasing_macro_begin($opts{ns});

    if ($Param{lang} eq "fr" and $close_delim =~ /^(?:!|:|\?|;)$/) {
        $close_delim .= $Param{'nbsp'} . $close_delim;
    }

    if (@Arg >= 2) {
        if (@Arg > 2) {
            diag_error("too many arguments in `.Lk' macro");
        }
        my ($url, $label) = @Arg;
        $url   = URI->new(escape($url));
        $label = escape_text($label);
        if ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
            $url = escape_xhtml_text($url);
            print qq{<a href="$url">$label</a>};
        }
        elsif ($Opts{target_format} eq "latex") {
            $url = escape_latex_percent($url);
            print qq|\\href{$url}{$label}|;
        }
    }
    elsif (@Arg == 1) {
        my $url   = shift @Arg;
        my $url_e = URI->new(escape_verbatim($url));
        {
            local $Flag{_verbatim} = 1;
            $url = escape_text($url);
        }
        if ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
            $url_e = escape_xhtml_text($url_e);
            print qq{<a href="$url_e">$url</a>};
        }
        elsif ($Opts{target_format} eq "latex") {
            $url_e = escape_latex_percent($url_e);
            print qq|\\url{$url_e}|;
        }
    }
    print "$close_delim";
}    # ]]]

sub handle_P_macro {    # [[[
    return unless $Process;
    if ($Scope{paragraph}) {
        handle_paragraph_end();
    }
    elsif ($State{text}) {
        handle_paragraph();
    }
    elsif ($Opts{target_format} eq "latex") {
        print "\n";     # can be usefull after a display block
    }
    $Scope{item} = 0;    # for verse

    if ($State{macro} eq "D") {
        paragraph_begin();
        print escape_text($Param{'dmark'});
    }
    elsif (@Arg) {
        my $title = process_inline_macros();
        if ($Opts{target_format} eq "latex") {
            print "\\paragraph{$title}\n";
        }
        elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
            print
              qq{<p class="paragraph"><strong class="paragraph">$title</strong>\n};
        }
        reopen_spanning_blocks();
        $Scope{paragraph} = 1;
    }
    $State{wants_space} = 0;
}    # ]]]

sub handle_Sm_macro {    # [[[
    my %opts = parse_options(
        {
            t  => "s",
            ns => "b",
            id => "s",
        }
    );
    $opts{id} //= "";
    $opts{id} = escape_text($opts{id});
    unless ($Process) {
        $ID{ $opts{id} } = xhtml_gen_href("", $opts{id}) if $opts{id};
        return;
    }
    if ($opts{id} =~ /\s/) {
        diag_error("id identifier should not contain spaces");
    }

    my $close_delim = @Arg > 1 ? get_close_delim() : "";

    my $text = "";
    if (defined $opts{t} and not defined $Xmtag{ $opts{t} }) {
        diag_error(
            "`.Sm' macro invocation:invalid tag argument to `-t' option");
        $opts{t} = undef;
    }
    if (@Arg) {
        $text = escape_text(args_to_text(\@Arg));
    }
    else {
        diag_error("`.Sm' macro invocation:arguments required");
        return;
    }

    phrasing_macro_begin($opts{ns});

    my ($begin, $end);
    if (defined $opts{t}) {
        $begin = enclose_begin(
            $Xmtag{ $opts{t} }{cmd},
            { class => $opts{t}, id => $opts{id} }
        );
        if (defined $Xmtag{ $opts{t} }{begin}) {
            $begin .= $Xmtag{ $opts{t} }{begin};
        }
        if (defined $Xmtag{ $opts{t} }{end}) {
            $end = $Xmtag{ $opts{t} }{end};
        }
        $end .= enclose_end($Xmtag{ $opts{t} }{cmd});
    }
    $begin //= enclose_begin($Xmtag{_default}{cmd}, { id => $opts{id} });
    $end //= enclose_end($Xmtag{_default}{cmd});
    if ($opts{id}) {
        if ($Opts{target_format} eq "latex") {
            $begin = "\\hypertarget{$opts{id}}{" . $begin;
            $end .= "}";
        }
    }
    print $begin . $text . $end . $close_delim;
}    # ]]]

sub handle_Sx_macro {    # [[[
    return unless $Process;
    my %opts = parse_options(
        {
            ns   => "b",
            name => "s",
            t    => "s",
            id   => "b",
        }
    );

    $opts{t} //= "toc";
    my $close_delim = @Arg > 1 ? get_close_delim() : "";
    unless (@Arg) {
        diag_error("`.Sx' macro invocation:arguments required");
        return;
    }
    unless (defined $Self->{loX}{ $opts{t} } or $opts{id}) {
        diag_error("`.Sx' macro invocation:invalid argument to -type");
        return;
    }

    my $id = args_to_text(\@Arg);
    $id = escape_text($id);
    my $valid_title;
    my $loX_entry;
    unless ($opts{id}) {
        $valid_title = 1;
        unless (exists $Self->{loX}{ $opts{t} }{$id}) {
            diag_error(
                "`.Sx' invocation:unknown title for type '$opts{t}':$id");
            $valid_title = 0;
        }
        $loX_entry = $Self->{loX}{ $opts{t} }{$id};
    }
    phrasing_macro_begin($opts{ns});
    my $name = $opts{name} ? escape_text($opts{name}) : process_inline_macros();

    if ($Opts{target_format} eq "latex") {
        if ($opts{id}) {
            unless ($ID{$id}) {
                diag_error("reference to unknown id '$id'");
            }
            print "\\hyperlink{$id}{$name}$close_delim";
        }
        elsif ($valid_title) {
            my $num    = $loX_entry->{count};
            my $prefix = $loX_entry->{href_prefix};
            print "\\hyperref[$prefix:", $num, "]{", $name, "}", $close_delim;
        }
        else {
            print $name, $close_delim;
        }
    }
    elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
        if ($opts{id}) {
            if (not $ID{$id}) {
                diag_error("reference to unknown id '$id'");
                print qq{<a>$name</a>$close_delim};
            }
            else {
                print qq{<a href="$ID{$id}">$name</a>$close_delim};
            }
        }
        elsif ($valid_title) {
            my $href = $loX_entry->{href};
            print qq{<a href="$href">$name</a>$close_delim};
        }
        else {
            print qq{<a>$name</a>$close_delim};
        }
    }
}    # ]]]

sub handle_Ta_macro {    # [[[
    return unless $Process;
    unless (@{ $Scope{Bl} }) {
        diag_error("unexpected `.Ta' macro outside a `.Bl' macro scope");
        return;
    }
    unless ($State{under_table_scope}) {
        diag_error("found `.Ta' macro in non ``table'' list");
        return;
    }
    unless ($Scope{item}) {
        diag_error("found `.Ta' macro outside an `.It' scope");
        return;
    }
    close_unclosed_blocks("Bm");

    chomp $State{text};
    give_wanted_space();
    flush_normal_text();
    print $Param{_table_cell_end};
    print $Param{_table_cell_begin};

    if (@Arg) {
        print escape_text(args_to_text(\@Arg)), "\n";
    }
}    # ]]]

sub handle_Tc_macro {    # [[[
    if ($Process) {
        handle_Tc_macro_process();
    }
    else {
        handle_Tc_macro_infos();
    }
}    # ]]]

sub handle_Tc_macro_infos {    # [[[
    my %opts = parse_options(
        {
            summary => "b",
            nonum   => "b",
            mini    => "b",
            toc     => "b",
            lof     => "b",
            lot     => "b",
            title   => "s",
        }
    );
    $InfosFlag{use_minitoc} = 1 if $opts{mini};
    $InfosFlag{dominilof}   = 1 if $opts{mini} and $opts{lof};
    $InfosFlag{dominilot}   = 1 if $opts{mini} and $opts{lot};
    $InfosFlag{dominitoc}   = 1 if $opts{mini} and $opts{toc};
}    # ]]]

sub handle_Tc_macro_process {    # [[[
    close_unclosed_blocks("Bm");
    close_unclosed_blocks("Bl");

    my %opts = parse_options(
        {
            summary => "b",
            nonum   => "b",
            mini    => "b",
            toc     => "b",
            lof     => "b",
            lot     => "b",
            title   => "s",
        }
    );

    close_eventual_final_paragraph();

    unless ($opts{toc} or $opts{lof} or $opts{lot}) {
        $opts{toc} = 1;
    }
    if (   $opts{toc} && $opts{lof}
        or $opts{toc} and $opts{lot}
        or $opts{lof} and $opts{lot})
    {
        diag_error(
            "`.Tc' invocation:only one of the -toc, -lof and -lot options should bet set"
        );
        return;
    }

    if ($Opts{target_format} eq "latex") {
        if ($opts{summary}) {
            print "\\setcounter{tocdepth}{0}\n";
        }
        else {
            print "\\setcounter{tocdepth}{3}\n";
        }
        if ($opts{mini}) {
            if ($opts{lof}) {
                print "\\minilof\n";
            }
            elsif ($opts{lot}) {
                print "\\minilot\n";
            }
            else {
                print "\\minitoc\n";
            }
        }
        else {
            if ($opts{lof}) {
                print "\\listoffigures\n";
            }
            elsif ($opts{lot}) {
                print "\\listoftables\n";
            }
            else {
                print "\\tableofcontents\n";
            }
        }
    }
    elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
        if ($opts{lof}) {
            xhtml_lof(\%opts);
        }
        elsif ($opts{lot}) {
            xhtml_lot(\%opts);
        }
        else {
            xhtml_toc("xhtml", \%opts);
        }
    }
}    # ]]]

sub handle_X_macro {    # [[[
    return if $Process;
    unless (@Arg) {
        warn diag(
            "warning:.$State{macro} invocation: you should specify arguments");
        return;
    }

    my $cmd = shift @Arg;
    if ($cmd eq "dtag") {
        handle_X_dtag_macro($cmd);
    }
    elsif ($cmd eq "ftag") {
        handle_X_ftag_macro($cmd);
    }
    elsif ($cmd eq "mtag") {
        handle_X_mtag_macro($cmd);
    }
    elsif ($cmd eq "set") {
        handle_X_set_macro($cmd);
    }
}    # ]]]

sub handle_X_dtag_macro {    # [[[
    my $cmd  = shift;
    my %opts = parse_options(
        {
            f => "s",
            t => "s",
            c => "s",
        },
        "$State{macro} $cmd",
    );
    unless (defined $opts{f}) {
        diag_error(
            "`.$State{macro} $cmd' invocation: you should specify `-f' option");
        return;
    }
    unless ($opts{f} =~ /$Rx{valid_format}/) {
        diag_error("`.X $cmd' invocation:invalid argument to -f:$opts{f}");
        return;
    }
    return unless $opts{f} =~ /$Rx{format}/;
    unless (defined $opts{t}) {
        diag_error(
            "-t option should have an argument in `.$State{macro} $cmd' invocation"
        );
        return;
    }

    $Xdtag{ $opts{t} }{cmd} = $Xdtag{_default}{cmd};
    if (defined $opts{c}) {
        if (not $opts{c} =~ /^[a-zA-Z]*$/) {
            diag_error(
                "`.X $cmd' invocation: invalid argument to -c:$opts{c}:it should be composed of ascii letters"
            );
        }
        if ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
            diag_warning(
                "`.X $cmd' invocation:possibly inadequate element argument to -c:$opts{c}"
              )
              unless $opts{c} eq ""
              or $HtmlContainingFlow{ $opts{c} };
        }
        $Xdtag{ $opts{t} }{cmd} = $opts{c};
    }
}    # ]]]

sub handle_X_ftag_macro {    # [[[
    my $cmd  = shift;
    my %opts = parse_options(
        {
            f     => "s",
            t     => "s",
            shell => "s",
            code  => "s",
        }
    );
    if (defined $opts{f}) {
        unless ($opts{f} =~ /$Rx{valid_format}/) {
            diag_error("`.X $cmd' invocation: invalid argument to -f:$opts{f}");
            return;
        }
        return unless $opts{f} =~ /$Rx{format}/;
    }
    unless (defined $opts{t}) {
        diag_error("`.X $cmd' invocation:-t option should be specified");
        return;
    }
    if ($opts{shell} and $opts{code}) {
        diag_error(
            "`.X $cmd' invocation:-shell and -code cannot be used simultaneously"
        );
    }
    $Filters{ $opts{t} }{shell} = $opts{shell};
    if ($opts{code}) {
        Text::Frundis::PerlEval::_compile_perl_code(
            $Self,       $opts{t},
            $opts{code}, "filter"
        );
    }
}    # ]]]

sub handle_X_mtag_macro {    # [[[
    my $cmd  = shift;
    my %opts = parse_options(
        {
            f => "s",
            t => "s",
            c => "s",
            b => "s",
            e => "s",
        },
        "$State{macro} $cmd",
    );
    unless (defined $opts{f}) {
        diag_error(
            "`.$State{macro} $cmd' invocation: you should specify `-f' option");
        return;
    }
    unless ($opts{f} =~ /$Rx{valid_format}/) {
        diag_error(
            "`.X $cmd' invocation:invalid argument to -f option:$opts{f}");
        return;
    }
    return unless $opts{f} =~ /$Rx{format}/;

    unless (defined $opts{t}) {
        diag_error("`.X $cmd' invocation:-t option should be specified");
        return;
    }

    $Xmtag{ $opts{t} }{cmd} = $Xmtag{_default}{cmd};
    if (defined $opts{c} and $opts{c} =~ /^[a-zA-Z]*$/) {
        if (not $opts{c} =~ /^[a-zA-Z]*$/) {
            diag_error(
                "`.X $cmd' invocation: invalid argument to -c:$opts{c}:it should be composed of ascii letters"
            );
        }
        if ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
            diag_warning(
                "`.X $cmd' invocation:non phrasing element argument to -c:$opts{c}:you should probably use a dtag"
              )
              unless $opts{c} eq ""
              or $HtmlPhrasing{ $opts{c} };
        }
        $Xmtag{ $opts{t} }{cmd} = $opts{c};
    }

    # other optional options
    if (defined $opts{b}) {
        $Xmtag{ $opts{t} }{begin} = escape_text($opts{b});
    }
    if (defined $opts{e}) {
        $Xmtag{ $opts{t} }{end} = escape_text($opts{e});
    }

}    # ]]]

sub handle_X_set_macro {    # [[[
    my $cmd  = shift;
    my %opts = parse_options(
        {
            f => "s",
        },
        "$State{macro} $cmd",
    );
    if (defined $opts{f}) {
        unless ($opts{f} =~ /$Rx{valid_format}/) {
            diag_error("`.X $cmd' invocation: invalid argument to -f:$opts{f}");
            return;
        }
        return unless $opts{f} =~ /$Rx{format}/;
    }
    unless (@Arg >= 2) {
        diag_error("`.X $cmd' invocation expects two arguments");
        return;
    }
    if (@Arg > 2) {
        diag_error("`.X $cmd' invocation: too many arguments");
    }

    my $parameter = $Arg[0];
    unless ($AllowedParam{$parameter}) {
        diag_warning(
            "useless `.X set' definition of unknown parameter '$parameter'");
    }

    $Param{$parameter} = $Arg[1];

    if ($parameter =~ /^document-(?:author|date|title)$/) {
        $Param{$parameter} = escape_text($Param{$parameter});
    }
    elsif ($parameter eq "nbsp") {
        $Xhtml_escapes{'\~'} = $Param{nbsp};
    }
    elsif ( $parameter eq "xhtml-index"
        and $Param{$parameter} !~ /^(?:full|summary|none)$/)
    {
        diag_error(
            "`.X set' invocation:xhtml-index parameter:unknown value:$Param{$parameter}"
        );
    }
    elsif ($parameter eq "epub-version") {
        diag_error(
            "`.X set' invocation:epub-version parameter should be 2 or 3")
          unless $Param{$parameter} =~ /^(?:2|3)$/;
    }
    elsif ($parameter eq "lang") {
        if ($IndexTraductions{ $Param{lang} }) {
            $Param{_index} = $IndexTraductions{ $Param{lang} };
        }
    }
}    # ]]]

sub handle_de_macro {    # [[[
    if ($Scope{de}) {
        diag_error(
            "found `.#de' macro in the scope of a previous `.#de' macro at line $DeMacro{lnum}"
        ) if $Process;
        return;
    }
    my %opts = parse_options(
        {
            f    => "s",
            perl => "b",
        }
    );

    unless (@Arg) {
        diag_error("a name should be specified to the `.#de' declaration")
          if $Process;
        return;
    }
    my $name = shift @Arg;
    if ($name =~ /^[A-Z][a-z]$/ or $name =~ /^#/) {
        diag_error(
            "two letters names of the form Xy and names starting by # are reserved"
        );
    }
    $Scope{de}     = 1;
    $DeMacro{file} = $File;
    $DeMacro{lnum} = $State{lnum};
    $DeMacro{perl} = $opts{perl};
    $DeMacro{name} = $name;
    $Macro{ $DeMacro{name} }{parse} //= [];

    if (defined $opts{f}) {
        unless ($opts{f} =~ /$Rx{valid_format}/) {
            diag_error(
                "`.#de' invocation:invalid argument to -f option:$opts{f}")
              if $Process;
        }
        unless ($opts{f} =~ /$Rx{format}/) {
            $DeMacro{ignore} = 1;
        }
    }

    if (@Arg && $Process) {
        diag_error("`.#de' invocation:too many arguments");
    }
}    # ]]]

sub handle_dv_macro {    # [[[
    my %opts = parse_options(
        {
            f => "s",
        }
    );
    unless (@Arg) {
        diag_error("`.dv' requires arguments");
        return;
    }
    if (defined $opts{f}) {
        unless ($opts{f} =~ /$Rx{valid_format}/) {
            diag_error(
                "`.dv' invocation:invalid argument to -f option:$opts{f}");
            return;
        }
        return unless $opts{f} =~ /$Rx{format}/;
    }

    my ($name, @arg) = @Arg;
    if (@arg) {
        $Self->{vars}{$name} = join(" ", @arg);
        return;
    }
    else {
        diag_error("`.dv' invocation:value required");
    }
}    # ]]]

sub handle_end_macro {    # [[[
    unless ($Scope{de}) {
        diag_error("`..' allowed only within a `.#de' macro scope")
          if $Process;
        return;
    }
    $Scope{de} = 0;
    if ($DeMacro{ignore}) {
        reset_de_macro_state();
        return;
    }
    $Macro{ $DeMacro{name} }{perl} = 1 if $DeMacro{perl};
    if ($DeMacro{perl}) {
        my $text = escape_verbatim($Macro{ $DeMacro{name} }{parse}->[0][0]);
        $Flag{_perl} = 1;
        Text::Frundis::PerlEval::_compile_perl_code(
            $Self, $DeMacro{name},
            $text, "macro"
        );
        $Flag{_perl} = 0;
    }
    $Macro{ $DeMacro{name} }{lnum} = $DeMacro{lnum};
    reset_de_macro_state();
}    # ]]]

sub handle_fl_macro {    # [[[
    return unless $Process;
    unless (@Arg) {
        diag_error("`.#fl' requires at least one argument");
        return;
    }
    my ($key, $value) = @Arg;
    unless ($AllowedFlag{$key}) {
        diag_warning("unsupported key in `.#fl' macro:$key");
    }
    if (defined $value) {
        if (defined $Flag{$key} and $value eq $Flag{$key}) {
            diag_warning("useless use of `.#fl', value doesn't change");
            return;
        }
        $Flag{$key} = $value;
    }
    elsif (defined $Flag{$key}) {
        $Flag{$key} = !$Flag{$key};
    }
    else {
        diag_warning("use of undefined state value in `.#fl' macro");
    }
}    # ]]]

sub handle_header_macro {    # [[[
    if ($Process) {
        handle_header_macro_process();
    }
    else {
        handle_header_macro_infos();
    }
}    # ]]]

sub handle_header_macro_infos {    # [[[
    my $macro = $State{macro};
    my %opts  = parse_options(
        { nonum => "b" },
    );
    unless (@Arg) {
        return;
    }

    my $href;
    headers_count_update($opts{nonum});
    if ($macro eq "Pt") {
        $InfosFlag{has_part} = 1;
        $href = xhtml_gen_href("s", $Count{header}, 1);
    }
    elsif ($macro eq "Ch") {
        $InfosFlag{has_chapter} = 1;
        $href = xhtml_gen_href("s", $Count{header}, 1);
    }
    elsif ($macro eq "Sh" or $macro eq "Ss") {
        if ($Opts{all_in_one_file}) {
            $href = xhtml_gen_href("s", "$Count{header}");
        }
        else {
            $href = xhtml_gen_href("s", "$Count{section}-$Count{subsection}");
        }
    }
    my $id = $href;
    $id =~ s/.*#//;
    $id =~ s/\.x?html$//;

    my $title = escape_text(args_to_text(\@Arg));
    if (exists $Self->{loX}{toc}{$title}) {
        diag_error(
            "The title '$title' is used more than once as header.  This will confuse cross-references."
        );
    }
    my $num = header_number($opts{nonum});
    $Self->{loX}{toc}{$title} = {
        href        => $href,
        id          => $id,
        href_prefix => "s",
        num         => $num,
        count       => $Count{header},
        nonum       => $opts{nonum},
    };

    if ($macro =~ /^(?:Pt|Ch)$/) {
        push @{ $loXstack{nav} },
          {
            href        => $href,
            id          => $id,
            href_prefix => "s",
            macro       => $macro,
            count       => $Count{header},
          };
    }

    push @{ $loXstack{toc} },
      {
        macro       => $macro,
        id          => $id,
        href_prefix => "s",
        title       => $title,
        href        => $href,
        num         => $num,
        nonum       => $opts{nonum},
        count       => $Count{header},
      };
}    # ]]]

sub handle_header_macro_process {    # [[[
    unless (@Arg) {
        diag_error("`.$State{macro}' macro requires at least one argument");
        return;
    }
    my %opts = parse_options(
        {
            nonum => "b",
        },
    );
    my $numbered = !$opts{nonum};
    my $title = escape_text(args_to_text(\@Arg));

    close_unclosed_blocks("Bm");
    close_unclosed_blocks("Bl");

    close_eventual_final_paragraph();

    headers_count_update($opts{nonum});
    if ($State{macro} =~ /^(?:Pt|Ch)$/) {
        $State{nav_count}++;
        if ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/
            and not $Opts{all_in_one_file})
        {
            xhtml_file_output_change($title);
        }
    }

    my $toc = $Self->{loX}{toc};

    # opening
    if ($Opts{target_format} eq "latex") {
        my $type = latex_header_name($State{macro});
        if ($numbered) {
            print enclose_begin($type);
        }
        else {
            print enclose_begin($type . "*");
        }
    }
    elsif ($Opts{target_format} eq "xhtml" and $Opts{all_in_one_file}) {
        print enclose_begin(
            xhtml_section_header($State{macro}),
            {
                id    => "s$toc->{$title}{count}",
                class => $State{macro},
            }
        );
    }
    elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
        my $id = $toc->{$title}{id};
        print enclose_begin(
            xhtml_section_header($State{macro}),
            {
                id    => $id,
                class => $State{macro},
            }
        );
    }

    my $num = "";
    if ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/ and not $opts{nonum}) {
        $num = $toc->{$title}{num};
        $num = "$num " if $num;
    }
    print $num;

    my $title_render = process_inline_macros();
    print $title_render;

    close_unclosed_blocks("Bm");

    # closing
    if ($Opts{target_format} eq "latex") {
        my $type = latex_header_name($State{macro});
        if ($numbered) {
            print enclose_end($type), "\n";
        }
        else {
            print enclose_end($type . "*"), "\n";
            print "\\addcontentsline{toc}{"
              . latex_header_name($State{macro})
              . "}{$title_render}\n";
        }
        print "\\label{s:", $toc->{$title}{count}, "}\n";
    }
    elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
        print enclose_end(xhtml_section_header($State{macro})), "\n";
    }

    $State{wants_space} = 0;
    $Scope{paragraph}   = 0;
}    # ]]]

sub handle_if_macro {    # [[[
    scope_stack_push("#if");
    if ($Count{if_ignore}) {
        $Count{if_ignore}++;
        return;
    }
    my %opts = parse_options(
        {
            f => "s",
        }
    );
    unless (defined $opts{f} or @Arg) {
        diag_warning("useless `.#if' invocation");
        return;
    }

    if (defined $opts{f}) {
        unless ($opts{f} =~ /$Rx{valid_format}/) {
            diag_error("invalid ``format'' argument in `.#if' macro:$opts{f}")
              if $Process;
        }
        unless ($opts{f} =~ /$Rx{format}/) {
            $Count{if_ignore} = 1;
            return;
        }
    }

    if (@Arg) {
        my $bool = shift @Arg;
        if (@Arg) {
            diag_error("`.#if' invocation:too many arguments")
              if $Process;
        }
        unless ($bool) {
            $Count{if_ignore} = 1;
        }
    }
}    # ]]]

sub handle_if_end_macro {    # [[[
    $Count{if_ignore}-- if $Count{if_ignore};
    if (@{ $Scope{'#if'} }) {
        pop @{ $Scope{'#if'} };
    }
    else {
        diag_error("`.#;' invocation with no previous `.#if'")
          if $Process;
    }
}    # ]]]

sub handle_user_macro {    # [[[
    my $macro = $State{macro};
    my $perl  = $Macro{$macro}{perl};
    my @processed_parse;

    unless ($perl) {
        my $parse = $Macro{$macro}{parse};
        unless (@$parse) {
            return;
        }

        foreach my $block (@$parse) {
            my $remaining = 0;
            if (@$block == 2) {
                my $t = $block->[0];
                $t =~ s{\\+\$(\d+)}{
                    defined $Arg[$1-1] ? $Arg[$1-1] : (++$remaining and "\\\$$1");
                }xge;
                push @processed_parse, [ $t, $block->[1] ];
            }
            elsif (@$block == 3) {
                my $macro_name = $block->[0];
                my @macro_args = @{ $block->[1] };
                s{\\+\$(\d+)}{
                    defined $Arg[$1-1] ? $Arg[$1-1] : (++$remaining and "\\\$$1");
                }xge for @macro_args;
                $macro_name =~ s{\\+\$(\d+)}{
                    defined $Arg[$1-1] ? $Arg[$1-1] : (++$remaining and "\\\$$1");
                }xge;
                push @processed_parse,
                  [ $macro_name, \@macro_args, $block->[2] ];
                my $remaining;

                foreach (@macro_args) {
                    $remaining++ and last if /\\+\$\d/;
                }
            }
            diag_error("`$macro' invocation:not enough arguments provided")
              if $remaining;
        }
    }

    # Keep the line number of the call, the name of the macro, and the current
    # file name for better diags.
    # Don't permit recursive calls to erase this values as the first user macro
    # called is the one that is usefull in diagnostics.
    if ($UserMacroCall{depth} == 0) {
        $UserMacroCall{lnum} = $State{lnum};
        $UserMacroCall{name} = $macro;
        $UserMacroCall{file} = $File;
    }
    $UserMacroCall{depth}++;
    if ($perl) {
        $Flag{_perl} = 1;
        $Self->_call_perl_macro($macro);
        $Flag{_perl} = 0;
    }
    else {
        if ($Process) {
            process_source(\@processed_parse);
        }
        else {
            collect_source_infos(\@processed_parse);
        }
    }
    $UserMacroCall{depth}--;
    if ($UserMacroCall{depth} == 0) {
        $UserMacroCall{lnum} = undef;
        $UserMacroCall{name} = undef;
        $UserMacroCall{file} = undef;
    }
}    # ]]]

################################################################################
# Utility functions, in alphabetic order.

sub add_non_breaking_spaces {    # [[[
    my $text = shift;
    if ($Flag{'fr-nbsp-auto'}) {
        $text =~ s/\h*(?:\\~)?(?<!\\&)([\x{bb}!:\?;])/\\~$1/xg;
        $text =~ s/(\x{ab})(?!\\&)(?:\\~)?\h*/$1\\~/xg;
    }
    return $text;
}    # ]]]

sub args_to_text {    # [[[
    my $args = shift;
    my $sep  = $Flag{ns} ? "" : " ";
    my $text = join($sep, @$args);
    return $text;
}    # ]]]

sub call {    # [[[
    my ($macro, @args) = @_;
    local $State{macro} = $macro;
    local @Arg = @args;
    if ($Process) {
        process_macro();
    }
    else {
        collect_macro_infos();
    }
}    # ]]]

sub close_eventual_final_paragraph {    # [[[
    my $last = shift;
    if ($Scope{paragraph}) {
        handle_paragraph_end($last);
    }
    elsif ($State{text}) {
        handle_paragraph($last);
    }
}    # ]]]

sub close_spanning_blocks {    # [[[
    my $stack = $Scope{Bm};
    for (my $i = $#{$stack}; $i >= 0; $i--) {
        my $st = $stack->[$i];
        my $begin_macro = $st->{macro};

        my $end;
        if (defined $st->{t}) {
            $end = enclose_end($Xmtag{ $st->{t} }{cmd});
        }
        $end //= enclose_end($Xmtag{_default}{cmd});

        print $end;
    }
}    # ]]]

sub close_unclosed_blocks {    # [[[
    my $type = shift;
    if (test_for_unclosed_block($type)) {
        local @Arg                = ();
        local $State{macro}       = $type;
        local $Flag{_no_warnings} = 1;
        if ($type eq "Bm") {
            handle_Em_macro while @{ $Scope{$type} };
        }
        elsif ($type eq "Bl") {
            handle_El_macro while @{ $Scope{$type} };
        }
        elsif ($type eq "Bd") {
            handle_Ed_macro while @{ $Scope{$type} };
        }
    }
}    # ]]]

sub diag {    # [[[
    my $message = shift;
    if (defined $UserMacroCall{lnum}) {
        return
          "frundis:$UserMacroCall{file}:$UserMacroCall{lnum}:in user macro `.$UserMacroCall{name}':$message\n";
    }
    elsif (defined $State{lnum}) {
        return "frundis:$File:$State{lnum}:$message\n";
    }
    elsif ($File) {
        return "frundis:$File:$message\n";
    }
    else {
        return "frundis:$message\n";
    }
}    # ]]]

sub diag_error {    # [[[
    return if $Flag{_no_warnings};
    my $message = shift;
    $Flag{_frundis_warning} = 1;
    $message = diag("error:$message");
    if ($Opts{use_carp}) {
        chomp $message;
        carp $message;
    }
    else {
        warn $message;
    }
    $Flag{_frundis_warning} = 0;
}    # ]]]

sub diag_fatal {    # [[[
    my $message = shift;
    $message = diag("fatal:$message");
    if ($Opts{use_carp}) {
        chomp $message;
        croak $message;
    }
    else {
        die $message;
    }
}    # ]]]

sub diag_warning {    # [[[
    return if $Flag{_no_warnings};
    my $message = shift;
    $Flag{_frundis_warning} = 1;
    $message = diag("warning:$message");
    if ($Opts{use_carp}) {
        chomp $message;
        carp $message;
    }
    else {
        warn $message;
    }
    $Flag{_frundis_warning} = 0;
}    # ]]]

sub enclose_begin {    # [[[
    my ($elt, $opts) = @_;
    unless ($elt) {
        return "";
    }
    if (defined $opts) {
        diag_fatal(
            'internal error: enclose_begin: $opts is not a hash reference')
          unless ref $opts eq "HASH";
    }
    else {
        $opts = {};
    }
    if ($Opts{target_format} eq "latex") {
        return $opts->{env} ? "\\begin{$elt}" : "\\$elt\{";
    }
    elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
        my $attributes = "";
        if ($opts->{class}) {
            $attributes .= qq{ class="$opts->{class}"};
        }
        if ($opts->{id}) {
            $attributes .= qq{ id="$opts->{id}"};
        }
        return "<${elt}${attributes}>";
    }
}    # ]]]

sub enclose_end {    # [[[
    my ($elt, $opts) = @_;
    unless ($elt) {
        return "";
    }
    if (defined $opts) {
        diag_fatal('internal error: enclose_end: $opts is not a hash reference')
          unless ref $opts eq "HASH";
    }
    else {
        $opts = {};
    }
    if ($Opts{target_format} eq "latex") {
        return $opts->{env} ? "\\end{$elt}" : '}';
    }
    elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
        return "</$elt>";
    }
}    # ]]]

sub end_any_previous_item {    # [[[
    if ($State{text}) {
        chomp $State{text};
        give_wanted_space();
        flush_normal_text();
    }
}    # ]]]

sub escape {    # [[[
    my $text = shift;
    $text =~ s/(\\&|\\e|\\~)/$Frundis_escapes{$1}/gex;
    return $text;
}    # ]]]

sub escape_latex_percent {    # [[[
    my $text = shift;

    # for url and path arguments
    $text =~ s/%/\\%/g;
    return $text;
}    # ]]]

sub escape_latex_text {    # [[[
    my $text = shift;

    $text =~ s/(\{|\}|\[|\]|%|&|\$|\#|_|\\|\^|~)/$Latex_escapes{$1}/gex;
    $text =~ tr/\x{a0}/~/;

    return $text;
}    # ]]]

sub escape_text {    # [[[
    my $text = shift;
    if ($Param{lang} eq "fr" and not $Flag{_verbatim}) {
        $text = add_non_breaking_spaces($text);
    }
    $text =~ s/(\\&|\\e|\\~)/$Frundis_escapes{$1}/gex;
    if ($Opts{target_format} eq "latex") {
        $text = escape_latex_text($text);
    }
    elsif ($Opts{target_format} =~ /$Rx{xhtml_or_epub}/) {
        $text = escape_xhtml_text($text);
    }
    return $text;
}    # ]]]

sub escape_verbatim {    # [[[
    my $text = shift;
    $text =~ s/(\\&|\\e|\\~)/$Frundis_escapes{$1}/gex;
    $text =~ tr/\x{a0}/ / if $Opts{target_format} eq "latex";
    return $text;
}    # ]]]

sub escape_xhtml_text {    # [[[
    my $text = shift;

    $text =~ s/(&|<|>|"|')/$Xhtml_escapes{$1}/gex;

    return $text;
}    # ]]]

sub flush_normal_text {    # [[[
    $State{text} =~ s/\n\s*\n/\n/g;
    print $State{text};
    $State{wanted_space} = 0;
    $State{text}         = "";
}    # ]]]

sub get_close_delim {    # [[[
    my $close_delim = "";
    if (    @Arg
        and $Arg[$#Arg] =~ /^(?:\\~)?\p{Punct}+$/
        and $Arg[$#Arg] !~ /^\\&/)
    {
        $close_delim = pop @Arg;
        if ($Param{lang} eq "fr") {
            $close_delim = add_non_breaking_spaces($close_delim);
        }
        $close_delim = escape_text($close_delim);
    }
    return $close_delim;
}    # ]]]

sub give_wanted_space {    # [[[
    print "\n" if $State{wanted_space};
}    # ]]]

sub handle_paragraph {    # [[[
    my $last = shift;
    paragraph_begin();
    handle_paragraph_end($last);
}    # ]]]

sub handle_paragraph_begin {    # [[[
    unless ($Scope{paragraph}) {
        paragraph_begin();
    }
    give_wanted_space();
    flush_normal_text();
}    # ]]]

sub handle_paragraph_end {    # [[[
    my $last = shift;
    paragraph_end();
    if ($Opts{target_format} eq "latex" and not $last) {
        print "\n";
    }
    $Scope{paragraph} = 0;
}    # ]]]

sub headers_count_update {    # [[[
    my $nonum = shift;
    my $macro = $State{macro};
    if ($macro eq "Pt") {
        $Count{part}++;
        $Count{numbered_part}++ unless $nonum;
        $Count{section}             = 0;
        $Count{subsection}          = 0;
        $Count{numbered_section}    = 0;
        $Count{numbered_subsection} = 0;
    }
    elsif ($macro eq "Ch") {
        $Count{chapter}++;
        $Count{numbered_chapter}++ unless $nonum;
        $Count{section}             = 0;
        $Count{subsection}          = 0;
        $Count{numbered_section}    = 0;
        $Count{numbered_subsection} = 0;
    }
    elsif ($macro eq "Sh") {
        $Count{section}++;
        $Count{numbered_section}++ unless $nonum;
        $Count{numbered_subsection} = 0;
        $Count{subsection}          = 0;
    }
    elsif ($macro eq "Ss") {
        $Count{subsection}++;
        $Count{numbered_subsection}++ unless $nonum;
    }
    $Count{header}++;
}    # ]]]

sub header_level {    # [[[
    my $header_macro = shift;
    my $level        = -1;
    if ($InfosFlag{has_part}) {
        $level = 1;
    }
    elsif ($InfosFlag{has_chapter}) {
        $level = 0;
    }
    return
        $header_macro eq "Pt" ? $level
      : $header_macro eq "Ch" ? $level + 1
      : $header_macro eq "Sh" ? $level + 2
      :                         $level + 3;
}    # ]]]

sub header_number {    # [[[
    my $nonum = shift;
    return "" if $nonum;
    my $macro = $State{macro};
    my $num;
    if ($macro eq "Pt") {
        $num = "$Count{numbered_part}";
    }
    elsif ($macro eq "Ch") {
        $num = "$Count{numbered_chapter}";
    }
    elsif ($macro eq "Sh") {
        if ($InfosFlag{has_chapter}) {
            $num = "$Count{numbered_chapter}.$Count{numbered_section}";
        }
        else {
            $num = "$Count{numbered_section}";
        }
    }
    elsif ($macro eq "Ss") {
        if ($InfosFlag{has_chapter}) {
            $num =
              "$Count{numbered_chapter}.$Count{numbered_section}.$Count{numbered_subsection}";
        }
        elsif ($Count{numbered_section}) {
            $num = "$Count{numbered_section}.$Count{numbered_subsection}";
        }
        else {
            $num = "0.$Count{numbered_subsection}";
        }
    }
    return $num;
}    # ]]]

sub init_infos {    # [[[
    if ($Opts{target_format} eq "latex") {
        %Param = (
            'dmark'           => '---',
            'nbsp'            => '~',
            _desc_name_begin  => '\item[',
            _desc_name_end    => "]\n",
            _desc_value_begin => '',
            _desc_value_end   => "\n",
            _item_begin       => '\item ',
            _item_end         => "\n",
            _line_break       => " \\\\\n",
            _list_desc        => 'description',
            _list_enum        => 'enumerate',
            _list_item        => 'itemize',
            _list_table       => 'tabular',
            _paragraph_begin  => "",
            _paragraph_end    => "\n",
            _poemtitle        => 'poemtitle',
            _table_cell_begin => " & ",
            _table_cell_end   => "",
            _table_row_begin  => "",
            _table_row_end    => " \\\\\n",
            _verse            => 'verse',
        );
        %Xmtag = (_default => { cmd => 'emph' });
        %Xdtag = (_default => { cmd => '' });
    }
    elsif ($Opts{target_format} eq "xhtml" or $Opts{target_format} eq "epub") {
        %Param = (
            'dmark'           => "\x{2014}",
            'nbsp'            => "\x{a0}",
            'xhtml-index'     => "full",
            'xhtml5'          => "0",
            _desc_name_begin  => '<dt>',
            _desc_name_end    => "</dt>\n",
            _desc_value_begin => '<dd>',
            _desc_value_end   => "</dd>\n",
            _item_begin       => '<li>',
            _item_end         => "</li>\n",
            _line_break       => "<br />\n",
            _list_desc        => 'dl',
            _list_enum        => 'ol',
            _list_item        => 'ul',
            _list_table       => 'table',
            _paragraph_begin  => "<p>",
            _paragraph_end    => "</p>\n",
            _poemtitle        => "h4",
            _table_cell_begin => "<td>",
            _table_cell_end   => "</td>",
            _table_row_begin  => "<tr>",
            _table_row_end    => "</tr>\n",
            _verse            => '',
        );
        %Xmtag = (_default => { cmd => 'em' });
        %Xdtag = (_default => { cmd => 'div' });
    }

    if ($Opts{target_format} eq "epub") {
        $Param{'epub-version'} = "2";
    }
    %loXstack = (
        toc => [],
        nav => [],
        lot => [],
        lof => [],
    );
    %InfosFlag = (
        use_verse    => 0,
        use_minitoc  => 0,
        has_part     => 0,
        has_chapter  => 0,
        use_graphicx => 0,
        dominilof    => 0,
        dominilot    => 0,
        dominitoc    => 0,
    );
    $Param{lang}   = "en";
    $Param{_index} = "Index";
    %Filters = defined $Opts{filters} ? %{ $Opts{filters} } : ();
    %ID      = ();
    @Image   = ();
}    # ]]]

sub init_state {    # [[[
    %State = (
        lnum                   => undef,    # current line number
        macro                  => undef,    # current macro name
        text                   => "",       # accumulated text
        _table_title           => undef,
        _xhtml_navigation_text => "",
    );
    %Flag = (
        'fr-nbsp-auto'   => 1,              # automatically add nbsps
        _ignore_text     => 0,              # whether to ignore text lines
        _frundis_warning => 0,
        _no_warnings     => 0,
        ns               => 0,              # no-space mode
        _perl            => 0,
        _verbatim        => 0,              # verbatim mode
    );
    %Scope = (
        Bd        => [],                    # list of nested .Bd macros
        Bl        => [],                    # list of nested .Bl macros
        Bm        => [],                    # list of nested .Bm macros
        "#if"     => [],                    # list of nested .#if macros
        de        => 0,                     # in macro definition
        if_ignore => 0,
        item      => 0,                     # under a non closed <it>
        paragraph => 0,                     # under a non closed <p>
    );
    reset_Bf_macro_state();
    reset_de_macro_state();
    %UserMacroCall = (
        depth => 0,
        file  => undef,
        lnum  => undef,
        name  => undef,
    );
    %Count = (
        chapter             => 0,
        fig                 => 0,
        header              => 0,
        numbered_chapter    => 0,
        numbered_part       => 0,
        numbered_section    => 0,
        numbered_subsection => 0,
        part                => 0,
        section             => 0,
        subsection          => 0,
        table               => 0,
    );
    %Macro = defined $Opts{user_macros} ? %{ $Opts{user_macros} } : ();
    $Self->{vars} = {};
}    # ]]]

sub interpolate_vars {    # [[[
    my $text = shift;
    my $vars = $Self->{vars};
    $text =~ s|\\\*\[([^\]]*)\]|
        my $name = $1;
        my $repl = $vars->{$name};
        if (defined $repl) { $repl }
        else { 
            diag_warning("variable interpolation:undefined variable:$name");
            "";
        }
    |gex;
    return $text;
}    # ]]]

sub loX_entry_infos {    # [[[
    my $opts   = shift;
    my $title  = $opts->{title};
    my $count  = $opts->{count};
    my $class  = $opts->{class};
    my $prefix = $opts->{href_prefix};
    my $href   = xhtml_gen_href($prefix, $count);
    $Self->{loX}{$class}{$title} = {
        href        => $href,
        href_prefix => $prefix,
        count       => $count,
    };
    unless (defined $loXstack{$class}) {
        $loXstack{$class} = [];
    }

    push @{ $loXstack{$class} },
      {
        href_prefix => $prefix,
        href        => $href,
        count       => $count,
        title       => $title,
      };
}    # ]]]

sub phrasing_macro_begin {    # [[[
    my $ns = shift;
    chomp $State{text};
    if (!$Flag{ns} and !$ns and ($State{wants_space} or $State{text})) {
        $State{text} .= $State{inline} ? " " : "\n";
    }
    phrasing_macro_handle_whitespace();
}    # ]]]

sub phrasing_macro_end {    # [[[
    chomp $State{text};
    phrasing_macro_handle_whitespace();
}    # ]]]

sub phrasing_macro_handle_whitespace {    # [[[
    if (!$Scope{paragraph} and !$Scope{item} and !$State{inline}) {
        handle_paragraph_begin();
    }
    else {
        give_wanted_space();
        flush_normal_text();
    }
    $State{wants_space} = !$Flag{ns};
}    # ]]]

sub paragraph_begin {    # [[[
    print $Param{_paragraph_begin};
    reopen_spanning_blocks();
    $Scope{paragraph} = 1;
}    # ]]]

sub paragraph_end {    # [[[
    chomp $State{text};
    give_wanted_space();
    flush_normal_text();
    close_spanning_blocks();
    print $Param{_paragraph_end};
}    # ]]]

sub parse_options {    # [[[
    my ($spec, $cmd) = @_;
    $cmd //= $State{macro};
    my %opts;
    while (@Arg) {
        my $flag = $Arg[0];
        last unless ($flag =~ s/^-//);
        $flag = escape($flag);
        shift @Arg;
        unless ($spec->{$flag}) {

            diag_error("`$cmd' macro invocation: unrecognized option: -$flag");
            next;
        }
        if ($spec->{$flag} eq "s") {

            # string argument
            unless (@Arg) {
                diag_error(
                    "`$cmd' macro invocation: option -$flag requires an argument"
                );
                next;
            }
            my $arg = shift(@Arg);
            if (defined $arg and $arg !~ /^-/) {
                $opts{$flag} = $arg;
            }
        }
        elsif ($spec->{$flag} eq "b") {

            # boolean flag
            $opts{$flag} = 1;
        }
    }
    return %opts;
}    # ]]]

sub parse_macro_line {    # [[[
    my $text = shift;
    my $macro;
    if ($text =~ s/^(\S+)//) {
        $macro = $1;
    }
    else {
        return ();
    }
    my @args;
    while (
        $text =~ /
        \s*
        (?| 
            "( (?| [^"] | "" )* ) "? # quoted string: "" is preserved inside
          |
            (\S+)                    # unquoted string
        )
        /xg
      )
    {
        my $arg = $1;
        $arg =~ s/""/"/g;
        push @args, $arg;
    }
    return $macro, \@args;
}    # ]]]

sub print_file {    # [[[
    my ($file, $msg) = @_;
    unless (-f $file) {
        $file = search_inc_file($file);
    }
    $msg //= "";
    open(my $fh, '<', $file)
      or diag_fatal("$msg:$file:$!");
    my $text;
    { local $/; $text = <$fh>; }
    close $fh;
    print $text;
}    # ]]]

sub print_filter {    # [[[
    my ($cmd, $text) = @_;
    require File::Temp;

    my $tmp = File::Temp->new(EXLOCK => 0);
    binmode($tmp, ':encoding(utf-8)');

    print $tmp $text;
    local $?;
    my $filtered_text = qx#<$tmp $cmd#;
    if ($?) {
        diag_warning(
            "`$State{macro}' macro:error in command '<$tmp $cmd':status $?:$filtered_text"
        );
    }
    else {
        print $filtered_text;
    }
    close $tmp;
}    # ]]]

sub process_inline_macros {    # [[[
    my $title_render = "";
    local @Arg = @Arg;
    {
        local *STDOUT;
        open(STDOUT, '>', \$title_render) or die "redirecting stdout:$!";

        # parse arguments
        my @arglist = ([]);
        while (@Arg) {
            my $word = shift @Arg;
            if ($word =~ /^(?:Bm|Em|Sm)$/) {
                push @arglist, [$word];
            }
            else {
                push @{ $arglist[$#arglist] }, $word;
            }
        }
        local $State{wanted_space} = 0;
        local $State{wants_space}  = 0;
        foreach my $args (@arglist) {
            next unless @$args;
            if ($args->[0] =~ /^(?:Bm|Em|Sm)$/) {
                my $macro = shift @$args;
                local $State{inline} = 1;
                local $State{macro}  = $macro;
                local @Arg           = @$args;
                $BuiltinMacroHandler{$macro}->();
            }
            else {
                print escape_text(args_to_text($args));
                $State{wants_space} = 1;
            }
        }
        close STDOUT;
    }

    return Encode::decode_utf8($title_render);
}    # ]]]

sub reopen_spanning_blocks {    # [[[
    my $stack = $Scope{Bm};
    foreach my $st (@$stack) {
        my $begin_macro = $st->{macro};

        my $begin;
        if (defined $st->{t}) {
            $begin = enclose_begin(
                $Xmtag{ $st->{t} }{cmd},
                { class => $st->{t} }
            );
        }
        $begin //= enclose_begin($Xmtag{_default}{cmd});

        print $begin;
    }
}    # ]]]

sub reset_Bf_macro_state {    # [[[
    %BfMacro = (
        begin_lnum => undef,
        begin_file => undef,
        in_macro   => 0,
        filter     => undef,
    );
}    # ]]]

sub reset_de_macro_state {    # [[[
    %DeMacro = (
        text   => "",
        name   => undef,
        lnum   => undef,
        perl   => 0,
        ignore => 0,
        file   => undef,
    );
}    # ]]]

sub scope_stack_push {    # [[[
    my ($type, $tag, $id) = @_;
    $Scope{$type} = [] unless defined $Scope{$type};
    push @{ $Scope{$type} },
      {
        t     => $tag,
        id    => $id,
        macro => $State{macro},
        lnum  => $UserMacroCall{depth} > 0
        ? $UserMacroCall{lnum}
        : $State{lnum},
        in_user_macro => $UserMacroCall{depth} > 0 ? 1 : 0,
        file => $UserMacroCall{depth} > 0 ? $UserMacroCall{file} : $File,
      };
}    # ]]]

sub search_inc_file {    # [[[
    my $file = shift;
    foreach (@FrundisINC) {
        my $fpath = catfile($_, $file);
        if (-f $fpath) {
            $file = $fpath;
            last;
        }
    }
    return $file;
}    # ]]]

sub slurp_file {    # [[[
    my ($file) = @_;
    open(my $fh, '<', $file)
      or diag_fatal("$file:$!");
    my $text;
    { local $/; $text = <$fh>; }
    close $fh;
    return $text;
}    # ]]]

sub test_for_unclosed_block {    # [[[
    my ($type) = @_;
    my $stack = $Scope{$type};
    if (@$stack) {
        my $st          = $stack->[ $#{$stack} ];
        my $begin_macro = $st->{macro};
        my $end_macro   = $BlockEnd{$begin_macro};
        my $Bfile       = $File eq $st->{file} ? "" : " of file $st->{file}";
        my $in_user_macro =
          $st->{in_user_macro} ? " opened inside user macro" : "";
        my $type = $st->{t} ? " of type $st->{t} " : "";

        my $macro = $State{macro};
        $macro = "`.$macro' macro" if $macro ne "End Of File";
        my $msg =
          !$State{inline}
          ? "found $macro while `.$begin_macro' macro${type}${in_user_macro} at line"
          . " $st->{lnum}$Bfile isn't closed yet by a `.$end_macro'"
          : "unclosed inline markup block${type}${in_user_macro}";
        diag_error($msg);
        return 1;
    }
    return 0;
}    # ]]]

sub test_for_unclosed_de {    # [[[
    if ($Scope{de}) {
        diag_error("found End Of File while `.#de' macro at line"
              . " $DeMacro{lnum} of file $DeMacro{file} isn't closed by a `.#.'"
        );
    }
}    # ]]]

sub test_for_unclosed_format_block {    # [[[
    if ($Scope{format}) {
        my $Bf_file =
          $File eq $BfMacro{begin_file}
          ? ""
          : " of file $BfMacro{begin_file}";
        my $in_user_macro =
          $BfMacro{in_macro} ? " opened inside user macro" : "";
        diag_error("`.$State{macro}' not allowed inside scope of "
              . "`.Bf' macro$in_user_macro at line $BfMacro{begin_lnum}$Bf_file"
        );
        return 1;
    }
    return 0;
}    # ]]]

sub test_if_not_allowed_macro {    # [[[
    my $macro = shift;
    if ($macro !~ /^Ef$/ and test_for_unclosed_format_block()) {
        return 1;
    }
    elsif ($Flag{_verbatim} and $macro !~ /^Ef|Ed$/) {
        diag_error(
            "`$macro' macro is not allowed inside `.Bf' or `.Bd -t literal' macro scope"
        );
        return 1;
    }
    elsif ( @{ $Scope{Bl} }
        and $Scope{Bl}->[0]->{t} ne "verse"
        and not $AllowedInBl{$macro})
    {
        diag_error(
            "`.$macro' macro not allowed inside list of type ``$Scope{Bl}->[0]->{t}''"
        );
        return 1;
    }
    return 0;
}    # ]]]

################################################################################
# Format specific functions, in alphabetic order.

sub epub_copy_images {    # [[[
    my $images_dir = catdir($Opts{output_file}, "EPUB", "images");
    unless (-d $images_dir) {
        mkdir $images_dir
          or diag_fatal("$images_dir:$!")
          unless not @Image and not defined $Param{'epub-cover'};
    }

    foreach my $image (@Image, $Param{'epub-cover'}) {
        next unless $image;
        my $image_name = basename($image);
        unless (-f $image) {
            $image = search_inc_file($image);
        }
        unless (-f $image) {
            diag_fatal("image copy:$image:no such file");
        }
        my $new_image = catfile($images_dir, $image_name);
        next if -f $new_image;
        copy($image, $new_image)
          or diag_fatal("image copy:$image to $new_image:$!");
    }
}    # ]]]

sub epub_gen {    # [[[
    unless ($Param{'document-title'}) {
        diag_error("EPUB requires document-title parameter to be set");
    }
    my $title = $Param{'document-title'} // "";
    my $lang = $Param{lang};

    epub_gen_mimetype();

    epub_copy_images();

    # now 'epub-cover' is copied: preserve only the name
    my $cover = $Param{'epub-cover'};
    $cover = basename($cover) if $cover;

    epub_gen_container();

    epub_gen_content_opf($title, $lang, $cover);

    if ($Param{'epub-version'} =~ /^3/) {
        epub_gen_nav($title);
    }

    epub_gen_css();

    epub_gen_ncx($title);

    if ($cover) {
        epub_gen_cover($title, $cover);
    }

}    # ]]]

sub epub_gen_container {    # [[[
    my $container_xml =
      catfile($Opts{output_file}, "META-INF", "container.xml");
    open(my $fh, '>', $container_xml)
      or diag_fatal("$container_xml:$!");

    print $fh <<EOS;
<?xml version="1.0" encoding="utf-8"?>
EOS

    print $fh <<EOS;
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
<rootfiles>
<rootfile full-path="EPUB/content.opf" media-type="application/oebps-package+xml" />
</rootfiles>
</container>
EOS
    close $fh;
}    # ]]]

sub epub_gen_content_opf {    # [[[
    my ($title, $lang, $cover) = @_;
    my $content_opf = catfile($Opts{output_file}, 'EPUB', 'content.opf');
    local *STDOUT;
    open(STDOUT, '>', $content_opf) or diag_fatal($!);

    # EPUB/content.opf
    print <<EOS;
<?xml version="1.0" encoding="utf-8"?>
EOS
    my $deterministic;
    if (defined $Param{'epub-uuid'}) {
        $deterministic = 1;
    }

    unless (defined $Param{'epub-uuid'}) {

        local $@;
        eval 'require Data::UUID;';
        if ($@) {
            diag_warning(
                "Data::UUID module not found, falling back to use system time as unique id for epub"
            );
            $Param{'epub-uuid'} = "epoch:" . time;
        }
        else {
            my $ug   = Data::UUID->new;
            my $uuid = $ug->create();
            $Param{'epub-uuid'} = "urn:uuid:" . $ug->to_string($uuid);
        }
    }
    chomp $Param{'epub-uuid'};
    print <<EOS if $Param{'epub-version'} =~ /^3/;
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="epub-id-1">
EOS
    print <<EOS if $Param{'epub-version'} =~ /^2/;
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="epub-id-1">
EOS
    print <<EOS;
<metadata xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:opf="http://www.idpf.org/2007/opf">
<dc:identifier id="epub-id-1">$Param{'epub-uuid'}</dc:identifier>
EOS
    print <<EOS;
<dc:language>$lang</dc:language>
<dc:title id="epub-title-1">$title</dc:title>
EOS
    if ($Param{'epub-version'} =~ /^3/) {
        require POSIX;
        my $time;
        if ($deterministic) {
            $time = "0001-01-01T01:01:01Z";
        }
        else {
            $time = POSIX::strftime("%Y-%m-%dT%H:%M:%SZ", gmtime);
        }
        print <<EOS if $Param{'epub-version'} =~ /^3/;
<meta property="dcterms:modified">$time</meta>
EOS
    }
    if ($Param{'epub-subject'}) {
        print <<EOS;
<dc:subject id="epub-subject-1">$Param{'epub-subject'}</dc:subject>
EOS
    }
    if ($Param{'document-author'}) {
        print <<EOS;
<dc:creator id="epub-creator-1">$Param{'document-author'}</dc:creator>
EOS
    }
    print <<EOS if $cover and not $Param{'epub-version'} !~ /^3/;
<meta name="cover" content="cover-image" />
EOS
    if ($Param{'epub-metadata'}) {
        print_file($Param{'epub-metadata'}, "epub-metadata");
    }
    print <<EOS;
</metadata>
<manifest>
EOS
    print <<EOS if $Param{'epub-version'} =~ /^3/;
<item id="nav"
      href="nav.xhtml"
      properties="nav"
      media-type="application/xhtml+xml" />
EOS
    print <<EOS;
<item id="epub2_ncx"
      href="toc.ncx"
      media-type="application/x-dtbncx+xml" />
EOS

    if ($cover) {
        my $cover_path = catfile('images', $cover);
        print <<EOS;
<item id="cover"
      href="$cover_path"
EOS
    }
    print <<EOS if $cover and $Param{'epub-version'} =~ /^3/;
      properties="cover-image"
EOS
    print <<EOS if $cover;
      media-type="image/jpeg" />
EOS
    print <<EOS if $cover;
<item id="cover_xhtml"
      href="cover.xhtml"
      media-type="application/xhtml+xml" />
EOS

    print <<EOS;
<item id="index" href="index.xhtml" media-type="application/xhtml+xml" />
EOS
    foreach (@{ $loXstack{toc} }) {
        next unless $_->{macro} =~ /^(?:Pt|Ch)$/;
        my $href = $_->{href};
        my $id   = $_->{id};
        print <<EOS;
<item id="$id" href="$href" media-type="application/xhtml+xml" />
EOS
    }
    print <<EOS;
<item id="css"
      href="stylesheet.css"
      media-type="text/css" />
EOS
    foreach my $image_name (@Image) {
        my $media_type;
        if ($image_name =~ /\.png$/) {
            $media_type = "image/png";
        }
        elsif ($image_name =~ /\.jpe?g$/) {
            $media_type = "image/jpeg";
        }
        elsif ($image_name =~ /\.gif$/) {
            $media_type = "image/gif";
        }
        elsif ($image_name =~ /\.svg$/) {
            $media_type = "image/svg";
        }
        my $image_bname = basename($image_name);
        my $image_path = catfile('images', $image_bname);
        $image_bname = escape_xhtml_text($image_bname);
        $image_path  = escape_xhtml_text($image_path);
        print <<EOS;
<item id="$image_bname"
      href="$image_path"
      media-type="$media_type" />
EOS
    }

    print <<EOS;
</manifest>
<spine toc="epub2_ncx">
EOS
    print <<EOS if $cover;
<itemref idref="cover_xhtml" />
EOS
    print <<EOS;
<itemref idref="index" />
EOS
    foreach (@{ $loXstack{toc} }) {
        next unless $_->{macro} =~ /^(?:Pt|Ch)$/;
        my $name = $_->{id};
        print <<EOS;
<itemref idref="$name" />
EOS
    }
    print <<EOS if $Param{'epub-version'} =~ /^3/;
<itemref idref="nav" linear="no" />
EOS
    print <<EOS;
</spine>
<guide>
EOS
    print <<EOS if $cover;
<reference type="cover" title="cover" href="cover.xhtml" />
EOS
    print <<EOS;
</guide>
EOS
    print <<EOS;
</package>
EOS
}    # ]]]

sub epub_gen_cover {    # [[[
    my ($title, $cover) = @_;
    my $cover_xhtml = catfile($Opts{output_file}, 'EPUB', 'cover.xhtml');
    local *STDOUT;
    open(STDOUT, '>', $cover_xhtml) or diag_fatal("$cover_xhtml:$!");
    print <<EOS;
<?xml version="1.0" encoding="utf-8"?>
EOS
    xhtml_and_epub_common_header();
    print <<EOS;
  <title>$title</title>
  <link rel="stylesheet" type="text/css" href="stylesheet.css" />
  </head>
  <body>
    <div id="cover-image" class="cover-image">
      <img class="cover-image" src="images/$cover" alt="cover image" />
    </div>
  </body>
</html>
EOS

}    # ]]]

sub epub_gen_css {    # [[[
    my $css_text = "";
    if ($Param{'epub-css'}) {
        unless (-f $Param{'epub-css'}) {
            $Param{'epub-css'} = search_inc_file($Param{'epub-css'});
        }
        open(my $fh, '<', "$Param{'epub-css'}")
          or diag_fatal("parameter epub-css:$Param{'epub-css'}:$!");
        local $/;
        $css_text = <$fh>;
        close $fh;
    }
    my $stylesheet_css = catfile($Opts{output_file}, 'EPUB', 'stylesheet.css');
    open(my $fh, '>', $stylesheet_css)
      or diag_fatal("$stylesheet_css:$!");

    # EPUB/stylesheet.css
    print $fh $css_text;
    close $fh;
}    # ]]]

sub epub_gen_mimetype {    # [[[
    my $mimetype = "application/epub+zip";
    my $mimetype_path = catfile($Opts{output_file}, 'mimetype');
    open(my $fh, '>', $mimetype_path)
      or diag_fatal("$mimetype_path:$!");
    print $fh $mimetype;
    close $fh;
}    # ]]]

sub epub_gen_nav {    # [[[
    my $title = shift;
    my $nav_xhtml = catfile($Opts{output_file}, 'EPUB', 'nav.xhtml');
    local *STDOUT;
    open(STDOUT, '>', $nav_xhtml)
      or diag_fatal("$nav_xhtml:$!");
    print <<EOS;
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="$Param{lang}"
      xmlns:epub="http://www.idpf.org/2007/ops">
<head>
    <meta charset="utf-8" />
EOS
    print <<EOS if $title;
    <title>$title</title>
    <link rel="stylesheet" type="text/css" href="stylesheet.css" />
</head>
<body>
EOS
    print <<EOS;

EOS

    xhtml_toc("nav");
    print_file($Param{'epub-nav-landmarks'})
      if $Param{'epub-nav-landmarks'};

    print <<EOS;
</body>
</html>
EOS
}    # ]]]

sub epub_gen_ncx {    # [[[
    my ($title) = @_;
    my $toc_ncx = catfile($Opts{output_file}, 'EPUB', 'toc.ncx');
    local *STDOUT;
    open(STDOUT, '>', $toc_ncx)
      or diag_fatal("$toc_ncx:$!");

    print <<EOS;
<?xml version="1.0" encoding="utf-8"?>
<ncx version="2005-1" xmlns="http://www.daisy.org/z3986/2005/ncx/">
  <head>
    <meta name="dtb:uid" content="urn:uuid:$Param{'epub-uuid'}" />
    <meta name="dtb:depth" content="2" />
    <meta name="dtb:totalPageCount" content="0" />
    <meta name="dtb:maxPageNumber" content="0" />
    <meta name="cover" content="cover-image" />
  </head>
EOS
    print <<EOS if $title;
  <docTitle>
    <text>$title</text>
  </docTitle>
EOS
    xhtml_toc("ncx");
    print <<EOS;
</ncx>
EOS
}    # ]]]

sub latex_document_begin {    # [[[
    my $lang       = $Param{lang};
    my $lang_babel = $Lang_babel{$lang} // "english";
    my $lang_mini  = $Lang_mini{$lang} // "english";

    my $title  = $Param{'document-title'}  // "";
    my $author = $Param{'document-author'} // "";
    my $date   = $Param{'document-date'}   // "";
    if ($Param{'latex-preamble'}) {
        print_file($Param{'latex-preamble'}, "latex-preamble");
    }
    else {
        if ($InfosFlag{has_chapter} or $InfosFlag{has_part}) {
            print <<EOS;
\\documentclass[a4paper,11pt]{book}
EOS
        }
        else {
            print <<EOS;
\\documentclass[a4paper,11pt]{article}
EOS
        }
        print <<EOS;
\\usepackage[T1]{fontenc}
\\usepackage[utf8]{inputenc}
\\usepackage[$lang_babel]{babel}
EOS
        print <<EOS if $InfosFlag{use_minitoc};
\\usepackage[$lang_mini]{minitoc}
EOS
        print <<EOS if $InfosFlag{use_verse};
\\usepackage{verse}
EOS
        print <<EOS if $InfosFlag{use_graphicx};
\\usepackage{graphicx}
EOS
        print <<EOS;
\\usepackage{verbatim}
\\usepackage[linkcolor=blue,colorlinks=true]{hyperref}

\\title{$title}
\\author{$author}
\\date{$date}
EOS
    }

    print "\\begin{document}\n";

    print "\\dominilof\n" if $InfosFlag{dominilof};
    print "\\dominilot\n" if $InfosFlag{dominilot};
    print "\\dominitoc\n" if $InfosFlag{dominitoc};

    print <<EOS if $Param{'title-page'};
\\maketitle
EOS
}

sub latex_document_end {
    print <<EOS;

\\end{document}
EOS
}    # ]]]

sub latex_header_name {    # [[[
    my $macro = shift;
    return
        $macro eq "Ch" ? "chapter"
      : $macro eq "Sh" ? "section"
      : $macro eq "Ss" ? "subsection"
      : $macro eq "Pt" ? "part"
      :   do { diag_error("internal_error:latex_header_name"); "section" };
}    # ]]]

sub xhtml_and_epub_common_header {    # [[[
    if (   $Opts{target_format} eq "epub" and $Param{'epub-version'} =~ /^3/
        or $Opts{target_format} eq "xhtml" and $Param{'xhtml5'})
    {
        print <<EOS;
<!DOCTYPE html>
EOS
    }
    else {
        print <<EOS;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
EOS
    }
    print <<EOS;
<html xmlns="http://www.w3.org/1999/xhtml" lang="$Param{lang}">
  <head>
EOS
    if ($Opts{target_format} eq "epub" and $Param{'epub-version'} =~ /^3/) {
        print <<EOS;
    <meta charset="utf-8" />
EOS
    }
    else {
        print <<EOS;
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
EOS
    }

}    # ]]]

sub xhtml_document_header {    # [[[
    my $title = shift;

    xhtml_and_epub_common_header();

    print <<EOS if $title;
    <title>$title</title>
EOS
    print <<EOS if $Param{favicon};
    <link rel="shortcut icon" type="image/x-icon" href="$Param{favicon}" />
EOS
    if ($Param{'epub-css'} and $Opts{target_format} eq "epub") {
        print <<EOS;
    <link rel="stylesheet" href="stylesheet.css" />
EOS
    }
    elsif ($Param{'xhtml-css'} and $Opts{target_format} eq "xhtml") {
        print <<EOS;
    <link rel="stylesheet" href="$Param{'xhtml-css'}" />
EOS
    }
    print <<EOS;
  </head>
  <body>
EOS
    if ($Opts{target_format} ne "epub" and $Param{'xhtml-top'}) {
        print_file($Param{'xhtml-top'}, "xhtml-top");
    }
}    # ]]]

sub xhtml_document_footer {    # [[[
    if ($Opts{target_format} ne "epub" and $Param{'xhtml-bottom'}) {
        print_file($Param{'xhtml-bottom'}, "xhtml-bottom");
    }
    print <<EOS;
  </body>
</html>
EOS
}    # ]]]

sub xhtml_file_output_change {    # [[[
    my $title = shift;

    if ($Opts{target_format} ne "epub" and $State{_xhtml_navigation_text}) {
        print $State{_xhtml_navigation_text};
    }
    xhtml_document_footer();

    my $out_file;
    if ($Opts{target_format} eq "epub") {
        $out_file = catfile(
            $Opts{output_file}, 'EPUB',
            "body-$Count{part}-$Count{chapter}.xhtml"
        );
    }
    else {
        $out_file =
          catfile($Opts{output_file}, "body-$Count{part}-$Count{chapter}.html");
    }
    open(STDOUT, '>', $out_file) or diag_fatal("$out_file:$!");
    xhtml_document_header($title);

    return if $Opts{target_format} eq "epub";

    # IF NOT EPUB

    my ($previous, $next);
    $previous = $loXstack{nav}->[ $State{nav_count} - 2 ]
      unless $State{nav_count} <= 1;
    $next = $loXstack{nav}->[ $State{nav_count} ]
      unless $State{nav_count} >= @{ $loXstack{nav} };

    $State{_xhtml_navigation_text} = <<EOS;
    <div class="topnav">
      <ul class="topnav">
EOS
    if (defined $previous) {
        my $href = $previous->{href};
        $State{_xhtml_navigation_text} .= <<EOS;
        <li><a href="$href">&lt;</a></li>
EOS
    }
    else {
        $State{_xhtml_navigation_text} .= <<EOS;
        <li>&lt;</li>
EOS
    }
    $State{_xhtml_navigation_text} .= <<EOS;
        <li><a href="index.html">$Param{_index}</a></li>
EOS
    if (defined $next) {
        my $href = $next->{href};
        $State{_xhtml_navigation_text} .= <<EOS;
        <li><a href="$href">&gt;</a></li>
EOS
    }
    else {
        $State{_xhtml_navigation_text} .= <<EOS;
        <li>&gt;</li>
EOS
    }
    $State{_xhtml_navigation_text} .= <<EOS;
      </ul>
    </div>
EOS
    print $State{_xhtml_navigation_text};

}    # ]]]

sub xhtml_loX {    # [[[
    my ($class) = @_;
    diag_warning("frundis:warning:no '$class' information found, skipping\n")
      and return
      unless defined $loXstack{$class}
      and @{ $loXstack{$class} };
    print qq{<div class="$class">\n};
    print qq{  <ul>\n};

    foreach my $entry (@{ $loXstack{$class} }) {
        xhtml_toc_like_entry($entry, {}, 1);
    }
    print qq{  </ul>\n};
    print qq{</div>\n};
}    # ]]]

sub xhtml_gen_href {    # [[[
    my ($prefix, $count, $hasfile) = @_;
    my $href;
    if ($Opts{all_in_one_file}) {
        $href = "#$prefix$count";
    }
    elsif ($hasfile) {
        my $suffix = $Opts{target_format} eq "epub" ? ".xhtml" : ".html";
        $href = "body-$Count{part}-$Count{chapter}" . $suffix;
    }
    else {
        my $suffix = $Opts{target_format} eq "epub" ? ".xhtml" : ".html";
        $href =
          ($Count{part} || $Count{chapter})
          ? "body-$Count{part}-$Count{chapter}$suffix#$prefix$count"
          : "index$suffix#$prefix$count";
    }
    return $href;
}    # ]]]

sub xhtml_lof {    # [[[
    xhtml_loX("lof");
}    # ]]]

sub xhtml_lot {    # [[[
    xhtml_loX("lot");
}    # ]]]

sub xhtml_section_header {    # [[[
    my $macro = shift;
    return "h" . header_level($macro);
}    # ]]]

sub xhtml_titlepage {    # [[[
    if ($Param{'title-page'}) {
        warn
          "frundis:warning:parameter ``title-page'' set to 1 but no document title specified\n"
          unless $Param{'document-title'};
        warn
          "frundis:warning:parameter ``title-page'' set to 1 but no document date specified\n"
          unless $Param{'document-date'};
        warn
          "frundis:warning:parameter ``title-page'' set to true value but no document "
          . "author specified with ``document-author'' parameter\n"
          unless $Param{'document-author'};
        print <<EOS if $Param{'document-title'};
<h1 class="title">$Param{'document-title'}</h1>
EOS
        print <<EOS if $Param{'document-author'};
<h2 class="author">$Param{'document-author'}</h2>
EOS
        print <<EOS if $Param{'document-date'};
<h3 class="date">$Param{'document-date'}</h3>
EOS
    }
}    # ]]]

sub xhtml_toc {    # [[[
    my ($type, $opts) = @_;
    diag_warning(
        "frundis:warning:no TOC information found, skipping TOC generation\n")
      and return
      unless @{ $loXstack{toc} };
    $opts //= {};
    $opts->{prefix} = "s";
    $opts->{toc}    = 1;
    my $start      = 0;
    my $mini_macro = "Ch";
    if ($opts->{mini} and $State{nav_count}) {
        my $nav_entry = $loXstack{nav}->[ $State{nav_count} - 1 ];
        $start      = $nav_entry->{count};
        $mini_macro = $nav_entry->{macro};
    }

    my $close_list =
        $type eq "ncx" ? ""
      : $type eq "nav" ? "</ol>"
      :                  "</ul>";
    my $close_item =
        $type eq "ncx"   ? "</navPoint>"
      : $type eq "xhtml" ? "</li>"
      : $type eq "nav"   ? "</li>"
      :                    diag_error("internal_error:xhtml_toc");

    # TOC top
    if ($type eq "ncx") {
        print "<navMap>\n";
        my $title = $Param{'document-title'} // "";
        print <<EOS;
    <navPoint id="titlepage">
      <navLabel><text>$title</text></navLabel>
      <content src="index.xhtml" />
    </navPoint>
EOS
    }
    elsif ($type eq "xhtml") {
        print q{<div class="toc">}, "\n";
        my $title;
        if ($opts->{mini} or defined $opts->{title}) {
            $title = $opts->{title};
        }
        else {
            $title = $Param{'document-title'};
        }
        print <<EOS if $title;
    <h2 id="toc-title" class="toc-title">$title</h2>
EOS
        print "  <ul>\n";
    }
    elsif ($type eq "nav") {
        print qq{<nav epub:type="toc" id="navtoc">\n};
        print <<EOS if $Param{'document-title'};
    <h2 id="toc-title" class="toc-title">$Param{'document-title'}</h2>
EOS
        print "  <ol>\n";
    }

    # TOC entries
    # $level: the actual depth level of the entry in TOC.
    # $title_level: the level of the title (1 for Pt, 2 for Ch, etc.)
    # $previous_title_level: the level of the previous title
    my $level                = 0;    # 0 for first iteration
    my $previous_title_level = 1;
    for (my $i = $start ; $i <= $#{ $loXstack{toc} } ; $i++) {
        my $entry = $loXstack{toc}->[$i];
        my $macro = $entry->{macro};
        if ($opts->{mini}) {
            last if $macro eq $mini_macro or $macro eq "Pt";
        }
        if ($opts->{summary}) {
            if ($opts->{mini} and $mini_macro eq "Ch") {
                next unless $macro eq "Sh";
            }
            else {
                next unless $macro =~ /^(?:Pt|Ch)$/;
            }
        }
        my $title_level = header_level($macro);

        # Computation of $level and $previous_title_level
        if ($level == 0) {
            $level                = 1;
            $previous_title_level = $title_level;
        }
        elsif ($title_level > $previous_title_level) {
            my $diference = $title_level - $previous_title_level;
            if ($type eq "xhtml") {
                print "  " x ($level + 1), "<ul>\n";
            }
            elsif ($type eq "nav") {
                print "  " x ($level + 1), "<ol>\n";
            }
            $previous_title_level = $title_level;
            $level                = $level + $diference;
        }
        elsif ($title_level < $previous_title_level) {
            my $diference = $title_level - $previous_title_level;
            $diference = 1 - $level if $diference + $level < 1;
            print "  " x ($level + 1), "$close_item\n";
            for (my $i = $level ; $i > $level + $diference ; $i--) {
                print "  " x $i, "$close_list$close_item\n";
            }
            $previous_title_level = $title_level;
            $level                = $level + $diference;
            $level                = 1 if $level < 1;
        }
        elsif ($title_level == $previous_title_level) {
            print "  " x ($level + 1), "$close_item\n";
        }

        # Print entry
        if ($type eq "ncx") {
            my $num = $entry->{num};
            $num = "$num. " if $num;
            print "  " x ($level + 1), qq{<navPoint id="$entry->{href}">\n};
            print "  " x ($level + 2),
              qq{<navLabel><text>$num$entry->{title}</text></navLabel>\n};
            my $href = $entry->{href};
            print "  " x ($level + 2), qq{<content src="$href" />\n};
        }
        elsif ($type eq "xhtml") {
            xhtml_toc_like_entry($entry, $opts, $level);
        }
        elsif ($type eq "nav") {
            my $href = $entry->{href};
            my $num  = $entry->{num};
            $num = "$num. " if $num;
            print "  " x ($level + 1),
              qq{<li><a href="$href">$num$entry->{title}</a>\n};
        }
    }
    print "  " x ($level + 1), "$close_item\n" if $level > 0;
    for (my $i = $level ; $i > 1 ; $i--) {
        print "  " x $i, "$close_list$close_item\n";
    }

    # TOC bottom
    if ($type eq "ncx") {
        print "</navMap>", "\n";
    }
    elsif ($type eq "xhtml") {
        print "  </ul>", "\n";
        print "</div>",  "\n";
    }
    elsif ($type eq "nav") {
        print "  </ol>", "\n";
        print "</nav>",  "\n";
    }
}    # ]]]

sub xhtml_toc_like_entry {    # [[[
    my ($entry, $opts, $level) = @_;
    my $href = $entry->{href};
    my $num  = "";
    unless ($opts->{nonum}
        or ($href =~ /^index/ and not $Opts{all_in_one_file}))
    {
        if ($opts->{toc}) {
            $num = $entry->{num};
            $num .= ". " if $num;
        }
        else {
            $num = "$entry->{count}. ";
        }
    }
    if ($Opts{all_in_one_file}) {
        print "  " x ($level + 1),
          qq{<li><a href="$entry->{href}">$num$entry->{title}</a>\n};
    }
    else {
        print "  " x ($level + 1),
          qq{<li><a href="$href">$num$entry->{title}</a>\n};
    }
}    # ]]]

1;

# vim:foldmarker=[[[,]]]:foldmethod=marker:sw=4:sts=4:expandtab
