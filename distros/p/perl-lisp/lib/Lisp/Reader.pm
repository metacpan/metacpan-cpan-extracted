package Lisp::Reader;

use strict;
use vars qw($DEBUG $SYMBOLS_AS_STRINGS $NIL_AS_SYMBOL
            @EXPORT_OK $VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);

use Lisp::Symbol qw(symbol);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(lisp_read);


sub my_symbol
{
    ($_[0] eq "nil" && !$NIL_AS_SYMBOL) ?
      undef : 
      ($SYMBOLS_AS_STRINGS ? $_[0] : symbol($_[0]));
}

sub lisp_read
{
    local($_) = shift;
    my $one   = shift;
    my $level = shift || 0;
    my $indent = "  " x $level;

    my @stack;
    my $form = [];

    if ($DEBUG) {
	print "${indent}Parse";
	print "-one" if $one;
	print ": $_\n";
    }
    
    while (1) {
	if (/\G\s*;+([^\n]*)/gc) {
	    print "${indent}COMMENT $1\n" if $DEBUG;
	} elsif (/\G\s*([()\[\]])/gc) {
	    print "${indent}PARA $1\n" if $DEBUG;
	    if ($1 eq "(" or $1 eq "[") {
		my $prev = $form;
		push(@stack, $prev);
		push(@$prev, $form = []);
		bless $form, "Lisp::Vector" if $1 eq "[";
	    } else {
		last unless @stack;
		if (ref($form) eq "ARRAY" && @$form == 0) {
                    # () and nil is supposed to be the same thing
		    $stack[-1][-1] = my_symbol("nil");
		}
		$form = pop(@stack);
		last if $one && !@stack;
	    }
	} elsif (/\G\s*(
			[-+]?                  # optional sign
			(?:\d+(\.\d*)?         # 0 0. 0.0
			 |
			 \.\d+)                # .0
			([eE][-+]?\d+)?        # optional exponent
		       )
		 (?![^\s()\[\];])              # not followed by plain chars
		 /gcx)  
	{
	    print "${indent}NUMBER $1\n" if $DEBUG;
	    push(@$form, $1+0);
	    last if $one && !@stack;
	} elsif (/\G\s*\?((?:\\[A-Z]-)*(?:\\\^.|\\[0-7]{1,3}|\\.|.))/sgc) {
	    print "${indent}CHAR $1\n" if $DEBUG;
	    push(@$form, parse_char($1));
	    last if $one && !@stack;
	} elsif (/\G\s*
		 \"(                           # start quote
		    [^\"\\]*                   # unescaped
		    (?:\\.[^\"\\]*)*           # (escaped char + unescaped)*
		 )\"/gcxs)                     # end quote
	{
	    my $str = $1;

	    # Unescape
	    $str =~ s/\\\n//g;    # escaped newlines disappear
	    $str =~ s/((?:\\[A-Z]-)+.)/chr(parse_char($1,1))/ge;
	    $str =~ s/((?:\\[A-Z]-)*\\(?:\^.|[0-7]{1,3}|.))/
	              chr(parse_char($1,1))/ge;
	    print "${indent}STRING $str\n" if $DEBUG;
	    push(@$form, $str);
	    last if $one && !@stack;
	} elsif (/\G\s*\'/gc) {
	    print "${indent}QUOTE\n" if $DEBUG;
	    my $old_pos = pos($_);
	    my($subform, $pos) = lisp_read(substr($_, $old_pos), 1, $level+1);
	    pos($_) = $old_pos + $pos;
	    push(@$form, [my_symbol("quote"), $subform]);
	    last if $one && !@stack;
	} elsif (/\G\s*\./gc) {
	    print "${indent}DOT\n" if $DEBUG;
	    #XXX Should handle (a b . c) correctly and (a . b c) as error
	    bless $form, "Lisp::Cons";
	} elsif (/\G\s*\#/gc) {
	    die qq(invalid-read-syntax: "\#");
	} elsif (/\G\s*
                   (  [^\s()\[\];\\]*          # unescaped plain chars
                      (?:\\.[^\s()\[\];\\]*)*  # (escaped char + unescaped)*
                   )/gcsx
		 && length($1))
	{
	    # symbols can have space and parentesis embedded if they are
	    # escaped.
	    my $sym = $1;
	    $sym =~ s/\\(.)/$1/g; # unescape
	    print "${indent}SYMBOL $sym\n" if $DEBUG;
	    push(@$form, my_symbol($sym));
	    last if $one && !@stack;
	} elsif (/\G\s*(.)/gc) {
	    print "${indent}? $1\n";
	    die qq(invalid-read-syntax: "$1");
	} else {
	    last;
	}
    }

    if (@stack) {
	warn "Form terminated early";  # or should we die?
	$form = $stack[0];
    }

    if ($one) {
	die "More than one form parsed, this should never happen"
	  if @$form > 1;
	$form = $form->[0];
    }

    wantarray ? ($form, pos($_)) : $form;
}


sub parse_char
{
    my($char, $instring) = @_;
    my $ord = 0;
    my @mod;
    while ($char =~ s/^\\([A-Z])-//) {
	push(@mod, $1);
    }

    if (length($char) == 1) {
	$ord = ord($char);  # a plain one
    } elsif ($char =~ /^\\([0-7]+)$/) {
	$ord = oct($1);
    } elsif ($char =~ /^\\\^(.)$/) {
	$ord = ord(uc($1)) - ord("@");
	$ord += 128 if $ord < 0;
    } elsif ($char eq "\\t") {
	$ord = ord("\t");
    } elsif ($char eq "\\n") {
	$ord = ord("\n");
    } elsif ($char eq "\\a") {
	$ord = ord("\a");
    } elsif ($char eq "\\f") {
	$ord = ord("\f");
    } elsif ($char eq "\\r") {
	$ord = ord("\r");
    } elsif ($char eq "\\e") {
	$ord = ord("\e");
    } elsif ($char =~ /^\\(.)$/) {
	$ord = ord($1);
    } else {
	warn "Don't know how to handle character ($char)";
    }

    for (@mod) {
	if ($_ eq "C") {
	    $ord = ord(uc(chr($ord))) - ord("@");
	    $ord += 128 if $ord < 0;
	} elsif ($_ eq "M") {
	    $ord += $instring ? 2**7 : 2**27;
	} elsif ($_ eq "H") {
	    $ord += 2**24;
	} elsif ($_ eq "S") {
	    $ord += 2**23;
	} elsif ($_ eq "A") {
	    $ord += 2**22;
	} else {
	    warn "Unknown character modified ($_)";
	}
    }

    $ord;
}


1;
