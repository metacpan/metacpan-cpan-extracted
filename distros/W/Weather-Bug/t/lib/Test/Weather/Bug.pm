package Test::Weather::Bug;

use warnings;
use strict;
use FindBin;
use File::Spec;
use Moose;

extends 'Weather::Bug';

our $suffix = '';
#
# All of the data files are stored in the data subdirectory under
# the directory I'm in.
my $datadir = File::Spec->catdir( $FindBin::Bin, 'data' );

sub set_suffix
{
    $suffix = shift;
}

#
# Fake a LWP request by extracting the filename from the request URL
# and use it to construct the name of the data file to read.
# Return the contents of that file.
override '_get' => sub {
    my $self = shift;
    my $url = shift;
    return unless $url =~ m[\.net/(\w+)\.aspx\?acode];
    my $cmd = $1;

    my $datafile = File::Spec->catfile( $datadir, "$cmd$suffix.xml" );
    return unless open( my $fh, '<', $datafile );
    local $/ = undef;
    return <$fh>;
};

1;
