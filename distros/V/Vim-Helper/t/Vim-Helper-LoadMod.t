#!/usr/bin/env perl
package Test::Vim::Helper::LoadMod;
use strict;
use warnings;

use Fennec;

our $CLASS = 'Vim::Helper::LoadMod';
require_ok $CLASS;

describe vimrc => sub {
    require_ok 'Vim::Helper';
    my $helper = Vim::Helper->new;
    $helper->_load_plugin( 'LoadMod', __PACKAGE__ );

    around_each localize => sub {
        my $self = shift;
        my ( $inner ) = @_;
        local $0 = 'foo';
        $inner->();
    };

    tests none_yet => sub {};
};

1;

