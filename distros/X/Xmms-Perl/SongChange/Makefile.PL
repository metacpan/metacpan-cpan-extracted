use 5.005;
use ExtUtils::MakeMaker;
use lib qw(./lib ../lib);
use Xmms::ExtUtils ();

$inc = Xmms::ExtUtils::inc();
$libs = Xmms::ExtUtils::libs();

WriteMakefile(
    'NAME'	=> 'Xmms::SongChange',
    'VERSION_FROM' => 'SongChange.pm',
    'LIBS'	=> ["-lpthread $libs"],
    'INC'	=> $inc,
);
