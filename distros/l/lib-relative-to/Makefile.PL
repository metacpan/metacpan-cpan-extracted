use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    NAME         => 'lib::relative::to',
    META_MERGE => {
        license => ["artistic_1", "gpl_2"],
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-lib-relative-to',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-lib-relative-to/issues'
        }
    },
    VERSION_FROM => 'lib/lib/relative/to.pm',
    PREREQ_PM    => {
        'Test::Exception' => 0,
        'Test::More' =>      0.88, # done_testing
    },
    test => {
        TESTS => join(' ', find_tests('t'))
    }
);

sub find_tests {
    my $dir = shift;
    opendir(DIR, $dir);
    my @dirs = grep { $_ !~ /^\.{1,2}$/ && -d "$dir/$_" } readdir(DIR);
    closedir(DIR);
    return (glob("$dir/*.t"), map { find_tests("$dir/$_") } @dirs);
}
