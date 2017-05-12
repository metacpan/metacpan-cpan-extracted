package TheEye::Plugin::Store::RRD;

use 5.010;
use Mouse::Role;
use RRD::Simple;
use Data::Dumper;

# ABSTRACT: RRD plugin for TheEye
#
our $VERSION = '0.1'; # VERSION

has 'rrd_dir' => (
    is      => 'rw',
    isa     => 'Str',
    required => 1,
    lazy     => 1,
    default => '/tmp/rrds/'
);

has 'rrd_bin' => (
    is      => 'rw',
    isa     => 'Str',
    required => 1,
    lazy     => 1,
    default => qx/which rrdtool/
);

has 'rrd_tmp' => (
    is      => 'rw',
    isa     => 'Str',
    required => 1,
    lazy     => 1,
    default => '/tmp'
);


around 'save' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;
    foreach my $result (@{$tests}) {
        my @fparts = split( /\./, $result->{file} );
        $fparts[0] =~ s/\//-/g;
        print STDERR "saving ".$result->{file}."\n" if $self->debug;
        my $rrd = RRD::Simple->new(
            file           => $self->rrd_dir. $fparts[0] . '.rrd',
            rrdtool        => $self->rrd_bin,
            tmpdir         => $self->rrd_tmp,
            cf             => [qw(AVERAGE MAX)],
            default_dstype => "GAUGE",
            on_missing_ds  => "add",
        );
        $rrd->update(
            $result->{time},
            delta  => $result->{delta},
            passed => $result->{passed},
            failed => $result->{failed},
        );
    }
    return;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TheEye::Plugin::Store::RRD - RRD plugin for TheEye

=head1 VERSION

version 0.1

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
