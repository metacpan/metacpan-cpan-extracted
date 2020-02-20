package Test2::Plugin::IOEvents::Tie;
use strict;
use warnings;

our $VERSION = '0.000002';

use Test2::API qw/context/;
use Carp qw/croak/;

sub TIEHANDLE {
    my $class = shift;
    my ($name, $fn, $fh) = @_;

    unless ($fn && $fh) {
        if ($fn) {
            open($fh, '>&', $fn);
        }
        elsif ($name eq 'STDOUT') {
            $fn = fileno(STDOUT);
            open($fh, '>&', STDOUT);
        }
        elsif ($name eq 'STDERR') {
            $fn = fileno(STDERR);
            open($fh, '>&', STDERR);
        }
    }

    return bless([$name, $fn, $fh], $class);
}

sub OPEN {
    no warnings 'uninitialized';

    if ($_[0]->[0] eq 'STDOUT') {
        untie(*STDOUT);
        return open(STDOUT, $_[1], @_ > 2 ? $_[2] : ());
    }
    elsif ($_[0]->[0] eq 'STDERR') {
        untie(*STDERR);
        return open(STDERR, $_[1], @_ > 2 ? $_[2] : ());
    }

    return;
}

sub PRINT {
    my $self = shift;
    my ($name) = @$self;

    my $output = defined($,) ? join( $,, @_) : join('', @_);

    return unless length($output);

    my $ctx = context();
    $ctx->send_ev2_and_release(
        info => [
            {tag => $name, details => $output, $name eq 'STDERR' ? (debug => 1) : ()},
        ]
    );
}

sub FILENO {
    my $self = shift;
    return $self->[1];
}

sub PRINTF {
    my $self = shift;
    my ($format, @list) = @_;
    my ($name) = @$self;

    my $output = sprintf($format, @list);
    return unless length($output);

    my $ctx = context();
    $ctx->send_ev2_and_release(
        info => [
            {tag => $name, details => $output, $name eq 'STDERR' ? (debug => 1) : ()},
        ]
    );
}

sub CLOSE { 1 }

sub WRITE {
    my $self = shift;
    my ($buf, $len, $offset) = @_;
    return syswrite($self->[2], $buf) if @_ == 1;
    return syswrite($self->[2], $buf, $len) if @_ == 2;
    return syswrite($self->[2], $buf, $len, $offset);
}

sub BINMODE {
    my $self = shift;
    return binmode($self->[2]) unless @_;
    return binmode($self->[2], $_[0]);
}

sub autoflush {
    my $self = shift;

    if (@_) {
        my ($val) = @_;
        $self->[2]->autoflush($val);
        $self->[3] = $val;
    }

    return $self->[3];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::IOEvents::Tie - Tie handler for Test2::Plugin::IOEvents

=head1 SOURCE

The source code repository for Test2-Harness can be found at
F<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
