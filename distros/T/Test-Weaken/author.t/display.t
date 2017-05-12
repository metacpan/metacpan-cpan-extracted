#!perl

use Pod::Parser;
use warnings;
use strict;
use English qw( -no_match_vars );
use Fatal qw(close);
use Carp;
use Getopt::Long qw(GetOptions);
use Test::More;

my $warnings = 0;
my $options_result = GetOptions( 'warnings' => \$warnings );
Carp::croak("$PROGRAM_NAME options parsing failed")
    unless $options_result;

package Marpa::Test::Display;

@Marpa::Test::Display::ISA       = qw(Exporter);
@Marpa::Test::Display::EXPORT_OK = qw(test_file);

use Text::Diff;
use Carp;
use Fatal qw(close);
use English qw( -no_match_vars );

our $FILE_ERROR = 'No error';

our $PREAMBLE   = q{1};
our $IN_COMMAND = 0;
our @DISPLAY;
our $DEFAULT_CODE             = q{ no_code_defined($_) };
our $CURRENT_CODE             = $DEFAULT_CODE;
our $COLLECTING_FROM_LINE_NUM = -1;
our $COLLECTED_DISPLAY;
our $COMMAND_COUNTDOWN = 0;
our $CURRENT_FILE      = '!!! NO CURRENT FILE !!!';
our $DISPLAY_SKIP      = 0;

sub no_code_defined {
    my $display = shift;
    return 'No code defined to test display:';
}

my %raw                     = ();
my %normalized              = ();
my %raw_display             = ();
my %normalized_display      = ();
my %normalized_display_uses = ();

sub normalize_whitespace {
    my $raw_ref = shift;
    my $text    = ${$raw_ref};
    $text =~ s/\A\s*//xms;
    $text =~ s/\s*\z//xms;
    $text =~ s/\s+/ /gxms;
    return \$text;
}

sub slurp {
    my ($file_name) = @_;
    my $open_result = open my $fh, '<', $file_name;
    if ( not $open_result ) {
        $Marpa::Test::Display::FILE_ERROR = "Cannot open $file_name: $ERRNO";
        return;
    }
    local ($RS) = undef;
    my $result = \<$fh>;
    close $fh;
    return $result;
}

sub parse_displays {
    my $raw_ref = shift;

    my $result = {};
    my @matches = ${$raw_ref} =~ m{
               ^ [ \t]* [#] \h* [#] [\h#]* use [ \t]+ Marpa[:][:]Test[:][:]Display \h+ (\w+(?:\s+\w+)*) \s* \h* $
               (.*?)
               ^ [ \t]* [#] \h* [#] [\h#]* no [ \t]+ Marpa[:][:]Test[:][:]Display \h* $
           }xmsg;
    while (@matches) {
        my $display_name = shift @matches;
        my $display_text = shift @matches;
        $result->{$display_name} = \$display_text;
    }

    return $result;
}

sub read_file {
    my $file_name    = shift;
    my $display_name = shift;

    my $file_ref = $normalized{$file_name};
    if ( not defined $file_ref ) {
        my $raw_ref = $raw{$file_name} = slurp($file_name);
        return if not defined $raw_ref;
        $file_ref = $normalized{$file_name} = normalize_whitespace($raw_ref);
        my $raw_display = $raw_display{$file_name} = parse_displays($raw_ref);
        for my $raw_display_name ( keys %{$raw_display} ) {
            $normalized_display{$file_name}{$raw_display_name} =
                normalize_whitespace( $raw_display->{$raw_display_name} );
        }
    }
    return $file_ref
        if not defined $display_name;
    my $display_ref = $normalized_display{$file_name}{$display_name};
    if ( not defined $display_ref ) {
        Carp::croak("No display named '$display_name' in file: $file_name");
    }
    $normalized_display_uses{$file_name}{$display_name}++;
    return $display_ref;
}

sub in_file {
    my ( $pod_display, $file_name, $display_name ) = @_;

    my $pod_display_ref = normalize_whitespace( \$pod_display );
    my $file_display_ref = read_file( $file_name, $display_name );
    if ( not defined $file_display_ref ) {
        return ( "$Marpa::Test::Display::FILE_ERROR\n", 1 );
    }

    my $location = index ${$file_display_ref}, ${$pod_display_ref};

    return (
        (   $location >= 0
            ? q{}
            : "Display in $Marpa::Test::Display::CURRENT_FILE not in $file_name\n"
                . $pod_display
        ),
        1
    );

}

sub is_file {
    my ( $pod_display, $file_name, $display_name ) = @_;

    my $pod_display_ref = normalize_whitespace( \$pod_display );
    my $file_display_ref = read_file( $file_name, $display_name );
    if ( not defined $file_display_ref ) {
        return ( "$Marpa::Test::Display::FILE_ERROR\n", 1 );
    }

    return q{} if ${$file_display_ref} eq ${$pod_display_ref};

    my $raw_file_display =
        defined $display_name
        ? $raw_display{$file_name}{$display_name}
        : $raw{$file_name};

    $pod_display =~ s/^\h*//gxms;
    ${$raw_file_display} =~ s/^\h*//gxms;

    my $header =
        $display_name
        ? "Display '$display_name'"
        : 'Display';
    $header
        .= " in $Marpa::Test::Display::CURRENT_FILE differs from the one in $file_name";

    return (
        (   $header
                . (
                Text::Diff::diff \$pod_display,
                $raw_file_display,
                { STYLE => 'Table' }
                )
        ),
        1
    );

}

sub test_file {
    my $file = shift;

    $Marpa::Test::Display::CURRENT_FILE      = $file;
    @Marpa::Test::Display::DISPLAY           = ();
    $Marpa::Test::Display::DEFAULT_CODE      = q{ no_code_defined($_) };
    $Marpa::Test::Display::CURRENT_CODE      = $DEFAULT_CODE;
    $Marpa::Test::Display::COMMAND_COUNTDOWN = 0;
    $Marpa::Test::Display::DISPLAY_SKIP      = 0;
    my $mismatch_count = 0;
    my $mismatches     = q{};

    my $parser = MyParser->new();
    $parser->parse_from_file($file);
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    my $eval_result = eval $PREAMBLE;
    ## use critic
    Carp::croak($EVAL_ERROR) unless $eval_result;

    for my $display_test (@Marpa::Test::Display::DISPLAY) {
        my ( $display, $code, $display_file, $display_line ) =
            @{$display_test}{qw(display code file line)};
        local $_ = $display;
        ## no critic (BuiltinFunctions::ProhibitStringyEval)
        $eval_result = eval '[ do {' . $code . '} ] ';
        ## use critic

        if (my $message =
              $eval_result
            ? $eval_result->[0]
            : $EVAL_ERROR . "Code with problem was:\n$code\n"
            )
        {
            my $do_not_add_display = $eval_result->[1];
            unless ($do_not_add_display) {
                $message .= "\n$display";
            }
            $mismatches .= "=== $message";
            $mismatch_count++;
        }

    }    # $display_test

    return ( $mismatch_count, \$mismatches );

}    # sub test_file

package MyParser;
@MyParser::ISA = qw(Pod::Parser);
use Carp;

sub queue_display {
    my $display  = shift;
    my $line_num = shift;
    push @Marpa::Test::Display::DISPLAY,
        {
        'display' => $display,
        'code'    => $Marpa::Test::Display::CURRENT_CODE,
        'file'    => $Marpa::Test::Display::CURRENT_FILE,
        'line'    => $line_num,
        }
        if not $Marpa::Test::Display::DISPLAY_SKIP;
    $Marpa::Test::Display::COMMAND_COUNTDOWN--;
    if ( $Marpa::Test::Display::COMMAND_COUNTDOWN <= 0 ) {
        $Marpa::Test::Display::CURRENT_CODE =
            $Marpa::Test::Display::DEFAULT_CODE;
        $Marpa::Test::Display::DISPLAY_SKIP = 0;
    }
    return;
}

sub verbatim {
    my ( $parser, $paragraph, $line_num ) = @_;

    if ( defined $Marpa::Test::Display::COLLECTED_DISPLAY ) {
        $Marpa::Test::Display::COLLECTED_DISPLAY .= $paragraph;
        $Marpa::Test::Display::COLLECTING_FROM_LINE_NUM //= $line_num;
        return;
    }
    queue_display( $paragraph, $line_num );
    return;
}

sub process_instruction {
    my $instruction = shift;
    my $code        = shift;
    my $line_num    = shift;

    $instruction =~ s/\s\z//xms;    # eliminate trailing whitespace
    $instruction =~ s/\s/ /gxms;    # normalize whitespace

    if ( $instruction =~ /^ next \s+ display $ /xms ) {
        $Marpa::Test::Display::COMMAND_COUNTDOWN = 1;
        $Marpa::Test::Display::CURRENT_CODE = join "\n", @{$code};
        return;
    }

    if ( $instruction =~ / ^ next \s+ (\d+) \s+ display(s)? $ /xms ) {
        $Marpa::Test::Display::COMMAND_COUNTDOWN = $1;
        Carp::croak(
            "File: $Marpa::Test::Display::CURRENT_FILE  Line: $line_num\n",
            "  'next $Marpa::Test::Display::COMMAND_COUNTDOWN display' has countdown less than one\n"
        ) if $Marpa::Test::Display::COMMAND_COUNTDOWN < 1;
        $Marpa::Test::Display::CURRENT_CODE = join "\n", @{$code};
        return;
    }

    if ( $instruction =~ / ^ default $ /xms ) {
        $Marpa::Test::Display::DEFAULT_CODE = join "\n", @{$code};
        $Marpa::Test::Display::CURRENT_CODE =
            $Marpa::Test::Display::DEFAULT_CODE
            if $Marpa::Test::Display::COMMAND_COUNTDOWN <= 0;
        return;
    }

    if ( $instruction =~ / ^ preamble $ /xms ) {
        $Marpa::Test::Display::PREAMBLE .= join "\n", @{$code};
        return;
    }

    if ( $instruction =~ / ^ skip \s+ display $ /xms ) {
        $Marpa::Test::Display::COMMAND_COUNTDOWN = 1;
        $Marpa::Test::Display::DISPLAY_SKIP++;
        return;
    }

    if ( $instruction =~ / ^ skip \s+ (\d+) \s+ display(s)? $ /xms ) {
        $Marpa::Test::Display::COMMAND_COUNTDOWN = $1;
        Carp::croak(
            "File: $Marpa::Test::Display::CURRENT_FILE  Line: $line_num\n",
            "  'display $Marpa::Test::Display::COMMAND_COUNTDOWN skip' has countdown less than one\n"
        ) if $Marpa::Test::Display::COMMAND_COUNTDOWN < 1;
        $Marpa::Test::Display::DISPLAY_SKIP++;
        return;
    }

    if ( $instruction =~ /^ start \s+ display $/xms ) {
        $Marpa::Test::Display::COLLECTED_DISPLAY = q{};
        return;
    }

    if ( $instruction =~ / ^ end \s+ display $ /xms ) {

        # line num will be set when first part of display is found
        queue_display(
            $Marpa::Test::Display::COLLECTED_DISPLAY,
            $Marpa::Test::Display::COLLECTING_FROM_LINE_NUM
        );
        $Marpa::Test::Display::COLLECTED_DISPLAY        = undef;
        $Marpa::Test::Display::COLLECTING_FROM_LINE_NUM = -1;
        return;
    }

    Carp::croak(
        "Unrecognized instruction in file $Marpa::Test::Display::CURRENT_FILE at line $line_num: $instruction\n"
    );

}

sub textblock {
    my ( $parser, $paragraph, $line_num ) = @_;
    return unless $Marpa::Test::Display::IN_COMMAND;

    ## Translate/Format this block of text; sample actions might be:

    my @lines = split /\n/xms, $paragraph;
    my $found_instruction = 0;
    LINE: while ( my $line = shift @lines ) {
        next LINE if $line =~ /^\s*$/xms;    # skip whitespace
        if ( $line =~ /\A[#][#]/xms ) {
            $line =~ s/\A[#][#]\s*//xms;
            process_instruction( $line, \@lines, $line_num );
            $found_instruction = 1;
            next LINE;
        }
        Carp::croak(
            "File: $Marpa::Test::Display::CURRENT_FILE  Line: $line_num\n",
            "test block doesn't begin with ## instruction\n$paragraph"
        ) if not $found_instruction;
        last LINE;
    }

    return;

}

sub interior_sequence { }

sub command {

    my ( $parser, $command, $paragraph ) = @_;
    if ( $command eq 'begin' ) {
        $Marpa::Test::Display::IN_COMMAND++ if $paragraph =~ m{
                \A
                Marpa[:][:]Test[:][:]Display[:]
                \s* \Z
            }xms;
        $Marpa::Test::Display::IN_COMMAND++ if $paragraph =~ /\Amake:$/xms;
    }
    elsif ( $command eq 'end' ) {
        $Marpa::Test::Display::IN_COMMAND = 0;
    }

    return;

}

package main;

my %exclude = map { ( $_, 1 ) } qw(
    Makefile.PL
);

my @test_files = ();
open my $manifest, '<', 'MANIFEST'
    or Carp::croak("Cannot open MANIFEST: $ERRNO");
FILE: while ( my $file = <$manifest> ) {
    chomp $file;
    $file =~ s/\s*[#].*\z//xms;
    next FILE if $exclude{$file};
    next FILE if -d $file;
    my ($ext) = $file =~ / [.] ([^.]+) \z /xms;
    next FILE unless defined $ext;
    $ext = lc $ext;
    next FILE
        if $ext ne 'pod'
            and $ext ne 'pl'
            and $ext ne 'pm'
            and $ext ne 't';

    push @test_files, $file;
}    # FILE
close $manifest;

Test::More::plan tests => 1 + scalar @test_files;

open my $error_file, '>', 'author.t/display.errs'
    or Carp::croak("Cannot open display.errs: $ERRNO");
FILE: for my $file (@test_files) {
    if ( not -f $file ) {
        Test::More::fail("attempt to test displays in non-file: $file");
        next FILE;
    }

    my ( $mismatch_count, $mismatches ) =
        Marpa::Test::Display::test_file($file);
    my $clean = $mismatch_count == 0;

    my $message =
        $clean
        ? "displays match for $file"
        : "displays in $file has $mismatch_count mismatches";

    Test::More::ok( $clean, $message );
    next FILE if $clean;
    print {$error_file} "=== $file ===\n" . ${$mismatches}
        or Carp::croak("print failed: $ERRNO");
}

my $unused       = q{};
my $unused_count = 0;
while ( my ( $file_name, $displays ) = each %normalized_display_uses ) {
    DISPLAY: while ( my ( $display_name, $uses ) = each %{$displays} ) {
        next DISPLAY if $uses > 0;
        $unused .= "display '$display_name' in $file_name never used\n";
        $unused_count++;
    }
}
if ($unused_count) {
    Test::More::fail('$unused count displays not used');
    print {$error_file} "=== UNUSED DISPLAYS ===\n" . $unused
        or Carp::croak("print failed: $ERRNO");
}
else {
    Test::More::pass('all displays used');
}
close $error_file;
