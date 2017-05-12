use strict;
my @scripts;

BEGIN {
@scripts = `find scripts/ -type 'f' | egrep -v '/.#|svn|~\$' `;
}

use Test::More tests => 1+$#scripts;

foreach my $script (@scripts) {
    next unless $script;
    my $file_type = `file $script`;
    if ($file_type =~ /Bourne shell script/) {
        `bash -n $script`;
        ok ( $?==0, "Verifying compilation of '$script'") or
           diag("Bash script '$script' failed");
    } elsif ($file_type =~ /perl script/) {
        `perl -c $script`;
        ok ( $?==0, "Verifying compilation of '$script'") or
            diag("Perl script '$script' failed");
    } else {
        ok ( 1==1, "Unknown script type '$file_type'... skipping");
    }
}



