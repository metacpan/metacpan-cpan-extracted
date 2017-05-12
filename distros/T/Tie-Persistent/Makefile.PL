use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $Has_Storable;
eval { require Storable; };
$Has_Storable = not $@; # did it load OK?

WriteMakefile(
	      'NAME'	=> 'Tie::Persistent',
	      'VERSION_FROM' => 'Persistent.pm', # finds $VERSION
	      'PREREQ_PM'    => { 'Storable' => '0.6',
                                  'Data::Dumper' => '2.09',
				  'File::Spec' => '0.6',
                                },
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'Persistent.pm', # retrieve abstract from module
		AUTHOR     => 'Roland Giersig <RGIERSIG@cpan.org>') : ()),
);

print <<_EOT_ if not $Has_Storable;

WARNING: the 'Storable' module is optional, but heavily recommended
for better performance!!

_EOT_
