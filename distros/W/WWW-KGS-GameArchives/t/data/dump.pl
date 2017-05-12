use strict;
use warnings;
use Data::Dumper;
use WWW::KGS::GameArchives;

my $html = do { local $/; <> };
my $archives = WWW::KGS::GameArchives->new;
my $result = $archives->scrape( \$html, $archives->base_uri );

local $Data::Dumper::Terse = 1;
local $Data::Dumper::Indent = 1;

print Dumper( $result );
