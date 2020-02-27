package Test2::Plugin::IOEvents::Tie;
use strict;
use warnings;

our $VERSION = '0.001001';

use Test2::API qw/context/;
use Carp qw/croak/;

sub TIEHANDLE {
    my $class = shift;
    my ($name, $fn, $fh, $inode) = @_;

    unless ($fn && $fh) {
        if ($fn) {
            open($fh, '>&', $fn);
        }
        elsif ($name eq 'STDOUT') {
            $fn = fileno(STDOUT);
            (undef, $inode) = stat(STDOUT);
            open($fh, '>&', STDOUT);
        }
        elsif ($name eq 'STDERR') {
            $fn = fileno(STDERR);
            (undef, $inode) = stat(STDERR);
            open($fh, '>&', STDERR);
        }
    }


    return bless([$name, $fn, $fh, $inode], $class);
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

sub _check_for_change {
    if ($_[0]->[0] eq 'STDOUT') {
        my (undef, $inode) = stat(STDOUT);
        if ($inode ne $_[0]->[3]) {
            untie(*STDOUT);
            return 1;
        }
    }
    elsif ($_[0]->[0] eq 'STDERR') {
        my (undef, $inode) = stat(STDERR);
        if ($inode ne $_[0]->[3]) {
            untie(*STDERR);
            return 1;
        }
    }

    return 0;
}

sub PRINT {
    my (undef, @args) = @_;

    my $name = $_[0]->[0];
    if ($_[0]->_check_for_change()) {
        if ($name eq 'STDOUT') {
            return print STDOUT @args;
        }
        elsif ($name eq 'STDERR') {
            return print STDERR @args;
        }
    }

    my $output = defined($,) ? join( $,, @args) : join('', @args);

    return unless length($output);

    my $ctx = context();
    $ctx->send_ev2_and_release(
        info => [
            {tag => $_[0]->[0], details => $output, $_[0]->[0] eq 'STDERR' ? (debug => 1) : ()},
        ]
    );
}

sub FILENO {
    my $self = shift;
    return $self->[1];
}

sub PRINTF {
    my (undef, @list) = @_;
    my $name = $_[0]->[0];
    if ($_[0]->_check_for_change()) {
        if ($name eq 'STDOUT') {
            return printf STDOUT @list;
        }
        elsif ($name eq 'STDERR') {
            return printf STDERR @list;
        }
    }

    my $self = shift;
    my $format = shift @list;

    my $output = sprintf($format, @list);
    return unless length($output);

    my $ctx = context();
    $ctx->send_ev2_and_release(
        info => [
            {tag => $name, details => $output, $name eq 'STDERR' ? (debug => 1) : ()},
        ]
    );
}

sub CLOSE {
    if ($_[0]->[0] eq 'STDOUT') {
        untie(*STDOUT);
        return close(STDOUT);
    }
    elsif ($_[0]->[0] eq 'STDERR') {
        untie(*STDERR);
        return close(STDERR);
    }
}

sub WRITE {
    my (undef, $buf, $len, $offset) = @_;
    my $fh;
    my $name = $_[0]->[0];
    if ($_[0]->_check_for_change()) {
        if ($name eq 'STDOUT') {
            $fh = \*STDOUT;
        }
        elsif ($name eq 'STDERR') {
            $fh = \*STDERR;
        }
    }
    else {
        $fh = $_[0]->[2];
    }

    return syswrite($fh, $buf) if @_ == 2;
    return syswrite($fh, $buf, $len) if @_ == 3;
    return syswrite($fh, $buf, $len, $offset);
}

sub BINMODE {
    my $fh;
    my $name = $_[0]->[0];
    if ($_[0]->_check_for_change()) {
        if ($name eq 'STDOUT') {
            $fh = \*STDOUT;
        }
        elsif ($name eq 'STDERR') {
            $fh = \*STDERR;
        }
    }
    else {
        $fh = $_[0]->[2];
    }

    return binmode($fh) unless @_ > 1;
    return binmode($fh, $_[1]);
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
