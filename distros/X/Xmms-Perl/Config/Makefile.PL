use 5.005;
use ExtUtils::MakeMaker;
use lib qw(./lib ../lib);
use Xmms::ExtUtils ();

$inc = Xmms::ExtUtils::inc();
$libs = Xmms::ExtUtils::libs();

WriteMakefile(
    'NAME'	=> 'Xmms::Config',
    'VERSION_FROM' => 'Config.pm',
    'LIBS'	=> [$libs],
    'INC'	=> $inc,
);
