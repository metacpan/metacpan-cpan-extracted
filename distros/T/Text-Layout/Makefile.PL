#! perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $master = 'lib/Text/Layout/Version.pm';
my $version = "0.013";
$master =~ s;/Version;;;

WriteMakefile(
 NAME                => 'Text::Layout',
 AUTHOR              => 'Johan Vromans <jv@cpan.org>',
 VERSION             => $version,
 ABSTRACT_FROM       => $master,
 LICENSE             => 'perl_5',
 PL_FILES            => {},
 MIN_PERL_VERSION    => '5.010001',
 PREREQ_PM => {
     'ExtUtils::MakeMaker' => 6.46, # for META_MERGE, LICENSE
     'Test::More' => 0,
 },
 TEST_REQUIRES  => {
		    'PDF::API2'  => 2.036,
		   },
 META_MERGE => {
   resources    => {
     repository => {
       type => 'git',
	web  => 'https://github.com/sciurius/perl-Text-Layout',
	url  => 'https://github.com/sciurius/perl-Text-Layout.git',
      },
      bugtracker => "https://github.com/sciurius/perl-Text-Layout/issues",
     },
     'meta-spec' => {
       version => '2',
       url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
     },
     provides => {
	 "Text::Layout"
		  => { file => "lib/Text/Layout.pm",
		       version => $version },
     },

     no_index => {
#         file => [
#	    "lib/Text/Layout/Version.pm",
#	 ],
         directory => [
	    "tests",
	    "lib/Text/Layout",
	 ],
     },
 }
);
