use warnings;
use strict;
use Test::More;
use Path::Class;
use FindBin;

use_ok ("Web::Mention");

my $source_path = "$FindBin::Bin/sources/rsvp.html";

my $source_url = "file://$source_path";

my $html = Path::Class::File->new( $source_path )->slurp;

my @wms = Web::Mention->new_from_html(
    source => $source_url,
    html => $html,
);

is ( scalar @wms, 1, 'Got just one webmention.' );
is ( $wms[0]->type, 'rsvp', 'It is an RSVP.' );
is ( $wms[0]->rsvp_type, 'interested', 'It has the expected RSVP value.' );

done_testing();
