use warnings; use strict;
use Test::More;
use Test::LWP::UserAgent;
use Test::Warn;
use FindBin;
use JSON;

use_ok ("Web::Mention");
my $source = 'file://' . "$FindBin::Bin/sources/content_property.html";
my $target = "http://example.com/webmention-target";

my $wm = Web::Mention->new(
    source => $source,
    target => $target,
);
ok (not($wm->is_tested), "Webmention marked as untested.");
ok ($wm->is_verified, "Webmention got verified.");
ok ($wm->is_tested, "Webmention marked as tested.");

my $json = JSON->new->convert_blessed;

my $serialized_wm = $json->encode($wm);

my $unserialized_wm = Web::Mention->FROM_JSON( $json->decode($serialized_wm) );

is ($unserialized_wm->source, $source,
    'Unserialized webmention remembers its source.',
);

ok ($unserialized_wm->is_tested,
    'Unserialized webmention remembers its is_tested status.',
);

done_testing();
