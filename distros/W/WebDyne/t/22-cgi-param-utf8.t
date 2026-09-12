use strict;
use warnings;
BEGIN { $ENV{'WEBDYNE_CONF'}='.'; }
use Test::More;
use WebDyne::CGI::Simple;
use JSON::PP;
my $query='name=Jos%C3%A9&name=%E6%9D%B1%E4%BA%AC&zero=0&empty=&bad=%FF';
foreach my $method (qw(GET POST)) {
    local $ENV{'REQUEST_METHOD'}=$method;
    my $request_or=InputRequest->new($method, $query);
    my $cgi_or=WebDyne::CGI::Simple->new($request_or);
    my $bytes="Jos\xc3\xa9";
    my $characters='Jos'.chr(0xe9);
    is(scalar($cgi_or->param('name')), $bytes, "$method existing API returns bytes");
    is(length(scalar($cgi_or->param('name'))), 5, "$method byte count reproduces issue");
    is(scalar($cgi_or->param_utf8('name')), $characters, "$method decodes first value");
    is_deeply([$cgi_or->param_utf8('name')], [$characters, chr(0x6771).chr(0x4eac)], "$method decodes repeated values");
    is(JSON::PP->new()->utf8()->encode(scalar($cgi_or->param_utf8('name'))), '"'.$bytes.'"', "$method JSON encodes exactly once");
    is(scalar($cgi_or->param_utf8('zero')), '0', "$method zero preserved");
    is(scalar($cgi_or->param_utf8('empty')), '', "$method empty preserved");
    is(scalar($cgi_or->param_utf8('missing')), undef, "$method missing scalar");
    is_deeply([$cgi_or->param_utf8('missing')], [], "$method missing list");
    is(scalar($cgi_or->param('name')), $bytes, "$method original bytes unchanged");
    my $ok=eval { $cgi_or->param_utf8('bad'); 1 };
    ok(!$ok, "$method malformed UTF-8 rejected");
    is(scalar($cgi_or->param('bad')), "\xff", "$method malformed original unchanged");
    my $decoded=chr(0x20ac);
    $cgi_or->param('decoded', $decoded);
    is(scalar($cgi_or->param_utf8('decoded')), $decoded, "$method decoded value preserved");
}
done_testing();

package InputRequest;
sub new { my ($class, $method, $query)=@_; return bless({method => $method, query => $query}, $class); }
sub headers_in { my ($self, $name)=@_; return $self->{'method'} eq 'POST' && lc($name) eq 'content-type' ? 'application/x-www-form-urlencoded' : undef; }
sub method { return shift()->{'method'}; }
sub args { my $self=shift(); return $self->{'method'} eq 'GET' ? $self->{'query'} : ''; }
sub body { return shift()->{'query'}; }
sub content_length { return 0; }
