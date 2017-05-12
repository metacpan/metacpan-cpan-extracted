#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use Pod::Usage;

use lib File::Spec->catfile( $FindBin::Bin, qw/.. lib/ );

use WWW::Favicon qw/detect_favicon_url/;
use URI::Fetch;

my ($url, $outfile) = @ARGV;
pod2usage(1) unless $url and $outfile;

my $res = URI::Fetch->fetch(detect_favicon_url($url))
    or die URI::Fetch->errstr;

open my $fh, ">$outfile";
print $fh $res->content;
close $fh;

print "favicon of $url is saved successfully to $outfile\n";

__END__

=head1 NAME

get_favicon.pl - get favicon and store as file

=head1 SYNOPSIS

get_favicon.pl [url] [savefile]

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
