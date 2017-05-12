use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'eGuideDog::Dict::Cantonese',
    'VERSION_FROM'	=> 'Cantonese.pm', # finds $VERSION
    'PL_FILES'      => {'update_dict.pl' => 'no_arguments'},
    'PREREQ_PM'		=> {Encode::CNMap => 0,
        Storable => 0,
        utf8 => 0,
    }, # e.g., Module::Name => 1.1
    'PM'                => {'Cantonese.pm' => '$(INST_LIBDIR)/Cantonese.pm',
        'Cantonese.dict' => '$(INST_LIBDIR)/Cantonese/Cantonese.dict',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM => 'Cantonese.pm', # retrieve abstract from module
            AUTHOR     => 'Cameron Wong <hgn823-perl@yahoo.com.cn>') : ()),
);
