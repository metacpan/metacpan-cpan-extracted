use strict;
use Test::Base;

use URI;
use URI::tag;

plan tests => 5 * blocks;
filters { input => 'chomp', authority => 'chomp', date => 'chomp', specific => 'chomp' };

run {
    my $block = shift;
    my $uri = URI->new($block->input);
    isa_ok $uri, 'URI::tag';
    is $uri->authority, $block->authority, "authority is " . $block->authority;
    is $uri->date, $block->date, "date is " . $block->date;
    is $uri->specific, $block->specific, "specific is " . $block->specific;

    # build new URI
    $uri = URI->new("tag:");
    $uri->authority($block->authority);
    $uri->date($block->date);
    $uri->specific($block->specific);

    is $uri->as_string, $block->input, $block->input;
}

__END__

===
--- input
tag:timothy@hpl.hp.com,2001:web/externalHome
--- authority
timothy@hpl.hp.com
--- date
2001
--- specific
web/externalHome

===
--- input
tag:sandro@w3.org,2004-05:Sandro
--- authority
sandro@w3.org
--- date
2004-05
--- specific
Sandro

===
--- input
tag:my-ids.com,2001-09-15:TimKindberg:presentations:UBath2004-05-19
--- authority
my-ids.com
--- date
2001-09-15
--- specific
TimKindberg:presentations:UBath2004-05-19

===
--- input
tag:blogger.com,1999:blog-555
--- authority
blogger.com
--- date
1999
--- specific
blog-555

===
--- input
tag:yaml.org,2002:int
--- authority
yaml.org
--- date
2002
--- specific
int
