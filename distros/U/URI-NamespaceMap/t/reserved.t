use strict;
use warnings;
use Test::More;
use URI::NamespaceMap::ReservedLocalParts;

subtest 'allowed/disallowed namespaces by default' => sub {
    my $r = URI::NamespaceMap::ReservedLocalParts->new();

    for my $ns (qw/can DOES isa VERSION/) {
        is $r->is_reserved($ns) => 1, "namespace $ns is reserved";
    }

    for my $ns (qw/allowed disallowed is_reserved uri/) {
        is $r->is_reserved($ns) => 0, "namespace $ns is *not* reserved";
    }
};

subtest 'extending disallowed namespaces' => sub {
    my $r = URI::NamespaceMap::ReservedLocalParts->new(disallowed => [qw/uri/]);
    is $r->is_reserved('uri') => 1, 'namespace uri is reserved';
};

done_testing;
