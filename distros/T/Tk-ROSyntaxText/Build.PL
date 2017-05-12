use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tk::ROSyntaxText',
    license             => 'perl',
    dist_author         => 'Ken Cotterill <kcott@cpan.org>',
    dist_version_from   => 'lib/Tk/ROSyntaxText.pm',
    requires => {
        'Syntax::Highlight::Engine::Kate' => 0.06,
        'Test::More' => 0.94,
        'Tk' => 0,
        'Tk::Derived' => 0,
        'Tk::ROText' => 0,
        'Tk::Widget' => 0,
    },
    add_to_cleanup      => [ 'Tk-ROSyntaxText-*' ],
);

$builder->create_build_script();
