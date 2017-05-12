use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
                       module_name => 'WebService::Images::Nofrag',
                       license     => 'perl',
                       dist_author => 'franck cuny <franck.cuny@gmail.com>',
                       dist_version_from => 'lib/WebService/Images/Nofrag.pm',
                       requires          => {
                                     'Test::More'            => 0,
                                     'version'               => 0,
                                     'WWW::Mechanize'        => 0,
                                     'LWP::Simple'           => 0,
                                     'Class::Accessor::Fast' => 0,
                                     'Image::Magick'         => 0,
                                     'Image::Magick::Info'   => 0,
                                     'Test::Perl::Critic'    => 0,
                       },
                       add_to_cleanup => [ 'WebService-Images-Nofrag-*' ],
);

$builder->create_build_script();
