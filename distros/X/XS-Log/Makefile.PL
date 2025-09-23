use ExtUtils::MakeMaker;
#Build  MD5 : BAgP7Fl10nxch0SUVKa3KA
#Build Time : 2025-09-23 09:18:54

WriteMakefile(
    NAME         => 'XS::Log',
    VERSION_FROM => 'lib/XS/Log.pm',
	XS           => {'Log.xs' => 'Log.c' },
    LIBS         => ['-L/usr/local/lib'],    # 需要额外库可加 -lsyslog 等
    INC          => '-I.',   # 包含 Log.h 的路径
	OBJECT       => '$(O_FILES)',
	test 			=> {"TESTS" => "t/*.t"},
	clean        	=> { FILES => ['Log.c',"Makefile.old","MANIFEST.bak","MANIFEST"] },
);
