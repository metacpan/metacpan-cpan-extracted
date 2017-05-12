package Tie::Handle::TtyRec;
use strict;
use warnings;
use base 'Tie::Handle';

use Symbol;
use Time::HiRes 'gettimeofday';
use Carp 'croak';

our $VERSION = '0.04';

sub new {
    my ($class, $filename, %params) = @_;
    my $symbol = Symbol::gensym;

    tie(*$symbol, __PACKAGE__, $filename, %params);

    return $symbol;
}

sub TIEHANDLE {
    my ($class, $filename, %params) = @_;

    my $mode = -p $filename    ? '+>'
             : $params{append} ? '>>'
             :                   '>';

    open(my $self, $mode, $filename)
        or croak "Unable to open $filename for writing: $!";

    $self->autoflush(1);

    bless $self, (ref $class || $class);
}

sub READ {
    croak "Cannot read from a Tie::Handle::TtyRec";
}

sub WRITE {
    my $self = shift;
    my ($buf, $length, $offset) = @_;
    $offset ||= 0;
    $length ||= length($buf) - $offset;
    syswrite $self, pack('VVV', gettimeofday, $length)
                  . substr($buf, $offset, $length);
}

sub PRINT {
    my $self = shift;
    $self->WRITE($_) for @_;
}

sub CLOSE {
    my $self = shift;
    close $self;
}

1;

__END__

=head1 NAME

Tie::Handle::TtyRec - write a ttyrec

=head1 SYNOPSIS

    use Tie::Handle::TtyRec;
    my $handle = Tie::Handle::TtyRec->new("foo.ttyrec");
    print $handle "hello", "world";

=head1 DESCRIPTION

A ttyrec is a format used for recording terminal sessions. Notably, practically
all NetHack games are recorded using ttyrecs. ttyrecs include precise timing
data and can be a little fiddly. This module lets you focus on your
application, instead of making sure your ttyrec headers are perfect.

The usual way to use this module is through its C<new> interface. It will
clobber the file you decide to record to, unless you pass C<< append => 1 >> as
additional arguments to C<new>.

Each argument to print will be put into its own ttyrec frame, using the current
time. So, the following will create three separate frames,

    print $handle "foo", "bar", "baz";

The following will create only one frame,

    print $handle "foo" . "bar" . "baz";

=head1 SEE ALSO

L<Term::TtyRec>, L<Term::TtyRec::Plus>

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 CONTRIBUTORS

Jesse Luehrs, C<doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2012 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

