use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;
use lib 't/lib';

use JSON::PP qw/encode_json decode_json/;
use Local::MockUA;
use Webservice::Overleaf::API;

sub ok_response {
    my ($content, $headers) = @_;
    return {
        success => 1,
        status  => 200,
        reason  => 'OK',
        headers => $headers || {},
        content => defined($content) ? $content : q{},
    };
}

my $ua = Local::MockUA->new;
my $projects_json = encode_json({
    projects => [
        { id => 'p1', name => 'Paper One', lastUpdated => '2026-09-01' },
        { _id => 'p2', name => 'Archived', archived => 1 },
        { id => 'p3', name => 'Trashed', trashed => 1 },
    ],
});
$projects_json =~ s/&/&amp;/g;
$projects_json =~ s/"/&quot;/g;

$ua->enqueue(ok_response(qq{<html><head>
<meta name="ol-csrfToken" content="csrf-123">
<meta name="ol-prefetchedProjectsBlob" content="$projects_json">
</head></html>}));

my $ol = Webservice::Overleaf::API->new(
    ua           => $ua,
    experimental => 1,
    session      => 'session-secret',
);

my $projects = $ol->projects;
is $projects->scalar, 1, 'archived and trashed projects filtered';
my ($project) = $projects->all;
is $project->id, 'p1', 'project id';
is $project->name, 'Paper One', 'project name';
is $ol->csrf, 'csrf-123', 'project page bootstraps CSRF token';

my $request = $ua->last_request;
is $request->{method}, 'GET', 'projects uses GET';
is $request->{url}, 'https://www.overleaf.com/project', 'projects page URL';
is $request->{opts}->{headers}->{Cookie}, 'overleaf_session2=session-secret', 'session cookie sent';

$ua->enqueue(ok_response('ZIP-BYTES'));
is $ol->project_zip('p1'), 'ZIP-BYTES', 'project ZIP bytes returned';

my $compile_response = {
    status       => 'success',
    compileGroup => 'standard',
    clsiServerId => 'clsi 1',
    outputFiles  => [
        { path => 'figure.pdf', type => 'pdf', url => '/build/figure.pdf' },
        { path => 'output.pdf', type => 'pdf', url => '/build/output.pdf' },
        { path => 'output.log', type => 'log', url => '/build/output.log' },
    ],
};
$ua->enqueue(ok_response(encode_json($compile_response)));
my $compile = $ol->compile('p1', resource_path => 'main.tex');
is $compile->status, 'success', 'compile status';
is $compile->pdf_url, 'https://www.overleaf.com/build/output.pdf?clsiserverid=clsi%201', 'main output.pdf selected and CLSI id appended';
is $compile->output_files->scalar, 3, 'all compile outputs retained';

$request = $ua->last_request;
is $request->{method}, 'POST', 'compile uses POST';
like $request->{url}, qr{/project/p1/compile\?enable_pdf_caching=true\z}, 'compile endpoint';
is $request->{opts}->{headers}->{'X-Csrf-Token'}, 'csrf-123', 'compile includes CSRF';
is $request->{opts}->{headers}->{'Content-Type'}, 'application/json', 'compile content type';
my $compile_body = decode_json($request->{opts}->{content});
is $compile_body->{rootResourcePath}, 'main.tex', 'resource path included';
ok $compile_body->{incrementalCompilesEnabled}, 'incremental compile enabled';

$ua->enqueue(ok_response('%PDF-1.7 mock'));
is $ol->download_pdf('p1', compile => $compile), '%PDF-1.7 mock', 'PDF bytes returned';
is $ua->last_request->{url}, $compile->pdf_url, 'PDF fetched from selected compile URL';

$ua->enqueue(ok_response("log line\n"));
is $ol->download_output($compile, 'output.log'), "log line\n", 'named compile output returned';

my $tmp = tempdir(CLEANUP => 1);
my $zip = File::Spec->catfile($tmp, 'project.zip');
$ua->enqueue(ok_response("PK\x03\x04mock"));
is $ol->project_zip('p1', to => $zip), $zip, 'ZIP saved to file';
open my $fh, '<:raw', $zip or die $!;
local $/;
is <$fh>, "PK\x03\x04mock", 'saved ZIP bytes exact';
close $fh;

my $guarded = Webservice::Overleaf::API->new(session => 'x', ua => Local::MockUA->new);
my $guard_ok = eval { $guarded->projects; 1 };
ok !$guard_ok, 'experimental interface requires opt-in';
like $@, qr/experimental => 1/, 'experimental guard diagnostic';

my $no_session = Webservice::Overleaf::API->new(experimental => 1, ua => Local::MockUA->new, session => '');
my $session_ok = eval { $no_session->projects; 1 };
ok !$session_ok, 'session required';
like $@, qr/session cookie is required/, 'session diagnostic';

done_testing;
