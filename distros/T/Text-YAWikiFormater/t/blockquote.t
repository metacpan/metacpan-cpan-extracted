#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Text::YAWikiFormater' ) || print "Bail out!\n";
}

my $wiki = Text::YAWikiFormater->new(
		body	=> <<EoB,

Some text just before the block
> Some block test stuff
> With several lines
> And some more lines
> Just to make sure.
Some text in the outside!

>
> some quote quoting quotes
> > some quote quoted inside the quote
> > that have more than one line of quote
> And goes back to the original quote
>

EoB
	);

my $res = $wiki->format();

my $eres;
{
	local $/;
	my $respath = $0;
	$respath =~s{blockquote\.t$}{html-res/blockquote.t.html};
	if (-e $respath) {
		open my $fh, '<', $respath;
		$eres=<$fh>;
	}
}
is($res, $eres, 'Formated text is as expected');

if ($ENV{DEBUG} and $res ne $eres) {
	open my $fh, '>', '/tmp/blockquote.res.html';
	print $fh $res;
	close $fh;
	open $fh, '>', '/tmp/blockquote.eres.html';
	print $fh $eres;
	close $fh;
}

done_testing();
