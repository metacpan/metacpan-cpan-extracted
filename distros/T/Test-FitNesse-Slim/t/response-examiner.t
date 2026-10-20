#! perl

use strict;
use warnings;

use lib "t/lib";
use Test::More;
use Fitnesse::Fixtures::ResponseContext;
use Fitnesse::Fixtures::ResponseExaminer;

Fitnesse::Fixtures::ResponseContext->store({
  status => 200,
  content => '<html><body>Assertions: 8 right, 2 wrong, 2 ignored, 0 exceptions</body></html>',
  page_html => "<table>\n<tr class=\"pass\">ok</tr>\n<tr class=\"ignore\">skip</tr>\n</table>",
  headers => { 'content-type' => 'text/html' },
});

my $examiner = Fitnesse::Fixtures::ResponseExaminer->new;
is($examiner->status, 200, "status reads the retained HTTP response status");
is($examiner->set_type("contents"), undef, "setType follows the upstream void setter contract");
is($examiner->contents, '<html><body>Assertions: 8 right, 2 wrong, 2 ignored, 0 exceptions</body></html>',
  "contents reads the retained response body");
is($examiner->html, '<html><body>Assertions: 8 right, 2 wrong, 2 ignored, 0 exceptions</body></html>',
  "html returns the HTTP response body after transport framing has been removed");
is($examiner->set_type("fullContents"), undef, "setType selects full response contents");
like($examiner->extract_value_from_response, qr/&lt;html&gt;/,
  "fullContents exposes HTML-escaped response text");
is($examiner->set_type("rawContents"), undef, "setType selects raw response contents");
like($examiner->extract_value_from_response, qr/<html>/,
  "rawContents preserves response markup");
is($examiner->set_type("status"), undef, "setType selects the response status source");
is($examiner->extract_value_from_response, "200", "status can be selected for pattern extraction");
is($examiner->set_type("contents"), undef, "setType returns to response body inspection");
is($examiner->set_pattern('Assertions: (\\d+ right, \\d+ wrong)'), undef,
  "setPattern follows the upstream void setter contract");
is($examiner->set_group(1), undef, "setGroup follows the upstream void setter contract");
is($examiner->found, '8 right, 2 wrong', "found returns the configured capture group");
is($examiner->extract_match('((8) right)', 'contents', 2), '8',
  "extractMatch can return a capture beyond the first regex group");
is($examiner->extract_match('Assertions: ([^<]+)', 'contents', 1),
  '8 right, 2 wrong, 2 ignored, 0 exceptions',
  "extractMatch selects a response type and returns its requested capture group");
is($examiner->matches, "true", "matches recognizes a matching response pattern");
is($examiner->match_count, 1, "matchCount counts response matches");
$examiner->set_pattern('not in the response');
is($examiner->found, undef, "found returns null when the response pattern does not match");

$examiner->set_type("pageHtml");
$examiner->set_pattern('class="(pass|ignore)"');
$examiner->set_group(1);
is($examiner->found, "pass", "pageHtml searches the retained rendered HTML");
$examiner->set_pattern('class="(ignore)"');
is($examiner->found, 'ignore', "ignored test markup remains inspectable in rendered HTML");
$examiner->set_number(3);
is($examiner->set_type("line"), undef, "setType selects rendered page lines");
is($examiner->string, '<tr class="ignore">skip</tr>', "string returns the requested rendered HTML line");

my $bad_type = eval { $examiner->set_type("unknown"); $examiner->extract_value_from_response; 1 } ? "" : $@;
like($bad_type, qr/Bad type in ResponseExaminer/, "unknown response types report the upstream exception message");
my $bad_pattern = eval { $examiner->set_type("contents"); $examiner->set_pattern("["); $examiner->found; 1 } ? "" : $@;
like($bad_pattern, qr/invalid response pattern/i, "invalid regex patterns are reported as fixture exceptions");

Fitnesse::Fixtures::ResponseContext->store({ status => 500, content => "nested test failed", page_html => "<pre>nested failure</pre>" });
is($examiner->status, 500, "an HTTP error response remains inspectable");
$examiner->set_type("contents");
$examiner->set_pattern("(nested test failed)");
$examiner->set_group(1);
is($examiner->found, "nested test failed", "expected nested-test failure content can be inspected");
Fitnesse::Fixtures::ResponseContext->store({
  status => 200,
  content => '<tr class="exception"><td>__EXCEPTION__:fitnesse.slim.SlimError: SETX_THROWS</td></tr>',
  page_html => '<tr class="exception"><td>__EXCEPTION__:fitnesse.slim.SlimError: SETX_THROWS</td></tr>',
});
$examiner->set_pattern('(SETX_THROWS)');
is($examiner->found, 'SETX_THROWS', "nested exception details can be extracted from the response");

my $missing = Fitnesse::Fixtures::ResponseExaminer->new;
Fitnesse::Fixtures::ResponseContext->store(undef);
my $no_response = eval { $missing->contents; 1 } ? "" : $@;
like($no_response, qr/no FitNesse response is available/, "missing nested responses raise a clear fixture exception");

done_testing();
