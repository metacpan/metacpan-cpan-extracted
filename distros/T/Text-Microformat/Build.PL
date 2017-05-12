use strict;
use warnings;
use Module::Build;

shift(@ARGV) if $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall

my $builder = Module::Build->new(
    module_name         => 'Text::Microformat',
    license             => 'perl',
    dist_author         => 'Keith Grennan <kgrennan@cpan.org>',
    dist_version_from   => 'lib/Text/Microformat.pm',
    build_requires => {
        'Module::Pluggable' => '3.4',
        'Class::Accessor' => '0.25',
        'NEXT' => '0.60',
        'HTML::TreeBuilder' => '3.21',
        'XML::TreeBuilder' => '3.09',
        'Test::More' => '0.62',
        'Class::Data::Inheritable' => '0.04',
        'UNIVERSAL::require' => '0.10',
        'Data::Dumper' => 0,
    },
    add_to_cleanup      => [ 'Text-Microformat-*' ],
    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();

__END__
# handy lister of installed dependency versions
use Data::Dumper;
my $requires = $builder->build_requires;
for my $mod (keys %$requires) {
    eval "require $mod";
    $requires->{$mod} = eval "\$$mod\::VERSION";
}
print "Current dependency versions:\n";
print Dumper $requires;
