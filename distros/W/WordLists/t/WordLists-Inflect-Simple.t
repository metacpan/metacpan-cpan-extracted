#!perl -w
use WordLists::Inflect::Simple;
use Data::Dumper;
use Test::More;

my $tests = {
	regular_inflection=>[
		{pos=>'n', type=>'singular', w=>'test', expected=>'test', motive=>'simple test case'},
		{pos=>'n', type=>'plural', w=>'test', expected=>'tests', motive=>'simple test case'},
		{pos=>'n', type=>'plural', w=>'gas', expected=>'gases', motive=>'special case s'},
		{pos=>'adj', type=>'comparative', w=>'light', expected=>'lighter', motive=>'simple test case'},
		{pos=>'adj', type=>'superlative', w=>'light', expected=>'lightest', motive=>'simple test case'},
		{pos=>'adj', type=>'comparative', w=>'noble', expected=>'nobler', motive=>'special case: e'},
		{pos=>'adj', type=>'superlative', w=>'grumpy', expected=>'grumpiest', motive=>'special case: y'},
		{pos=>'adj', type=>'superlative', w=>'exciting', expected=>'most exciting', motive=>'3-syllable adjective'},
		{pos=>'v', type=>'present_participle', w=>'test', expected=>'testing', motive=>'simple test case'},
		{pos=>'v', type=>'present_3rd_person', w=>'test', expected=>'tests', motive=>'simple test case'},
		{pos=>'v', type=>'past_participle', w=>'test', expected=>'tested', motive=>'simple test case'},
		{pos=>'v', type=>'past_tense', w=>'test', expected=>'tested', motive=>'simple test case'},
		{pos=>'v', type=>'present_participle', w=>'dry', expected=>'drying', motive=>'special case y'},
		{pos=>'v', type=>'present_3rd_person', w=>'dry', expected=>'dries', motive=>'special case y'},
		{pos=>'v', type=>'past_participle', w=>'dry', expected=>'dried', motive=>'special case y'},
		{pos=>'v', type=>'present_participle', w=>'stay', expected=>'staying', motive=>'special case y (vowel preceding)'},
		{pos=>'v', type=>'present_3rd_person', w=>'stay', expected=>'stays', motive=>'special case y (vowel preceding)'},
		{pos=>'v', type=>'past_participle', w=>'stay', expected=>'stayed', motive=>'special case y (vowel preceding)'},
		{pos=>'v', type=>'present_participle', w=>'guess', expected=>'guessing', motive=>'special case s'},
		{pos=>'v', type=>'present_3rd_person', w=>'guess', expected=>'guesses', motive=>'special case s'},
		{pos=>'v', type=>'past_participle', w=>'guess', expected=>'guessed', motive=>'special case s'},
		{pos=>'v', type=>'present_participle', w=>'inch', expected=>'inching', motive=>'special case s (ch)'},
		{pos=>'v', type=>'present_3rd_person', w=>'inch', expected=>'inches', motive=>'special case s (ch)'},
		{pos=>'v', type=>'past_participle', w=>'inch', expected=>'inched', motive=>'special case s (ch)'},
		{pos=>'v', type=>'present_participle', w=>'tone', expected=>'toning', motive=>'special case e'},
		{pos=>'v', type=>'present_3rd_person', w=>'tone', expected=>'tones', motive=>'special case e'},
		{pos=>'v', type=>'past_participle', w=>'tone', expected=>'toned', motive=>'special case e'},
		{pos=>'v', type=>'present_participle', w=>'tee', expected=>'teeing', motive=>'special case e (e preceding)'},
		{pos=>'v', type=>'present_3rd_person', w=>'tee', expected=>'tees', motive=>'special case e (e preceding)'},
		{pos=>'v', type=>'past_participle', w=>'tee', expected=>'teed', motive=>'special case e (e preceding)'},
	],
	phrase_inflection=>[
		{pos=>'n', type=>'plural', w=>'noble gas', expected=>'noble gases', motive=>'Compound Noun - inflect last part'},
		{pos=>'n', type=>'plural', w=>'top-up card', expected=>'top-up cards', motive=>'Compound Noun - inflect last part even if previous part is hyphenated'},
		{pos=>'n', type=>'plural', w=>'man of straw', expected=>'men of straw', motive=>'Compound Noun - X of Y : Xs of Y'},
		{pos=>'v', type=>'present_participle', w=>'lock away', expected=>'locking away', motive=>'PV - inflect first part'},
		{pos=>'v', type=>'present_participle', w=>'absolve yourself of something', expected=>'absolving yourself of something', motive=>'PV+ys+sth - inflect first part'},
		{pos=>'v', type=>'present_participle', w=>'left-click', expected=>'left-clicking', motive=>'Hyphenated verb - inflect last part'},
		{pos=>'adj', type=>'comparative', w=>'above board', expected=>'more above board', motive=>'compound comparative adjective'},
		{pos=>'adj', type=>'superlative', w=>'above board', expected=>'most above board', motive=>'compound superlative adjective'},
	],
};


my $inflector = WordLists::Inflect::Simple->new;
foreach (@{$tests->{regular_inflection}})
{
	is (
		$inflector->regular_inflection({w=>$_->{'w'}, pos=>$_->{'pos'}, type=>$_->{'type'}}),
		$_->{'expected'},
		'regular_inflection: ' . $_->{'w'} . ' (' . $_->{'pos'} . ' ' . $_->{'type'} . ') - ' . $_->{'motive'}
	);
}
foreach (@{$tests->{phrase_inflection}})
{
	is ($inflector->phrase_inflection({w=>$_->{'w'}, pos=>$_->{'pos'}, type=>$_->{'type'}}), 
		$_->{'expected'},
		'phrase_inflection: ' . $_->{'w'} . ' (' . $_->{'pos'} . ' ' . $_->{'type'} . ') - ' . $_->{'motive'}
	);
}
$inflector->add_special_case('general');
is_deeply(
	$inflector->all_inflections({w=>'light'}),
	{
		'n' => {
			'plural' => 'lights',
			'singular' => 'light'
		},
		'adj' => {
			'comparative' => 'lighter',
			'superlative' => 'lightest'
		},
		'v' => {
			'past_participle' => 'lighted',
			'present_3rd_person' => 'lights',
			'infinitive' => 'light',
			'past_tense' => 'lighted',
			'present_participle' => 'lighting',
			'present_2nd_person_plural' => 'light',
			'present_2nd_person' => 'light',
			'present_3rd_person_plural' => 'light',
			'present_1st_person_plural' => 'light',
			'present_1st_person' => 'light'
		}
	},'is_deeply will fail'
);	

$inflector->add_irregular_word({w=>'light', past_participle=>'lit' });
is ($inflector->phrase_inflection({w=>'light', pos=>'v', type=>'past_participle'}), 'lit', 'add irregular inflection');
$inflector->add_irregular_word({w=>'light', n=>{plural=>'lightses'} });
is ($inflector->phrase_inflection({w=>'light', pos=>'n', type=>'plural'}), 'lightses', 'add mutlitple irregular inflections');

done_testing();