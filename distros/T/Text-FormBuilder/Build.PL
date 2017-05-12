use Module::Build;
my $build = Module::Build->new(
    module_name => 'Text::FormBuilder',
    license  => 'perl',
    configure_requires => {
        Module::Build => 0.30,
    },
    requires => {
        CGI::FormBuilder => 3.0,
        Parse::RecDescent => 1.94,
        Text::Template => 1.44,
        # requirement for Class::ParseText::Base
        Class::Base => 0.03,
    },
    dist_author => 'Peter Eichman <peichman@cpan.org>',
);
$build->create_build_script;
