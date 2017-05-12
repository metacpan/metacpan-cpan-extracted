use ExtUtils::MakeMaker;

push(@extras,
    AUTHOR        => 'Mike Wong <mike_w3@pacbell.net>'
    ) if ($ExtUtils::MakeMaker::Version >= 5.4301);
WriteMakefile(
    NAME	=> 'XML::Dumper',
    VERSION_FROM => 'Dumper.pm',
    PREREQ_PM => { XML::Parser => '2.16' } 
);
