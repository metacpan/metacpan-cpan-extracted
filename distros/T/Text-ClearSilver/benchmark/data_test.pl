use strict;
use warnings;
use ClearSilver;
use Data::ClearSilver::HDF;
use IPC::Cmd;

local $Data::Dumper::Terse = 1;
local $Data::Dumper::Deepcopy = 1;

my $loadpath = 'benchmark/template';
my $template = 'index.cs';
my $hdf_file = 'var.hdf';

my $var = do 'benchmark/data/var.pl';
my $hdf = Data::ClearSilver::HDF->hdf($var);
$hdf->setValue('hdf.loadpaths.0', $loadpath);
$hdf->writeFile($hdf_file);
my $cs = ClearSilver::CS->new($hdf);

if (!$cs->parseFile($template) && 0) {
    my $buffer = '';
    my $file = qq{$loadpath/$template};
    my @run = (
        command => [ 'cstest', '-v', $hdf_file, $file ],
        buffer  => \$buffer,
        timeout => 1,
    );
    IPC::Cmd::run( @run );
    die $buffer;
}
print $cs->render;

