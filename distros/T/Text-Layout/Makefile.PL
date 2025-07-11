#! perl

use strict;
use warnings;

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.026000;

use ExtUtils::MakeMaker 7.24;

my $master = 'lib/Text/Layout/Version.pm';
my $version = "0.045";
$master =~ s;/Version;;;

WriteMakefile(
 NAME                => 'Text::Layout',
 AUTHOR              => 'Johan Vromans <jv@cpan.org>',
 VERSION             => $version,
 ABSTRACT_FROM       => $master,
 LICENSE             => 'perl_5',
 PL_FILES            => {},
 DIR		     => [],
 MIN_PERL_VERSION    => '5.026000',
 PREREQ_PM           => {
			 'Object::Pad'                 => 0.78,
			 'Text::ParseWords' => 0,
			 'Test::More' => 0,
			},
 TEST_REQUIRES       => {
			 'Object::Pad'                 => 0.78,
			 'PDF::API2'  => 2.036,
			 'Text::ParseWords' => 0,
			},
 META_MERGE => {
   resources    => {
     repository => {
       type => 'git',
       web  => 'https://github.com/sciurius/perl-Text-Layout',
       url  => 'https://github.com/sciurius/perl-Text-Layout.git',
     },
     bugtracker => {
       web => "https://github.com/sciurius/perl-Text-Layout/issues",
     },
   },
   'meta-spec' => {
     version => '2',
     url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
   },
   provides => {
       "Text::Layout"
		=> { file => "lib/Text/Layout.pm",
		     version => $version },
       "Text::Layout::FontConfig"
		=> { file => "lib/Text/Layout/FontConfig.pm",
		     version => $version },
       "Text::Layout::FontDescriptor"
		=> { file => "lib/Text/Layout/FontDescriptor.pm",
		     version => $version },
   },

   no_index => {
         file => [
		  "lib/Text/Layout/Cairo.pm",
		  "lib/Text/Layout/ElementRole.pm",
		  "lib/Text/Layout/Markdown.pm",
		  "lib/Text/Layout/Pango.pm",
		  "lib/Text/Layout/PDFAPI2.pm",
	 ],
       directory => [
		  "lib/Text/Layout/PDFAPI2",
		  "tests",
       ],
   },
 }
);
