package Parser::TopDown::Table;

# $Revision:   1.1  $

=head1 NAME 

Table - generate state tables for a top-down LL(1) parser

=cut

require 5.001;
use Parser::Parser;
use Parser::Table;

%select_sets;

sub select_sets {
    foreach $rule (keys %{$_[0]}) {
        foreach $prod (keys %{$_[0]{$rule}}) {
            if (! exists $select_sets{"$rule,$prod"}) {
                $select_sets{"$rule,$prod"} = {};
            }
            if (first_rhs($select_sets{"$rule,$prod"}, $_[0],
                          $rule, $prod)) {
                union $select_sets{"$rule,$prod"}, $follow_sets{$rule};
            }
        }
    }
    remove_epsilon(\%select_sets);
}

%terms;
%nonterms;
$dtran;

sub Generate {
    my $out = $_[0];
    my $grammar = $_[1];
    Parser::Table::first($grammar);
    Parser::Table::follow($grammar);
    select_sets($grammar);

    if ($_[3]) {
#        Parser::Table::closeup();
        display_set("FIRST", \%first_sets);
        display_set("FOLLOW", \%follow_sets);
        display_set("SELECT", \%select_sets);
    }

    $dtran = {};

    foreach $rule (sort keys %{$grammar}) {
        $nonterms{$rule} = 1;
        foreach $prod (sort keys %{$grammar->{$rule}}) {
            my $term = $prod;
            my $i = 0;
            do {
                if ($term !~ /^sub {/ && ! exists $grammar->{$term}) {
                    $terms{$term} = 1 if $term ne $EPSILON;
                }
                $term = $grammar->{$rule}{$prod}[$i++];
                
            } while ($term);
        }
    }
    foreach $nonterm (keys %nonterms) {
        foreach $term (keys %terms) {
            $dtran->{$nonterm}{$term} = -1;
        }
    }
    foreach $rule (sort keys %{$grammar}) {
        foreach $prod (keys %{$grammar->{$rule}}) {
            foreach $term (keys %{$select_sets{"$rule,$prod"}}) {
                if ($dtran->{$rule}{$term} == -1) {
                    $dtran->{$rule}{$term} = [ $prod,
                                              $grammar->{$rule}{$prod} ];
                } else {
                    warn "Grammar not LL(1), select-set conflict in <$rule>\n";
                }
            }
        }
    }

    print $out '%', $_[2], " = (\n";
    foreach $nonterm (keys %nonterms) {
        print $out "    \"$nonterm\" => {\n";
        $line_length = 0;
        $string = "        ";
        foreach $term (keys %terms) {
            append_string($term, \$string);
            $string .= " => ";
            if (ref $dtran->{$nonterm}{$term}) {
                if ($dtran->{$nonterm}{$term}[0] eq $EPSILON) {
                    $string .= "0";
                } else {
                    $string .= "[";
                    append_string($dtran->{$nonterm}{$term}[0], \$string);
                    $string .= ", ";
                    foreach $element (@{$dtran->{$nonterm}{$term}[1]}) {
                        if ($element =~ /^sub \{/) {
                            $string .= $element;
                        } else {
                            append_string($element, \$string);
                        }
                        $string .= ", ";
                    }
                    $string .= "]";
                }
            } else {
                append_string($dtran->{$nonterm}{$term}, \$string);
            }
            $string .= ",";
            print $out $string;
            $line_length += length $string;
            if ($line_length > 50) {
                print $out "\n";
                $line_length = 0;
                $string = "        ";
            } else {
                $string = "  ";
            }
        }
        print $out "    },\n";
    }
    print $out ");\n\n1;\n";
}

sub append_string {
    my $string = $_[1];
    if ($_[0] !~ /^-?[0-9]+$/) {
        $$string .= "'" . $_[0] . "'";
    } else {
        $$string .= $_[0];
    }
}

1;
