#!/usr/bin/perl

use strict;
use warnings;
use File::Find;
use Getopt::Long;

my $project_root = '.';
my $custom_shebang;

GetOptions(
    'shebang=s' => \$custom_shebang,
) or die "Usage: $0 [--shebang='/custom/path/to/perl']\n";

my $shebang_line = $custom_shebang ? "#!$custom_shebang\n" : "#!/usr/bin/perl\n";

find(
    {
        wanted => sub {
            return unless /\.pl$/ && -f $_;

            open my $fh, '<', $_ or do {
                warn "Could not open $_: $!";
                return;
            };
            binmode $fh;

            my @lines = <$fh>;
            close $fh;

            return if $lines[0] && $lines[0] =~ /^#!\s*\/usr\/bin\/perl/;
            if (defined $custom_shebang) {
                return if $lines[0] && $lines[0] =~ /^#!\s*\Q$custom_shebang\E/;
            }

            print "Adding shebang to: $_\n";
            open my $out, '>', $_ or do {
                warn "Could not write to $_: $!";
                return;
            };
            binmode $out;

            print $out $shebang_line;
            print $out @lines;
            close $out;
        },
        no_chdir => 1,
    },
    $project_root
);