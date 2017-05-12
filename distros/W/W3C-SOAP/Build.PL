use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'W3C::SOAP',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/W3C/SOAP.pm',
    requires          => {
        'perl'                         => '5.006',
        'DateTime'                     => 0,
        'DateTime::Format::Strptime'   => 0,
        'File::ShareDir'               => 1.0,
        'File::Temp'                   => '0.22',
        'List::MoreUtils'              => 0,
        'List::Util'                   => 0,
        'LWP::UserAgent'               => 0,
        'Module::Build'                => 0.3,
        'Moose'                        => 1,
        'Moose::Meta::Method'          => 1,
        'Moose::Role'                  => 1,
        'Moose::Util::TypeConstraints' => 1,
        'MooseX::Exception::Base'      => 0,
        'MooseX::Types'                => 0,
        'MooseX::Types::XMLSchema'     => 0.03,
        'namespace::autoclean'         => 0,
        'Path::Tiny'                   => 0,
        'Scalar::Util'                 => 0,
        'Template'                     => 2.2,
        'Time::HiRes'                  => 0,
        'Try::Tiny'                    => 0,
        'URI'                          => 0,
        'WWW::Mechanize'               => 1.6,
        'XML::LibXML'                  => 1.7,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => 0,
        'Test::XML'      => 0,
        'parent'         => '0.225',
    },
    recommends => {
        'MooseX::Aliases'                => 0,
        'Test::Spelling'                 => 0,
        'Test::Perl::Critic'             => 0,
        'Test::Kwalitee'                 => 0,
        'Pod::Coverage'                  => 0,
        'AnyEvent'                       => 0,
        'AnyEvent::HTTP::LWP::UserAgent' => 0,
    },
    share_dir => {
        dist => [
            'templates',
        ],
    },
    add_to_cleanup     => [ 'W3C-SOAP-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'git://github.com/ivanwills/W3C-SOAP.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=W3C::SOAP',
        },
    },
);

$builder->create_build_script();
