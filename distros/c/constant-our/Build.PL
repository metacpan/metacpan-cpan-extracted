#!/usr/bin/perl
use strict;
use warnings;
use Module::Build;

my $build_cpan_release;
if ( @ARGV && $ARGV[0] eq 'cpan' )
{
    shift @ARGV;
    $build_cpan_release = 1;
}

my $builder = Module::Build->new(
                                  module_name       => 'constant::our',
                                  license           => 'perl',
                                  dist_author       => 'Green <Evdokimov.Denis@gmail.com>',
                                  dist_version_from => 'lib/constant/our.pm',
                                  build_requires    => {
                                                      'Test::More' => 0,
                                                      'constant'   => 0,
                                                      'Exporter'   => 0,
                                  },
                                  add_to_cleanup     => ['constant::our-*'],
                                  create_makefile_pl => 'traditional',
);

if ( !$build_cpan_release )
{
    $builder->create_build_script();
}
else
{
    $builder->dispatch('distmeta');
    $builder->dispatch('manifest');
    print_delimiter();
    print "Functional tests:\n";
    $builder->dispatch('test');
    {
        print_delimiter();
        print "CPAN release tests:\n";
        local $builder->{properties}->{test_files} = 't_cpan_release';
        $builder->dispatch('test');
    }
    print_delimiter();
    $builder->dispatch('dist');
    $builder->dispatch('realclean');
    unlink qw(Makefile.PL MANIFEST MANIFEST.bak MANIFEST.SKIP.bak META.json META.yml);
}
################################################################################
sub print_delimiter
{
    print "\n\n\n";
}
################################################################################
