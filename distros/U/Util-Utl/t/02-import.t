#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use Util::Utl;

is( utl, 'Util::Utl' );

diag 'List::Util';
ok( utl->can( $_ ), "Util::Util::$_" ) for @List::Util::EXPORT_OK;
diag 'List::MoreUtils';
ok( utl->can( $_ ), "Util::Util::$_" ) for @List::MoreUtils::EXPORT_OK;
diag 'Scalar::Util';
ok( utl->can( $_ ), "Util::Util::$_" ) for @Scalar::Util::EXPORT_OK;
diag 'String::Util';
ok( utl->can( $_ ), "Util::Util::$_" ) for @String::Util::EXPORT_OK;

done_testing;

1;
