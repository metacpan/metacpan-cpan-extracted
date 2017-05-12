# -*- perl -*-
use Test::More tests => 13;
use strict;
use warnings;
#use Smart::Comments;

BEGIN {
    eval q{use Tripletail qw(/dev/null)};
}

END {
}

my $src = qq{
<FORM>
  aaa<br>
  bbb
  <small class='la"r"ge'>ccc</small>
</FORM>
<!-- <comment> -->
};

my $dst = qq{
<FORM action="foo.cgi"><small>FORM</small>
  aaa<!-- BR -->
  bbb
  <small class="la&quot;r&quot;ge">ccc</small>
</FORM>
<!-- MODIFIED COMMENT: [<comment>] -->
};

my $filter;
ok($filter = $TL->newHtmlFilter(
    interest       => [qr/f.rm/i, 'br', 'small'],
    filter_comment => 1,
   ), 'newHtmlFilter');

ok($filter->set($src), 'set');

while (my ($context, $elem) = $filter->next) {
	### $elem
    if ($elem->isElement) {
		if (lc $elem->name eq 'form') {
			ok($elem->attr(action => 'foo.cgi'), 'attr (set)');
			is($elem->attr('action'), 'foo.cgi', 'attr (get)');

			my $elem;
			ok($elem = $context->newElement('small'), 'newElement');
			ok($context->add($elem), 'add');

			ok($context->add('FORM'), 'newElement(text)');
			$context->add($context->newElement('/small'));
		}
		elsif (lc $elem->name eq 'br') {
			ok($context->delete, 'delete');

			my $elem;
			ok($elem = $context->newComment('BR'), 'newComment');
			$context->add($elem);
		}
    }
    elsif ($elem->isComment) {
		ok($elem->str(sprintf 'MODIFIED COMMENT: [%s]', $elem->str), 'str');
    }
}

is($filter->toStr, $dst, 'toStr');



$filter = $TL->newHtmlFilter(
    interest => ['foo'],
   );
$filter->set(qq{a<foo\t\n\ta="b">b});
while (my ($context, $elem) = $filter->next) {
    is $elem->attr('a'), 'b', 'attribute after newline [1]';

    $elem->attr(a => 'bbb');
}
is $filter->toStr, qq{a<foo a="bbb">b}, 'attribute after newline [2]';
