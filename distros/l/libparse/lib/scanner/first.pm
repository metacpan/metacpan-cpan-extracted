package Scanner::First;

# $Revision:   1.1  $

=head1 NAME 

First - implements a simple "first match" tokenizer

=head1 SYNOPSIS

    use Scanner::Stream::File;
    use Scanner::Scanner;
    use Scanner::First;
    $tokens = [ '[A-Za-z_][A-Za-z0-9_]*', sub { print "$_[1] "; } ];
    # Print all the identifiers in blah.txt
    $scanner = new Scanner::First($tokens, new
        Scanner::Stream::File "blah.txt");

=cut

require 5.001;
use Scanner::Scanner;
@ISA = qw(Scanner::Scanner);

sub new {
    my $self = new Scanner::Scanner $_[1], $_[2];
    bless $self;
    $self->[2] = @{$self->[0]};
    return $self;
}

sub Switch {
    ${_[0]}->[0] = $_[1];
    ${_[0]}->[2] = @{$_[1]};
}

sub Read {
    my $self = shift @_;
    my $i, $lexeme, $action, $ret;
  LOOP:
    while ($self->[1]->Valid()) {
        for ($i = 0; $i < $self->[2]; $i += 2) {
            if ($self->[1]->Match($self->[0][$i], \$lexeme)) {
                $action = $self->[0][$i + 1];
                if (ref($action)) {    # assume equals CODE
                    $ret = &$action($self, $lexeme);
                    return ($ret, $lexeme) if $ret;
                } else {
                    return ($action, $lexeme);
                }
                next LOOP;
            }
        }
        $self->[1]->Skip(1);
    }
    return ($END_OF_INPUT, "<EOF>");
}

1;
