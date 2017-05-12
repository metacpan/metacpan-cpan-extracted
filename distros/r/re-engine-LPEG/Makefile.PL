use 5.01000;
use strict;
use warnings;

use File::Basename;
use File::Compare;
use File::Copy;
use File::Path;
use Archive::Extract;

my %files = (
    'http://www.lua.org/ftp/lua-5.1.4.tar.gz' => {
            'src/*.c'   => 'liblua',
            'src/*.h'   => 'liblua',
    },
    'http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-0.9.tar.gz' => {
            '*.c'       => 'liblpeg',
            're.lua'    => 'LPEG',
    },
);


foreach my $url (keys %files) {
    my $filename = basename( $url );
    unless (-f $filename) {
        warn "retrieving $filename\n";
        eval "use LWP::UserAgent;";
        unless ($@) {
            my $ua = new LWP::UserAgent();
            $ua->env_proxy();
            my $request = new HTTP::Request( 'GET', $url );
            my $response = $ua->request( $request, $filename );
            die "Error while getting ", $response->request->uri, " -- ",
                                        $response->status_line, "\nAborting"
                    if ($response->is_error);
        }
        else {
            system("wget $filename") == 0 or die "can't retrieve $filename";
        }
    }
    my $dirname = basename( $filename, '.tar.gz' );
    unless (-d $dirname) {
        warn "extracting $filename\n";
        my $ae = Archive::Extract->new( archive => $filename );
        $ae->extract();
    }
    while (my ($pat, $dest) = each %{$files{$url}}) {
        mkpath($dest) unless (-d $dest);
        foreach my $src (glob("$dirname/$pat")) {
            copy($src, $dest . '/' . basename($src));
        }
    }
}

if (compare('liblpeg/lpeg.c', 'lpeg-0.9/lpeg.c') == 0) {
    my $file = 'liblpeg/lpeg.c';
    warn "patch $file\n";
    my $subs1 = 's/^#define VERSION/#undef VERSION\n#define VERSION/;';
    my $subs2 = 's/static\s+const\s+char\s+\*\s*match/const char *match/;';
    system("perl -i.bak -pe \"$subs1 $subs2\" $file");
}

# now, we have all source

use ExtUtils::MakeMaker;

my @OBJ = map  { s/\.c$/\$(OBJ_EXT)/; $_ }
          grep { ! /\/(print|lua)/ }
          (glob('liblpeg/*.c'), glob('liblua/*.c'));

WriteMakefile(
    NAME          => 're::engine::LPEG',
    AUTHOR        => 'Francois PERRAD <francois.perrad@gadz.org>',
    VERSION_FROM  => 'LPEG.pm',
    ABSTRACT_FROM => 'LPEG.pm',
    PM            => {
            'LPEG.pm'           => '$(INST_LIBDIR)/LPEG.pm',
            'LPEG/re.lua'       => '$(INST_LIBDIR)/LPEG/re.lua',
    },
    LICENSE       => 'MIT',
    DIR           => [ 'liblua', 'liblpeg' ],
    INC           => '-Iliblua',
    PREREQ_PM     => {
            'Test::Warn'        => 0,
    },

    # This used to be '-shared lib*/*.o' but that doesn't work on Win32
    LDDLFLAGS     => "-shared \$(LDFLAGS) @OBJ",
);

