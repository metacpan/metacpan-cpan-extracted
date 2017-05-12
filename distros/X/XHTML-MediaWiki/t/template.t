use Test::More tests => 2;

use_ok('XHTML::MediaWiki');

my $mediawiki = XHTML::MediaWiki->new();

my $xhtml;

$xhtml = $mediawiki->format(<<EOT);
{{template}}
{{
template
}}
<div>
{{template
}}
</div>
{{
template}}
{{{ template }}}
EOT

$cmp = <<EOT;
<p><b style="color: red;">No template for: template</b>
<b style="color: red;">No template for: template</b>
</p>
<div><p><b style="color: red;">No template for: template</b>
</p>
</div><p><b style="color: red;">No template for: template</b>
{<b style="color: red;">No template for: template</b>}</p>
EOT

is($xhtml, $cmp, "regression");

