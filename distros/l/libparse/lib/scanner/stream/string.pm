package Scanner::Stream::String;

# $Revision:   1.0  $

=head1 NAME 

String - allows for simple streaming access to a string buffer

=head1 SYNOPSIS

    use Scanner::Stream::String;

    $stream = new Scanner::Stream::String "Data!";

=cut

require 5.001;
use Scanner::Stream;
@ISA = qw(Scanner::Stream);

sub new {
    my $self = new Scanner::Stream \&GetLine;
    $self->[4] = $_[1];
    bless $self;
    $self->next();
    return $self;
}

sub GetLine {
    ${_[0]}->[4] =~ s/^(.*\n?)//;
    return $1;
}

1;
