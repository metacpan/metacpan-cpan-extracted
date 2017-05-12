
use strict;
use warnings;

use lib 'lib', '../lib'; #  XXX

use WWW::Workflowy;

my $wf = WWW::Workflowy->new(
    url => 'https://workflowy.com/shared/b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25/',
    # or else:  guid => 'b141ebc1-4c8d-b31a-e3e8-b9c6c633ca25',
);

print "getting ready to sync in 15...\n";
sleep 15;

$wf->sync;
print $wf->dump;


