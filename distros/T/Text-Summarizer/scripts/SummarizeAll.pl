#!/usr/bin/env perl
use lib 'lib';
use Text::Summarizer;
use utf8;

my $summarizer = Text::Summarizer->new( print_working => 0, print_scanner => 0, print_summary => 0, print_graphs => 0, print_typifier => 1 );

my $sample_text = <<'END_SAMPLE';
  Avram Noam Chomsky (born December 7, 1928) is an American linguist, cognitive scientist, historian, social critic, and political activist. Sometimes described as "the father of modern linguistics," Chomsky is also one of the founders of the field of cognitive science. He is the author of over 100 books on topics such as linguistics, war, politics, and mass media. Ideologically, he aligns with anarcho-syndicalism and libertarian socialism. He holds a joint appointment as Institute Professor Emeritus at the Massachusetts Institute of Technology (MIT) and laureate professor at the University of Arizona.[22][23]  Born to middle-class Ashkenazi Jewish immigrants in Philadelphia, Chomsky developed an early interest in anarchism from alternative bookstores in New York City. At the age of 16 he began studies at the University of Pennsylvania, taking courses in linguistics, mathematics, and philosophy. From 1951 to 1955 he was appointed to Harvard University's Society of Fellows, where he developed the theory of transformational grammar for which he was awarded his doctorate in 1955. That year he began teaching at MIT, in 1957 emerging as a significant figure in the field of linguistics for his landmark work Syntactic Structures, which remodeled the scientific study of language, while from 1958 to 1959 he was a National Science Foundation fellow at the Institute for Advanced Study. He is credited as the creator or co-creator of the universal grammar theory, the generative grammar theory, the Chomsky hierarchy, and the minimalist program. Chomsky also played a pivotal role in the decline of behaviorism, being particularly critical of the work of B. F. Skinner.  An outspoken opponent of U.S. involvement in the Vietnam War, which he saw as an act of American imperialism, in 1967 Chomsky attracted widespread public attention for his anti-war essay "The Responsibility of Intellectuals". Associated with the New Left, he was arrested multiple times for his activism and placed on President Richard Nixon's Enemies List. While expanding his work in linguistics over subsequent decades, he also became involved in the Linguistics Wars. In collaboration with Edward S. Herman, Chomsky later co-wrote an analysis articulating the propaganda model of media criticism, and worked to expose the Indonesian occupation of East Timor. Additionally, his defense of unconditional freedom of speech – including for Holocaust deniers – generated significant controversy in the Faurisson affair of the early 1980s. Following his retirement from active teaching, he has continued his vocal political activism, including opposing the War on Terror and supporting the Occupy movement.  One of the most cited scholars in history, Chomsky has influenced a broad array of academic fields. He is widely recognized as a paradigm shifter who helped spark a major revolution in the human sciences, contributing to the development of a new cognitivistic framework for the study of language and the mind. In addition to his continued scholarly research, he remains a leading critic of U.S. foreign policy, neoliberalism and contemporary state capitalism, the Israeli–Palestinian conflict, and mainstream news media. His ideas have proved highly significant within the anti-capitalist and anti-imperialist movements. Some of his critics have accused him of anti-Americanism.
END_SAMPLE

#my $text_words = $summarizer->scan_text($sample_text);
#my $text_summs = $summarizer->summ_text($sample_text);

#my $file_words = $summarizer->scan_file("articles/17900108-Washington.txt");
#my $file_summs = $summarizer->summ_file("articles/17900108-Washington.txt");

#my @each_words = $summarizer->scan_each();
#my @each_summs = $summarizer->summ_each("articles/*");

#summarizer->summ_each();

$summarizer->summ_file("articles/001.html");