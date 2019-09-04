use strict;
use warnings;
use ExtUtils::MakeMaker;

my $master = 'lib/Text/Layout/Version.pm';
my $version = MM->parse_version($master);
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
		    'PDF::API2'  => 2.020,
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
	 "Text::Layout::Pango"
		  => { file => "lib/Text/Pango.pm",
		       version => $version },
	 "Text::Layout::Cairo"
		  => { file => "lib/Text/Cairo.pm",
		       version => $version },
	 "Text::Layout::PDFAPI2"
		  => { file => "lib/Text/PDFAPI2.pm",
		       version => $version },
	 "Text::Layout::Markdown"
		  => { file => "lib/Text/Markdown.pm",
		       version => $version },
	 "Text::Layout::FontConfig"
		  => { file => "lib/Text/FontConfig.pm",
		       version => $version },
	 "Text::Layout::FontDescriptor"
		  => { file => "lib/Text/FontDescriptor.pm",
		       version => $version },
     },
     no_index => {
         file => [
	    "lib/App/Music/ChordPro/Version.pm",
	 ],
         directory => [
	    "tests",
	 ],
     },
 }
);
