use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'NAME' => 'Web::XDO',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'Web::XDO -- static web site tool',
               'PL_FILES' => {},
               'EXE_FILES' => [],
               'VERSION_FROM' => 'lib/Web/XDO.pm',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {
                                'String::Util' => 0,
                                'HTML::Parser' => 0,
                                'URI::URL' => 0
                              }
             };


WriteMakefile(%$make_args);
