#!/usr/bin/env perl
use strict;
use warnings;
use Template;
use POSIX qw(strftime);
use Time::gmtime;
use Git::Wrapper;
use Cwd qw(cwd);


# Quick and dirty to generate templates
#
my %base = (
  debian => 'debian:bookworm',
  alpine => 'alpine:latest',
  fedora => 'fedora:43',
  perl   => 'perl:latest'
);


#  Get git version
#
my $git_or=&_git();
my $git_version=($git_or->describe(qw(--tags --abbrev=0)))[0];
$git_version=~s/^WebDyne_//;
my $git_revision=($git_or->rev_parse(qw(--short HEAD)))[0];


#  Template vars we need
#
my %label= (

  label_created => strftime("%Y-%m-%dT%H:%M:%SZ", @{gmtime()}),
  label_version => $git_version,
  label_revision => $git_revision

);

#use Data::Dumper;
#die Dumper(\%label);



# Iterate
#
while (my($family, $base_image)=each %base) {


  #  Hash of template vars
  #
  my %vars = (
    base_image    => $base_image,
    family        => $family,
    %label
  );

  
  # Render
  #
  my $tt = Template->new({ INCLUDE_PATH => '.', TRIM => 1 })
    or die Template->error();
  $tt->process('Dockerfile.tt', \%vars, "Dockerfile.$family")
    or die $tt->error();

  print "Generated Dockerfile.$family\n";

}

sub _git {

    my $git_or=Git::Wrapper->new(cwd()) ||
        return err('unable to get Git::Wrapper object');
    return $git_or;

}


exit 0;