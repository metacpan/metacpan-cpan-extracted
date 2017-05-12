use File::Path;
use File::Copy;

# get perl executable
@PerlBin = split /\\/, $^X;

pop @PerlBin;
pop @PerlBin;

$PerlBin = join "/", @PerlBin;

# get perl version
$BUILD = 
	($] eq '5.00502' || $] eq '5.00503') ? '5xx' : 
	($] eq '5.006'  || $] eq '5.006001') ? '6xx' : 
	($] eq '5.008') ? '8xx' : 'xxx';

die "Wrong build number ..."
	if $BUILD ne '8xx' && $BUILD ne '6xx' && $BUILD ne '5xx';

# set lib path
$INST_LIBDIR = "$PerlBin/site/lib/";

-d $INST_LIBDIR or die "Cannot find library directory ...\n";

copy('Lanman.pm', $INST_LIBDIR . 'Win32/Lanman.pm');

mkpath($INST_LIBDIR . 'auto/Win32/Lanman');

if($BUILD eq '8xx')
{
	copy('Lanman.8xx.dll', $INST_LIBDIR . 'auto/Win32/Lanman/Lanman.dll');
}
elsif($BUILD eq '6xx')
{
	copy('Lanman.6xx.dll', $INST_LIBDIR . 'auto/Win32/Lanman/Lanman.dll');
}
else
{
	copy('Lanman.5xx.dll', $INST_LIBDIR . 'auto/Win32/Lanman/Lanman.dll');
}
