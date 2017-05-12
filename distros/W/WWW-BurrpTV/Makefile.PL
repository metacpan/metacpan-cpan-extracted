use ExtUtils::MakeMaker;
use strict;

my $online_tests = ExtUtils::MakeMaker::prompt('Do you want to perform online tests during "make test" phase?', 'yes') =~ /^\s*(y)/i;
my $tests = join ' ', glob ($online_tests ? 't/off_*.t t/on_*.t' : 't/off_*.t');

WriteMakefile(
    NAME              => 'WWW::BurrpTV',
    VERSION_FROM      => 'lib/WWW/BurrpTV.pm',
    PREREQ_PM         => {
				'DateTime'		=> 0,
				'LWP::UserAgent'	=> 0,
				'HTML::TreeBuilder'	=> 0,
				'Test::More'		=> 0,
				'Carp'			=> 0,
				'File::Path'		=> 0,				
				'Path::Abstract'	=> 0,	
    			 },
    test	      => {TESTS => $tests},
    
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/WWW/BurrpTV.pm',
       LICENSE	      => 'perl',
       AUTHOR         => 'rarbox <rarbox@cpan.org>') : ()),
);
