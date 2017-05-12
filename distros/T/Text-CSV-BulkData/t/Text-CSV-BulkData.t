use strict;
use Test::More tests=>47;

BEGIN { use_ok('Text::CSV::BulkData') };

my $output_filename = 'example.dat';
my $format_1 = "0907000%04d,JPN,160-%04d,type000%04d,0120444%04d,2008041810%02d00,2008041811%02d00\n";
my $gen = Text::CSV::BulkData->new($output_filename, $format_1);

my $res;
my $pattern_1 = [undef,'*2*2','-2','*2+1','%60-1','%60-40'];
ok ref $pattern_1 eq 'ARRAY', 'pattern_1 data';

$gen->_set_debug;

ok $res = $gen->initialize, '$obj->initialize';
is $res, $gen, 'returns $self';

ok $res = $gen->set_pattern($pattern_1), '$obj->set_pattern($array_ref)';
is $res, $gen, 'returns $self';

ok $res = $gen->set_start(58), '$obj->set_start($int)';
is $res, $gen, 'returns $self';
is $gen->{start}, 58, 'set_start';

ok $res = $gen->set_end(62), '$obj->set_end($int)';
is $res, $gen, 'returns $self';
is $gen->{end}, 62, 'set_end';

ok $res = $gen->make, '$obj->make';
is $$res[0], "09070000058,JPN,160-0232,type0000056,01204440117,20080418105700,20080418111800\n", 'calc result';
is $$res[1], "09070000059,JPN,160-0236,type0000057,01204440119,20080418105800,20080418111900\n", 'calc result';
is $$res[2], "09070000060,JPN,160-0240,type0000058,01204440121,20080418105900,20080418112000\n", 'calc result';
is $$res[3], "09070000061,JPN,160-0244,type0000059,01204440123,20080418100000,20080418112100\n", 'calc result';
is $$res[4], "09070000062,JPN,160-0248,type0000060,01204440125,20080418100100,20080418112200\n", 'calc result';

my $format_2  = "0907000%04d,JPN,160-%04d,type000%04d,0120444%04d,20080418%02d0000,20080418%02d0000\n";
my $pattern_2 = [undef,'/10','*3/2','%2', '%24-1','%24']; 
ok ref $pattern_2 eq 'ARRAY', 'pattern_2 data';

ok $res = $gen->set_format($format_2), '$obj->set_format($string)';
is $res, $gen, 'returns $self';

ok $res = $gen->set_pattern($pattern_2), '$obj->set_pattern($array_ref)';
is $res, $gen, 'returns $self';

ok $res = $gen->set_start(239), '$obj->set_start($int)';
is $res, $gen, 'returns $self';
is $gen->{start}, 239, 'set_start';

ok $res = $gen->set_end(241), '$obj->set_end($int)';
is $res, $gen, 'returns $self';
is $gen->{end}, 241, 'set_end';

ok $res = $gen->make, '$obj->make';
is $$res[0], "09070000239,JPN,160-0023,type0000358,01204440001,20080418220000,20080418230000\n", 'calc result';
is $$res[1], "09070000240,JPN,160-0024,type0000360,01204440000,20080418230000,20080418000000\n", 'calc result';
is $$res[2], "09070000241,JPN,160-0024,type0000361,01204440001,20080418000000,20080418010000\n", 'calc result';

my $format_3  = "0907000%04d,%s,160-%04d,20080418%02d0000\n";
my $pattern_3 = ['3398','JAPAN','10', '0']; 
ok ref $pattern_3 eq 'ARRAY', 'pattern_3 data';

ok $res = $gen->set_format($format_3), '$obj->set_format($string)';
is $res, $gen, 'returns $self';

ok $res = $gen->set_pattern($pattern_3), '$obj->set_pattern($array_ref)';
is $res, $gen, 'returns $self';

ok $res = $gen->set_start(100), '$obj->set_start($int)';
is $res, $gen, 'returns $self';
is $gen->{start}, 100, 'set_start';

ok $res = $gen->set_end(101), '$obj->set_end($int)';
is $res, $gen, 'returns $self';
is $gen->{end}, 101, 'set_end';

ok $res = $gen->make, '$obj->make';
is $$res[0], "09070003398,JAPAN,160-0010,20080418000000\n", 'calc result';
is $$res[1], "09070003398,JAPAN,160-0010,20080418000000\n", 'calc result';

__END__
