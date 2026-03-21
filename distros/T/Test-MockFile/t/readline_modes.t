#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw< nostrict >;

my $filename = '/tmp/readline_modes_test';

# ============================================================
# Slurp mode: $/ = undef
# ============================================================

note "-------------- SLURP MODE (\$/ = undef) --------------";

{
    note "Slurp from beginning of file";
    my $mock = Test::MockFile->file( $filename, "line1\nline2\nline3\n" );
    open( my $fh, '<', $filename ) or die "open: $!";
    my $content = do { local $/; <$fh> };
    is( $content, "line1\nline2\nline3\n", "Slurp from tell=0 returns entire contents" );
    is( eof($fh), 1, "EOF after slurp" );
    close $fh;
}

{
    note "Slurp from non-zero tell position";
    my $mock = Test::MockFile->file( $filename, "ABCDEFGHIJ" );
    open( my $fh, '<', $filename ) or die "open: $!";
    read( $fh, my $buf, 4 );    # Read "ABCD", tell is now 4
    is( $buf, "ABCD", "Read first 4 bytes" );
    my $rest = do { local $/; <$fh> };
    is( $rest, "EFGHIJ", "Slurp from tell=4 returns remainder" );
    is( eof($fh), 1, "EOF after partial slurp" );
    close $fh;
}

{
    note "Slurp empty file";
    my $mock = Test::MockFile->file( $filename, "" );
    open( my $fh, '<', $filename ) or die "open: $!";
    my $content = do { local $/; <$fh> };
    is( $content, undef, "Slurp on empty file returns undef" );
    close $fh;
}

{
    note "Slurp in list context";
    my $mock = Test::MockFile->file( $filename, "all\nin\none\n" );
    open( my $fh, '<', $filename ) or die "open: $!";
    my @lines = do { local $/; <$fh> };
    is( \@lines, ["all\nin\none\n"], "Slurp in list context returns single element" );
    close $fh;
}

# ============================================================
# Fixed-record mode: $/ = \N
# ============================================================

note "-------------- FIXED-RECORD MODE (\$/ = \\N) --------------";

{
    note "Read in 5-byte records";
    my $mock = Test::MockFile->file( $filename, "ABCDEFGHIJKLM" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = \5;
    my $r1 = <$fh>;
    my $r2 = <$fh>;
    my $r3 = <$fh>;    # Only 3 bytes left
    my $r4 = <$fh>;    # EOF

    is( $r1, "ABCDE",  "First 5-byte record" );
    is( $r2, "FGHIJ",  "Second 5-byte record" );
    is( $r3, "KLM",    "Third record (partial, 3 bytes left)" );
    is( $r4, undef,    "Fourth read returns undef (EOF)" );
    close $fh;
}

{
    note "Fixed-record in list context";
    my $mock = Test::MockFile->file( $filename, "ABCDEFGH" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = \3;
    my @records = <$fh>;
    is( \@records, [ "ABC", "DEF", "GH" ], "List context returns all fixed-size records" );
    close $fh;
}

{
    note "Fixed-record with 1-byte records";
    my $mock = Test::MockFile->file( $filename, "XYZ" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = \1;
    my @chars = <$fh>;
    is( \@chars, [ "X", "Y", "Z" ], "1-byte records return individual characters" );
    close $fh;
}

{
    note "Fixed-record larger than file";
    my $mock = Test::MockFile->file( $filename, "small" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = \100;
    my $r1 = <$fh>;
    my $r2 = <$fh>;
    is( $r1, "small", "Record larger than file returns all contents" );
    is( $r2, undef,   "Second read returns undef" );
    close $fh;
}

# ============================================================
# Paragraph mode: $/ = ''
# ============================================================

note "-------------- PARAGRAPH MODE (\$/ = '') --------------";

{
    note "Two paragraphs separated by blank line";
    my $mock = Test::MockFile->file( $filename, "para1 line1\npara1 line2\n\npara2 line1\n" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = '';
    my $p1 = <$fh>;
    my $p2 = <$fh>;
    my $p3 = <$fh>;
    is( $p1, "para1 line1\npara1 line2\n\n", "First paragraph with collapsed \\n\\n" );
    is( $p2, "para2 line1\n",                "Second paragraph (last, no trailing blank)" );
    is( $p3, undef,                          "Third read returns undef (EOF)" );
    close $fh;
}

{
    note "Multiple blank lines between paragraphs (collapsed)";
    my $mock = Test::MockFile->file( $filename, "first\n\n\n\nsecond\n" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = '';
    my $p1 = <$fh>;
    my $p2 = <$fh>;
    is( $p1, "first\n\n",  "First paragraph with collapsed separator" );
    is( $p2, "second\n",   "Second paragraph after multiple blank lines" );
    close $fh;
}

{
    note "Leading blank lines are skipped";
    my $mock = Test::MockFile->file( $filename, "\n\n\nhello\n\nworld\n" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = '';
    my $p1 = <$fh>;
    my $p2 = <$fh>;
    my $p3 = <$fh>;
    is( $p1, "hello\n\n",  "First paragraph (leading blanks skipped)" );
    is( $p2, "world\n",    "Second paragraph" );
    is( $p3, undef,        "EOF" );
    close $fh;
}

{
    note "Single paragraph, no blank lines";
    my $mock = Test::MockFile->file( $filename, "just one\nparagraph\n" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = '';
    my $p1 = <$fh>;
    my $p2 = <$fh>;
    is( $p1, "just one\nparagraph\n", "Single paragraph returned whole" );
    is( $p2, undef,                   "EOF" );
    close $fh;
}

{
    note "Paragraph mode in list context";
    my $mock = Test::MockFile->file( $filename, "p1\n\np2\n\np3\n" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = '';
    my @paras = <$fh>;
    is( \@paras, [ "p1\n\n", "p2\n\n", "p3\n" ], "List context returns all paragraphs" );
    close $fh;
}

{
    note "File is only blank lines";
    my $mock = Test::MockFile->file( $filename, "\n\n\n" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = '';
    my $p1 = <$fh>;
    is( $p1, undef, "File with only newlines returns undef in paragraph mode" );
    close $fh;
}

{
    note "Paragraph without trailing newline";
    my $mock = Test::MockFile->file( $filename, "abc\n\ndef" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = '';
    my $p1 = <$fh>;
    my $p2 = <$fh>;
    is( $p1, "abc\n\n", "First paragraph ends with collapsed \\n\\n" );
    is( $p2, "def",     "Last paragraph without trailing newline" );
    close $fh;
}

# ============================================================
# Custom multi-character record separator
# ============================================================

note "-------------- CUSTOM SEPARATOR (\$/ = multi-char) --------------";

{
    note "Multi-character record separator";
    my $mock = Test::MockFile->file( $filename, "part1::part2::part3" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = '::';
    my $r1 = <$fh>;
    my $r2 = <$fh>;
    my $r3 = <$fh>;
    my $r4 = <$fh>;
    is( $r1, "part1::", "First record with :: separator" );
    is( $r2, "part2::", "Second record" );
    is( $r3, "part3",   "Third record (no trailing separator)" );
    is( $r4, undef,     "EOF" );
    close $fh;
}

{
    note "Custom single-char separator (not newline)";
    my $mock = Test::MockFile->file( $filename, "a,b,c,d" );
    open( my $fh, '<', $filename ) or die "open: $!";
    local $/ = ',';
    my @parts = <$fh>;
    is( \@parts, [ "a,", "b,", "c,", "d" ], "Comma-separated reading" );
    close $fh;
}

# ============================================================
# GETC
# ============================================================

note "-------------- GETC --------------";

{
    note "getc reads one character at a time";
    my $mock = Test::MockFile->file( $filename, "Hello" );
    open( my $fh, '<', $filename ) or die "open: $!";
    is( getc($fh), 'H', "getc 1st char" );
    is( getc($fh), 'e', "getc 2nd char" );
    is( getc($fh), 'l', "getc 3rd char" );
    is( getc($fh), 'l', "getc 4th char" );
    is( getc($fh), 'o', "getc 5th char" );
    is( getc($fh), undef, "getc at EOF returns undef" );
    close $fh;
}

{
    note "getc after partial read";
    my $mock = Test::MockFile->file( $filename, "ABCDEF" );
    open( my $fh, '<', $filename ) or die "open: $!";
    read( $fh, my $buf, 3 );
    is( $buf, "ABC", "Read first 3 bytes" );
    is( getc($fh), 'D', "getc after read returns next char" );
    is( getc($fh), 'E', "getc continues" );
    close $fh;
}

{
    note "getc on empty file";
    my $mock = Test::MockFile->file( $filename, "" );
    open( my $fh, '<', $filename ) or die "open: $!";
    is( getc($fh), undef, "getc on empty file returns undef" );
    close $fh;
}

# ============================================================
# Edge cases: interaction between seek and readline modes
# ============================================================

note "-------------- SEEK + READLINE INTERACTIONS --------------";

{
    note "Seek then slurp";
    my $mock = Test::MockFile->file( $filename, "0123456789" );
    open( my $fh, '<', $filename ) or die "open: $!";
    seek( $fh, 5, 0 );
    my $rest = do { local $/; <$fh> };
    is( $rest, "56789", "Slurp after seek(5) returns remainder" );
    close $fh;
}

{
    note "Seek then fixed-record";
    my $mock = Test::MockFile->file( $filename, "ABCDEFGHIJ" );
    open( my $fh, '<', $filename ) or die "open: $!";
    seek( $fh, 3, 0 );
    local $/ = \4;
    my $r1 = <$fh>;
    my $r2 = <$fh>;
    is( $r1, "DEFG", "Fixed record after seek" );
    is( $r2, "HIJ",  "Partial record at end" );
    close $fh;
}

done_testing();
exit;
