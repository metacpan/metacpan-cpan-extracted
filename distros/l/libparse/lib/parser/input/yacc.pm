package Parser::Input::Yacc;

# $Revision:   1.1  $

=head1 NAME 

Yacc - allow users to input grammars using a Yacc-like syntax

=head1 DESCRIPTION

This is an example of a syntax-directed translator.  It is intended to
be used as follows: write a yacc-style grammar in a separate file,
with a line at the bottom that will call this module.  Output the
result to a file, and require the resultant perl data structure into
your code.  The name of the variable is "grammar" by default.
Example:

    use Parser::Input::Yacc;
    use Scanner::Stream::String;

    $grammar = new Scanner::Stream::String(<<'EOG');
    start:   $SAMPLE  { print "sample\n"; }
           | $EXAMPLE { print "example\n"; }
           ;
    EOG

    Parser::Input::Yacc::Convert($grammar, "grammar");

=cut

require 5.001;
use Scanner::Stream::Handle;
use Scanner::Scanner;
use Scanner::First;
use Parser::Parser;
use Parser::TopDown::PDA;

($TOKEN, $ACTION, $NAME, $SCALAR) = (1000 .. 1003);

($depth, $action, $code, $textual, $out) = ();

@action_tokens = ();
@yacc_tokens = (
    '\{', sub { $action = ""; ${_[0]}->Switch(\@action_tokens); $depth = 0; },
    '[:;|]', sub { $_[1]; },
    "(\\\$[A-Za-z_][A-Za-z0-9_]*|'.')", $SCALAR,
    '[^:;|\s]+', $NAME,
);
@action_tokens = (
    '\}',  sub {
               if (! $depth) {
                   ${_[0]}->Switch(\@yacc_tokens);
                   return $ACTION;
               }
               $depth--; $action .= $_[1]; 0;
           },
    '\{',  sub { $depth++; $action .= $_[1]; 0; },
    '.',   sub { $action .= $_[1]; 0; },
);

$pos;
$cnt;
%grammar = (
    "start" => {
        $NAME => [sub { print $out ("    \"" . $_[0] . '"'); }, ':',
                  sub { $cnt = 0; print $out " => {\n"; $pos = 0; },
                  "prods", ';',
sub {
    if (! $cnt) {
        print $out sprintf("%s%-10s => 0\n", " " x 8, '$EPSILON');
    }
    print $out "    },\n";
},
                  "start"],
        $END_OF_INPUT => [ sub { print $out ");\n\n1;\n"; } ],
    },
    "prods" => {
        "terms"  => [
sub {
    if ($cnt == 1) {
        print $out "0,\n";
    }
    elsif ($cnt > 1) {
        print $out "],\n";
    }
},
                     "or_prods"]
    },
    "or_prods" => {
        '|'      => [sub { $cnt = 0; $pos = 0; }, "prods" ],
        $EPSILON => 0
    },
    "terms" => {
        "term"   => [ sub { $cnt++; $pos++; print $out ', ' if $pos > 1; },
                     "terms"],
        $EPSILON => 0
    },
    "term" => {
        $NAME    => [
sub {
    print $out ! $pos ? ((" " x 8) . sprintf("\"%-10s => ", $_[0] . '"')) :
        (($pos == 1 && '[') . '"' . $_[0] . '"');
} ],
        $SCALAR => [
sub {
    print $out ! $pos ? ((" " x 8) .  sprintf("%-10s => ", $_[0])) :
        (($pos == 1 && '[') . $_[0]);
} ],
        $ACTION  => [
sub {
    if (! $textual) {
        print $out (($pos == 1 && '[') . 'sub {' . $action . '}');
    } else {
        print $out (($pos == 1 && '[') . "<<'EOF'\nsub {" . $action .
                    "}\nEOF\n");
    }
} ]
    },
);

sub Convert {
    $out = $_[0];
    my $name = $_[2] || "grammar";
    $scanner = new Scanner::First \@yacc_tokens, $_[1];
    print $out "\%$name = (\n";
    $textual = $_[3];
    Parser::TopDown::PDA::Parse(\%grammar, $scanner);
}

1;
