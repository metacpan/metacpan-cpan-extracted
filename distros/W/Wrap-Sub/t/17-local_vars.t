#!/usr/bin/perl
use strict;
use warnings;

use Data::Dump;
use Data::Dumper;
use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Wrap::Sub');
    use_ok('Three');
};

{
    my $post = sub { return $Wrap::Sub::name; };

    my $wrap = Wrap::Sub->new(post => $post, post_return => 1);
    my $subs = $wrap->wrap('Three');

    while (my $subname = <DATA>){
        no strict 'refs';
        chomp $subname;
        my $ret = &$subname();

        is ($ret, $subname, "\$Wrap::Sub::name for $subname works");
    }
}

done_testing();

__DATA__
Three::one
Three::two
Three::three
Three::four
Three::five
