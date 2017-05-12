#!perl -T

use warnings;
use strict;

use Test::More;

use XML::Quick;
use Data::Dumper;

plan tests => 3;

sub _dump {
    my ($hash) = @_;
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Indent = 1;
    return Dumper $hash;
}

{
    my $hash = {
        root => {
            _attrs => { attr => 'value' },
        },
    };
    my $hash_orig = _dump($hash);
    xml($hash);
    is(_dump($hash), $hash_orig, "passed data hash retains attrs");
}

{
    my $hash = {
        root => {
            _cdata => '_cdata text',
            cdata  => 'cdata tag',
            tag    => 'text',
        },
    };
    my $hash_orig = _dump($hash);
    xml($hash);
    is(_dump($hash), $hash_orig, "passed data hash retains cdata");
}

{
    my $hash = {
        root => {
            _attrs => { attr=>'value' },
        },
    };
    my $opts = {};
    my $opts_orig = _dump($opts);
    xml($hash, $opts);
    is(_dump($opts), $opts_orig, "passed opts hash not modified");
}
