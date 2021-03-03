package main;

use 5.010;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();
use Test::Prereq::Meta;

my $tpm = Test::Prereq::Meta->new();

$tpm->file_prereq_ok( 'lib/Test/Prereq/Meta.pm' );

$tpm->file_prereq_ok( 't/basic.t' );

$tpm->file_prereq_ok( 't/data/hello_world.PL' );

{
    my $rslt = 1;
    TODO: {
	local $TODO = 'Intentional failure';
	$rslt = $tpm->file_prereq_ok( 't/data/non-existent.PL' );
    }

    ok( ! $rslt, 'Non-existent file generated a failure.' );
}

$tpm = Test::Prereq::Meta->new(
    perl_version	=> $],	# So we accept ExtUtils::MakeMaker
);
$tpm->file_prereq_ok( 'Makefile.PL' );

done_testing();

1;

# ex: set textwidth=72 :
