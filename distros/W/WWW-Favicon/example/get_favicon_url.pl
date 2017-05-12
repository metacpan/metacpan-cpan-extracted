#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use Pod::Usage;

use lib File::Spec->catfile( $FindBin::Bin, qw/.. lib/ );

use WWW::Favicon qw/detect_favicon_url/;

my $url = $ARGV[0] or pod2usage(1);
print detect_favicon_url($url), "\n";

__END__

=head1 NAME

get_favicon_url.pl - get favicon url of specified url

=head1 SYNOPSIS

get_favicon_url.pl [url]

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut
