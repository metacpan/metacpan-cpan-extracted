die "not a module: use Time::Decimal";

=encoding utf-8

=head1 NAME/NOMO

Time::Decimal -- Pritraktu franc-revoluciajn dek horajn tagojn

L<I<English description>|Time::Decimal>



=head1 SUPERRIGARDO

    use Time::Decimal qw($precision h24s_h10 h24_h10 h10s_h24 h10_h24
			 transform now_h10 loop);
    $precision = 'ms';

    $dec = h24s_h10( 1234.5678 );
    $dec = h24_h10( 13, 23, 45, 345_678 );
    $bab = h10s_h24( 1234.5678 );
    $bab = h10_h24( 1, 50, 75, 345_678 );

    $dec = transform( '13:23' );
    $dec = transform( '1:23:45.345_678 pm' );
    $bab = transform( '1_50_75.345_678' );

    $dec = now_h10;
    $dec = now_h10( time + 60 );

    $precision = 's';
    loop { print "$_[0]\t" . localtime() . "\n" };

aŭ

    perl <path>/Time/Decimal.pm [-option ...] [time ...]
    ln <path>/Time/Decimal.pm dectime
    dectime [-option ...] [time ...]

=head1 PRISKRIBO

La babilona 24-hora horloĝo estas unu de la lastaj komplikaj restaĵoj de la
antaŭ-dekuma epoko.  La franca revolucio, kiam ĝi kreis dekumajn mezurojn por
ĉio, ankaŭ inventis disdividon de la tago en dek horojn, ĉiuj je 100 minutoj
kaj tiuj de 100 sekundoj.  La belaĵo estas ke sekundoj kaj (malpli precize)
minutoj daŭras proksimume same kiel tiuj kiujn ni konas.  Horoj kompreneble
daŭras pli ol duoble.

Por povi memstare rekoni dekuman tempon, ni uzas C<_> anstataŭ C<:> kiel
separilo.  Tiu signo uzeblas en multe pli da komputilaj kuntekstoj.  En Perl
ĝi estas ebla separilo inter ciferoj.  Kaj pri tio ja temas ĉi tie, ĉar dekuma
tempo H_MM estas nenio alia ol tri-cifera nombro da minutoj.  Samo direblas
pri kvin-cifera nombro da sekundoj

Por la transformcelo ne gravas ĉu ni konsideru 1:30 kiel frumatena tempo aŭ
kiel daŭro de unu horo kaj duono.  Do tempo kiel 84:00 aŭ 35_00 por signifi
tri tagojn kaj duona estas permesata.



=head2 Modulaj Funkcioj

Nenio estas memstare elportita, sed vi povas enporti la sekvajn per la C<use>
ordono:

=over

=item $precision

    's'		sekundoj
    'ds'	dekonsekundoj
    'cs'	centonsekundoj
    'ms'	milonsekundoj
    'µs', 'us'	milionon- aŭ mikrosekundoj

Kie la µ-signo povas esti en UTF-8, Latino-1, -3, -5, -7 aŭ Latino-9.

=item Vidu SUPERRIGARDO-n supre

I<Priskribo de la diversaj funkcioj plu skribendas.>

=back



=head2 Kommando Linio

=over

=item -s, --seconds

=item -d, --ds, --deciseconds

=item -c, --cs, --centiseconds

=item -m, --ms, --milliseconds

=item -u, --us, --microseconds

Eligu tempojn je la donita precizeco, anstataŭ minutoj.


=item -e, --echo

Eligu la transformitan tempon kune kun la transformaĵo.


=item -r, --reverse

Retransformu la transformaĵon por vidi eblan perdon pro manko de precizeco.


=item -l, --loop

Eligu la tempon denove ĉiufoje ke la rezulto ŝanĝiĝas je la dezirita
precizeco.  Uzeblas kiel horloĝo, sed se la precizeco tro malgrandas, la
montrila programo povas havi problemojn, aŭ ŝanceliĝante, aŭ ade rifuzantete
(C<rxvt> familio).


=item -o, --old, --old-table, --babylonian, --babylonian-table

=item -n, --new, --new-table, --decimal, --decimal-table

Provizas superrigardojn de po ĉirkaŭ 70 tempoj de komuna intereso.  Implicas
C<--echo>.

=back



=head1 VIDU ANKAŭ

L<DateTime::Calendar::FrenchRevolutionary> bone kongruas kun la DateTime
hierarĥio.  Malfeliĉe ĝi ne kapablas onojn, do la transformoj estas
precizecperdaj.  Krome onoj ŝajnas pli naturaj en dekuma tempo.

=head1 AUTHOR

Daniel Pfeiffer <occitan@esperanto.org>
