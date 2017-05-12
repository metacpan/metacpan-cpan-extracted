use Test::More tests => 19;
use Test::Exception;
use strict;
use warnings;

BEGIN {
    eval q{use Tripletail qw(/dev/null)};
}
END {
}

dies_ok {$TL->charconv} 'charconv die';
dies_ok {$TL->charconv(\123)} 'charconv die';
dies_ok {$TL->charconv('テスト',\123)} 'charconv die';
dies_ok {$TL->charconv('テスト','auto',\123)} 'charconv die';

is($TL->charconv("\xa5\xc6\xa5\xb9\xa5\xc8"), 'テスト', 'charconv auto(EUC-JP) => UTF-8');

is($TL->charconv('テスト', 'UTF-8' => 'EUC-JP'), "\xa5\xc6\xa5\xb9\xa5\xc8", 'charconv UTF-8 => EUC-JP');
is($TL->charconv('テスト', 'auto' => 'EUC-JP'), "\xa5\xc6\xa5\xb9\xa5\xc8", 'charconv auto(UTF-8) => EUC-JP');

is($TL->charconv("\xa5\xc6\xa5\xb9\xa5\xc8", 'EUC-JP' => 'UTF-8'), 'テスト', 'charconv EUC-JP => UTF-8');
is($TL->charconv("\xa5\xc6\xa5\xb9\xa5\xc8", 'euc' => 'UTF-8'), 'テスト', 'charconv euc => UTF-8');
is($TL->charconv("\xa5\xc6\xa5\xb9\xa5\xc8", 'auto' => 'UTF-8'), 'テスト', 'charconv auto(EUC-JP) => UTF-8');
is($TL->charconv("\xa5\xc6\xa5\xb9\xa5\xc8", 'auto' => 'utf8' ), 'テスト', 'charconv auto(EUC-JP) => UTF-8');

is($TL->charconv('テスト', 'auto' => 'Shift_JIS'), "\x83\x65\x83\x58\x83\x67", 'charconv auto(UTF-8) => Shift_JIS');
is($TL->charconv("\x83\x65\x83\x58\x83\x67", 'auto' => 'UTF-8'), 'テスト', 'charconv auto(Shift_JIS) => UTF-8');

is($TL->charconv('テスト', 'auto' => 'ISO-2022-JP'), "\x1b\x24\x42\x25\x46\x25\x39\x25\x48\x1b\x28\x42", 'charconv auto(UTF-8) => ISO-2022-JP');
is($TL->charconv("\x1b\x24\x42\x25\x46\x25\x39\x25\x48\x1b\x28\x42", 'auto' => 'UTF-8'), 'テスト', 'charconv auto(ISO-2022-JP) => UTF-8');

is($TL->charconv("ABC123", 'auto' => 'UTF-8'), 'ABC123', 'charconv auto(ASCII) => UTF-8');

is($TL->charconv("ABCDE", 'EUC-JP' => 'Big-5'), 'ABCDE', 'charconv EUC-JP => BIG-5');
is($TL->charconv("ABCDE", 'Big-5' => 'EUC-JP'), 'ABCDE', 'charconv BIG-5 => EUC-JP');
is($TL->charconv("ABCDE", 'Big-5' => 'EUC-KR'), 'ABCDE', 'charconv BIG-5 => EUC-KR');


