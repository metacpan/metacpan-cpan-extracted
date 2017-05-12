use strict;
use warnings;
use Test::More;
use LWP::Online ":skip_all";
plan skip_all => "BROKEN";
plan tests => 16;
use LWP::Online ':skip_all';
use WWW::MobileCarrierJP::DoCoMo::Flash;

my $dat = WWW::MobileCarrierJP::DoCoMo::Flash->scrape;
is ref($dat), 'ARRAY';
is $dat->[0]->{version}, '1.0';
is $dat->[1]->{version}, '1.1';
is $dat->[2]->{version}, '3.0';
is $dat->[3]->{version}, '3.1';

is scalar(grep { $_->{model} =~ /^\p{Print}+$/ } @{$dat->[2]->{models}}), scalar(@{$dat->[2]->{models}});

is $dat->[2]->{models}->[0]->{model}, 'SH905I', 'model';
is $dat->[2]->{models}->[0]->{working_memory_capacity}, '3072';
is $dat->[2]->{models}->[0]->{browser}->[0]->{width}, 480;
is $dat->[2]->{models}->[0]->{browser}->[0]->{height}, 640;
is $dat->[2]->{models}->[0]->{browser}->[1]->{width}, 480;
is $dat->[2]->{models}->[0]->{browser}->[1]->{height}, 480;
is $dat->[2]->{models}->[2]->{browser}->[0]->{width}, 480;
is $dat->[2]->{models}->[2]->{browser}->[0]->{height}, 640;
is $dat->[2]->{models}->[2]->{standby_screen}->{width}, 480;
is $dat->[2]->{models}->[2]->{standby_screen}->{height}, 854;

