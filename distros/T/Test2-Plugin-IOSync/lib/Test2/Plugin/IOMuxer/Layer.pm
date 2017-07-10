package Test2::Plugin::IOMuxer::Layer;
use strict;
use warnings;

BEGIN {
    local $@ = undef;
    my $ok = eval {
        require JSON::MaybeXS;
        JSON::MaybeXS->import('JSON');
        1;
    };

    unless($ok) {
        require JSON::PP;
        *JSON = sub() { 'JSON::PP' };
    }

    my $json = JSON()->new->utf8(1);

    sub encode_json { $json->encode(@_) }
}

use Time::HiRes qw/time/;

our $VERSION = '0.000009';

use Test2::Plugin::OpenFixPerlIO;
use IO::Handle;

our %MUXED;
our %MUX_FILES;

sub name { 'other' }

sub PUSHED {
    my ($class, $mode, $handle) = @_;
    $handle->autoflush(1);
    bless {buffer => [], handle => $handle, count => 0}, $class;
}

sub FLUSH {
    my $self = shift;
    my ($handle) = @_;
    $handle->flush;
}

my $DEPTH = 0;
sub WRITE {
    my ($self, $buffer, $handle) = @_;

    my $count = ++$self->{count};

    if ($self->{DIED} || $DEPTH) {
        print $handle $buffer;
        return length($buffer);
    }

    $DEPTH++;

    my $ok1 = eval {
        my $time   = time;
        my $fileno = fileno($handle);

        my @parts = split /(\n)/, $buffer;
        unshift @parts => '' if @parts == 1 && $parts[0] eq "\n";
        push @parts => undef if @parts % 2;
        my %parts = @parts;
        for my $part (@parts) {
            next unless defined $part;
            next if $part eq "\n";

            my $about = {stamp => $time, fileno => $fileno, name => $self->name, buffer => $part, write_no => $count};

            # Time to flush
            if ($parts{$part}) {
                $about->{buffer} .= $parts{$part}; # Put the \n back

                my $out;
                if (@{$self->{buffer}}) {
                    push @{$self->{buffer}} => $about;
                    $out = {
                        parts => $self->{buffer},
                        %$about,
                        buffer => join '' => map { $_->{buffer} } @{$self->{buffer}},
                    };

                    # Reset the buffer
                    $self->{buffer} = [];
                }
                else {    # Easy
                    $out = $about;
                }

                my $json = encode_json($out);
                my $mh   = $MUX_FILES{$MUXED{$fileno}};
                print $mh $json, "\n";
            }
            else {
                push @{$self->{buffer}} => $about;
            }
        }

        1;
    };
    my $err1 = $@;

    my $ok2 = eval { print $handle $buffer };
    my $err2 = $@;

    $DEPTH--;

    unless ($ok1 && $ok2) {
        $self->{DIED}++;

        die $err2 if $ok1;
        die $err1 if $ok2;

        warn $err2;
        die $err1;
    }

    return length($buffer);
}

sub DESTROY {
    my $self = shift;
    my $handle = $self->{handle} or return;
    my $buffer = $self->{buffer} or return;
    return unless @$buffer;

    my $fileno = fileno($handle);

    my $out = {
        parts    => $self->{buffer},
        stamp    => time,
        fileno   => $fileno,
        name     => $self->name,
        write_no => ++$self->{count},
        DESTROY  => 1,
        buffer   => join '' => map { $_->{buffer} } @$buffer,
    };

    my $json = encode_json($out);
    my $mh = $MUX_FILES{$MUXED{$fileno}};
    print $mh $json, "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::IOMuxer::Layer - The PerlIO::via class used by
Test2::Plugin::IOMuxer.

=head1 SOURCE

The source code repository for Test2-Plugin-IOSync can be found at
F<http://github.com/Test-More/Test2-Plugin-IOSync/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2017 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
