package TheEye::Plugin::Graph::RRD;

use 5.010;
use Mouse::Role;
use RRD::Simple;

# ABSTRACT: RRD plugin for TheEye
#
our $VERSION = '0.1'; # VERSION

has 'rrd_dir' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => '/tmp/rrds/'
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

has 'img_dir' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => '/tmp/images/'
);

around 'graph' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    foreach my $test (@{$tests}) {
        my @fparts = split( /\./, $test->{file} );
        my $file = $fparts[0];
        $file =~ s/\//-/g;
        $file = $self->rrd_dir . $file.'.rrd';
        print STDERR "graphing ".$file."\n" if $self->debug;

        my $rrd = RRD::Simple->new(
            file    => $file,
            rrdtool => $self->rrd_bin,
            tmpdir  => $self->rrd_tmp,
        );
        my %rtn = $rrd->graph(
            destination    => $self->img_dir,
            title          => $test->{file} .': '. $test->{steps}->[0]->{message},
            periods        => [ qw(hour day week month) ],
            vertical_label => "passed/failed",
            interlaced     => "",
            extended_legend => 1,
            source_labels  => {
                passed => 'passed Tests',
                failed => 'failed Tests',
                delta  => 'time needed (s)'
            },
            source_colors  => {
                passed => '66CC00',
                failed => 'FF3300',
                delta  => 'CCCCCC'
            },
            source_drawtypes  => {
                passed => 'LINE',
                failed => 'AREA',
                delta  => 'LINE1'
            },
        );
        printf( "Created %s\n", join( ", ", map { $rtn{$_}->[0] }
        keys %rtn ) ) if $self->debug;
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TheEye::Plugin::Graph::RRD - RRD plugin for TheEye

=head1 VERSION

version 0.1

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
