#!/usr/bin/env perl
use lib qw/ data lib /;
use Text::Summarizer;
use utf8;

use Test::More;
use List::AllUtils qw/ all all_u /;


#test object instantiation
my $summarizer = new_ok( Text::Summarizer => [ articles_path => "articles/*" ] );


#test default datafile existence
subtest 'Datafile Attributes Set' => sub {
	my $paths = ['data/permanent.stop','data/stopwords.stop','data/watchlist.stop'];
	is $summarizer->permanent_path, $paths->[0] => "permanent path is '$paths->[0]'";
	is $summarizer->stopwords_path, $paths->[1] => "stopwords path is '$paths->[1]'";
};


#test structure of summaries returned from summarize function
sub summary_test {
	my @summaries = @_;

	if ( ok all_u( sub { ref $_ eq 'HASH' } => @summaries), 'summaries in hash form' ) {
		 ok all_u( sub { exists $_->{sentences} && exists $_->{fragments} && exists $_->{words} } => @summaries), 'summaries contain sentences, fragments, and words' ;

		 ok all_u( sub { all_u( sub { $_ > 0 } => values %{$_->{sentences}} ) } => @summaries ), 'all sentences scored';
		 ok all_u( sub { all_u( sub { $_ > 0 } => values %{$_->{fragments}} ) } => @summaries ), 'all fragments scored';
		 ok all_u( sub { all_u( sub { $_ > 0 } => values %{$_->{  words  }} ) } => @summaries ), 'all words are scored';

		 ok all_u( sub { all_u( sub { /(?<!\s[A-Z][a-z]) (?<!\s[A-Z][a-z]{2}) \. (?![A-Z]\.|\s[a-z0-9]) | \! | \? | : | \b\Z/x } => keys %{$_->{sentences}} ) } => @summaries ), 'sentences look sentency';
		 ok all_u( sub { all_u( sub { /(?: \( [\w'’-]+ (?: \| [\w'’-]+ )*  \) ) | (?: [\w'’-]+ (?: \s [\w'’-]+ )* )/x } => keys %{$_->{fragments}} ) } => @summaries ), 'fragments look fragmenty';
		 ok all_u( sub { all_u( sub { /[\w'’-]+/x } => keys %{$_->{  words  }} ) } => @summaries ), 'all words look like words';
	}
}


sub scanner_test {
	my @results = @_;

	if ( ok all_u( sub { ref $_ eq 'HASH' } => @results), 'all scanner results in hash form' ) {
		 ok all_u( sub { all_u( sub { /[\w'’-]+/x } => keys %{$_} ) } => @results ), 'all scanner results look like word-lists'
	}
}


my $some_text = <<'END_SAMPLE';
	Avram Noam Chomsky, born December 7, 1928) is an American linguist, cognitive scientist, historian, social critic, and political activist. Sometimes described as "the father of modern linguistics," Chomsky is also one of the founders of the field of cognitive science. He is the author of over 100 books on topics such as linguistics, war, politics, and mass media. Ideologically, he aligns with anarcho-syndicalism and libertarian socialism. He holds a joint appointment as Institute Professor Emeritus at the Massachusetts Institute of Technology (MIT) and laureate professor at the University of Arizona.[22][23]

	Born to middle-class Ashkenazi Jewish immigrants in Philadelphia, Chomsky developed an early interest in anarchism from alternative bookstores in New York City. At the age of 16 he began studies at the University of Pennsylvania, taking courses in linguistics, mathematics, and philosophy. From 1951 to 1955 he was appointed to Harvard University's Society of Fellows, where he developed the theory of transformational grammar for which he was awarded his doctorate in 1955. That year he began teaching at MIT, in 1957 emerging as a significant figure in the field of linguistics for his landmark work Syntactic Structures, which remodeled the scientific study of language, while from 1958 to 1959 he was a National Science Foundation fellow at the Institute for Advanced Study. He is credited as the creator or co-creator of the universal grammar theory, the generative grammar theory, the Chomsky hierarchy, and the minimalist program. Chomsky also played a pivotal role in the decline of behaviorism, being particularly critical of the work of B. F. Skinner.

	An outspoken opponent of U.S. involvement in the Vietnam War, which he saw as an act of American imperialism, in 1967 Chomsky attracted widespread public attention for his anti-war essay "The Responsibility of Intellectuals". Associated with the New Left, he was arrested multiple times for his activism and placed on President Richard Nixon's Enemies List. While expanding his work in linguistics over subsequent decades, he also became involved in the Linguistics Wars. In collaboration with Edward S. Herman, Chomsky later co-wrote an analysis articulating the propaganda model of media criticism, and worked to expose the Indonesian occupation of East Timor. Additionally, his defense of unconditional freedom of speech – including for Holocaust deniers – generated significant controversy in the Faurisson affair of the early 1980s. Following his retirement from active teaching, he has continued his vocal political activism, including opposing the War on Terror and supporting the Occupy movement.

	One of the most cited scholars in history, Chomsky has influenced a broad array of academic fields. He is widely recognized as a paradigm shifter who helped spark a major revolution in the human sciences, contributing to the development of a new cognitivistic framework for the study of language and the mind. In addition to his continued scholarly research, he remains a leading critic of U.S. foreign policy, neoliberalism and contemporary state capitalism, the Israeli–Palestinian conflict, and mainstream news media. His ideas have proved highly significant within the anti-capitalist and anti-imperialist movements. Some of his critics have accused him of anti-Americanism.
END_SAMPLE


my @each_summ = $summarizer->summ_each();
my $file_summ = $summarizer->summ_file("articles/17900108-Washington.txt");
my $text_summ = $summarizer->summ_text($some_text);

subtest 'Summ Each - Structure Intact' => sub { summary_test(@each_summ) };
subtest 'Summ File - Structure Intact' => sub { summary_test($file_summ) };
subtest 'Summ Text - Structure Intact' => sub { summary_test($text_summ) };

my @each_scan = $summarizer->scan_each();
my $file_scan = $summarizer->scan_file("articles/17900108-Washington.txt");
my $text_scan = $summarizer->scan_text($some_text);

subtest 'Scan Each - Structure Intact' => sub { scanner_test(@each_summ) };
subtest 'Scan File - Structure Intact' => sub { scanner_test($file_summ) };
subtest 'Scan Text - Structure Intact' => sub { scanner_test($text_summ) };

done_testing();