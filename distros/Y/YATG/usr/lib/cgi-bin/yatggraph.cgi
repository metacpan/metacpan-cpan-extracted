#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use CGI ':cgi-lib';
use Symbol;
use YATG::Config;
YATG::Config->Defaults->{'no_validation'} = 1;
use Config::Any;

use perlchartdir; # please do; it's very good.

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my $yatg_config_file = $ENV{YATG_CONFIG_FILE} || die "no yatg conf location";
my $yatg_conf = YATG::Config->parse($yatg_config_file)
    || die "failed to load yatg config $yatg_config_file";

perlchartdir::setLicenseCode($yatg_conf->{yatg}->{perlchartdir_key})
    if exists $yatg_conf->{yatg}->{perlchartdir_key};

my $yatg_graph_conf = $ENV{YATG_GRAPH_CONF} || die "missing yatg graph conf";
my $graph_conf = Config::Any->load_files(
    {files => [$yatg_graph_conf], use_ext => 1})->[0]->{$yatg_graph_conf}
    || die "failed to load yatg graph config $yatg_graph_conf";

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my $width = "700";
my $height = "290";

my %p = Vars;
map {s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg} values %p; # uri unescape

my ($period,$title,$ytitle,$ip,$port,$lf,$lftxt,$end)
    = @p{qw/period title ytitle ip port lf lftxt end/};

# FIXME params should be validated

my ($xtitle, $totaltime, $timefmt, $step, $major,
        $xlbloffset, $rulecols, $xtickcols)
    = @{ $graph_conf->{$period} };

$end = ($end - ($end % $step));
my $start = (($end - $totaltime) - (($end - $totaltime) % $major));

my @ports  = split "\0", $port;
my @legend = split "\0", $lftxt; # lib_cgi
my %leaves = map {$_ => shift @legend} split "\0", $lf;

my %colour;
@colour{keys %leaves} = ( 0x00990033, 0x003366cc );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub normalize_data {
    my $leaf = shift;
    my %input = @_;
    my $wrap32 = 2**32;
    my $wrap64 = 2**64;

    my $xdata = [sort {$a <=> $b} keys %input];
    my $data  = [map {$input{$_}} @$xdata];

    my $xdataary = ArrayMath->new($xdata)->delta;
    my $dataary  = ArrayMath->new($data)->delta;

    # fix missing points to zero
    for (reverse (1 .. $#{$data})) {
        $data->[$_] = 0
            if !defined $data->[$_]
            or !defined $data->[$_ - 1]
            or $data->[$_ - 1] eq 0;
    }

    # look for strange or wrapped data points
    while (1) {
        my $shifted = 0;
        for (1 .. $#{$data}) {
            if ($data->[$_] != 0
            and $data->[$_] < $data->[$_ - 1]) {

                $data->[$_] += ( $leaf =~ m/HC/ ? $wrap64 : $wrap32);
                    # broken, in so many ways. assumes a wrap but it could
                    # have been a reboot. assumes naming of leaves; and so on
                $shifted = 1;
            }
        }
        last if ! $shifted;
    }


    # now squish and scale the data
    $dataary->selectGTZ($data);
    $dataary->div($xdataary->result);
    $dataary->mul2(8);
    $dataary->div2(1048576);
    $dataary->selectNEZ([],$perlchartdir::NoValue);

    return ($dataary, $xdata);
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Create an XYChart object with a light blue (EEEEFF)
# background, black border, 1 pixel border
my $c = new XYChart($width, $height, 0x00eeeeff, 0x00000000);

# Set the plotarea at (55, 48) and of size 520 x 195 pixels, with white background.
# Turn on both horizontal and vertical grid lines with light grey color (0x00cccccc)
$c->setPlotArea(55, 48, ($width - 80), ($height - 95), 0x00ffffff)->setGridColor(@$rulecols);

# Add a legend box at (50, 20) (top of the chart) with horizontal layout. Use 9 pts
# Arial Bold font. Set the background and border color to Transparent.
$c->addLegend(50, 20, 0, "arialbd.ttf", 9)->setBackground($perlchartdir::Transparent);

# Add a title box to the chart using 12 pts Times Bold Italic font, on a light
# blue (CCCCFF) background.
$c->addTitle($title, "timesbi.ttf", 12)->setBackground(0x00ccccff, 0x00000000);

$c->yAxis->setTitle($ytitle,"",9);
$c->xAxis->setTitle($xtitle,"",9);

$c->xAxis->setLabelFormat("{value|$timefmt}");
$c->xAxis->setLabelOffset($xlbloffset);
$c->xAxis->setTickColor(@$xtickcols);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my ($minx, $maxx);

foreach my $leaf (keys %leaves) {

    my $mod = undef;
    $mod = 'RPC'
        if grep m/^rpc$/i,  @{$yatg_conf->{yatg}->{oids}->{$leaf}};
    $mod = 'Disk'
        if grep m/^disk$/i, @{$yatg_conf->{yatg}->{oids}->{$leaf}};
    defined $mod or die "Storage for $leaf is not RPC or Disk\n";

    eval "require YATG::Retrieve::$mod" or die $@;

    my @ret;
    foreach my $port (@ports) {
        (my $mport = $port) =~ s/[^A-Za-z0-9]/./g;

        my $tmp_ret =
            &{*{Symbol::qualify_to_ref('retrieve',"YATG::Retrieve::$mod")}}
                ({%$yatg_conf}, $ip, $mport, $leaf, $start, $end, $step);

        $#ret = $#{$tmp_ret};
        foreach (@ret) { $_ ||= 0; $_ += shift @$tmp_ret }
    }

    my $data;
    foreach my $offset (0 .. $#ret) {
        $data->{$start + ($offset * $step)} = $ret[$offset];
    }

    my ($dataary, $xdata);
    if (grep m/^ifindex$/, @{$yatg_conf->{yatg}->{oids}->{$leaf}}) { # hacky?
        ($dataary, $xdata) = normalize_data($leaf, %$data);
    }
    else {
        ($dataary, $xdata) =
            (ArrayMath->new(values %$data), ArrayMath->new(keys %$data));
    }

    $minx ||= $xdata->[0];
    $maxx ||= $xdata->[-1];

    my $layer =
        $c->addLineLayer($dataary->result, $colour{$leaf}, $leaves{$leaf});
    $layer->setXData( ArrayMath->new($xdata)->add(62135600400 - 3600)->result );
}

# fix unix epoch to perlchartdir epoch
$c->xAxis->setDateScale(
     62135600400 - 3600 + $minx,
     62135600400 - 3600 + $maxx,
     $major, $major / 3
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

print "Content-type: image/png\n\n";
print $c->makeChart2($perlchartdir::PNG);

# ABSTRACT: CGI to make PNG of YATG polled port traffic data
# PODNAME: yatggraph.cgi

=head1 IMPORTANT NOTE

Do not place this script on a public or Internet-accessible web server!

It is a proof-of-concept, and contains no parameter checking whatsoever, so
your users can pass any old junk parameters in, and they will be assumed
valid. This could cause your web-server to be hacked.

The author and copyright holder take no responsibility whatsoever for any
damages incurred as a result of using this software.

=head1 DESCRIPTION

Please see the documentation for L<yatgview.cgi>.

=head1 ACKNOWLEDGEMENTS

This CGI is based upon the RTG CGIs by Anthony Tonns.

=cut
