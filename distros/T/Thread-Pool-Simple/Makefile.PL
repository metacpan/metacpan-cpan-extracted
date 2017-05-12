use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Thread::Pool::Simple',
    'VERSION_FROM'	=> 'Simple.pm',
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?
      (AUTHOR     => 'Jianyuan Wu <jwu@cpan.org>') : ()),
);
