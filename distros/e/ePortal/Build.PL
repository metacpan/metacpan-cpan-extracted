#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software.
#
#----------------------------------------------------------------------------
use strict;
use Module::Build;
use Getopt::Long qw //;

# ------------------------------------------------------------------------
# Get options
my ($opt_target, $opt_t_host, $opt_t_database, $opt_t_username, $opt_t_password, $opt_t_webserver);
Getopt::Long::GetOptions(
    'target=s' => \$opt_target,
    'test_host=s' => \$opt_t_host,
    'test_database=s' => \$opt_t_database,
    'test_username=s' => \$opt_t_username,
    'test_password=s' => \$opt_t_password,
    'test_webserver=s' => \$opt_t_webserver,
  );
if (! $opt_target ) {
  open(F, 'target');
  $opt_target = <F>; chomp $opt_target;
  close F;
} else {
  open(F, '>target') or die "Cannot create file target\n";
  print F $opt_target;
  close F;
}
die "Cannot discover build target. Incomplete distribution?\n" if ! $opt_target;


# ------------------------------------------------------------------------
# Create Builder
# 
my $builder_class = Module::Build->subclass(
  class => 'ePortal::Builder', code => q{

sub ACTION_manifest {
  my $self = shift;
  $self->run_perl_script('release/make_manifest.pl', undef, '--target='.$self->notes('ePortal_target'));
}  

sub ACTION_install {
  my $self = shift;
  $self->SUPER::ACTION_install();
  ExtUtils::Install::install(
    { 'comp_root' => $self->notes('ePortal_home').'/comp_root',
      'bin' =>  $self->notes('ePortal_home').'/bin',
      'samples' =>  $self->notes('ePortal_home').'/samples',
    }, 1, 0, $self->{args}{uninst}||0);
}

sub ACTION_fakeinstall {
  my $self = shift;
  $self->SUPER::ACTION_fakeinstall();
  ExtUtils::Install::install(
    { 'comp_root' => $self->notes('ePortal_home').'/comp_root',
      'bin' =>  $self->notes('ePortal_home').'/bin',
      'samples' =>  $self->notes('ePortal_home').'/samples',
    }, 1, 1, $self->{args}{uninst}||0);
}

sub ACTION_distmeta {
  my $self = shift;
  if ($self->notes('ePortal_target') ne 'ePortal') {
    $self->{properties}{requires}{'ePortal::Server'} = $self->dist_version();
  }
  $self->SUPER::ACTION_distmeta();
}

sub ACTION_test {
  my $self = shift;

  if (-d './t') {
    my @test_parameters = (
      ['ePortal_test_host', 'Mysql server host', 'localhost'],
      ['ePortal_test_database', 'MySQL database name (must exists)', 'eportal_test'],
      ['ePortal_test_username', 'MySQL username', 'root'],
      ['ePortal_test_password', 'MySQL password', ''],
      ['ePortal_test_webserver', 'WEB server to test ("none" to skip)', 'http://test/'],
    );
    foreach my $rec (@test_parameters) {
      local $^W = 0;
      $self->notes($rec->[0], $self->prompt($rec->[1], $self->notes($rec->[0]) || $rec->[2])) if ! defined $self->notes($rec->[0]);
    }
  }  

  $self->SUPER::ACTION_test();
}
  
});  # end of Module::Build->subclass

# ------------------------------------------------------------------------
# 
  my $builder = $builder_class->new(
    dist_name => $opt_target eq 'ePortal'
                 ? 'ePortal'
                 : "ePortal-$opt_target",
    dist_version_from => 'lib/ePortal/Server.pm',
    author => 'Sergey Rusakov <rusakov_sa@users.sourceforge.net>',
    license => 'open_source',
    create_readme => 1,
    test_files => 't/*.t',
    create_makefile_pl => 'passthrough',
    requires       => {
        'Apache::Request'       => 0,
        'CGI'                   => 0,
        'Data::Dumper'          => 0,
        'Date::Calc'            => 5.0,
        'DBD::mysql'            => 0,
        'DBI'                   => 1.28,
        'Digest::MD5'           => 2.13,
        'Error'                 => 0,
        'HTML::Mason'           => 1.22,
        'Image::Size'           => 2.99,
        'List::Util'            => 0,
        'Mail::Sendmail'        => 0.78,
        'MIME::Base64'          => 0,
        'Net::LDAP'             => 0,
        'Params::Validate'      => 0.24,
        'Storable'              => 0,
        'Text::Wrap'            => 0,
        'Unicode::Map8'         => 0,
        'Unicode::String'       => 0,
        }, # e.g., Module::Name => 0 or 1.1
    recommends  => {
        'CGI'                   => 3.04,
        'HTML::Mason'           => 1.25,
    },
    );

  $builder->{args}->{home} ||= '/opt/ePortal';
  $builder->notes( ePortal_home => $builder->{args}->{home} );
  $builder->notes( ePortal_target => $opt_target );

  $builder->notes( ePortal_test_host => $opt_t_host ) if $opt_t_host;
  $builder->notes( ePortal_test_database=> $opt_t_database ) if $opt_t_database;
  $builder->notes( ePortal_test_username => $opt_t_username ) if $opt_t_username;
  $builder->notes( ePortal_test_password => $opt_t_password ) if $opt_t_password;
  $builder->notes( ePortal_test_webserver => $opt_t_webserver ) if $opt_t_webserver;

  $builder->create_build_script;
  print "ok\n";
