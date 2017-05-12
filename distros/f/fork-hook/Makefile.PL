use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'fork::hook',
    VERSION_FROM      => 'lib/fork/hook.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/fork/hook.pm', # retrieve abstract from module
    AUTHOR            => 'Evgeniy Vansevich <hammer@cpan.org>',
    LICENSE           => 'MIT',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => {version => 2},
        no_index       => {directory => ['t']},
        prereqs        => {runtime => {requires => {perl => '5.010001'}}},
        resources      => {
            bugtracker    => {web => 'https://github.com/kadavr/p5-fork-hook/issues'},
            license       => ['https://opensource.org/licenses/MIT'],
            repository    => {
                type => 'git',
                url  => 'https://github.com/kadavr/p5-fork-hook.git',
                web  => 'https://github.com/kadavr/p5-fork-hook',
            },
        },
    },

    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
