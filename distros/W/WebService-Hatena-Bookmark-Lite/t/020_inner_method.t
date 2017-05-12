#!/usr/bin/perl 

use strict;
use warnings;
    
use Test::More tests=>15;

use WebService::Hatena::Bookmark::Lite;

my $URL = 'http://www.example.com';
my $HatenaURI = q{http://b.hatena.ne.jp/};

my $package = 'WebService::Hatena::Bookmark::Lite';


#  new
{
    my $bookmark = WebService::Hatena::Bookmark::Lite->new(
        username => 'samplename',
        password => 'samplepass'
    );

    my $client = $bookmark->client();
    isa_ok( $client , 'XML::Atom::Client' , 'XML::Atom::Client object OK');

    is( $client->username() , 'samplename' , 'XML::Atom::Client username OK');
    is( $client->password() , 'samplepass' , 'XML::Atom::Client password OK');
}


# _set_edit_uri
{
    is( $package->_set_edit_uri() , undef  , 'empty edit_ep _set_edit_uri OK');
    is( $package->_set_edit_uri('atom/edit/123') ,  $HatenaURI.'atom/edit/123' , 'normal _set_edit_uri OK');
}

#  _make_link_element
{
    my $link = $package->_make_link_element( $URL );
    isa_ok( $link , 'XML::Atom::Link' , 'XML::Atom::Link object OK');

    is( $link->rel() , 'related' , 'link_rel OK');
    is( $link->type() , 'text/html' , 'link type OK');
    is( $link->href() , $URL , 'link_href OK');
}

# _make_tag
{
    is( $package->_make_tag() ,  '' , 'empty _make_tag OK');
    is( $package->_make_tag(['aaa']) ,  '[aaa]' , '1 ary _make_tag OK');
    is( $package->_make_tag(['bbb','ccc']) ,  '[bbb][ccc]' , 'multi ary _make_tag OK');
}

# _make_summary
{
    is( $package->_make_summary()                      , ''                , 'empty _make_summary OK');
    is( $package->_make_summary(['aaa'],'test')        , '[aaa]test'       , '1 ary _make_summary OK');
    is( $package->_make_summary(['bbb','ccc'],'test2') , '[bbb][ccc]test2' , 'multi ary _make_summary OK');
}
