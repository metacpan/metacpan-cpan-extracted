use strict;
use warnings;
use Test::More tests => 12;
use WWW::TarPipe;

use constant KEY     => 'b66837fe2e795566d8e284fe6b99a2a5';
use constant BAD_KEY => '99999999999999999999999999999999';

{
    ok my $tp = WWW::TarPipe->new(
        title => 'Title',
        body  => 'Body',
        image => 'Image',
        key   => 'Key'
      ),
      'created';
    isa_ok $tp, 'WWW::TarPipe';
    is $tp->base_uri, 'http://rest.receptor.tarpipe.net:8000/',
      'default URI';
    is $tp->default_base_uri, 'http://rest.receptor.tarpipe.net:8000/',
      'default URI';
    is $tp->title, 'Title', 'title';
    is $tp->body,  'Body',  'body';
    is $tp->image, 'Image', 'image';
    is $tp->key,   'Key',   'key';
}

{
    ok my $tp = WWW::TarPipe->new( key => KEY );
    my $got = $tp->upload(
        title => 'A test',
        body  => 'Just testing',
        image => 'XXXX'
    );
    is $got, 'ok!';    # Not formally part of the spec.
}

{
    ok my $tp = WWW::TarPipe->new( key => BAD_KEY );
    eval { $tp->upload( title => 'Oops' ) };
    ok $@, 'error';
}
