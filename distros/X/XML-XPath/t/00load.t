#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 22;
use lib 'lib';
use Path::Tiny;

my $dir  = path('lib/');
my $iter = $dir->iterator({
    recurse         => 1,
    follow_symlinks => 0,
});

while (my $path = $iter->()) {
    next if $path->is_dir || $path !~ /\.pm$/;
    my $module = $path->relative;
    $module =~ s/(?:^lib\/|\.pm$)//g;
    $module =~ s/\//::/g;
    BAIL_OUT( "$module does not compile" ) unless require_ok($module);
}

diag( "Testing XML::XPath $XML::XPath::VERSION, Perl $], $^X" );

done_testing;
