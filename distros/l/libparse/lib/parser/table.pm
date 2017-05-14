package Parser::Table;

# $Revision:   1.0  $

=head1 NAME 

Parser - global methods for the two table generators

=cut

require 5.001;
use Parser::Parser;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(%first_sets %follow_sets display_set remove_epsilon union
             first_rhs closeup);

%first_sets;
%follow_sets;

$did_something;

sub display_set {
    print "$_[0] sets:\n";
    foreach $set (sort keys %{$_[1]}) {
        print "   ";
        print_set($_[0], $set, $_[1]);
    }
}

sub print_set {
    print "$_[0]($_[1]) = { ";
    $first = 1;
    foreach $member (keys %{$_[2]{$_[1]}}) {
        print ", " if ! $first;
        print $member;
        $first = 0;
    }
    print " }\n";
}

sub remove_epsilon {
    foreach $set (keys %{$_[0]}) {
        delete $_[0]{$set}{$EPSILON} if exists $_[0]{$set}{$EPSILON};
    }
}

sub union {
    foreach $member (keys %{$_[1]}) {
        if (! exists $_[0]{$member}) {
            $_[0]{$member} = 1;
            $did_something = 1;
        }
    }
}

sub first {
    do {
        $did_something = 0;
        foreach $nonterm (keys %{$_[0]}) {
            first_closure($_[0], $nonterm);
        }
    } while ($did_something);
}

sub first_closure {
    if (! exists $first_sets{$_[1]}) {
        $first_sets{$_[1]} = {};
    }
    my $set = $first_sets{$_[1]};

  PRODUCTIONS:
    foreach $prod (keys %{$_[0]{$_[1]}}) {
        my $term = $prod;
        my $i = 0;
        do {
            goto TERMS if $term =~ /^sub \{/;    # no actions
            if (! exists $_[0]{$term}) {         # terminal
                if (! exists $set->{$term})  {
                    $set->{$term} = 1;
                    $did_something = 1;
                }
                next PRODUCTIONS;
            } else {
                union $set, $first_sets{$term};
                next PRODUCTIONS if ! exists $first_sets{$term}{$EPSILON};
            }
          TERMS:
            $term = $_[0]{$_[1]}{$prod}[$i++];

        } while ($term);
    }
}

sub first_rhs {
    if ($_[3] eq $EPSILON) {
        $_[0]{$EPSILON} = 1;
        return 1;
    }
    my $term = $_[3];
    my $i = 0;
    do {
        goto TERMS if $term =~ /^sub \{/;    # no actions
        if (! exists $_[1]{$term}) {         # terminal
            $_[0]{$term} = 1;
            return 0;
        } else {
            union $_[0], $first_sets{$term};
            return 0 if ! exists $first_sets{$term}{$EPSILON};
        }
      TERMS:
        $term = $_[1]{$_[2]}{$_[3]}[$i++];
        
    } while ($term);

    return 1;
}

sub follow {
    foreach $nonterm (keys %{$_[0]}) {
        follow_init($_[0], $nonterm);
    }
    do {
        $did_something = 0;
        foreach $nonterm (keys %{$_[0]}) {
            follow_closure($_[0], $nonterm);
        }
    } while ($did_something);
}

sub follow_init {
    my $grammar = $_[0];
    $follow_sets{$_[1]}{$END_OF_INPUT} = 1 if $_[1] eq "start";

    foreach $prod (keys %{$grammar->{$_[1]}}) {
        my $term = $prod;
        my $i = 0, $x = 0;
        do {
            if (exists $grammar->{$term}) {                # non-terminal
                $x = $i;
                while ($inner = $grammar->{$_[1]}{$prod}[$x++]) {
                    next if $inner =~ /^sub \{/;           # no actions
                    if (! exists $grammar->{$inner}) {     # terminal
                        if (! exists $follow_sets{$term}{$inner})  {
                            $follow_sets{$term}{$inner} = 1;
                            $did_something = 1;
                        }
                        last;
                    } else {
                        if (! exists $follow_sets{$term}) {
                            $follow_sets{$term} = {};
                        }
                        union $follow_sets{$term}, $first_sets{$inner};
                        last if ! exists $first_sets{$inner}{$EPSILON};
                    }
                }
            }
            $term = $grammar->{$_[1]}{$prod}[$i++];

        } while ($term);
    }
}

sub follow_closure {
    my $grammar = $_[0];
    my $set = $follow_sets{$_[1]};

  PRODUCTIONS:
    foreach $prod (keys %{$grammar->{$_[1]}}) {
        my $i = @{$grammar->{$_[1]}{$prod}} - 1;
        my $term = $grammar->{$_[1]}{$prod}[$i];
        do {
            # Use ! $term to catch epsilon, which points at a NULL
            if ($term && $term !~ /^sub \{/) {            # no actions
                next PRODUCTIONS if ! exists $_[0]{$term};  # terminal
                if (! exists $follow_sets{$term}) {
                    $follow_sets{$term} = {};
                }
                union $follow_sets{$term}, $set;
                next PRODUCTIONS if ! exists $first_sets{$term}{$EPSILON};
            }
            if ($i == -1) {
                $term = $prod;
                $i--;
            } else {
                $term = $grammar->{$_[1]}{$prod}[$i--];
            }

        } while ($i >= -2);
    }
}

sub closeup {
    remove_epsilon(\%follow_sets);
    remove_epsilon(\%first_sets);
}

1;
