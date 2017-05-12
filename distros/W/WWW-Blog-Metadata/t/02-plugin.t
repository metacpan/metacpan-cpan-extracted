use strict;
use Test::More tests => 8;
use WWW::Blog::Metadata;
use File::Spec::Functions;

use constant SAMPLES => catdir 't', 'samples';

my($meta);

## On the first attempt, we have not loaded the plugin, so the
## rsd_uri should not be available.
$meta = WWW::Blog::Metadata->extract_from_uri('http://btrott.typepad.com/');
ok($meta);
ok(!$meta->can('rsd_uri'));
ok(!$meta->can('is_typepad'));
ok(!$meta->can('finished'));

## Set up the @INC so that the plugin can be found...
require lib;
lib->import(catdir 't', 'lib');

## Now we have loaded the plugin, so the rsd_uri will be set after
## calling extract_metadata.
$meta = WWW::Blog::Metadata->extract_from_uri('http://btrott.typepad.com/');
ok($meta);
like $meta->rsd_uri, qr/www\.typepad\.com/, 'rsd_uri is extracted';
is($meta->is_typepad, 1);
is($meta->finished, 1);
