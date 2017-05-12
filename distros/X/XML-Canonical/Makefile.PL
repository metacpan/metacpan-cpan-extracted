use ExtUtils::MakeMaker;
use Config;

$|=0;

my %config;
 
while($_ = shift) {
    my ($key, $val) = split(/=/, $_, 2);
    $config{$key} = $val;
}

my $DEBUG = delete $config{DEBUG};

# get libs and inc from gdome-config
eval {
    print "running gdome-config... ";
    my $ver = backtick('gdome-config --version');
    my ($major, $minor, $point) = $ver =~ /(\d+).(\d+)\.(\d+)/g;
    die "VERSION" unless $major == 0 && $minor == 7 && $point == 1;
    $config{LIBS} ||= backtick('gdome-config --libs');
    $config{INC} ||= backtick('gdome-config --cflags');
    print "ok\n";
};
if ($@) {
    print "failed\n";
    if ($@ =~ /^VERSION/) {
        die "XML::Canonical needs gdome2 version 0.7.1 or higher - see README for details\n";
    }
    warn "*** ", $@ if $DEBUG;
    warn "using fallback values for LIBS and INC\n";
    # backtick fails if gnome-config didn't exist...
    $config{LIBS} = '-L/usr/local/lib -L/usr/lib -lgdome -lxml2 -lglib';
    $config{INC} = '-I/usr/local/include/libgdome -I/usr/include/glib-1.2 -I/usr/lib/glib/include';
 
    print <<OPT;
options:
  LIBS='$config{LIBS}'
  INC='$config{INC}'
If this is wrong, Re-run as:
  \$ $^X Makefile.PL LIBS='-L/path/to/lib' INC='-I/path/to/include'

OPT

}

if ($config{LIBS} !~ /\-lxml2\b/) {
    $config{LIBS} .= ' -lxml2';
}

if ($config{LIBS} !~ /\-lgdome\b/) {
    $config{LIBS} .= ' -lgdome';
}

if ($config{LIBS} !~ /\-lglib\b/) {
    $config{LIBS} .= ' -lglib';
}

WriteMakefile(
    'NAME'		=> 'XML::Canonical',
    'VERSION_FROM'	=> 'lib/XML/Canonical.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'XML::GDOME' => 0 }, # e.g., Module::Name => 1.1
    'AUTHOR'            => 'T.J. Mather',
    'ABSTRACT'          => 'Canonical XML for Perl',
    'OBJECT'            => '$(O_FILES)', # add the DOM extensions to libxml2
    %config,
);

sub backtick {
    my $command = shift;
    if ($DEBUG) {
        print $command, "\n";
        my $results = `$command`;
        chomp $results;
        if ($? != 0) {
            die "backticks call to '$command' failed";
        }
        return $results;
    }
    open(OLDOUT, ">&STDOUT");
    open(OLDERR, ">&STDERR");
    open(STDOUT, ">$DEVNULL");
    open(STDERR, ">$DEVNULL");
    my $results = `$command`;
    my $retval = $?;
    open(STDOUT, ">&OLDOUT");
    open(STDERR, ">&OLDERR");
    if ($retval != 0) {
        die "backticks call to '$command' failed";
    }
    chomp $results;
    return $results;
}
