use Test::Most;
use utf8;

BEGIN {
	use_ok('Test::Pcuke::Gherkin::I18n');
}

my $i18n = 'Test::Pcuke::Gherkin::I18n';

my $tests = [
	['en', 'examples', "\t\tExamples: scenarios title"],
	['en', 'examples', "\t\tScenarios: scenarios title"],
	['en', 'given', "\t\t* a step"],
	['ru', 'given', "\t\tдопустим описание шага"],
	['ru', 'given', "\t\tдано описание шага"],
	['ru', 'given', "\t\tпусть описание шага"],
	['ru', 'outline', "\t\tСтруктура сценария: бла-бла-бла"],
];

can_ok($i18n, qw{patterns languages language_info});

foreach my $t ( @$tests ) {
	my $re = find( @$t );
	my $title = "Match found for $t->[2]";
	utf8::encode($title);
	like($t->[2], $re, $title);
}


{
	my ($russian) = grep { /^ru/ } @{ $i18n->languages };
	
	is($russian, q{ru => Russian (русский)}, "Russian found")
}

{
	my $russian = $i18n->language_info('ru');
	is($russian->[0]->[0], 'feature', 'first line of info is "feature" keyword');
	is($russian->[0]->[1], '"Функция", "Функционал", "Свойство"', "Correct russian translations for feature");
}

done_testing();

# returns a pattern that match either a null-string or $line
# patterns for $line are choosen in the translations for $lang
sub find {
	my ($lang, $key, $line) = @_;
	my $res = $i18n->patterns($lang)->{$key};

	my $re = qr{^$};
	
	foreach (@$res) {
		if ( $line =~ $_ ) {
			$re = $_;
			last ;
		}	
	}

	return $re;	
}