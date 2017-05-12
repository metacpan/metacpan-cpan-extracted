use ExtUtils::MakeMaker;

use 5.006;  # this module requires Perl 5.6.0
WriteMakefile(
    NAME          => 'Text::ProcessMap',
    VERSION_FROM  => 'lib/Text/ProcessMap.pm',  # finds $VERSION
    ABSTRACT_FROM => 'lib/Text/ProcessMap.pm',  # retrieve abstract from module
    AUTHOR        => 'Brad Adkins <bradjadkins@badkins.net>',
    PREREQ_PM     => { 'Carp'         => 0,
                       'File::Spec'   => 0
                     }
);

package MY; # so that "SUPER" works right
sub test {
    my $inherited = shift->SUPER::test(@_);
    $inherited =~ s/TEST_VERBOSE=0/TEST_VERBOSE=1/;;
    $inherited;
}
