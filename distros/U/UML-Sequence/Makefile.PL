use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @executables;

print <<EOJ;
This distribution can sometimes be used to diagram Java programs by running
them.  For this to work, you must have the Sun SDK installed.  That SDK must
have a tools.jar, which must be in the classpath when you use
UML::Sequence::JavaSeq.  Further, the classpath must also include Seq.java
found in the java directory of the distribution.  See README
and samples/README for details.

During testing, I will try to find your SDK and its tools.jar, which I
will temporarily insert into the classpath.  If I can't do that, I will
skip the Java tests.
EOJ

use Config;
foreach my $source ('genericseq.source', 'seq2svg.source', 'seq2rast.source') {
    my    $script      = $source;
    $script            =~ s/\.source/.pl/;
    open  SCRIPT,       ">$script" or next;
    open  SOURCE,        "$source" or next;
    chmod 0755,          "$script";
    push @executables,   "$script";
    print SCRIPT "$Config{startperl}\n";
    while (<SOURCE>) {
        print SCRIPT;
    }
    close SCRIPT;
    close SOURCE;
}

my %prereq = (
    XML::DOM   => 1.25,
    Test::More => 0,
);

my %opts = (
    'NAME'		=> 'UML::Sequence',
    'VERSION_FROM'	=> 'lib/UML/Sequence.pm', # finds $VERSION
    'PREREQ_PM'		=> \%prereq,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM   => 'lib/UML/Sequence.pm',
        AUTHOR          => 'Phil Crow <philcrow2000@yahoo.com>'
      )    :   ()
    ),
    'EXE_FILES'         => \@executables # [ 'genericseq.pl', 'seq2svg.pl', 'seq2rast.pl' ]
);

my $ok = 1;
$ok &&= CheckOptModule('GD', '2.30');
$ok &&= CheckOptModule('GD::Text', '0.86');

print '
In order to use the seq2rast.pl application to directly
render diagrams to raster images, the GD (min. version 2.30)
and GD::Text (min. version 0.86) modules are needed.
Missing modules are available from CPAN at http://search.cpan.org;
in addition, PPMs for the latest versions of GD and GD::Text
are usually available at the usual repositories.
',

($^O eq 'MSWin32') ? '
Also, to map fontnames to font files, Win32::Font::NameToFile
is required.
' : ''
	unless $ok;

ExtUtils::MakeMaker::WriteMakefile(%opts);

sub CheckOptModule ($$;$) {
    my($module, $version, $package) = @_;
    $package ||= $module;
    $prereq{$module} = $version || 0;
    if ($version) {
		print "Checking for $package, $version or later ... ";
		eval "use $module $version";
		if ($@) {
		    print("\nYou don't have the optional $package package",
			  " version $version or later, installed.\n");
		    return 0;
		}
    } else {
		print "Checking for $package ... ";
		eval "use $module";
		if ($@) {
		    print("\nYou don't have the optional $package package installed.\n");
		    return 0;
		}
    }
    print "ok\n";
    return 1;
}

