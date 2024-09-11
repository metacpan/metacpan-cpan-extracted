use ExtUtils::MakeMaker;

use strict;
use warnings;

my %prereq = (
	'Data::Compare'         => '1.29',
	'File::Basename'				    => '2.85',
	'File::MimeInfo'		      => '0.35',
	'File::Path'						      => '2.18',
	'File::Spec'						      => '3.84',
	'FreeDesktop::Icons'    => '0.01',
	'Imager'                => '1.019',
	'Imager::File::PNG'     => '0.99',
	'MIME::Base64'						    => '3.16',
	'Pod::Usage'            => '2.01',
	'Scalar::Util'						    => '1.62',
	'Scalar::Util::Numeric'	=> '0.40',
	'Test::Tk'							    => '3.03',
	'Test::More'            => '1.3',
	'Tk'                   	=> '804.023',
	'Tk::DocumentTree'      => '0.08',
	'Tk::FontDialog'	   				=> '0.18',
	'Tk::PodViewer'         => '0.03',
	'Tk::QuickForm'         => '0.05',
	'Tk::YADialog'          => '0.04',
	'Tk::YANoteBook'        => '0.07',
);

WriteMakefile(
	NAME					=> 'Tk::AppWindow',
	VERSION_FROM		=> 'lib/Tk/AppWindow.pm',
	PREREQ_PM			=> \%prereq,
	ABSTRACT_FROM		=> 'lib/Tk/AppWindow.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
         repository => {
            type => 'git',
            url  => 'git://github.com/haje61/Tk-AppWindow.git',
            web  => 'https://github.com/haje61/Tk-AppWindow',
         },
      }}
    ) : () ),
);




