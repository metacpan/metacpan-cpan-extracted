use 5.010001;
use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %mk;
unless ($^O =~ /Win/i && $^O !~ /darwin/i) {
	system("sh ./build_detect_platform");
	open(MK,"build_config.mk") or die;
	map { $mk{$1} = $2 if(/^(.+?)\=(.*)$/) } <MK>;
	close(MK);
}

# fix: why MM_Unix->init_dirscan() haven't found these O_FILES?
my $OBJECT = "LevelDB.obj db/builder.obj db/db_impl.obj db/db_iter.obj db/filename.obj db/dbformat.obj db/log_reader.obj db/log_writer.obj db/memtable.obj db/repair.obj db/table_cache.obj db/version_edit.obj db/version_set.obj db/write_batch.obj table/block.obj table/block_builder.obj table/format.obj table/iterator.obj table/merger.obj table/table.obj table/table_builder.obj table/two_level_iterator.obj util/arena.obj util/cache.obj util/coding.obj util/comparator.obj util/crc32c.obj util/env.obj util/hash.obj util/histogram.obj util/logging.obj util/options.obj util/status.obj";


if ($^O =~ /Win/i && $^O !~ /darwin/i) {
	*MY::dynamic_lib = sub {
		package MY;
		my $lib_rules = shift->SUPER::dynamic_lib(@_);
		
		# Add deploy functionality for the extra dlls.
		$lib_rules .= <<END;
\t\$(NOECHO) \$(MOD_INSTALL) deploy blib
END

		$lib_rules;
	};
	
	$OBJECT .= " port/port_win.obj util/env_boost.obj util/win_logger.obj";
	
	WriteMakefile(
		NAME              	=> 'Tie::LevelDB',
		VERSION_FROM      	=> 'lib/Tie/LevelDB.pm', # finds $VERSION
		PREREQ_PM         	=> {}, # e.g., Module::Name => 1.1
		($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		  (ABSTRACT_FROM  	=> 'lib/Tie/LevelDB.pm', # retrieve abstract from module
		   AUTHOR         	=> 'martin <martin@>') : ()),
		LIBS              	=> [''],
		DEFINE            	=> ("-D_WINDOWS -D_USRDLL -DLEVELDB_EXPORTS -DLEVELDB_PLATFORM_WINDOWS -DOS_WIN -D_CRT_SECURE_NO_WARNINGS " . '-Fo$@'),
		INC               	=> '-I. -Iinclude -Iport -Iutil -Iboost_1_47',
		OBJECT            	=> $OBJECT,
		CC				    => 'cl',
		CCFLAGS				=> $Config{ccflags} . ' -TP -EHsc',
		LDDLFLAGS			=> $Config{lddlflags} . ' -libpath:"boost_1_47\lib" boost_filesystem-vc100-mt-1_47.lib boost_date_time-vc100-mt-1_47.lib boost_thread-vc100-mt-1_47.lib boost_system-vc100-mt-1_47.lib msvcprt.lib',
		XSOPT       	    => '-C++',
		TYPEMAPS	        => ['perlobject.map'],
	);
} else {
	$OBJECT .= " port/port_posix.obj util/env_posix.obj";
	WriteMakefile(
		NAME              => 'Tie::LevelDB',
		VERSION_FROM      => 'lib/Tie/LevelDB.pm', # finds $VERSION
		PREREQ_PM         => {}, # e.g., Module::Name => 1.1
		($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		  (ABSTRACT_FROM  => 'lib/Tie/LevelDB.pm', # retrieve abstract from module
		   AUTHOR         => 'martin <martin@>') : ()),
		LIBS              => [$mk{SNAPPY} ? '-lsnappy':''],
		DEFINE            => ($mk{SNAPPY} ? '-DSNAPPY':'').
								" ".$mk{PLATFORM_CFLAGS}." ".$mk{PORT_CFLAGS}
								.' -o $@',
		INC               => '-I. -Iinclude -Iport -Iutil',
		#OBJECT            => '$(O_FILES)', # link all the C files too
		OBJECT            => $OBJECT,

		'CC'			    => 'g++ '.$mk{PLATFORM_CFLAGS}." ".$mk{PORT_CFLAGS},
		'LD'			    => 'g++ '.$mk{PLATFORM_LDFLAGS},
		'XSOPT'             => '-C++',
		'TYPEMAPS'          => ['perlobject.map' ],
	);
}
