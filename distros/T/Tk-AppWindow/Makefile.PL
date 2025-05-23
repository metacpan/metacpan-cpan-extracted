use ExtUtils::MakeMaker;

use strict;
use warnings;
use Config;
my $mswin = 0;
$mswin = 1 if $Config{'osname'} eq 'MSWin32';

my %prereq = (
	'Data::Compare'          => '1.29',
	'File::Basename'				     => '2.85',
	'File::MimeInfo'		       => '0.35',
	'File::Path'				 	       => '2.18',
	'File::Spec'             => '3.75',
	'FreeDesktop::Icons'     => '0.01',
	'Imager'                 => '1.019',
	'Imager::File::PNG'      => '0.99',
	'MIME::Base64'						     => '3.16',
	'Pod::Usage'             => '2.01',
	'Scalar::Util'						     => '1.62',
	'Scalar::Util::Numeric'	 => '0.40',
	'Test::Tk'				           => '3.04',
	'Test::More'             => '1.3',
	'Tk'                   	 => '804.032',
	'Tk::DocumentTree'       => '0.08',
	'Tk::DynaMouseWheelBind' => '0.07',
	'Tk::FileBrowser'        => '0.07',
	'Tk::FontDialog'	   				 => '0.18',
	'Tk::PodViewer'          => '0.03',
	'Tk::QuickForm'          => '0.06',
	'Tk::YADialog'           => '0.04',
	'Tk::YANoteBook'         => '0.09',
);
if ($mswin) {
	$prereq{'File::MimeInfo::Simple'} = '0.7'
} else {
	$prereq{'File::MimeInfo'} = '0.35'
}

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
         bugtracker => {
            web  => "https://github.com/haje61/Tk-AppWindow/issues",
         },
      }}
    ) : () ),
);




