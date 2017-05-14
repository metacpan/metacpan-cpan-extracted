package Scanner::Scanner;

# $Revision:   1.1  $

=head1 NAME 

Scanner - implements the base for all scanners

=head1 SYNOPSIS

    use Scanner::Scanner;

    $tokens = [ '[A-Za-z_][A-Za-z0-9_]*', $IDENT ];

    $scanner = new Scanner::FirstMatch($tokens, new
        Scanner::Stream::File "blah.txt");

=cut

require 5.001;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($END_OF_INPUT);

$END_OF_INPUT = 10000;

sub new {
    my $self = [ $_[1], $_[2] ];
    bless $self;
    return $self;
}

sub Error {
    my $self = $_[0];
    warn "line " . $self->[1]->Line() . ": " .
        ($_[1] || "syntax error") . "\n";
    warn $self->[1]->Context();
}

# Reset token input.  Allows user to continue input in a different
# file.

sub Reset {
    ${_[0]}->[1] = $_[1];
}

1;
