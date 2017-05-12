#!/usr/bin/env perl
use warnings;
use strict;

use utf8;
use Encode;

use Test::Pcuke::Gherkin;

print "###\n###\tThis is an integration test in russian (utf8)\n###\n";

my $content = 
	"# language: ru\n"
	. "Функция: это простой тест"
	. "\t\n"
	. "\tЭто рассказец на несколько строчек\n"
	. "\tвот вторая строчка\n"
	. "\t\n"
	. "\tКонтекст: а эти шаги должны выполняться перед каждым сценарием\n"
	. "\t\tДопустим допущение 1\n"
	. "\t\tДопустим допущение 2\n"
	. "\t\t\n"
	. "\tСценарий: это простенький сценарий\n"
	. "\t\tПусть это - первый шаг сценария\n"
	. "\t\tЕсли это - второй шаг сценария\n"
	. "\t\tТогда это - третий шаг\n"
	. "\t\tА это - четвёртый\n"
	. "\t\n"
	. "\tСтруктура сценария: шаблончик\n"
	. "\t\tПусть дано <n>\n"
	. "\t\tК тому же  <m>\n"
	. "\t\tТогда получим <R>\n"
	. "\t\t\n"
	. "\t\t\tПримеры: исключающее или\n"
	. "\t\t\t  | m | n | R |\n"
	. "\t\t\t  | 0 | 0 | 0 |\n"
	. "\t\t\t  | 0 | 1 | 1 |\n"
	. "\t\t\t  | 1 | 0 | 1 |\n"
	. "\t\t\t  | 1 | 1 | 0 |\n"
	. "\n";

my $feature = Test::Pcuke::Gherkin->compile( $content );

utf8::encode($content);
print "Content is:\n---\n$content\n---\n";

print "\n\nBelow are dumb warnings from the default executor (one per each executed step)\n\n";

$feature->execute;



sub print_tokens {
	my $tokens = shift;
	print Encode::encode('utf8', join("\n", map { '['.join(", ", @$_).']' } @$tokens) );
}

sub pr ($) {
	print Encode::encode('utf8',$_[0]);
}