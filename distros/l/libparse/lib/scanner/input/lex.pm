package Scanner::Input::Lex;

# $Revision:   1.1  $

=head1 NAME 

Lex - allow users to input token tables using a Lex-like syntax

=cut

require 5.001;
use Scanner::Scanner;
use Scanner::First;
use Parser::Parser;
use Parser::TopDown::PDA;

($ACTION, $REGEXP, $SCALAR) = (1000 .. 1003);

($depth, $action, $out) = ();

@action_tokens = ();
@lex_tokens = (
    '\{', sub { $action = ""; ${_[0]}->Switch(\@action_tokens); $depth = 0; },
    '\$[A-Za-z_][A-Za-z0-9_]*', $SCALAR,
    '("[^"]+"|[^ \n]+)', $REGEXP,
);
@action_tokens = (
    '\}',  sub {
               if (! $depth) {
                   ${_[0]}->Switch(\@lex_tokens);
                   return $ACTION;
               }
               $depth--; $action .= $_[1]; 0;
           },
    '\{',  sub { $depth++; $action .= $_[1]; 0; },
    '.',   sub { $action .= $_[1]; 0; },
);

%grammar = (
    "start" => {
        $REGEXP => [sub { print $out ("    '" . $_[0] . "', "); },
                    "action", sub { print $out ",\n"; }, "start"],
        $END_OF_INPUT => [ sub { print $out ");\n\n1;\n"; } ],
    },
    "action" => {
        $SCALAR => [ sub { print $out $_[0]; } ],
        $ACTION => [sub { print $out 'sub {' . $action . '}'; } ]
    }
);

sub Convert {
    $out = $_[0];
    my $name = $_[2] || "tokens";
    $scanner = new Scanner::First \@lex_tokens, $_[1];
    print $out "\@$name = (\n";
    $textual = $_[3];
    Parser::TopDown::PDA::Parse(\%grammar, $scanner);
}

1;
