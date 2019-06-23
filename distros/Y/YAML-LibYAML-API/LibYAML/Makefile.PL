use strict;
use warnings;
use 5.008000;
use ExtUtils::MakeMaker;
use Config;
use Data::Dumper;


my %args = (
    NAME           => 'YAML::LibYAML::API::XS',
    VERSION_FROM   => 'lib/YAML/LibYAML/API/XS.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Exporter' => '5.57' },
    ABSTRACT_FROM  => 'lib/YAML/LibYAML/API/XS.pm',
    AUTHOR         => 'You',
);

if ($ENV{WITH_SYSTEM_LIBYAML}) {
    # For this to work, you need to remove the libyaml files first

    WriteMakefile(
        %args,
        LIBS           => ['-lyaml'],
        DEFINE         => '',
        INC            => '-I.',
        OBJECT         => '$(O_FILES)',
    );

}
else {

    my $DEFINE = $^O eq 'MSWin32'
    ? '-DHAVE_CONFIG_H -DYAML_DECLARE_EXPORT'
    : '-DHAVE_CONFIG_H';

    my $obj_files = join ' ', map {
        my $c = $_;
        $c =~ s/\.c$/$Config::Config{_o}/;
        $c;
    } glob("*.c"), 'XS.c';

    WriteMakefile(
        %args,
        LIBS           => [''],
        DEFINE         => $DEFINE,
        INC            => '-I.',
        OBJECT         => $obj_files,
    );

}
