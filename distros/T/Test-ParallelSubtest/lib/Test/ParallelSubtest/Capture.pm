package Test::ParallelSubtest::Capture;
use strict;
use warnings;

our $VERSION = '0.05';
$VERSION = eval $VERSION;

{
    package Test::ParallelSubtest::CaptureFH;
    use IO::WrapTie;
    use Tie::FileHandle::Base;
    our @ISA = qw(IO::WrapTie::Slave Tie::FileHandle::Base);

    sub TIEHANDLE {
        my ($pkg, $bufref, $prefix) = @_;

        return bless {
            BufRef => $bufref,
            Prefix => $prefix,
        }, ref($pkg)||$pkg;
    }

    sub PRINT {
        my $self = shift;

        my $text = join '', @_;
        if (length $text) {
            # Append to the buffer the prefix that identifies this
            # filehandle, followed by the data length and then the data.
            ${ $self->{BufRef} } .= $self->{Prefix}
                                        . pack('N', length $text) . $text;
        }
    }
}

use Carp;

sub new {
    my ($pkg, $bufref) = @_;

    if ($bufref) {
        ref $bufref eq 'SCALAR' or croak 'new() arg must be a scalar ref';
    }
    else {
        my $buf = '';
        $bufref = \$buf;
    }

    return bless {
        BufRef => $bufref,
    }, ref($pkg)||$pkg;
}

sub install {
    my ($self, $builder) = @_;

    my %fh;
    foreach my $prefix (qw( o f t )) {
        $fh{$prefix} = Test::ParallelSubtest::CaptureFH->new_tie(
                                                   $self->{BufRef}, $prefix);
    }

    $builder->output(        $fh{'o'});
    $builder->failure_output($fh{'f'});
    $builder->todo_output(   $fh{'t'});
}

sub as_string_ref {
    my $self = shift;

    return $self->{BufRef};
}

sub replay_writes {
    my ($self, $out_dest, $fail_dest, $todo_dest) = @_;

    my %fh = (
        'o' => $out_dest,
        'f' => $fail_dest,
        't' => $todo_dest,
    );

    my $buf = ${ $self->{BufRef} };
    while (length $buf) {
        $buf =~ s/^([oft])// or return;
        my $fh = $fh{$1};
        my $packed_len = substr $buf, 0, 4, '';
        return if length($packed_len) != 4;
        my $len = unpack 'N', $packed_len;
        return if $len < 1 or $len > length $buf;
        print $fh substr $buf, 0, $len, '';
    }

    return 1;
}

1;

__END__

=head1 NAME

Test::ParallelSubtest::Capture - capture Test::Builder output

=head1 SYNOPSIS

    my $capture = Test::ParallelSubtest::Capture->new;
    
    $capture->install(Test::Builder->new);

    ok 1, 'blah';
    # ...

    $capture->replay_writes(\*STDOUT, \*STDERR, \*STDOUT);

=head1 DESCRIPTION

A helper class for L<Test::ParallelSubtest>, allowing all L<Test::Builder>
output generated in the child process to be buffered and passed to the
parent process for printing.

For now this class is private to L<Test::ParallelSubtest>, and it may
change or vanish without notice.  If anyone wants to use this outside of
L<Test::ParallelSubtest>, please drop me a line and I'll make it into a
separate package under a new name.

=head1 METHODS

=over

=item new ( [BUFREF] )

Creates a new output capture object.  If BUFREF is supplied then it must
be a reference to a scalar holding the buffer contents returned by the
as_string_ref() method of a B<Test::ParallelSubtest::Capture> object.

=item install ( BUILDER )

BUILDER must be a L<Test::Builder> object.

Installs the capture object as BUILDER's destination for all test output.
Test output will now accumulate in the capture object until BUILDER's
outputs are redirected elsewhere.

=item as_string_ref ()

Returns a reference to a string that encodes the sequence of writes so far.
The string is suitable for passing to new() to build a new capture object
holding the same the sequence of writes.

=item replay_writes ( OUT_DEST, FAIL_DEST, TODO_DEST )

Replays the captured sequence of writes.  The parameters must be file
handles, and each will receive writes of a particular type.  See
L<Test::Builder/output>.

Returns true on success, false if the internal buffer cannot be decoded
because a malformed buffer was passed to new().

=back

=head1 AUTHOR

Nick Cleaton, E<lt>nick@cleaton.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Nick Cleaton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
