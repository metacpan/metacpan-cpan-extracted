#!perl

use utf8;
use strict;
use warnings;
use Devel::PPPort;
use FindBin qw($Bin);
use File::Spec;
use File::Temp;
use Test::More;

my $tmpdir = File::Temp->newdir;
my $ppport = File::Spec->catfile( $tmpdir->dirname, 'ppport.h' );
my $xs     = File::Spec->catfile( $Bin, qw/.. lib Text Sass XS.xs/ );

Devel::PPPort::WriteFile($ppport);

my $output = `$^X $ppport --cplusplus $xs`;

like $output, 'Looks good' or warn $output;
done_testing;
