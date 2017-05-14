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

our $VERSION = '0.000007';

use Test2::Plugin::OpenFixPerlIO;
use IO::Handle;

our %MUXED;
our %MUX_FILES;

sub PUSHED {
    my ($class, $mode, $handle) = @_;
    $handle->autoflush(1);
    bless {}, $class;
}

sub WRITE {
    my ($self, $buffer, $handle) = @_;

    if ($self->{DIED}) {
        print $handle $buffer;
        return length($buffer);
    }

    my $ok = eval {
        my $time = time;
        my $fileno = fileno($handle);

        my $json = encode_json({stamp => $time, fileno => $fileno, buffer => $buffer});
        my $mh = $MUX_FILES{$MUXED{$fileno}};
        print $mh $json, "\n";

        1;
    };
    my $err = $@;

    print $handle $buffer;

    unless ($ok) {
        $self->{DIED}++;
        die $err;
    }

    return length($buffer);
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
