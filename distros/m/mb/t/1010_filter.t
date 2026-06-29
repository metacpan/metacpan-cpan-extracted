# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# Opportunistic source code filter (path 1) test.
#
# On perl 5.8 or later, "use mb 'utf8';" installs a Filter::Util::Call source
# filter that auto-transpiles the rest of the script. Each case writes a tiny
# script that loads mb with only "use mb 'utf8';" (no modulino, no require)
# and runs it through a child perl, then checks the output. The encoding is
# given explicitly ('utf8') so the test does not depend on the system locale.
#
# On perl earlier than 5.8 the source filter is unavailable, so every case
# self-skips (returns true) -- the modulino path is covered elsewhere.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use vars qw(@test);

my $lib = "$FindBin::Bin/../lib";
my $tmp = "$FindBin::Bin/_filt_$$.pl";

# the source filter (path 1) needs perl 5.8 or later
my $has_filter = ($] >= 5.008);

sub write_script {
    my $body = $_[0];
    open(OUT, ">$tmp") or die "can't write $tmp: $!";
    print OUT $body;
    close(OUT);
}

sub run {
    my $out = `$^X -I"$lib" "$tmp" 2>&1`;
    return $out;
}

@test = (

    # mb::length under the filter (あいうえお漢字ABC = 10 characters)
    sub {
        return 1 if not $has_filter;
        write_script(qq{use mb 'utf8';\nmy \$s="あいうえお漢字ABC";\nprint mb::length(\$s),"\\n";\n});
        run() =~ /^10\b/;
    },

    # UTF-8 character class match
    sub {
        return 1 if not $has_filter;
        write_script(qq{use mb 'utf8';\nmy \$s="あいうえお漢字ABC";\nprint "Y" if \$s =~ /[あ-お]+/;\n});
        run() =~ /^Y/;
    },

    # substitution of a multibyte substring
    sub {
        return 1 if not $has_filter;
        write_script(qq{use mb 'utf8';\nmy \$s="あいうえお漢字ABC";\n\$s =~ s/漢字/KANJI/;\nprint \$s,"\\n";\n});
        run() =~ /KANJI/;
    },

    # global capture counts characters, not octets (10 characters)
    sub {
        return 1 if not $has_filter;
        write_script(qq{use mb 'utf8';\nmy \$s="あいうえお漢字ABC";\nmy \@c=(\$s=~/(.)/g);\nprint scalar(\@c),"\\n";\n});
        run() =~ /^10\b/;
    },

    # negated class: ASCII "A" is not in [あ-お]
    sub {
        return 1 if not $has_filter;
        write_script(qq{use mb 'utf8';\nmy \$s="あいうえお漢字ABC";\nprint "Y" if \$s =~ /[^あ-お]/;\n});
        run() =~ /^Y/;
    },
);

END { unlink $tmp if defined $tmp and -e $tmp }

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
