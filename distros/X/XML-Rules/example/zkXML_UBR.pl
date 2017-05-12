use strict;
use XML::Rules;

my $parser = XML::Rules->new(
	rules => [
		_default => 'content',
		qr/^UBR\d+$/ => 'no content',
		Mibs => 'pass no content',
	]
);

<<'*END*';
sdfgskdfh glsdfhg sldfhg sdfg
sfgh
 dfhgfhjgf hj
*END*

my $data = $parser->parse(\*DATA);

use Data::Dumper;
print Dumper($data);

foreach my $ubr (keys %$data) {
  print "$ubr: SNR=$data->{$ubr}{SNR} / SNRTotal=$data->{$ubr}{SNRTotal}\n";
}


__DATA__
<?xml version="1.0" standalone="yes"?>
<Mibs>
        <UBR100000>
                <SNRTotal>a</SNRTotal>
                <SNR>b</SNR>
                <CW_UNER>c</CW_UNER>
                <CW_CORR>d</CW_CORR>
                <CW_UNCORR>e</CW_UNCORR>
                <FREQ>f</FREQ>
                <OCUPACION>g</OCUPACION>
                <MODCM>h</MODCM>
                <MOD>i</MOD>
        </UBR100000>
        <UBR7200>
                <SNRTotal>a</SNRTotal>
                <SNR>b</SNR>
                <CW_UNER>c</CW_UNER>
                <CW_CORR>d</CW_CORR>
                <CW_UNCORR>e</CW_UNCORR>
                <FREQ>f</FREQ>
                <OCUPACION>g</OCUPACION>
                <MODCM>h</MODCM>
                <MOD>i</MOD>
        </UBR7200>
</Mibs>