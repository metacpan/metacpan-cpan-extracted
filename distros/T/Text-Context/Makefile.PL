use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Text::Context',
    'VERSION_FROM'	=> 'lib/Text/Context.pm', 
    'PREREQ_PM'		=> {
        'Text::Context::EitherSide' => 1.1,
        'UNIVERSAL::require'        => 0.03,
        'HTML::Entities'            => 0,
    },
);
