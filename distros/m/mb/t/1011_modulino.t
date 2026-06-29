# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use vars qw(@test);

my $mb = "$FindBin::Bin/../lib/mb.pm";

my $nodata = "$FindBin::Bin/_nodata_$$.pl";
my $nodata_oo = $nodata;
$nodata_oo =~ s/\.pl\z/.oo.pl/;

my $withdata = "$FindBin::Bin/_withdata_$$.pl";
my $withdata_oo = $withdata;
$withdata_oo =~ s/\.pl\z/.oo.pl/;

my $err = "$FindBin::Bin/_err_$$.pl";

sub spew {
    open(OUT, ">$_[0]") or die "can't write $_[0]: $!";
    print OUT $_[1];
    close(OUT);
}

# no __DATA__/__END__ : transpiled and run in process (no temporary file)
spew($nodata, qq{my \$s="あいうえお漢字ABC";\nprint mb::length(\$s),"\\n";\nprint "Y" if \$s =~ /[あ-お]+/;\nprint "\\n";\n});

# has __DATA__ : written to *.oo and run via a child interpreter so <DATA> works
spew($withdata, qq{my \$n=0;\nwhile (<DATA>) { chomp; \$n += mb::length(\$_); }\nprint \$n,"\\n";\n__DATA__\nあいう\n漢字\n});

# no __DATA__ : die on line 3, the #line directive must report line 3
spew($err, qq{my \$a=1;\nmy \$b=2;\ndie "boom";\n});

sub run {
    return scalar `$^X "$mb" -e utf8 "$_[0]" 2>&1`;
}

@test = (

    # no __DATA__: runs in process, prints codepoint length 10
    sub { run($nodata) =~ /^10\b/ },

    # no __DATA__: matches the codepoint class [あ-お]+
    sub { run($nodata) =~ /Y/ },

    # no __DATA__: no *.oo temporary file is created
    sub { run($nodata); not -e $nodata_oo },

    # has __DATA__: 3 + 2 = 5 codepoints are read from <DATA>
    sub { run($withdata) =~ /^5\b/ },

    # has __DATA__: a *.oo companion script IS created
    sub { run($withdata); -e $withdata_oo },

    # in-process error line number matches the original script (line 3)
    sub { run($err) =~ /line 3\b/ },
);

END {
    for ($nodata, $nodata_oo, $withdata, $withdata_oo, $err) {
        unlink $_ if defined $_ and -e $_;
    }
}

$| = 1;
print "1..", scalar(@test), "\n";
my $testno = 1;
sub ok {
    print $_[0] ? 'ok ' : 'not ok ', $testno++, $_[1] ? " - $_[1]\n" : "\n";
}
ok($_->()) for @test;

__END__
