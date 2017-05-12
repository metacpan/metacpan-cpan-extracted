use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
        code => <<'SUBCLASS' );

sub ACTION_install_short {
        my $self = shift;
        use File::Spec;

        $self->depends_on("build");
        use File::Copy qw(copy);
        copy(
              File::Spec->catfile(qw(blib lib ToolSet y.pm)),
              File::Spec->catfile(qw(blib lib y.pm))
        );
        chmod (
               (stat File::Spec->catfile(qw(blib lib y.pm)))[2] | 0200,
               File::Spec->catfile(qw(blib lib y.pm))
        );
        { 
            local @ARGV=(File::Spec->catfile(qw(blib lib y.pm)));
            $^I=".bak";
            while(<>){
                s{ToolSet::y}{y}gxms;
                print;
            }
            unlink File::Spec->catfile(qw(blib lib y.pm.bak));
        }
        $self->SUPER::ACTION_install();
}
SUBCLASS

my $builder = $class->new(
    module_name         => 'ToolSet::y',
    license             => 'perl',
    dist_author         => 'codeacrobat <joerg {AT} joergmeltzer.de>',
    dist_version_from   => 'lib/ToolSet/y.pm',
    dist_abstract       => '-My one-liner ToolSet',
    build_requires => {
        'ToolSet' => 1.0,
        'Class::Autouse' => 1.29,
        'Test::More' => 0,
    },
    recommends => {
        'Package::Alias' => 0.04,
        'Data::Dump' => 1.14,
        'File::ReadBackwards' => 0,
        'Statistics::Descriptive' => 2.6,
        'List::MoreUtils' => 0,
        'List::Pairwise' => 0,
        'File::Find::Rule' => 0,
    },
    add_to_cleanup      => [ 'ToolSet-y-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
