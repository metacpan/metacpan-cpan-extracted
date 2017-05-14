package Parser::TopDown::DFA;

# $Revision:   1.0  $

=head1 NAME 

TopDown::DFA - implements a top-down PDA that uses a DFA

=cut

require 5.001;
use Parser::Parser;

sub Parse {
    my($dtran, $scanner) = ($_[0], $_[1]);
    @stack = ( $_[2] || "start" );
    my $top = 0;
    @lvalues = ( 0 );
    @rvalues = ( 0 );

    $last_lexeme = 0;
    ($lookahead, $lexeme) = $scanner->Read();

    while (@stack) {
        $top = $stack[$#stack];
        if (exists $dtran->{$top}) {       # non-terminal
            pop @stack;
            $lhs = $rvalues[0];
            shift @lvalues;
            shift @rvalues;

            $prod = $dtran->{$top}{$lookahead};
            $scanner->Error("unexpected") if $prod == -1;

            if ($prod) {
                push @stack, reverse @$prod;
                unshift @lvalues, ($lhs) x @$prod;
                unshift @rvalues, ($lhs) x @$prod;
            }
        }
        elsif (ref($top)) {             # action (assume eq CODE)
            &{$top}($last_lexeme, $lvalues[0], \@rvalues);
            pop @stack;
        }
        else {                          # terminal
            $scanner->Error() if $top != $lookahead;
            pop @stack;
            $last_lexeme = $lexeme;
            ($lookahead, $lexeme) = $scanner->Read();
            shift @lvalues;
            shift @rvalues;
        }
    }
}

1;
