#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Text::YAWikiFormater' ) || print "Bail out!\n";
}

my $wiki = Text::YAWikiFormater->new(
		body	=> <<EoB,
{{toc}}

! head1

!! head2

!!! head3

!!!! head4

!!!!! head5

!!!!!! head6

**bold**, //italic//, __underline__, --deleted--, ''monospaced''

* list 1
** list 1.1
*# list 1.I
*** list 1.2.1
* list 2
* list 3

----

{{{

\$a++;
--\$b;

{ json: [
	{test1: 1 },
	{test2: 2 }
]}

}}}

Some text just before the block
> Some block test stuff
> With several lines
> And some more lines
> Just to make sure.
Some text in the outside!

[[SomePage]]

[[Some other Page|Page2]]

[[Some Page Section|SomePage#section]]

http://www.sapo.pt

{{image: "/images/test.png"}}

EoB
	);

my $res = $wiki->format();

my $eres;
{
	local $/;
	my $respath = $0;
	$respath =~s{format\.t$}{html-res/format.t.html};
	open my $fh, '<', $respath;
	$eres=<$fh>;
}
is($res, $eres, 'Formated text is as expected');

if ($ENV{DEBUG} and $res ne $eres) {
	open my $fh, '>', '/tmp/format.res.html';
	print $fh $res;
	close $fh;
	open $fh, '>', '/tmp/format.eres.html';
	print $fh $eres;
	close $fh;
}

done_testing();
