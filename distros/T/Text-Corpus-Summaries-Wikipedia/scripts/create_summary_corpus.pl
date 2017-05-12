#!/usr/bin/env perl

use utf8;

#12345678901234567890123456789012345678901234
#Script to create corpus for summary testing.

=head1 NAME

create_summary_corpus.pl - Script to create corpus for summary testing.

=head1 SYNOPSIS

  create_summary_corpus.pl [-d corpusDirectory -l languageCode -p maxProcesses -h -t n]

=head1 DESCRIPTION

The script C<create_summary_corpus.pl> makes a corpus for summarization testing
using the featured articles of various Wikipedias.

All errors and warnings are logged using L<Log::Log4perl> to the file C<corpusDirectory/languageCode/log.txt>.

=head1 OPTIONS

=head2 C<-d corpusDirectory>

The option C<-d> sets the directory to store the corpus of documents;
the directory is created if it does not exist. The default is the C<cwd>.

A language subdirectory is created at C<corpusDirectory/languageCode> that
will contain the directories C<log>, C<html>, C<unparsable>, C<text>, and C<xml>.  The directory
C<log> will contain the file C<log.txt> that all errors, warnings, and
informational messages are logged to using L<Log::Log4perl>. The directory
C<html> will contain copies of the HTML versions of the featured
article pages fetched using L<LWP>. The directory C<text>
will contain two files for each article; one file will end with C<_body.txt>
and contain the body text of the article, the other will end with
C<_summary.txt> and will contain the summary. The directory C<unparsable> will contain the
HTML files that could not be parsed into I<body> and I<summary> sections. The XML files
are UTF8 encoded, the text and html files are saved as UTF8 octets.

=head2 C<-l languageCode>

The option C<-l> sets the language code of the Wikipedia from which the
corpus of featured articles are to be created. The supported language codes are
C<af>:Afrikaans, C<ar>:Arabic, C<az>:Azerbaijani, C<bg>:Bulgarian, C<bs>:Bosnian, C<ca>:Catalan, 
C<cs>:Czech, C<de>:German, C<el>:Greek, C<en>:English, C<eo>:Esperanto, C<es>:Spanish, C<eu>:Basque, 
C<fa>:Persian, C<fi>:Finnish, C<fr>:French, C<he>:Hebrew, C<hr>:Croatian, C<hu>:Hungarian, 
C<id>:Indonesian, C<it>:Italian, C<ja>:Japanese, C<jv>:Javanese, C<ka>:Georgian, C<kk>:Kazakh, 
C<km>:Khmer, C<ko>:Korean, C<li>:Limburgish, C<lv>:Latvian, C<ml>:Malayalam, C<mr>:Marathi, 
C<ms>:Malay, C<mzn>:Mazandarani, C<nl>:Dutch, C<nn>:Norwegian (Nynorsk), C<no>:Norwegian (Bokm?l), 
C<pl>:Polish, C<pt>:Portuguese, C<ro>:Romanian, C<ru>:Russian, C<sh>:Serbo-Croatian, 
C<simple>:Simple English, C<sk>:Slovak, C<sl>:Slovenian, C<sr>:Serbian, C<sv>:Swedish, 
C<sw>:Swahili, C<ta>:Tamil, C<th>:Thai, C<tl>:Tagalog, C<tr>:Turkish, C<tt>:Tatar, 
C<uk>:Ukrainian, C<ur>:Urdu, C<vi>:Vietnamese, C<vo>:Volap?k, and C<zh>:Chinese.
If the language code is C<all>, then the corpus for each supported language is
created (which takes a long time). The default is C<en>.

=head2 C<-p maxProcesses>

 maxProcesses => 1

The option C<-p> is the maximum number of processes that can be running
simultaneously to parse the files. Parsing the files for the summary
and body sections may be computational intensive so the module L<Forks::Super> is used
for parallelization. The default is one.

=head2 C<-r>

Causes only the text and XML files from all the HTML files that have already been fetched to
be created; no new files are downloaded.

=head2 C<-h>

Makes this documentation print.

=head2 C<-t 0>

The option C<-t> initiates testing mode; only the specified number of pages are fetched and parsed.
The default is zero, indicating no testing, all possible pages are fetched and parsed.

=head1 BUGS

This script creates corpora by parsing Wikipedia pages, the xpath
expressions used to extract links and text will become invalid as the format
of the various pages changes, causing some corpora not to be created.

Please email bugs reports or feature requests to C<bug-text-corpus-summaries-wikipedia@rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Corpus-Summaries-Wikipedia>.  The author
will be notified and you can be automatically notified of progress on the bug fix or feature request.

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2010 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

corpus, information processing, summaries, summarization, wikipedia

=head1 SEE ALSO

L<Forks::Super>, L<Log::Log4perl>, L<Text::Corpus::Summaries::Wikipedia>

=begin html

<p>
Links to the featured article page for the supported language codes:
<a href="http://af.wikipedia.org/wiki/Wikipedia:Voorbladartikel">af:Afrikaans</a>,
<a href="http://ar.wikipedia.org/wiki/%D9%88%D9%8A%D9%83%D9%8A%D8%A8%D9%8A%D8%AF%D9%8A%D8%A7:%D9%85%D9%82%D8%A7%D9%84%D8%A7%D8%AA_%D9%85%D8%AE%D8%AA%D8%A7%D8%B1%D8%A9">ar:Arabic</a>,
<a href="http://az.wikipedia.org/wiki/Vikipediya:Se%C3%A7ilmi%C5%9F_m%C9%99qal%C9%99l%C9%99r">az:Azerbaijani</a>,
<a href="http://bg.wikipedia.org/wiki/%D0%A3%D0%B8%D0%BA%D0%B8%D0%BF%D0%B5%D0%B4%D0%B8%D1%8F:%D0%98%D0%B7%D0%B1%D1%80%D0%B0%D0%BD%D0%B8_%D1%81%D1%82%D0%B0%D1%82%D0%B8%D0%B8">bg:Bulgarian</a>,
<a href="http://bs.wikipedia.org/wiki/Wikipedia:Odabrani_%C4%8Dlanci">bs:Bosnian</a>,
<a href="http://ca.wikipedia.org/wiki/Viquip%C3%A8dia:Articles_de_qualitat">ca:Catalan</a>,
<a href="http://cs.wikipedia.org/wiki/Wikipedie:Nejlep%C5%A1%C3%AD_%C4%8Dl%C3%A1nky">cs:Czech</a>,
<a href="http://de.wikipedia.org/wiki/Wikipedia:Exzellente_Artikel">de:German</a>,
<a href="http://el.wikipedia.org/wiki/%CE%92%CE%B9%CE%BA%CE%B9%CF%80%CE%B1%CE%AF%CE%B4%CE%B5%CE%B9%CE%B1:%CE%91%CE%BE%CE%B9%CF%8C%CE%BB%CE%BF%CE%B3%CE%B1_%CE%AC%CF%81%CE%B8%CF%81%CE%B1">el:Greek</a>,
<a href="http://en.wikipedia.org/wiki/Wikipedia:FA">en:English</a>,
<a href="http://eo.wikipedia.org/wiki/Vikipedio:Elstaraj_artikoloj">eo:Esperanto</a>,
<a href="http://es.wikipedia.org/wiki/Wikipedia:Art%C3%ADculos_destacados">es:Spanish</a>,
<a href="http://eu.wikipedia.org/wiki/Wikipedia:Nabarmendutako_artikuluak">eu:Basque</a>,
<a href="http://fa.wikipedia.org/wiki/%D9%88%DB%8C%DA%A9%DB%8C%E2%80%8C%D9%BE%D8%AF%DB%8C%D8%A7:%D9%85%D9%82%D8%A7%D9%84%D9%87%E2%80%8C%D9%87%D8%A7%DB%8C_%D8%A8%D8%B1%DA%AF%D8%B2%DB%8C%D8%AF%D9%87">fa:Persian</a>,
<a href="http://fi.wikipedia.org/wiki/Wikipedia:Suositellut_artikkelit">fi:Finnish</a>,
<a href="http://fr.wikipedia.org/wiki/Wikip%C3%A9dia:Articles_de_qualit%C3%A9">fr:French</a>,
<a href="http://he.wikipedia.org/wiki/%D7%A4%D7%95%D7%A8%D7%98%D7%9C:%D7%A2%D7%A8%D7%9B%D7%99%D7%9D_%D7%9E%D7%95%D7%9E%D7%9C%D7%A6%D7%99%D7%9D">he:Hebrew</a>,
<a href="http://hr.wikipedia.org/wiki/Wikipedija:Izabrani_%C4%8Dlanci">hr:Croatian</a>,
<a href="http://hu.wikipedia.org/wiki/Wikip%C3%A9dia:Kiemelt_sz%C3%B3cikkek_bemutat%C3%B3ja">hu:Hungarian</a>,
<a href="http://id.wikipedia.org/wiki/Wikipedia:Artikel_pilihan/Topik">id:Indonesian</a>,
<a href="http://it.wikipedia.org/wiki/Wikipedia:Vetrina">it:Italian</a>,
<a href="http://ja.wikipedia.org/wiki/Wikipedia:%E7%A7%80%E9%80%B8%E3%81%AA%E8%A8%98%E4%BA%8B">ja:Japanese</a>,
<a href="http://jv.wikipedia.org/wiki/Wikipedia:Artikel_pilihan">jv:Javanese</a>,
<a href="http://ka.wikipedia.org/wiki/%E1%83%95%E1%83%98%E1%83%99%E1%83%98%E1%83%9E%E1%83%94%E1%83%93%E1%83%98%E1%83%90:%E1%83%A0%E1%83%A9%E1%83%94%E1%83%A3%E1%83%9A%E1%83%98_%E1%83%A1%E1%83%A2%E1%83%90%E1%83%A2%E1%83%98%E1%83%94%E1%83%91%E1%83%98">ka:Georgian</a>,
<a href="http://kk.wikipedia.org/wiki/%D0%A3%D0%B8%D0%BA%D0%B8%D0%BF%D0%B5%D0%B4%D0%B8%D1%8F:%D0%A2%D0%B0%D2%A3%D0%B4%D0%B0%D1%83%D0%BB%D1%8B_%D0%BC%D0%B0%D2%9B%D0%B0%D0%BB%D0%B0%D0%BB%D0%B0%D1%80">kk:Kazakh</a>,
<a href="http://km.wikipedia.org/wiki/%E1%9E%9C%E1%9E%B7%E1%9E%82%E1%9E%B8%E1%9E%97%E1%9E%B8%E1%9E%8C%E1%9E%B6:%E1%9E%A2%E1%9E%8F%E1%9F%92%E1%9E%90%E1%9E%94%E1%9E%91%E1%9E%96%E1%9E%B7%E1%9E%9F%E1%9F%81%E1%9E%9F">km:Khmer</a>,
<a href="http://ko.wikipedia.org/wiki/%EC%9C%84%ED%82%A4%EB%B0%B1%EA%B3%BC:%EC%95%8C%EC%B0%AC_%EA%B8%80">ko:Korean</a>,
<a href="http://li.wikipedia.org/wiki/Wikipedia:Sjterartikel">li:Limburgish</a>,
<a href="http://lv.wikipedia.org/wiki/Vikip%C4%93dija:V%C4%93rt%C4%ABgi_raksti">lv:Latvian</a>,
<a href="http://ml.wikipedia.org/wiki/%E0%B4%B5%E0%B4%BF%E0%B4%95%E0%B5%8D%E0%B4%95%E0%B4%BF%E0%B4%AA%E0%B5%80%E0%B4%A1%E0%B4%BF%E0%B4%AF:%E0%B4%A4%E0%B4%BF%E0%B4%B0%E0%B4%9E%E0%B5%8D%E0%B4%9E%E0%B5%86%E0%B4%9F%E0%B5%81%E0%B4%A4%E0%B5%8D%E0%B4%A4_%E0%B4%B2%E0%B5%87%E0%B4%96%E0%B4%A8%E0%B4%99%E0%B5%8D%E0%B4%99%E0%B4%B3%E0%B5%8D%E2%80%8D">ml:Malayalam</a>,
<a href="http://mr.wikipedia.org/wiki/%E0%A4%B5%E0%A4%BF%E0%A4%95%E0%A4%BF%E0%A4%AA%E0%A5%80%E0%A4%A1%E0%A4%BF%E0%A4%AF%E0%A4%BE:%E0%A4%AE%E0%A4%BE%E0%A4%B8%E0%A4%BF%E0%A4%95_%E0%A4%B8%E0%A4%A6%E0%A4%B0/%E0%A4%AE%E0%A4%BE%E0%A4%97%E0%A5%80%E0%A4%B2_%E0%A4%85%E0%A4%82%E0%A4%95_%E0%A4%B8%E0%A4%82%E0%A4%97%E0%A5%8D%E0%A4%B0%E0%A4%B9">mr:Marathi</a>,
<a href="http://ms.wikipedia.org/wiki/Wikipedia:Rencana_pilihan">ms:Malay</a>,
<a href="http://mzn.wikipedia.org/wiki/%D9%88%DB%8C%DA%A9%DB%8C%E2%80%8C%D9%BE%D8%AF%DB%8C%D8%A7:%D8%AE%D8%A7%D8%B1_%D8%A8%D9%86%D9%88%DB%8C%D8%B4%D8%AA%D9%87">mzn:Mazandarani</a>,
<a href="http://nl.wikipedia.org/wiki/Wikipedia:Etalage">nl:Dutch</a>,
<a href="http://nn.wikipedia.org/wiki/Wikipedia:Gode_artiklar">nn:Norwegian (Nynorsk)</a>,
<a href="http://no.wikipedia.org/wiki/Wikipedia:Utmerkede_artikler">no:Norwegian (Bokm?l)</a>,
<a href="http://pl.wikipedia.org/wiki/Wikipedia:Artyku%C5%82y_na_medal">pl:Polish</a>,
<a href="http://pt.wikipedia.org/wiki/Wikipedia:Artigos_destacados">pt:Portuguese</a>,
<a href="http://ro.wikipedia.org/wiki/Wikipedia:Articole_de_calitate">ro:Romanian</a>,
<a href="http://ru.wikipedia.org/wiki/%D0%92%D0%B8%D0%BA%D0%B8%D0%BF%D0%B5%D0%B4%D0%B8%D1%8F:%D0%98%D0%B7%D0%B1%D1%80%D0%B0%D0%BD%D0%BD%D1%8B%D0%B5_%D1%81%D1%82%D0%B0%D1%82%D1%8C%D0%B8">ru:Russian</a>,
<a href="http://sh.wikipedia.org/wiki/Wikipedia:Izabrani_%C4%8Dlanci">sh:Serbo-Croatian</a>,
<a href="http://simple.wikipedia.org/wiki/Wikipedia:Very_good_articles/by_date">simple:Simple English</a>,
<a href="http://sk.wikipedia.org/wiki/Wikip%C3%A9dia:Zoznam_najlep%C5%A1%C3%ADch_%C4%8Dl%C3%A1nkov">sk:Slovak</a>,
<a href="http://sl.wikipedia.org/wiki/Wikipedija:Izbrani_%C4%8Dlanki">sl:Slovenian</a>,
<a href="http://sr.wikipedia.org/wiki/%D0%92%D0%B8%D0%BA%D0%B8%D0%BF%D0%B5%D0%B4%D0%B8%D1%98%D0%B0:%D0%A1%D1%98%D0%B0%D1%98%D0%BD%D0%B8_%D1%82%D0%B5%D0%BA%D1%81%D1%82%D0%BE%D0%B2%D0%B8">sr:Serbian</a>,
<a href="http://sv.wikipedia.org/wiki/Wikipedia:Utm%C3%A4rkta_artiklar">sv:Swedish</a>,
<a href="http://sw.wikipedia.org/wiki/Wikipedia:Featured_articles">sw:Swahili</a>,
<a href="http://ta.wikipedia.org/wiki/%E0%AE%B5%E0%AE%BF%E0%AE%95%E0%AF%8D%E0%AE%95%E0%AE%BF%E0%AE%AA%E0%AF%8D%E0%AE%AA%E0%AF%80%E0%AE%9F%E0%AE%BF%E0%AE%AF%E0%AE%BE:%E0%AE%9A%E0%AE%BF%E0%AE%B1%E0%AE%AA%E0%AF%8D%E0%AE%AA%E0%AF%81%E0%AE%95%E0%AF%8D_%E0%AE%95%E0%AE%9F%E0%AF%8D%E0%AE%9F%E0%AF%81%E0%AE%B0%E0%AF%88%E0%AE%95%E0%AE%B3%E0%AF%8D">ta:Tamil</a>,
<a href="http://th.wikipedia.org/wiki/%E0%B8%A7%E0%B8%B4%E0%B8%81%E0%B8%B4%E0%B8%9E%E0%B8%B5%E0%B9%80%E0%B8%94%E0%B8%B5%E0%B8%A2:%E0%B8%9A%E0%B8%97%E0%B8%84%E0%B8%A7%E0%B8%B2%E0%B8%A1%E0%B8%84%E0%B8%B1%E0%B8%94%E0%B8%AA%E0%B8%A3%E0%B8%A3">th:Thai</a>,
<a href="http://tl.wikipedia.org/wiki/Wikipedia:Mga_napiling_artikulo">tl:Tagalog</a>,
<a href="http://tr.wikipedia.org/wiki/Vikipedi:Se%C3%A7kin_maddeler">tr:Turkish</a>,
<a href="http://tt.wikipedia.org/wiki/%D0%92%D0%B8%D0%BA%D0%B8%D0%BF%D0%B5%D0%B4%D0%B8%D1%8F:%D0%A1%D0%B0%D0%B9%D0%BB%D0%B0%D0%BD%D0%B3%D0%B0%D0%BD_%D0%BC%D3%99%D0%BA%D0%B0%D0%BB%D3%99%D0%BB%D3%99%D1%80">tt:Tatar</a>,
<a href="http://uk.wikipedia.org/wiki/%D0%92%D1%96%D0%BA%D1%96%D0%BF%D0%B5%D0%B4%D1%96%D1%8F:%D0%92%D0%B8%D0%B1%D1%80%D0%B0%D0%BD%D1%96_%D1%81%D1%82%D0%B0%D1%82%D1%82%D1%96">uk:Ukrainian</a>,
<a href="http://ur.wikipedia.org/wiki/%D9%85%D9%86%D8%B5%D9%88%D8%A8%DB%81:%D9%85%D9%86%D8%AA%D8%AE%D8%A8_%D9%85%D8%B6%D9%85%D9%88%D9%86">ur:Urdu</a>,
<a href="http://vi.wikipedia.org/wiki/Wikipedia:B%C3%A0i_vi%E1%BA%BFt_ch%E1%BB%8Dn_l%E1%BB%8Dc">vi:Vietnamese</a>,
<a href="http://vo.wikipedia.org/wiki/V%C3%BCkiped:Yegeds_gudik">vo:Volap?k</a>, and
<a href="http://zh.wikipedia.org/wiki/Wikipedia:%E7%89%B9%E8%89%B2%E6%9D%A1%E7%9B%AE">zh:Chinese</a>.
</p>

<p>
Copies of the data sets generated in May 2010 and February 2013 can be download <a href="http://jeffkubina.org/data/wfa">here</a>.
</p>

=end html

=cut

use strict;
use warnings;
use Text::Corpus::Summaries::Wikipedia;
use Data::Dump qw(dump);
use Getopt::Long;
use File::Basename;
use File::Path;
use Cwd qw(getcwd abs_path);
use Pod::Usage;
use XML::Code;

my $el = "\n";

my $totalArguments = @ARGV;

# set the default $corpusDirectory.
my $corpusDirectory = getcwd;
$corpusDirectory = $ENV{TEXT_CORPUS_SUMMARIES_CORPUSDIRECTORY} if exists $ENV{TEXT_CORPUS_SUMMARIES_CORPUSDIRECTORY};
$corpusDirectory = File::Spec->catfile($ENV{HOME}, 'projects/corpora/summaries2');

# get the options.
my $languageCode = 'all';

my $helpMessage  = 0;
my $maxProcesses = 1;
my $recreate     = 0;
my $test         = 0;
my $result = GetOptions(
												"d:s"    => \$corpusDirectory,
												"l:s"    => \$languageCode,
												"h|help" => \$helpMessage,
												'p:i'    => \$maxProcesses,
												"r"      => \$recreate,
												"t:i"    => \$test
);

# force the lanuage code to lowercase.
$languageCode = lc $languageCode;

# make sure $maxProcesses is a sane value;
$maxProcesses = int abs $maxProcesses;
$maxProcesses = 1 unless $maxProcesses;

# print info message
if ($helpMessage || ($totalArguments == 0))
{
	pod2usage({ -verbose => 1, -output => \*STDOUT });
	exit 0;
}

#$corpusDirectory = '/tmp/sum2';
#$languageCode = 'all';
#$test = 3;

# get the default path for the corpus directory.
$corpusDirectory = abs_path(getcwd) unless (defined $corpusDirectory);

# create the corpusDirectory.
mkpath($corpusDirectory, 0, 0700);
unless (-e $corpusDirectory)
{
	die("corpus directory '" . $corpusDirectory . "' does not exist and could not be created.");
}

my @listOfLanguageCodes;

# if the corpus is 'all', then all of them will be created.
if ($languageCode eq 'all')
{
	# get the list of all supported language codes.
	@listOfLanguageCodes = Text::Corpus::Summaries::Wikipedia::getListOfSupportedLanguageCodes();
}
else
{
	push @listOfLanguageCodes, $languageCode;
}

# build the corpus for each language.
foreach my $languageCode (@listOfLanguageCodes)
{
	eval {
		my $corpus = Text::Corpus::Summaries::Wikipedia->new(languageCode => $languageCode, corpusDirectory => $corpusDirectory);
		if ($recreate) { $corpus->recreate(maxProcesses => $maxProcesses, test => $test); }
		else           { $corpus->create(maxProcesses => $maxProcesses, test => $test); }
	};
	if ($@)
	{
		warn $@;
	}
}

