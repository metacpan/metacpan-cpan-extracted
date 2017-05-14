package Scanner::Stream::File;

# $Revision:   1.0  $

=head1 NAME 

Handle - allows for simple streaming access to a file

=head1 SYNOPSIS

    use Scanner::Stream::File;

    $stream = new Scanner::Stream::File "blah.txt";

=head1 DESCRIPTION

The only difference between this class and the Handle class is that it
will open the file, and close the file when it is done with it.

=cut

require 5.001;
use Scanner::Stream::Handle;
@ISA = qw(Scanner::Stream::Handle);

sub new {
    open(HANDLE, $_[1]) || die "Can't open file $_[1]";
    my $self = new Scanner::Stream::Handle \*HANDLE;
    bless $self;
    return $self;
}

sub DESTROY {
    close ${_[0]}->[4];
}

1;
