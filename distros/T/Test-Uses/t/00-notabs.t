use strict;
use warnings;

use Test::More;
BEGIN {
    plan skip_all => 'Author test.  Set environment variable TEST_AUTHOR to a true value to run.'
        unless $ENV{TEST_AUTHOR};
}

use Test::NoTabs;
use File::Spec;
use File::Find;
use FindBin ();

find(
    {   no_chdir => 1,
        wanted   => sub {
            return if (-d $File::Find::name);
        	my $value = File::Spec->abs2rel($File::Find::name, File::Spec->curdir());
        	$value =~ s{\\}{/}g;
            return unless ($value =~ /\.p[lm]?$/i);
            notabs_ok( $value, "No tabs in $value");
        }
    },
    'lib'
);

done_testing();

1;