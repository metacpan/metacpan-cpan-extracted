package Parser::TopDown::PDA;

# $Revision:   1.0  $

=head1 NAME 

TopDown::PDA - implements a top-down PDA parser

=cut

require 5.001;
use Parser::Parser;

# Find which path to take based on the lookahead.  It will be in the
# set of FIRST(rule).

sub which_prod {
    return 1 if exists $_[0]{$_[1]}{$_[2]};
    foreach $corner (keys %{$_[0]{$_[1]}}) {
        return $corner if exists $_[0]{$corner} &&
            which_prod($_[0], $corner, $_[2]);
    }
    # jww (7/27/96): The way the code is currently written makes
    # epsilon useless (that is, there is an implicit epsilon
    # transition from all left-hand sides).  There should be an error
    # if an acceptable move cannot be found.
    return 0 if exists $_[0]{$_[1]}{$EPSILON};
    return 0;
}

sub Parse {
    my($grammar, $scanner, $debug) = ($_[0], $_[1], $_[3]);
    @stack = ( $_[2] || "start" );
    @lvalues = ( 0 );
    @rvalues = ( 0 );

    $last_lexeme = 0;
    ($lookahead, $lexeme) = $scanner->Read();

    while (@stack) {
        $top = $stack[$#stack];
        if (exists $grammar->{$top}) {       # non-terminal
            print "pop  $top\n" if $debug;
            pop @stack;

            $lhs = $rvalues[0];
            shift @lvalues;
            shift @rvalues;

            if (exists $grammar->{$top}{$lookahead}) {
                if ($terms = $grammar->{$top}{$lookahead}) {
                    print "push @$terms\n" if $debug;
                    push @stack, reverse @$terms;
                    unshift @lvalues, ($lhs) x (@$terms + 1);
                    unshift @rvalues, ($lhs) x (@$terms + 1);
                }
                print "push $lookahead\n" if $debug;
                push @stack, $lookahead;
            } else {
                if ($corner = which_prod($grammar, $top, $lookahead))  {
                    if ($terms = $grammar->{$top}{$corner}) {
                        print "push @$terms\n" if $debug;
                        push @stack, reverse @$terms;
                        unshift @lvalues, ($lhs) x (@$terms + 1);
                        unshift @rvalues, ($lhs) x (@$terms + 1);
                    }
                    print "push $corner\n" if $debug;
                    push @stack, $corner;
                }
            }
        }
        elsif (ref($top)) {             # action (assume eq CODE)
            &{$top}($last_lexeme, $lvalues[0], \@rvalues);
            print "pop  $top\n" if $debug;
            pop @stack;
        }
        else {                          # terminal
            $scanner->Error() if $top != $lookahead;
            print "POP  $top\n" if $debug;
            pop @stack;
            $last_lexeme = $lexeme;
            ($lookahead, $lexeme) = $scanner->Read();
            shift @lvalues;
            shift @rvalues;
        }
    }
}

1;
