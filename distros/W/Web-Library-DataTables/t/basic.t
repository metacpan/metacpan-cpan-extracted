#!/usr/bin/env perl
use strict;
use warnings;
use Web::Library::Test qw(:all);
use Test::More;
library_ok(
    name              => 'DataTables',
    version           => '1.9.4',
    css_assets        => ['/css/datatables.css'],
    javascript_assets => ['/js/jquery.dataTables.min.js']
);
done_testing;
