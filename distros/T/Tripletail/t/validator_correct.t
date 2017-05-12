#! perl -w

# Tripletail::Validator::Filter.pm の @correctFilterNames から
# 生成された各フィルタのテスト: 次の4点をテスト
# 1. フィルタを addFilter できる事
# 2. check() メソッドで die する事
# 3. correct() メソッドで検証OKとなる事
# 4. フィルタによる変更結果が Tripletail::Value の各メソッドの出力と一致する事

# Haruka Kataoka, Archinet inc.
# $Id: validator_correct.t 4158 2007-06-15 02:41:32Z hio $

use strict;
use warnings;
use Test::Exception;
use Test::More;

use Tripletail File::Spec->devnull;

my @blocks = do{
	no warnings 'once';
	my $data = join('',<DATA>);
	my @data= split(/^===\r?\n--- input \r?\n/m, $data);
	shift @data;
	map{[split(/\r?\n/,$_)]} @data;
};

plan tests => 4 * @blocks;

foreach my $block (@blocks)
{
	my ($filter, @values) = @$block;
	my $form = $TL->newForm;
	my $validator = $TL->newValidator;
	
	# 値リスト中のエスケープシーケンス \r\n\t 等をコード化
	foreach (@values)
	{
		s/\\t/\t/g;
		s/\\r/\r/g;
		s/\\n/\n/g;
		s/\\\\/\\/g;
	}
	
	ok($validator->addFilter({ test  => $filter }), "addFilter $filter");
	
	$form->set(test => [@values]);
	
	dies_ok { $validator->check($form); } "check() with $filter will die";
	
	my $error = $validator->correct($form);
	ok(! defined $error->{test} , "$filter passes");
	
	my ($conv_method,@conv_args) = $filter =~ /(\w+)/g;
	$conv_method =~ s/^([A-Z])/lc($1)/e;
	my $conv_args = join(',', @conv_args);
	my @conv_values = map {
		$TL->newValue($_)->$conv_method(@conv_args)->get();
	} @values;
	
	is_deeply([$form->getValues('test')], \@conv_values, "$filter equals Value::$conv_method($conv_args)");
}


__DATA__
===
--- input 
ConvHira
1あアあ

===
--- input 
ConvKata
1あアあ

===
--- input 
ConvNumber
あ１２３

===
--- input 
ConvNarrow
_！１Ａ

===
--- input 
ConvWide
＃3b

===
--- input 
ConvKanaNarrow
1１aａあいうアイウポダｱｲｳﾎﾟﾀﾞ

===
--- input 
ConvKanaWide
1１aａあいうアイウポダｱｲｳﾎﾟﾀﾞ

===
--- input 
ConvComma
1
12
123
1234
12345
123456
1234567
12345678
-12345678
-12345678.9

===
--- input 
ConvLF
\n\n
\r\n\r\n
\r\r

===
--- input 
ConvBR
\n
\r
\r\n

===
--- input 
ForceHira
1あア

===
--- input 
ForceKata
1あア

===
--- input 
ForceNumber
１ａｂ9

===
--- input 
ForceMin(10,foo)
500
5

===
--- input 
ForceMax(10,foo)
500
5

===
--- input 
ForceMaxLen(6)
あえいおう

===
--- input 
ForceMaxUtf8Len(5)
あえいおう

===
--- input 
ForceMaxSjisLen(5)
あえいおう

===
--- input 
ForceMaxCharLen(4)
あえいおう

===
--- input 
TrimWhitespace
 A 
　A　
\t\tA\t\t
\t\t 　\tA  A\t 　　\t
