use strict;
use warnings;

use Test::More tests => 4;

use_ok('XML::Reader::RS');

{
    my ($errflag, @result) = test_func(q{<data><item a2="abc" a1="def" a2="ghi"></item></data>}, {dupatt => '|'});

    like($errflag, qr{Failed \s assertion \s \#0035 \s in \s XML::Reader->new:}xms,    'Test-D020-0010: error');
    is(scalar(@result), 0,                                                             'Test-D020-0020: Find 0 elements');
}

{
    my $line3 = q{<data atr1='abc' atr2='def' atr1='ghi'></data>};

    my $aref = eval{ XML::Reader::slurp_xml(\$line3,
      { dupatt => '|' },
      { root => '/', branch => '*' }) };

    my $errflag = $@ ? $@ : '';

    like($errflag, qr{Failed \s assertion \s \#0035 \s in \s XML::Reader->new:}xms,    'Test-D034-0010: error');
}

sub test_func {
    my ($text, $opt) = @_;

    my $err = '';
    my @res;

    eval {
        my $rdr = XML::Reader::RS->new(\$text, $opt);

        while ($rdr->iterate) { push @res, '<'.$rdr->tag.':'.$rdr->value.'>'; }
    };

    if ($@) {
        $err = $@;
        $err =~ s{\s+}' 'xmsg;
        $err =~ s{\A \s+}''xms;
        $err =~ s{\s+ \z}''xms;
    }

    return ($err, @res);
}
