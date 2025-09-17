use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'XS::Log',
    VERSION_FROM => 'lib/XS/Log.pm',
	XS           => {'Log.xs' => 'Log.c' },
    LIBS         => ['-L/usr/local/lib'],    # 需要额外库可加 -lsyslog 等
    INC          => '-I.',   # 包含 Log.h 的路径
	OBJECT       => '$(O_FILES)',
	test 			=> {"TESTS" => "t/*.t"},
	clean        	=> { FILES => ['Log.c',"Makefile.old"] },
);