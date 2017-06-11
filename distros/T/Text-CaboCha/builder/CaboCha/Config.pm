package builder::CaboCha::Config;
use ExtUtils::MakeMaker ();

sub prove_config {
    my $class = shift;

    # May specify encoding from ENV
    my $default_encoding = $ENV{PERL_TEXT_CABOCHA_ENCODING} || 'euc-jp';

    # XXX Silly hack
    local *STDIN = *STDIN;
    close STDIN if $ENV{TRAVIS_TEST};

    my ($version, $cflags, $libs, $include, $cabocha_config);

    $cflags = '';
    $cabocha_config = '';

    # Save the poor puppies that run on Windows
    if ($^O =~ m/(?:MSWin2|cygwin)/) {
        $version = ExtUtils::MakeMaker::prompt(
            join(
                "\n",
                "",
                "You seem to be running on an environment that may not have cabocha-config",
                "available. This script uses cabocha-config to auto-probe",
                "  1. The version string of libcabocha that you are building Text::CaboCha",
                "     against. (e.g. 0.69)",
                "  2. Additional compiler flags that you may have built libcabocha with, and",
                "  3. Additional linker flags that you may have build libcabocha with.",
                "  4. Location where cabocha.h header file may be found",
                "",
                "Since we can't auto-probe, you should specify the above three to proceed",
                "with compilation:",
                "",
                "Version of libcabocha that you are compiling against (e.g. 0.69)? (REQUIRED) []"
            )
        );
        chomp $version;

        unless ($version) {
            print STDERR "no version specified! cowardly refusing to proceed.";
            exit;
        }

        $cflags  = ExtUtils::MakeMaker::prompt("Additional compiler flags (e.g. -DWIN32 -Ic:\\path\\to\\cabocha\\sdk)? []");

        $libs    = ExtUtils::MakeMaker::prompt("Additional linker flags (e.g. -lc:\\path\\to\\cabocha\\sdk\\libcabocha.lib)? [] ");
        $include = ExtUtils::MakeMaker::prompt("Directory containing cabocha.h (e.g. c:\\path\\to\\include)? [] ");
    } else {
        # try probing in places where we expect it to be
        if (! defined $default_config || ! -x $default_config) {
            foreach my $path (qw(/usr/bin /usr/local/bin /opt/local/bin)) {
                my $tmp = File::Spec->catfile($path, 'cabocha-config');
                if (-f $tmp && -x _) {
                    $default_config = $tmp;
                    last;
                }
            }
        }

        $cabocha_config = ExtUtils::MakeMaker::prompt("Path to cabocha config?", $default_config);

        if (!-f $cabocha_config || ! -x _) {
            print STDERR "Can't proceed without cabocha-config. Aborting...\n";
            exit;
        }
        
        $version = `$cabocha_config --version`;
        chomp $version;

        $cflags = `$cabocha_config --cflags`;
        chomp $cflags;

        $libs   = `$cabocha_config --libs`;
        chomp $libs;

        $include = `$cabocha_config --inc-dir`;
        chomp $include;
    }

    print "detected cabocha version $version\n";

    my ($major, $minor, $micro) = map { s/\D+//g; $_ } split(/\./, $version);

    $cflags .= " -DCABOCHA_MAJOR_VERSION=$major -DCABOCHA_MINOR_VERSION=$minor";

    # remove whitespaces from beginning and ending of strings
    $cflags =~ s/^\s+//;
    $cflags =~ s/\s+$//;

    print "Using compiler flags '$cflags'...\n";

    if ($libs) {
        $libs =~ s/^\s+//;
        $libs =~ s/\s+$//;
        print "Using linker flags '$libs'...\n";
    } else {
        print "No linker flags specified\n";
    }

    my $encoding = ExtUtils::MakeMaker::prompt(
        join(
            "\n",
            "",
            "Text::CaboCha needs to know what encoding you built your dictionary with",
            "to properly execute tests.",
            "",
            "Encoding of your cabocha dictionary? (shift_jis, euc-jp, utf-8)",
        ),
        $default_encoding
    );

    print "Using $encoding as your dictionary encoding\n";

    return +{
        version  => $version,
        cflags   => $cflags,
        libs     => $libs,
        include  => $include,
        encoding => $encoding,
        config   => $cabocha_config,
    };
}
1;