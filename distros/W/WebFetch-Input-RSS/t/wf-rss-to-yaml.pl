#!/usr/bin/env perl
# wf-rss-to-yaml.pl - generate YAML files for WebFetch::Input::RSS tests
#===============================================================================

use strict;
use warnings;
use utf8;
use autodie;
use Carp qw(croak);
use FindBin;
use File::Temp;
use File::Basename qw(basename dirname);
use Try::Tiny;
use YAML::XS;
use WebFetch "0.15.1";
use WebFetch::Input::RSS;
use WebFetch::Output::Capture;
use Data::Dumper;

# configuration
Readonly::Scalar my $progname        => basename($0);
Readonly::Scalar my $debug_mode      => ( exists $ENV{WEBFETCH_TEST_DEBUG} and $ENV{WEBFETCH_TEST_DEBUG} ) ? 1 : 0;
Readonly::Scalar my $src_format      => "rss";
Readonly::Scalar my $dest_format     => "capture";
Readonly::Scalar my $base_dir        => dirname($FindBin::Bin);
Readonly::Scalar my $input_dir       => $base_dir . "/t/test-inputs/020-spec-samples";
Readonly::Scalar my $date_num        => 0;                       # field number for date from WebFetch::Input::RSS
Readonly::Scalar my $title_num       => 1;                       # field number for title
Readonly::Scalar my $link_num        => 1;                       # field number for link
Readonly::Scalar my $creator_num     => 5;                       # field number for creator
Readonly::Scalar my $tmpdir_template => "WebFetch-XXXXXXXXXX";
Readonly::Array my @rss_versions     => qw(0.9 0.91 1.0 2.0);

# process file: input RSS, output YAML
sub rss2yaml
{
    my ( $input_dir, $rss_file, $temp_dir ) = @_;
    print STDERR "processing $rss_file\n";

    # run for multiple RSS versions
    my %results;
    foreach my $version (@rss_versions) {

        # read with WebFetch
        my %test_probe;
        my %Options = (
            dir           => $temp_dir,
            source_format => $src_format,
            source        => "file://" . $input_dir . "/" . $rss_file,
            dest_format   => $dest_format,
            dest          => "",                                         # unused
            rss_version   => $version,
            test_probe    => \%test_probe,
            debug         => $debug_mode,
        );
        my $ok = 1;
        try {
            WebFetch::Input::RSS->run( \%Options );
        } catch {
            $results{$version} = "$_";
            $ok = 0;
            WebFetch::debug "RSS $version run -> exception: $_";
        };
        if ($ok) {
            $results{$version} = [ WebFetch::Output::Capture::data_records() ];
            WebFetch::debug "RSS $version run -> " . Dumper( \%test_probe );
        }
    }

    # output YAML
    my $yaml_path = $input_dir . "/" . basename( $rss_file, ".xml" ) . "-expected.yml";
    YAML::XS::DumpFile( $yaml_path, \%results );
    return;
}

# initialize debug mode setting and temporary directory for WebFetch
# In debug mode the temp directory is not cleaned up (deleted) so that its contents can be examined.
# For later manual cleanup, the temp dirs are easy to find named WebFetch-... in the system's temp dir location.
WebFetch::debug_mode($debug_mode);
my $temp_dir = File::Temp->newdir(
    TEMPLATE => $tmpdir_template,
    CLEANUP  => ( $debug_mode ? 0 : 1 ),
    TMPDIR   => 1
);

# find .xml files in input directory
opendir( my $input_dh, $input_dir )
    or croak "Can't open $input_dir: $!";
my @xmls = grep { /\.xml$/ and -f $input_dir . "/" . $_ } readdir $input_dh;
closedir $input_dh;

# process each file
foreach my $xml_file ( sort @xmls ) {
    print $xml_file. "\n";
    rss2yaml( $input_dir, $xml_file, $temp_dir );
}

