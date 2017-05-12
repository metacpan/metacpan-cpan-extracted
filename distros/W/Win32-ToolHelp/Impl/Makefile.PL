use ExtUtils::MakeMaker;

use Config;

$Verbose = 1;

WriteMakefile(
	NAME	=> 'Win32::ToolHelp::Impl',
	SKIP	=> [qw(all static static_lib dynamic dynamic_lib)],
	clean	=> {'FILES' => 'Impl$(LIBEEXT)'},
);

sub MY::top_targets {

# when using MinGW (gcc) to build, it uses the 'ar'
# command instead of 'lib' and then the option
# style needs to change
#
$opt = $Config{ar} =~ /ar\.exe$/ ? '-ru ' : '/out:';

"
all :: static
pure_all :: static
static :: Impl\$(LIB_EXT)
Impl\$(LIB_EXT): \$(O_FILES)
	\$(AR) ${opt}Impl\$(LIB_EXT) \$(O_FILES)
";
}
