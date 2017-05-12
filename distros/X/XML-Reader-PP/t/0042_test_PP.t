use strict;
use warnings;

use Test::More tests => 21;

use_ok('XML::Reader::PP');

{
    my ($errflag, @result) = test_func(q{<data><item a2="abc" a1="def" a2="ghi"></item></data>}, {dupatt => '|'});

    is($errflag, '',                    'Test-D010-0010: no error');
    is(scalar(@result), 5,              'Test-D010-0020: Find 5 elements');
    is($result[ 0], '<data:>',          'Test-D010-0030: Check element');
    is($result[ 1], '<@a1:def>',        'Test-D010-0040: Check element');
    is($result[ 2], '<@a2:abc|ghi>',    'Test-D010-0050: Check element');
    is($result[ 3], '<item:>',          'Test-D010-0060: Check element');
    is($result[ 4], '<data:>',          'Test-D010-0070: Check element');
}

{
    my ($errflag, @result) = test_func(q{<data><item a2="abc" a1="def" a2="ghi"></item></data>}, {dupatt => 'é'});

    like($errflag, qr{invalid \s dupatt}xms, 'Test-D012-0010: error');
    is(scalar(@result), 0,                   'Test-D012-0020: Find 0 elements');
}

{
    my ($errflag, @result) = test_func(q{<data><item a2="abc" a1="def" a2="ghi"></item></data>}, {dupatt => 'a'});

    like($errflag, qr{invalid \s dupatt}xms, 'Test-D013-0010: error');
    is(scalar(@result), 0,                   'Test-D013-0020: Find 0 elements');
}

{
    my ($errflag, @result) = test_func(q{<data><item a2="abc" a1="def" a2="ghi"></item></data>}, {dupatt => q{'}});

    like($errflag, qr{invalid \s dupatt}xms, 'Test-D014-0010: error');
    is(scalar(@result), 0,                   'Test-D014-0020: Find 0 elements');
}

{
    my ($errflag, @result) = test_func(q{<data><item a2="abc" a1="def" a2="ghi"></item></data>}, {dupatt => q{"}});

    like($errflag, qr{invalid \s dupatt}xms, 'Test-D015-0010: error');
    is(scalar(@result), 0,                   'Test-D015-0020: Find 0 elements');
}

{
    my $line3 = q{<data atr1='abc' atr2='def' atr1='ghi'></data>};

    my $aref = eval{ XML::Reader::slurp_xml(\$line3,
      { dupatt => '|' },
      { root => '/', branch => '*' }) };

    my $errflag = $@ ? $@ : '';

    is($errflag, '',                                              'Test-D030-0010: no error');
    is($aref->[0][0], q{<data atr1='abc|ghi' atr2='def'></data>}, 'Test-D030-0020: result');
}

{
    my $line3 = q{<data atr1='abc' atr2='def' atr1='ghi'></data>};

    my $aref = eval{ XML::Reader::slurp_xml(\$line3,
      { root => '/', branch => '*' }) };

    my $errflag = $@ ? $@ : '';

    like($errflag, qr{duplicate \s attribute}xms,    'Test-D032-0010: error');
}

{
    my $line3 = q{<data><test1>abc</test1><test2>def</test2></data>};

    my $aref = eval{ XML::Reader::slurp_xml(\$line3,
      { dupatt => '|' },
      { root => '/', branch => ['/does/not/exist', '/data/test1', '/does/not/exist/either'] }) };

    my $errflag = $@ ? $@ : '';

    is($errflag, '',             'Test-D040-0010: no error');
    is($aref->[0][0][1], q{abc}, 'Test-D040-0020: result');
}

sub test_func {
    my ($text, $opt) = @_;

    my $err = '';
    my @res;

    eval {
        my $rdr = XML::Reader::PP->new(\$text, $opt);

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
