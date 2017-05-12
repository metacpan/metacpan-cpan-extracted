use Module::Build;
Module::Build->new(
    module_name        => 'WebDAO',
    license            => 'perl',
    configure_requires => { 'Module::Build' => 0.38 },
    prereq             => {
        'XML::Flow'              => '0.86',
        'DateTime'               => 0.37,
        'DateTime::Format::HTTP' => 0.37,
        'Encode'                 => 0,
        'Getopt::Long'           => 2.35,
        'FCGI'                   => 0.67,
        'Test::Class'            => 0,
        'URI'                    => 1.36,
        'HTTP::Body'             => 1.11,
        'MIME::Base64'           => 0
    },
    script_files => [
        qw!
          script/wd_fcgi.fpl
          script/wd_shell.pl
          script/webdao.psgi
          !
    ],
    dist_version_from => 'lib/WebDAO.pm',
    meta_merge        => {
        resources => {
            repository  => 'https://github.com/zag/webdao.git',
            homepage    => 'http://webdao.sourceforge.net',
            bugtracker  => 'https://github.com/zag/webdao/issues',
            ProjectHome => 'https://github.com/zag/webdao',
        }
    },
    dist_author        => 'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl => $ENV{DO_OUTCPAN} ? 'traditional' : 'passthrough'
)->create_build_script;
