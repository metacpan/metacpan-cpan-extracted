package Scanner::Greedy;

# $Revision:   1.1  $

=head1 NAME 

Greedy - a greedy tokenizer based on flex fast tables

=cut

require 5.001;
use Scanner::Scanner;
@ISA = qw(Scanner::Scanner);

sub new {
    my $self = new Scanner::Scanner [ $_[1], $_[2], $_[3] ], $_[4];
    bless $self;
    $self->[2] = @{$_[3]} / 2;
    $self->[3] = $self->[1]->GetChar();
    return $self;
}

sub Switch {
    ${_[0]}->[0] = [ $_[1], $_[2], $_[3] ];
    ${_[0]}->[2] = @{$_[3]} / 2;
}

sub Read {
    my $self = shift @_;
    my $accept, $pos;

    while ($self->[1]->Valid()) {
        my $current = 1;
        my $lexeme;

        # Initialize lookahead
        $self->[3] = $self->[1]->GetChar() if ! defined $self->[3];

        while (($current = $self->[0][0][$current][ord $self->[3]]) > 0) {
            $lexeme .= $self->[3];
            $self->[3] = $self->[1]->GetChar();
            $pos++;
            if ($self->[0][1][$current]) {
                $accept = $current;
                $pos = 0;
            }
        }
        $current = -$current;

      find_action:
        my $action = $self->[0][1][$current];

        if (! $action) {
            $lexeme = substr $lexeme, 0, length($lexeme) - $pos;
            $self->[1]->Backup(-$pos);
            $current = $accept;
            goto find_action;
        }
        elsif (--$action < $self->[2]) {
            $action = $self->[0][2][$action * 2 + 1];
            next if (ref $action && ! ($action = &$action($self, $lexeme)));
            return ($action, $lexeme);
        }
    }
    return ($END_OF_INPUT, "<EOF>");
}

1;
