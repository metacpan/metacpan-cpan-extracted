use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Rest',
    license             => 'perl',
    dist_author         => 'Keith Grennan <kgrennan@cpan.org>',
    dist_version_from   => 'lib/Test/Rest.pm',
    build_requires => {
        'Test::More' => '0.94',
        'Test::MockObject' => '1.09',
    },
    requires => {
          'URI' => '1.40',
          'LWP::UserAgent' => '5.834',
          'WWW::Mechanize' => '1.60',
          'XML::LibXML' => '1.70',
          'Class::Accessor' => '0.31',
          'Template' => '2.22',
          'String::Random' => '0.22',
    },    
    add_to_cleanup      => [ 'Test-Rest-*' ],
    create_makefile_pl => 'passthrough',
);

$builder->create_build_script();

__END__
# handy lister of installed dependency versions
use Data::Dumper;
my $requires = $builder->requires;
for my $mod (keys %$requires) {
    eval "require $mod";
    $requires->{$mod} = eval "\$$mod\::VERSION";
}
print "Current dependency versions:\n";
print Dumper $requires;
