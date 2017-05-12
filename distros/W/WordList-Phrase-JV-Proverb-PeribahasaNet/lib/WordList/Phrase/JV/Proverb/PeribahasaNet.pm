package WordList::Phrase::JV::Proverb::PeribahasaNet;

our $DATE = '2016-02-10'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_unicode",0,"shortest_word_len",16,"num_words_contains_nonword_chars",107,"avg_word_len",64.7009345794392,"num_words_contains_whitespace",106,"num_words",107,"longest_word_len",323); # STATS

1;
# ABSTRACT: Javanese proverbs from peribahasa.net

=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::JV::Proverb::PeribahasaNet - Javanese proverbs from peribahasa.net

=head1 VERSION

This document describes version 0.01 of WordList::Phrase::JV::Proverb::PeribahasaNet (from Perl distribution WordList-Phrase-JV-Proverb-PeribahasaNet), released on 2016-02-10.

=head1 SYNOPSIS

 use WordList::Phrase::JV::Proverb::PeribahasaNet;

 my $wl = WordList::Phrase::JV::Proverb::PeribahasaNet->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 64.7009345794392 |
 | longest_word_len                 | 323              |
 | num_words                        | 107              |
 | num_words_contains_nonword_chars | 107              |
 | num_words_contains_unicode       | 0                |
 | num_words_contains_whitespace    | 106              |
 | shortest_word_len                | 16               |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-JV-Proverb-PeribahasaNet>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-JV-Proverb-PeribahasaNet>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-JV-Proverb-PeribahasaNet>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<http://www.peribahasa.net/peribahasa-jawa.php>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
Adigang Adidung Adiguno Adiwacara.
Adigang,adigung,adiguna.
Aja dumeh wong gedhe.
Ajining diri dumunung ana ing lathi, ajining raga ana ing busana.
Ala lan becik iku gandhengane, kabeh kuwi saka karsaning Pangeran.
Alon-alon waton kelakon.
Ana catur mungkur.
Anak polah bapa kepradah
Asu gedhe menang kerahe.
Asu rebutan balung.
Becik ketitik ala ketara.
Beda-beda pandumaning dumadi.
Bener kang asale saka Pangeran iku lamun ora darbe sipat angkara murka lan seneng gawe sangsaraning liyan.
Bener saka kang lagi kuwasa iku uga ana rong warna, yakuwi kang cocok karo benering Pangeran lan kang ora cocok karo benering Pangeran.
Berat sama dipikul ringan sama dijinjing.
Bibit, bebet, bobot.
Cakra manggilingan.
Crah agawe bubrah
Dhemit ora ndulit, setan ora doyan
Dhuwur wekasane, endhek wiwitane
Diobong gak kobong, disiram gak teles
Diwehi ati ngrogoh rempela
Dumadining sira iku lantaran anane bapa biyung ira.
Gupak Pulut ora mangan nangkane
Guru Sejati bisa nuduhake endi lelembut sing mitulungi lan endi sing nyilakani.
Gusti Allah ora sare.
Gusti iku dumunung ana atining manungsa kang becik, mula iku diarani Gusti iku bagusing ati.
Gusti iku sambaten naliko sira lagi nandhang kasangsaran. Pujinen yen sira lagi nampa kanugrahaning Gusti.
Ing donya iki ana rong warna sing diarani bener, yakuwi bener mungguhing Pangeran lan bener saka kang lagi kuwasa.
Ing ngarsa sung tuladha, ing madya mangun karsa, tut wuri andayani.
Iro yudho wicaksono
Jaman iku owah gingsir.
Kadangira pribadi ora beda karo jeneng sira pribadi, gelem nyambut gawe.
Kahanan donya ora langgeng, mula aja ngegungke kesugihan lan drajat ira, awit samangsa ana wolak-waliking jaman ora ngisin-isini.
Kahanan kang ana iki ora suwe mesthi ngalami owah gingsir, mula aja lali marang sapadha-padhaning tumitah.
Kakehan gludhug, kurang udan
Kaya banyu karo lenga
Kebo kabotan sungu.
Kebo nusu gudel.
Kegedhen empyak kurang cagak
Ketemu Gusti iku lamun sira tansah eling.
Krido lumahing asto.
Kutuk marani sunduk.
Lamun sira durung wikan alamira pribadi, mara takona marang wong kang wus wikan.
Lamun sira durung wikan kadangira pribadi, coba dulune sira pribadi.
Lamun sira kepengin wikan marang alam/ jaman kelanggengan, sira kudu weruh alamira pribadi. Lamun sira durung mikani alamira pribadi adoh ketemune.
Lamun sira pribadi wus bisa caturan karo lelembut, mesthi sira ora bakal ngala-alamarang wong kang wus bisa caturan karo lelembut.
Lamun sira wus mikani alamira pribadi, alam jaman kalanggengan iku cedhak tanpa senggolan, adoh tanpa wangenan.
Lelembut iku ana rong warna, yakuwi kang nyilakani lan kang mitulungi.
Mangan ora mangan ngumpul.
Manunggaling kawula gusti.
Manungsa iku bisa kadunungan dating Pangeran, nanging aja darbe pangira yen manungsa mau bisa diarani Pangeran.
Manungsa iku kanggonan sipating Pangeran.
Manungsa iku saka dating Pangeran mula uga darbe sipating Pangeran.
Mikul dhuwur, mendhem jero
Mimi lan mintuno.
Nabok nyilih tangan.
Nglurug tanpa bala, menang tanpa ngasorake.
Ngono ya ngono ning aja ngono.
Nguyahi banyu segara.
Ora ana kasekten sing madhani pepesthen, awit pepesthen iku wis ora ana sing bisa murungake.
Owah gingsiring kahanan iku saka karsaning Pangeran Kang Murbeng Jagad.
Pangeran bisa ngrusak kahanan kang wis ora diperlokake, lan bisa gawe kahanan anyar kang dipeerlokake.
Pangeran iku adoh tanpa wangenan, cedhak tanpa senggolan.
Pangeran iku ana ing ngendi papan, aneng sira uga ana Pangeran, nanging aja sira wani ngaku Pangeran.
Pangeran iku bisa mawujud, nanging wewujudan iki dudu Pangeran.
Pangeran iku bisa ngowahi kahanan iku wae tan kena kinaya ngapa.
Pangeran iku dudu dewa utawa manungsa, nanging sakabehing kang ana iki ugo dewa lan manungsa asale saka Pangeran.
Pangeran iku kuwasa tanpa piranti, akarya alam saisine, kang katon lan kang ora kasat mata.
Pangeran iku kuwasa tanpa piranti, mula saka kuwi aja darbe pengira yen manungsa iku bisa dadi wakiling Pangeran.
Pangeran iku kuwasa, dene manungsa iku bisa.
Pangeran iku langgeng, tan kena kinaya ngapa, sangkan paraning dumadi.
Pangeran iku maha kuwasa, pepesthen saka karsaning Pangeran ora ana sing bisa murungake.
Pangeran iku maha welas lan maha asih, hayuning bawana marga saka kanugrahaning Pangeran.
Pangeran iku menangake manungsa senajan kaya ngapa.
Pangeran iku ora ana sing padha, mula aja nggambar-nggambarake wujuding Pangeran.
Pangeran iku ora mbedak-mbedakake kawulane.
Pangeran iku ora sare.
Pangeran iku siji, ana ing ngendi papan, langgeng, sing nganakake jagad iki saisine, dadi sesembahane wong saalam kabeh, nganggo carane dhewe-dhewe.
Pangeran maringi kawruh marang manungsa bab anane titah alus mau.
Pangeran nitahake sira iku lantaran biyung ira, mula kudu ngurmat biyung ira.
Pasrah marang Pangeran iku ora ategas ora galem nyambut gawe, nanging percaya yren Pangeran iku Maha Kuwasa. Dena kasil orane apa kang kita tuju kuwi saka karsaning Pangeran.
Purwa madya wasana.
Rukun agawe santosa.
Sanubarang kang katon iki kalebu titah kang kasat mata, dene liyane kelebu titah alus.
Sapa sira sapa ingsun.
Sekabehing ngelmu iku asak saka Pangeran kang Mahakuwasa.
Sing bisa dadi utusaning Pangeran iku ora mung janma manungsa wae.
Sing sapa durung ngerti lamun piyandel iku kanggo pathokaning urip, iku sejatine durung ngerti lamun ana ing donya iki ana sing ngatur.
Sing sapa gelem nglakoni kebecikan lan ugo gelem lelaku, ing tembe bakal tampa kanugrahaning Pangeran.
Sing sapa mikani anane Pangeran, kalebu urip kang sempurna.
Sing sapa nyembah lelembut iku keliru, jalaran lelembut iku sejatine rowangira, lan ora perlu disembah kaya dene manebah marang Pangeran.
Sing sapa nyumurupi dating Pangeran iku ateges nyumurupi awake dhewe. Dene kang diurung mikani aawake dhewe durung mikani dating Pangeran.
Sing sapa wani ngowahi kahanan kang lagi ana, iku dudu sadhengah wong, nanging minangku utusaning Pangeran.
Titah alus iku ana patang warna, yakuwi kang bisa mrentah manungsa nanging ya bisa mitulungi manungsa, kapinhdo kang bisa mrentah manungsa nanging ora bisa mitulungi manungsa, katelu kang ora bisa mrentah manungsa nanging bisa mitulungi manungsa, kapat kang ora bisa mrentah manungsa nanging ya ora bisa mitulungi manungsa.
Titah alus iku ora bisa dadi manungsa lamun manungsa dhewe ora darbe penyuwun marang Pangeran supaya titah alus mau ngejawantah.
Titah alus lan titah kasat mata iku kabeh saka Pangeran, mula aja nyembah titah alus nanging aja ngina titah alus.
Urip iku saka Pangeran, bali marang Pangeran.
Wani ngalah, luhur wekasane.
Wani silit, wedi rai.
Watu kayu iku darbe dating Pangeran, nanging dudu Pangeran.
Weruh marang Pangeran iku ategas wis weruh marang awake dhewe, lamun durung weruh awake dhewe, tangeh lamun weruh marang Panngeran.
Witing tresna jalaran saka kulina.
Yen cocok karo benering Pangeran iku ategas bathara ngejawantah, nanging yan ora cocok karo benering Pangeran iku ategas titisaning brahala.
Yen sira wus mikani alamira pribadi, mana sira mulanga marang wong kang durung wikan.
Yen wedi aja wani-wani, yen wani aja wedi-wedi
surga manut neroko katut.
