use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Text::Ngram',
    'VERSION_FROM'	=> 'lib/Text/Ngram.pm',
    'PREREQ_PM'		=> {
    	'Unicode::CaseFold' => '1.00',
    	},
    ($] >= 5.005 ? 
      (ABSTRACT_FROM => 'lib/Text/Ngram.pm', 
       AUTHOR     => 'Alberto Simoes <ambs@cpan.org>') : ()),
    'LIBS'		=> [''],
    'DEFINE'		=> '',
    'INC'		=> '-I.',
);
