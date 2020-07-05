#!perl

use strict;
use warnings;
use Pod::Html;
# pod2html @ARGV;

use Path::Tiny qw/path cwd/;
die "need a lib/ subdir\n" unless path('lib')->is_dir;
path('html')->mkpath unless path('html')->is_dir;
my $visited = path('lib/')->visit(
    sub {
        my ($path, $state) = @_;
        return if $path->is_dir;
        return unless $path->basename =~ /\.(pm|pod)$/;
        my $infile = $path->stringify;
        my $outfile = $path->stringify;
        $outfile =~ s{lib/}{html/};
        $outfile =~ s{\.(pm|pod)}{.html};
        path($outfile)->parent->mkpath unless path($outfile)->parent->is_dir;
        print "pod2html --podroot=lib --htmldir=html --css=C:/usr/local/scripts/pod2html.css --infile=$infile --outfile=$outfile\n";
        pod2html(
            #"--verbose",
            "--podpath=.",
            '--podroot=c:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\lib',
            '--htmlroot=c:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\html',
            '--css=C:\usr\local\scripts\pod2html.css',
            "--infile=".$infile,
            "--outfile=".$outfile,
        );

        $state->{$path}++;
    },
    { recurse => 1 }
);

__END__
pod2html --verbose --podpath=. --podroot=c:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\lib --htmlroot=c:\usr\local\share\GitHubSvn\Win32-Mechanize-NotepadPlusPlus\html --css=C:\usr\local\scripts\pod2html.css --infile=lib/Win32/Mechanize/NotepadPlusPlus.pm --outfile=html/Win32/Mechanize/NotepadPlusPlus.html
