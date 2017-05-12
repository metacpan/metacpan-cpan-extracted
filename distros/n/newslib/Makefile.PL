use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $modules = {};  my $manpage = {};
foreach my $module ( 
   	qw( Net::NNTP::Auth Net::NNTP::Proxy Net::NNTP::Client
	    Net::NNTP::Functions News::NNTPAuth News::Article::Cancel 
	    News::Article::Ref News::Article::Response 
	    News::Article::Clean ) ) {
  my $file = $module;
     $file =~ s/::/\//g;  
     $file =~ s/$/.pm/;
  my $libdir = join('/', '$(INST_LIBDIR)', $file);
  my $man3 = join('/', '$(INST_MAN3DIR)', "$module.3");
  $$modules{$file} = $libdir; $$manpage{$file} = $man3;
}

WriteMakefile(
    'NAME'	   => 'NewsLib',
    'DISTNAME'     => 'newslib',
    'MAN3PODS'     => $manpage,
    'VERSION_FROM' => 'Version.pm', # finds $VERSION
    'PREREQ_PM'    => { 'News::Article' => 1.27, 'Net::NNTP' => 2.19,
			'Net::Domain' => 2 },
    'PM'	   => $modules,
    'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
