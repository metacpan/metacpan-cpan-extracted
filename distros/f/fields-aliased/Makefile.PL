use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'fields::aliased',
    VERSION_FROM      => 'lib/fields/aliased.pm',
    PREREQ_PM         => {
        'Test::More'            =>  0,
        'Tie::IxHash'           =>  0,
        'Filter::Util::Call'    =>  0,
    },
    ABSTRACT_FROM     => 'lib/fields/aliased.pm',
    AUTHOR            => 'Kevin Michael Vail <kvail@cpan.org>',
    LIBS              => [''],
    DEFINE            => '',
    # Insert -I. if you add *.h files later:
    INC               => '',
    # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)',
);
