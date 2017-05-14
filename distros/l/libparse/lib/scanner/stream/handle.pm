package Scanner::Stream::Handle;

# $Revision:   1.0  $

=head1 NAME 

Handle - allows for simple streaming access to a file handle

=head1 SYNOPSIS

    use Scanner::Stream::Handle;

    $stream = new Scanner::Stream::Handle DATA;

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
    my $input = ${_[0]}->[4];
    return scalar(<$input>);
}

1;
