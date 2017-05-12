use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'VS::Chart',
    VERSION_FROM      => 'lib/VS/Chart.pm',
    PREREQ_PM         => {
        Date::Simple        => "0",
        Cairo               => "1.040",
        List::MoreUtils     => "0",
        Test::Exception     => "0",
        Scalar::Util        => "0",
        List::Util          => "0",
        Module::Pluggable   => "0",
    },
    LICENSE         => 'mit',
    ABSTRACT_FROM   => 'lib/VS/Chart.pm',
    AUTHOR          => 'Claes Jakobsson <claes@versed.se>',
);
