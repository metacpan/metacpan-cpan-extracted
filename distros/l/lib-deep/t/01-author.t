#!/usr/bin/perl
# vim: ft=perl ts=4 shiftwidth=4 softtabstop=4 expandtab
#===============================================================================
#
#         FILE:  01-author.t
#
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Anatoliy Grishaev (), grian@cpan.org
#      CREATED:  03/31/2014 11:32:21 AM
#  DESCRIPTION:  ---
#
#===============================================================================
use strict;
use warnings;
use Test::More;
use lib 'lib';
require lib::deep;
*mkapath = \&lib::deep::mkapath;
if ( $ENV{TEST_AUTHOR} ){
    plan tests => 16;
    is( mkapath( '/home/webadmin/A.pm', 0, 'lib' ), '/home/webadmin/lib' );
    is( mkapath( '/home/webadmin/A.pm', 0, '' ), '/home/webadmin' );
    is( mkapath( '/home/webadmin/A.pm', 0, ), '/home/webadmin' );


    chdir( '/home/gtoly' );
    is( mkapath( './1.pm',  0, 'lib' ), '/home/gtoly/lib' );
    is( mkapath( '../1.pm', 0, 'lib' ), '/home/lib' );
    is( mkapath( 'lib/./1.pm', 0, 'lib'), '/home/gtoly/lib/lib' );
    
    is( invoke( A=>'/home/gtoly/lib/A.pm', ),  '/home/gtoly/lib');
    is( invoke( "A::B"=>'/home/gtoly/lib/A/B.pm', ),  '/home/gtoly/lib');
    is( invoke( "A::B::C"=>'/home/gtoly/lib/A/B/C.pm', ),  '/home/gtoly/lib');

    is( invoke( main=>'/home/gtoly/lib/A.pm', -1),  '/home/gtoly/lib');
    is( invoke( main=>'/home/gtoly/lib/A/B.pm', -2),  '/home/gtoly/lib');
    is( invoke( main=>'/home/gtoly/lib/A/B/C.pm', -3),  '/home/gtoly/lib');

    is( invoke( main=>'/home/gtoly/bin/a.pl', 0),  '/home/gtoly/bin/lib');
    is( invoke( main=>'/home/gtoly/bin/a.pl', -1),  '/home/gtoly/lib');

    is( invoke( main=>'/home/gtoly/bin/a.pl'),  '/home/gtoly/lib');
    is( invoke( main=>'/home/gtoly/a.pl'),  '/home/gtoly/lib');
}
else {
    plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
}
sub invoke{
    my ( $p, $file, @args ) = @_;
    local @INC;
    my $import = \&lib::deep::import;
    
    my $s = "package $p;\n#line 1 $file\nlib::deep::import(1,\@args)";
    eval $s;
    warn $@ if $@;
    return shift @INC;
}

