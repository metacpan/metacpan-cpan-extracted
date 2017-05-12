#!/usr/bin/env perl
package Test::Vim::Helper::Fennec;
use strict;
use warnings;

use Fennec;

our $CLASS = 'Vim::Helper::Fennec';
require_ok $CLASS;

describe vimrc => sub {
    require_ok 'Vim::Helper';
    my $helper = Vim::Helper->new;
    $helper->_load_plugin( 'Fennec', __PACKAGE__ );

    tests defaults => sub {
        my $plugin = $helper->plugin( 'Fennec' );
        my $vimrc = $plugin->vimrc( $helper, {} );
        like( $vimrc, qr/^:map <F8> :w/m );
        like( $vimrc, qr/^:map <F12> :w/m );
        like( $vimrc, qr/^:imap <F8> <ESC>:w/m );
        like( $vimrc, qr/^:imap <F12> <ESC>:w/m );
    };

    tests configured => sub {
        my $plugin = $helper->plugin( 'Fennec' );
        $plugin->run_key(  'xxx' );
        $plugin->less_key( 'yyy' );
        my $vimrc = $plugin->vimrc( $helper, {} );
        like( $vimrc, qr/^:map xxx :w/m );
        like( $vimrc, qr/^:map yyy :w/m );
        like( $vimrc, qr/^:imap xxx <ESC>:w/m );
        like( $vimrc, qr/^:imap yyy <ESC>:w/m );
    };
};

1;

