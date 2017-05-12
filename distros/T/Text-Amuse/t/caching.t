use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions qw/catfile tmpdir/;
use Data::Dumper;

plan tests => 7;
my $target = catfile(t => testfiles => 'headings.muse');
my $doc = Text::Amuse->new(file => $target);

ok($doc->wants_toc, "Toc is needed");
ok($doc->toc_as_html =~ m/Part \(2\)/, "Html toc found"); 
undef $doc;

$doc = Text::Amuse->new(file => catfile(t => testfiles => 'headings.muse'));
is_deeply($doc->header_as_html, { title => '<em>headings</em>' }, "header ok");
is_deeply($doc->header_as_latex, { title => '\emph{headings}' }, "header ok");

ok($doc->as_latex, "latex body ok");
ok($doc->as_html, "html body ok");

is $doc->file, $target;
