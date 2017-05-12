use ExtUtils::MakeMaker;
use strict;
$^W = 1;

my $PACKAGE = 'XML::Mini';
(my $PACKAGE_FILE = $PACKAGE) =~ s|::|/|g;

WriteMakefile(
	      NAME            => $PACKAGE,
	      VERSION_FROM    => "lib/$PACKAGE_FILE.pm", # finds $VERSION
	      PREREQ_PM       => {
		  'FileHandle'   => 2.0,
		  'Data::Dumper' => 2.1,
		  'Text::Balanced' => 1.95,
	      }
	      );
