use Test::More;

eval 'use Test::Spelling;';

plan skip_all => "Test::Spelling required for testing POD spelling"
    if $@;

add_stopwords(qw(
        Jozef Kutej
        OFC
        API
        JSON
        TBD
        TODO
        html
        RT
        CPAN
        AnnoCPAN
        http
        GitHub
        GLOBs
        Pavlovic
        chainable
        toString
        xc
        jQuery
        xpath
        )
);
all_pod_files_spelling_ok();
