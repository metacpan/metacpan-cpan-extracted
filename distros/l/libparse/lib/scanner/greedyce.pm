package Scanner::GreedyCe;

# $Revision:   1.1  $

=head1 NAME 

GreedyCe - a greedy tokenizer based on flex compressed tables

=cut

require 5.001;
use Scanner::Scanner;
@ISA = qw(Scanner::Scanner);

sub new {
    my $self = new Scanner::Scanner [ $_[1], $_[2], $_[3], $_[4],
                                      $_[5], $_[6], $_[7], $_[8] ], $_[9];
    bless $self;
    $self->[2] = @{$_[7]} / 2;
    $self->[3] = $self->[1]->GetChar();
    return $self;
}

sub Switch {
    ${_[0]}->[0] = [ $_[1], $_[2], $_[3], $_[4], $_[5], $_[6], $_[7], $_[8] ];
    ${_[0]}->[2] = @{$_[7]} / 2;
}

sub Read {
    my $self = shift @_;

    my $accept;

  LOOP:
    while ($self->[1]->Valid()) {
        my $current = 1;
        my $lexeme, $pos;

        # Initialize lookahead
        $self->[3] = $self->[1]->GetChar() if ! defined $self->[3];

        # $self->[0][x]:
        #   0 yy_accept
        #   1 yy_ec
        #   2 yy_base
        #   3 yy_def
        #   4 yy_nxt
        #   5 yy_chk
        #   6 yy_act
        #   7 jambase

        do {
            $yy_c = $self->[0][1][ord $self->[3]];
            if ($self->[0][0][$current]) {
                $accept = $current;
                $pos = -1;
            }
            while ($self->[0][5][$self->[0][2][$current] + $yy_c] !=
                   $current) {
                $current = $self->[0][3][$current];
            }
            $current = $self->[0][4][$self->[0][2][$current] + $yy_c];

            if (! ($pos < 0 && $self->[0][2][$current] == $self->[0][7])) {
                $lexeme .= $self->[3];
                $self->[3] = $self->[1]->GetChar();
                $pos++;
            } else {
                $pos = 0;
            }

        } while ($self->[0][2][$current] != $self->[0][7]);

      find_action:
        my $action = $self->[0][0][$current];

        if (! $action) {
            $lexeme = substr $lexeme, 0, length($lexeme) - $pos;
            $self->[1]->Backup(-$pos);
            $current = $accept;
            goto find_action;
        }
        elsif (--$action < $self->[2]) {
            $action = $self->[0][6][$action * 2 + 1];
            next if (ref $action && ! ($action = &$action($self, $lexeme)));
            return ($action, $lexeme);
        }
    }
    return ($END_OF_INPUT, "<EOF>");
}

1;
