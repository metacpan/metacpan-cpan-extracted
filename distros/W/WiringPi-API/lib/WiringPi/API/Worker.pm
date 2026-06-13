package WiringPi::API::Worker;

use strict;
use warnings;

use WiringPi::API::BackgroundInterrupt;

# Handle returned by worker(). Owns one forked child that runs the user body in
# a loop. The pid/running/stop/DESTROY lifecycle (TERM -> poll -> KILL -> reap)
# is mechanism-agnostic, so it is inherited wholesale from BackgroundInterrupt,
# as are the {results=>1} streaming read()/fh(). value() adds the lossy
# latest-value drain for the {shared=>1} channel.

our @ISA = ('WiringPi::API::BackgroundInterrupt');

sub _new {
    my ($class, $pid, $results_fh, $value_fh) = @_;

    my $self = $class->SUPER::_new($pid, $results_fh);
    $self->{value_fh} = $value_fh;

    return $self;
}
sub value {
    # Lossy latest value from the {shared=>1} channel: drain every record the
    # child has written and keep only the most recent, caching it so a later
    # call with nothing new pending still returns the last seen value.
    my ($self) = @_;

    my $fh = $self->{value_fh};
    return $self->{value} if ! defined $fh;

    while (1) {
        my $rin = "";
        vec($rin, fileno($fh), 1) = 1;
        my $nfound = select(my $rout = $rin, undef, undef, 0);
        last if ! $nfound || $nfound < 0;

        # Each record is one non-blocking syswrite from the single child, and
        # the writer skips any frame larger than PIPE_BUF (4096B, incl. the
        # 4-byte length) - a partial non-blocking write of an oversized frame
        # would desync this length-framed read. So every frame that reaches here
        # is whole: once the length prefix is readable the payload is too, and
        # _read_exact won't block.
        my $len_buf = WiringPi::API::BackgroundInterrupt::_read_exact($fh, 4);
        last if ! defined $len_buf;

        my $rec = WiringPi::API::BackgroundInterrupt::_read_exact(
            $fh, unpack("N", $len_buf));
        last if ! defined $rec;

        $self->{value} = $rec;
    }

    return $self->{value};
}

1;
__END__

=head1 NAME

WiringPi::API::Worker - Handle for a fork-based background worker

=head1 SYNOPSIS

    use WiringPi::API qw(setup pin_mode analog_read worker);

    setup();
    pin_mode(0, 0);

    my $w = worker(sub { analog_read(0) }, { interval => 1, shared => 1 });

    my $latest = $w->value;   # most recent sample, or undef yet
    $w->stop;                 # idempotent; END reaps if forgotten

=head1 DESCRIPTION

An object of this class is returned by L<WiringPi::API/worker(\&body, \%opts)>
when the default C<< mechanism => 'fork' >> is used. It owns one forked child
that runs the user body in a loop.

You never construct one directly - C<worker()> forks the child and hands you the
handle.

It is a subclass of L<WiringPi::API::BackgroundInterrupt> and inherits that
class's C<pid>/C<running>/C<stop>/C<DESTROY> lifecycle (the fork TERM -> poll ->
KILL -> reap sequence is mechanism-agnostic), as well as the C<< results => 1 >>
streaming C<read>/C<fh>. This class adds C<value> for the C<< shared => 1 >>
channel.

=head1 METHODS

=head2 value

The latest value published by the body when the worker was started with
C<< shared => 1 >> (otherwise C<undef>). This is a B<lossy latest value>: every
record the child has written is drained and only the most recent is kept, then
cached so a later call with nothing new pending still returns the last seen
value.

=head1 SEE ALSO

L<WiringPi::API>, L<WiringPi::API::BackgroundInterrupt>,
L<WiringPi::API::WorkerThread>.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
