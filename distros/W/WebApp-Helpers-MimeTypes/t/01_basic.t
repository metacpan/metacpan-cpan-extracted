#!/usr/bin/env perl

use strict;
use warnings;


package MyTunes::Resource::CD;

use Moo;
with 'WebApp::Helpers::MimeTypes';

has title => (is => 'ro');


package main;

$INC{'MyTunes::Resource::CD.pm'} = __FILE__;



use Test::More;

{
    my $cd = MyTunes::Resource::CD->new({title => 'Crabotage',});

    is $cd->mime_type_for('xlsx'),
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'mime_type_for(xlsx) returns correct mime-type';
}


done_testing();
