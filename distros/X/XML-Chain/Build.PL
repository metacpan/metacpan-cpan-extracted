use strict;
use warnings;
use Module::Build;

my $mb_subclass = Module::Build->subclass(
    class => 'XML::Chain::MB_Builder',
    code  => q{
        use Path::Class qw(file);
        use Pod::Simple::Text;

        sub create_readme {
            my @readmes;
            my @lib_files = qw(
                lib/XML/Chain.pm
                lib/XML/Chain/Selector.pm
                lib/XML/Chain/Element.pm
            );
            foreach my $file (@lib_files) {
                my $pst = Pod::Simple::Text->new;
                my $readme = '';
                $pst->output_string(\$readme);
                $pst->parse_file($file);
                push(@readmes, $readme);
            }
            file('README')->spew(join("\n".('-'x76)."\n", @readmes));

            return;
        }
    },
);

my $builder = $mb_subclass->new(
    module_name       => 'XML-Chain',
    license           => 'perl',
    dist_author       => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from => 'lib/XML/Chain.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    build_requires => {
        'Test::Most'        => 0,
        'File::Temp'        => 0,
        'Path::Class'       => 0,
        'Pod::Simple::Text' => 0,
        'DateTime'          => 0,
    },
    requires => {
        'perl'            => 5.010,
        'XML::LibXML'     => 2.0100,   # Added the unique_key() method to XML::LibXML::Node
        'IO::Any'         => 0,
        'Moose'           => 0,
        'MooseX::Aliases' => 0,
        'Moose::Exporter' => 0,
        'Try::Tiny'       => 0,
    },
    script_files => [qw()],
    add_to_cleanup => ['XML-Chain-*'],
    create_readme  => 1,
    meta_merge => {
        resources => {
            repository => 'https://github.com/meon/XML-Chain.git',
            bugtracker => 'https://github.com/meon/XML-Chain/issues',
        },
        keywords => [ qw/ XML chain build manipulation traversal LibXML / ],
    },
);

$builder->create_build_script();
