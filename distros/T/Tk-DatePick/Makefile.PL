use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tk::DatePick',
    'VERSION_FROM'	=> "DatePick.pm", 
    'PREREQ_PM'		=> {'Tk' => 0,
			'Tk::FireButton' => 0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'DatePick.pm', # retrieve abstract from module
       AUTHOR     => 'Kenneth Gonsalves <lawgon@thenilgiris.com>') : ()),
);
