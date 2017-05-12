use strict;
use warnings;
use inc::dtRdrBuilder;

our $dotBuilder;
my $build_class =  $dotBuilder || 'inc::dtRdrBuilder';

my $builder = $build_class->new(
  dist_name         => 'dotReader',
  # this would be 'gpl' when we release
  license             => 'gpl',
  dist_version_from   => 'lib/dtRdr.pm',
  dist_author         => 'OSoft Inc.',
  dist_abstract       => 'Cross-Platform XML Book Reader',
  recursive_test_files => 1,
  test_types       => {
    gui  => 'gt',
    sync => 'ct',
  },
  build_requires => { # should be test_requires, but not in 0.28
    'IPC::Run' => 0,
  },
  main_pl_file => 'client/app.pl',
  macmaker_icon => 'client/icons/dotreader.tiff',
  requires => {
    'Archive::Zip'             => 0,
    #'Archive::Zip::MemberRead' => 0,
    'Class::Accessor'          => '0.25',
    'Class::Accessor::Classy'  => '0.001003',
    'Date::Format'             => 0, # TODO DateTime?
    'File::NCopy'              => 0,
    'Module::Finder'           => '0.001001',
    'Module::Pluggable'        => '2.96',
    'wxPerl::Constructors'     => '0.000002',
    'wxPerl::Styles'           => '0.000001',
    'Wx'                       => '0.26',
    #'Wx::Event'                => 0,
    #'Wx::Html'                 => 0,
    'XML::Parser::Expat'       => 0,
    'Method::Alias'            => 0,
    'Data::GUID'               => 0,
    'Log::Log4perl'            => 1.0,
    'LWP::Parallel::UserAgent' => 0,
    'XML::Twig'                => 3.22,
    'YAML::Syck'               => 0.67,
    'Scope::Guard'             => 0,
    'Tree::Simple'             => 0,
    'URI'                      => 0,
    ################################################################
    # Windows prereqs
    ( $^O eq 'MSWin32' ? (
      'Wx::ActiveX::IE' => 0
      ) : ()),
    ################################################################
    # linux prereqs
    ( $^O eq 'linux' ? (
      'Wx::Mozilla' => 0.05
      ) : ()),
    ################################################################
    # darwin prereqs
    ( $^O eq 'darwin' ? (
      'Wx::WebKit' => 0.04
      ) : ()),
    ################################################################
  }, # end requires
  build_requires => {
    'Module::Build'            => 0.2807,
    'Test::More'               => 0.62,
  },
  # XXX Module::Build doesn't speak test_recommends :-/
  test_recommends => {
    'Test::HTTP::Server::Simple' => 0.04,
  },
  # XXX Module::Build doesn't speak build_recommends :-/
  build_recommends => {
    'PAR'             => 0,
    'Devel::TraceUse' => 0,
  },
  add_to_cleanup      => [ qw(
    binary_build
    )],
  create_makefile_pl => 'passthrough',
);

$builder->create_build_script();

# vim:ts=2:sw=2:et:sta
