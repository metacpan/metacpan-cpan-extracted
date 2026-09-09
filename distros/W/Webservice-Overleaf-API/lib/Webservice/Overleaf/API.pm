package Webservice::Overleaf::API;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.06';

# General-purpose Overleaf tooling, also informed by practical Science Perl
# Journal author/editor work.  The author is a Science Perl Committee member
# and a Co-Editor of the Journal; see the POD for context and links.

use Carp qw/croak/;
use Dispatch::Fu qw/dispatch on xdefault xshift_and_deref/;
use HTML::Entities qw/decode_entities/;
use HTTP::Tiny;
use JSON::PP qw/decode_json encode_json/;
use MIME::Base64 qw/encode_base64/;
use URI::Escape qw/uri_escape_utf8/;
use Util::H2O::More qw/baptise d2o h2o/;

use constant {
    DEFAULT_BASE_URL     => 'https://www.overleaf.com',
    DEFAULT_GIT_BASE_URL => 'https://git.overleaf.com',
};

sub new {
    my $pkg  = shift;
    my %opts = @_;

    my $base_url = defined $opts{base_url}
      ? $opts{base_url}
      : DEFAULT_BASE_URL;
    $base_url =~ s{/+$}{};

    my $git_base_url;
    if (defined $opts{git_base_url}) {
        $git_base_url = $opts{git_base_url};
    }
    elsif ($base_url eq DEFAULT_BASE_URL) {
        $git_base_url = DEFAULT_GIT_BASE_URL;
    }
    else {
        # Overleaf Server Pro commonly exposes Git below /git.  A deployment
        # with a different Git bridge location should pass git_base_url.
        $git_base_url = $base_url . '/git';
    }
    $git_base_url =~ s{/+$}{};

    # Keep HTTP construction lazy.  HTTP::Tiny reads proxy-related
    # environment variables in new(), which should not make URL builders or
    # Git-only use fail before an HTTP request is ever attempted.
    my $self = baptise {
        ua           => $opts{ua},
        timeout      => defined $opts{timeout} ? $opts{timeout} : 30,
        base_url     => $base_url,
        git_base_url => $git_base_url,
        session      => defined $opts{session} ? $opts{session} : $ENV{OVERLEAF_SESSION},
        cookie_name  => $opts{cookie_name} || 'overleaf_session2',
        csrf         => $opts{csrf},
        experimental => $opts{experimental} ? 1 : 0,
        git_runner   => $opts{git_runner} || \&_default_git_runner,
        last_response => undef,
    }, $pkg;

    return $self;
}

sub project_url {
    my ($self, $project_id) = @_;
    $project_id = _project_id($project_id);
    return $self->base_url . '/project/' . $project_id;
}

sub git_url {
    my ($self, $project_id) = @_;
    $project_id = _project_id($project_id);

    my $base = $self->git_base_url;

    # Overleaf Cloud documents the public Git username as "git".  Keep the
    # token out of the URL, but include that non-secret username so ordinary
    # Git does not guess an account email address when it needs credentials.
    $base =~ s{\Ahttps://git\.overleaf\.com(?=/|\z)}{https://git\@git.overleaf.com};

    return $base . '/' . $project_id;
}

sub open_uri {
    my $self = shift;
    my %opts = @_;

    my $uris = delete $opts{uris};
    $uris = [ delete $opts{uri} ] if !defined $uris && exists $opts{uri};
    $uris = [$uris] if defined $uris && ref($uris) ne 'ARRAY';

    croak 'open_uri requires uri => $uri or uris => \\@uris'
      if !$uris || !@$uris || grep { !defined($_) || $_ eq q{} } @$uris;

    my $names = delete $opts{names};
    $names = [ delete $opts{name} ] if !defined $names && exists $opts{name};
    $names = [$names] if defined $names && ref($names) ne 'ARRAY';

    croak 'names must contain one entry for each URI'
      if $names && @$names != @$uris;

    my @pairs;
    if (@$uris == 1 && !$names) {
        push @pairs, [ snip_uri => $uris->[0] ];
    }
    else {
        for my $i (0 .. $#$uris) {
            push @pairs, [ 'snip_uri[]' => $uris->[$i] ];
            push @pairs, [ 'snip_name[]' => $names->[$i] ] if $names;
        }
    }

    _append_open_features(\@pairs, \%opts);
    croak 'unsupported open_uri option(s): ' . join(', ', sort keys %opts)
      if keys %opts;

    return $self->base_url . '/docs?' . _query_string(@pairs);
}

sub open_data {
    my ($self, $content, %opts) = @_;
    croak 'open_data requires content' if !defined $content;

    my $mime = delete($opts{mime}) || 'application/x-tex';
    my $uri  = 'data:' . $mime . ';base64,' . encode_base64($content, q{});

    return $self->open_uri(uri => $uri, %opts);
}

sub open_snippet_form {
    my ($self, $snippet, %opts) = @_;
    croak 'open_snippet_form requires a snippet' if !defined $snippet;

    my %fields = (snip => $snippet);
    _append_open_features_hash(\%fields, \%opts);
    croak 'unsupported open_snippet_form option(s): ' . join(', ', sort keys %opts)
      if keys %opts;

    return d2o {
        action => $self->base_url . '/docs',
        method => 'POST',
        fields => \%fields,
    };
}

sub git_clone {
    my ($self, $project_id, $directory) = @_;
    croak 'git_clone requires a destination directory'
      if !defined($directory) || $directory eq q{};

    return $self->_run_git('git', 'clone', $self->git_url($project_id), $directory);
}

sub git_pull {
    my ($self, $directory) = @_;
    croak 'git_pull requires a repository directory'
      if !defined($directory) || $directory eq q{};

    return $self->_run_git('git', '-C', $directory, 'pull');
}

sub git_push {
    my ($self, $directory, @args) = @_;
    croak 'git_push requires a repository directory'
      if !defined($directory) || $directory eq q{};

    # Optional arguments deliberately map directly to `git push` arguments.
    # The high-level CLI compile workflow uses this to push the complete
    # committed project to the branch discovered from the Overleaf Git remote.
    # It does not upload selected .tex/.bib files or use the ZIP export as a
    # work tree.
    return $self->_run_git('git', '-C', $directory, 'push', @args);
}

sub git_remote_add {
    my ($self, $directory, $project_id, $remote) = @_;
    $remote ||= 'overleaf';
    croak 'git_remote_add requires a repository directory'
      if !defined($directory) || $directory eq q{};

    return $self->_run_git(
        'git', '-C', $directory, 'remote', 'add',
        $remote, $self->git_url($project_id)
    );
}

sub bootstrap {
    my $self = shift;
    $self->_require_experimental;
    $self->_require_session;

    my $html = $self->_project_page;
    my $csrf = _csrf_from_html($html);
    croak 'could not find an Overleaf CSRF token; the session may have expired'
      if !defined($csrf) || $csrf eq q{};

    $self->csrf($csrf);
    return h2o {
        authenticated => 1,
        csrf          => $csrf,
    };
}

sub projects {
    my $self = shift;
    $self->_require_experimental;
    $self->_require_session;

    my $html = $self->_project_page;
    my $csrf = _csrf_from_html($html);
    $self->csrf($csrf) if defined $csrf && $csrf ne q{};

    my @meta = _meta_tags($html);
    my $projects;

    # Current Overleaf shape.
    my ($prefetched) = grep {
        defined $_->{name} && $_->{name} eq 'ol-prefetchedProjectsBlob'
    } @meta;
    $projects = _projects_from_json($prefetched->{content}) if $prefetched;

    # Intermediate shape: an otherwise-generic meta element containing a
    # JSON object with a projects member.
    if (!$projects || !@$projects) {
        META:
        for my $m (@meta) {
            next if !defined $m->{content};
            next if $m->{content} !~ /["']projects["']/;
            my $candidate = _projects_from_json($m->{content});
            if ($candidate) {
                $projects = $candidate;
                last META;
            }
        }
    }

    # Legacy shape retained by older/self-hosted releases.
    if (!$projects || !@$projects) {
        my ($legacy) = grep {
            defined $_->{name} && $_->{name} eq 'ol-projects'
        } @meta;
        $projects = _projects_from_json($legacy->{content}) if $legacy;
    }

    $projects ||= [];

    my @normalized;
    for my $p (@$projects) {
        next if ref($p) ne 'HASH';
        next if $p->{archived} || $p->{trashed};

        push @normalized, {
            id            => defined $p->{id} ? $p->{id} : $p->{_id},
            name          => $p->{name},
            last_updated  => $p->{lastUpdated},
            last_updated_by => $p->{lastUpdatedBy},
            owner         => $p->{owner},
            archived      => 0,
            trashed       => 0,
        };
    }

    return d2o \@normalized;
}

sub project_zip {
    my ($self, $project_id, %opts) = @_;
    $self->_require_experimental;
    $self->_require_session;
    $project_id = _project_id($project_id);

    my $response = $self->_request(
        'GET',
        $self->project_url($project_id) . '/download/zip',
        headers => $self->_headers,
    );

    return _save_or_return($response->{content}, $opts{to});
}

sub compile {
    my ($self, $project_id, %opts) = @_;
    $self->_require_experimental;
    $self->_require_session;
    $project_id = _project_id($project_id);
    $self->_ensure_csrf;

    my %body = (
        rootDoc_id                 => undef,
        draft                      => JSON::PP::false,
        check                      => 'silent',
        incrementalCompilesEnabled => JSON::PP::true,
    );
    $body{rootResourcePath} = $opts{resource_path}
      if defined $opts{resource_path} && $opts{resource_path} ne q{};

    my %headers = %{ $self->_headers };
    $headers{'Content-Type'} = 'application/json';

    my $response = $self->_request(
        'POST',
        $self->project_url($project_id) . '/compile?enable_pdf_caching=true',
        headers => \%headers,
        content => encode_json(\%body),
    );

    my $data = eval { decode_json($response->{content}) };
    croak 'Overleaf compile response was not valid JSON: ' . ($@ || 'unknown error')
      if !$data || ref($data) ne 'HASH';

    my $status = defined $data->{status} ? $data->{status} : 'error';
    if ($status ne 'success') {
        my $hint = defined $opts{resource_path}
          ? ' (the requested resource file may not exist in the project)'
          : q{};
        croak 'Overleaf compilation failed: ' . $status . $hint;
    }

    my $clsi_qs = defined($data->{clsiServerId}) && $data->{clsiServerId} ne q{}
      ? '?clsiserverid=' . uri_escape_utf8($data->{clsiServerId})
      : q{};

    my @outputs;
    for my $f (@{ $data->{outputFiles} || [] }) {
        next if ref($f) ne 'HASH';
        push @outputs, {
            path => $f->{path},
            type => $f->{type},
            url  => _absolute_url($self->base_url, $f->{url}) . $clsi_qs,
        };
    }

    my ($pdf) = grep { defined($_->{path}) && $_->{path} eq 'output.pdf' } @outputs;
    ($pdf) = grep { defined($_->{type}) && $_->{type} eq 'pdf' } @outputs if !$pdf;
    croak 'Overleaf compilation succeeded but no PDF output was returned' if !$pdf;

    return d2o {
        status        => $status,
        pdf_url       => $pdf->{url},
        compile_group => $data->{compileGroup},
        clsi_server_id => $data->{clsiServerId},
        output_files  => \@outputs,
    };
}

sub download_pdf {
    my ($self, $project_id, %opts) = @_;
    $self->_require_experimental;
    $self->_require_session;
    my $compile = delete $opts{compile};
    if (!$compile) {
        $compile = $self->compile($project_id, %opts);
    }

    my $pdf_url = eval { $compile->pdf_url };
    $pdf_url = $compile->{pdf_url} if !$pdf_url && ref($compile) eq 'HASH';
    croak 'compile result does not contain pdf_url' if !defined $pdf_url;

    my $response = $self->_request(
        'GET', $pdf_url,
        headers => $self->_headers,
    );

    return _save_or_return($response->{content}, $opts{to});
}

sub download_output {
    my ($self, $compile, $path, %opts) = @_;
    $self->_require_experimental;
    $self->_require_session;
    croak 'download_output requires a compile result and output path'
      if !$compile || !defined $path;

    my $files = eval { $compile->output_files };
    $files = $compile->{output_files} if !$files && ref($compile) eq 'HASH';
    croak 'compile result does not contain output_files' if !$files;

    my @files = ref($files) eq 'ARRAY' ? @$files : eval { $files->all };
    my ($file) = grep {
        my $p = eval { $_->path };
        $p = $_->{path} if !defined($p) && ref($_) eq 'HASH';
        defined($p) && $p eq $path;
    } @files;
    croak "compile output '$path' was not found" if !$file;

    my $url = eval { $file->url };
    $url = $file->{url} if !defined($url) && ref($file) eq 'HASH';
    croak "compile output '$path' does not contain a URL"
      if !defined($url) || $url eq q{};

    my $response = $self->_request(
        'GET', $url,
        headers => $self->_headers,
    );
    return _save_or_return($response->{content}, $opts{to});
}

sub call {
    my ($self, $operation, @args) = @_;
    my $input = [ $operation, @args ];

    return dispatch {
        my ($op) = xshift_and_deref @_;
        return xdefault $op;
    }
    $input,
      on open_uri => sub {
          my ($op, @a) = xshift_and_deref @_;
          return $self->open_uri(@a);
      },
      on open_data => sub {
          my ($op, @a) = xshift_and_deref @_;
          return $self->open_data(@a);
      },
      on git_url => sub {
          my ($op, @a) = xshift_and_deref @_;
          return $self->git_url(@a);
      },
      on git_clone => sub {
          my ($op, @a) = xshift_and_deref @_;
          return $self->git_clone(@a);
      },
      on git_pull => sub {
          my ($op, @a) = xshift_and_deref @_;
          return $self->git_pull(@a);
      },
      on git_push => sub {
          my ($op, @a) = xshift_and_deref @_;
          return $self->git_push(@a);
      },
      on projects => sub {
          my ($op, @a) = xshift_and_deref @_;
          return $self->projects(@a);
      },
      on project_zip => sub {
          my ($op, @a) = xshift_and_deref @_;
          return $self->project_zip(@a);
      },
      on compile => sub {
          my ($op, @a) = xshift_and_deref @_;
          return $self->compile(@a);
      },
      on download_pdf => sub {
          my ($op, @a) = xshift_and_deref @_;
          return $self->download_pdf(@a);
      },
      on default => sub {
          my ($op) = xshift_and_deref @_;
          croak "unsupported Overleaf operation '$op'";
      };
}

sub _project_page {
    my $self = shift;
    my $response = $self->_request(
        'GET', $self->base_url . '/project',
        headers => $self->_headers,
    );
    return $response->{content};
}

sub _ensure_csrf {
    my $self = shift;
    return $self->csrf if defined($self->csrf) && $self->csrf ne q{};
    return $self->bootstrap->csrf;
}

sub _headers {
    my $self = shift;
    my %headers = (
        'User-Agent' => 'Webservice-Overleaf-API/' . $VERSION,
    );

    $headers{Cookie} = $self->cookie_name . '=' . $self->session
      if defined($self->session) && $self->session ne q{};
    $headers{'X-Csrf-Token'} = $self->csrf
      if defined($self->csrf) && $self->csrf ne q{};

    return \%headers;
}

sub _request {
    my ($self, $method, $url, %opts) = @_;

    my $ua = $self->ua;
    if (!$ua) {
        $ua = HTTP::Tiny->new(
            agent   => 'Webservice-Overleaf-API/' . $VERSION,
            timeout => $self->timeout,
        );
        $self->ua($ua);
    }

    my $response = $ua->request($method, $url, \%opts);
    $self->last_response($response);

    return dispatch {
        my $r = shift;
        return 'ok' if $r->{success};
        return 'auth' if defined($r->{status}) && ($r->{status} == 401 || $r->{status} == 403);
        return 'http';
    }
    $response,
      on ok => sub {
          return shift;
      },
      on auth => sub {
          my $r = shift;
          croak 'Overleaf authentication failed (HTTP ' . $r->{status} . '); the session may have expired';
      },
      on http => sub {
          my $r = shift;
          croak 'Overleaf request failed: HTTP '
            . (defined($r->{status}) ? $r->{status} : '?')
            . ' '
            . (defined($r->{reason}) ? $r->{reason} : q{});
      };
}

sub _run_git {
    my ($self, @cmd) = @_;
    my $exit = $self->git_runner->(@cmd);
    croak 'git command failed with exit status ' . $exit . ': ' . join(' ', @cmd)
      if $exit;
    return 1;
}

sub _default_git_runner {
    my @cmd = @_;
    system { $cmd[0] } @cmd;
    return $? == -1 ? 255 : ($? >> 8);
}

sub _require_experimental {
    my $self = shift;
    croak 'this method uses Overleaf\'s undocumented web application interface; construct with experimental => 1 to enable it'
      if !$self->experimental;
    return 1;
}

sub _require_session {
    my $self = shift;
    croak 'an Overleaf session cookie is required (session => ... or OVERLEAF_SESSION)'
      if !defined($self->session) || $self->session eq q{};
    return 1;
}

sub _project_id {
    my $id = shift;
    croak 'project id is required' if !defined($id) || $id eq q{};
    croak 'invalid project id' if $id !~ /\A[A-Za-z0-9_-]+\z/;
    return $id;
}

sub _append_open_features {
    my ($pairs, $opts) = @_;

    if (exists $opts->{engine}) {
        my $engine = delete $opts->{engine};
        my %valid = map { $_ => 1 } qw/latex_dvipdf pdflatex xelatex lualatex/;
        croak "unsupported TeX engine '$engine'" if !$valid{$engine};
        push @$pairs, [ engine => $engine ];
    }
    if (exists $opts->{main_document}) {
        push @$pairs, [ main_document => delete $opts->{main_document} ];
    }
    if (exists $opts->{visual_editor}) {
        push @$pairs, [ visual_editor => delete($opts->{visual_editor}) ? 'true' : 'false' ];
    }

    return;
}

sub _append_open_features_hash {
    my ($fields, $opts) = @_;
    my @pairs;
    _append_open_features(\@pairs, $opts);
    $fields->{ $_->[0] } = $_->[1] for @pairs;
    return;
}

sub _query_string {
    my @pairs = @_;
    return join '&', map {
        uri_escape_utf8($_->[0]) . '=' . uri_escape_utf8(defined($_->[1]) ? $_->[1] : q{})
    } @pairs;
}

sub _attrs {
    my $text = shift;
    my %attrs;

    while ($text =~ /([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/g) {
        my ($key, $dq, $sq, $bare) = ($1, $2, $3, $4);
        my $value = defined($dq) ? $dq : defined($sq) ? $sq : $bare;
        $attrs{lc $key} = decode_entities($value);
    }

    return \%attrs;
}

sub _meta_tags {
    my $html = shift;
    my @meta;
    while ($html =~ /<meta\b([^>]*)>/ig) {
        push @meta, _attrs($1);
    }
    return @meta;
}

sub _csrf_from_html {
    my $html = shift;

    for my $meta (_meta_tags($html)) {
        return $meta->{content}
          if defined($meta->{name})
          && $meta->{name} eq 'ol-csrfToken'
          && defined($meta->{content});
    }

    while ($html =~ /<input\b([^>]*)>/ig) {
        my $attrs = _attrs($1);
        return $attrs->{value}
          if defined($attrs->{name})
          && $attrs->{name} eq '_csrf'
          && defined($attrs->{value});
    }

    if ($html =~ /csrfToken["']?\s*[:=]\s*["']([^"']+)["']/) {
        return $1;
    }

    return;
}

sub _projects_from_json {
    my $text = shift;
    return if !defined($text) || $text eq q{};

    my $data = eval { decode_json($text) };
    return if $@ || !defined $data;
    return $data if ref($data) eq 'ARRAY';
    return $data->{projects} if ref($data) eq 'HASH' && ref($data->{projects}) eq 'ARRAY';
    return;
}

sub _absolute_url {
    my ($base, $url) = @_;
    return q{} if !defined $url;
    return $url if $url =~ m{\Ahttps?://}i;
    return $base . $url if $url =~ m{\A/};
    return $base . '/' . $url;
}

sub _save_or_return {
    my ($content, $to) = @_;
    return $content if !defined $to;

    open my $fh, '>:raw', $to or croak "could not write '$to': $!";
    print {$fh} $content;
    close $fh or croak "could not close '$to': $!";
    return $to;
}

1;

__END__

=head1 NAME

Webservice::Overleaf::API - Perl client helpers for Overleaf import, Git, and experimental project operations

=head1 SYNOPSIS

    use Webservice::Overleaf::API;

    my $ol = Webservice::Overleaf::API->new;

    # Official Open in Overleaf interface
    my $url = $ol->open_uri(
        uri           => 'https://example.org/paper.zip',
        engine        => 'lualatex',
        main_document => 'main.tex',
    );

    # Official Git bridge
    say $ol->git_url('0123456789abcdef');
    $ol->git_clone('0123456789abcdef', 'paper');

    # Undocumented web application interface -- opt in explicitly.
    my $web = Webservice::Overleaf::API->new(
        experimental => 1,
        session      => $ENV{OVERLEAF_SESSION},
    );

    for my $project ($web->projects->all) {
        say $project->name;
    }

    my $compile = $web->compile(
        '0123456789abcdef',
        resource_path => 'main.tex',
    );
    $web->download_pdf('0123456789abcdef', compile => $compile, to => 'paper.pdf');

=head1 DESCRIPTION

This distribution deliberately separates supported Overleaf integration surfaces
from browser-session interfaces that Overleaf does not document as a public API.

The supported side covers the C<Open in Overleaf> import interface and the
Overleaf Git bridge.  The experimental side uses the same project HTML and
compile/download endpoints used by the web application.  Those endpoints may
change without notice and therefore require C<< experimental => 1 >>.

C<Dispatch::Fu> is used for both public operation dispatch and HTTP response
classification.  C<Util::H2O::More> is used for compact construction and for
objectifying returned project and compile data.

=head1 CONSTRUCTOR

=head2 new

    my $ol = Webservice::Overleaf::API->new(
        base_url     => 'https://www.overleaf.com',
        git_base_url => 'https://git.overleaf.com',
        experimental => 0,
        session      => $ENV{OVERLEAF_SESSION},
        cookie_name  => 'overleaf_session2',
        ua           => $http_tiny_compatible_object,
        git_runner   => sub { ... },
    );

C<ua> and C<git_runner> are injectable specifically so callers and the test suite
can isolate all network and process execution.

=head1 OFFICIAL OVERLEAF INTERFACES

=head2 open_uri

Builds an C<Open in Overleaf> URL.  Accepts C<uri> or C<uris>, optional C<name>
or C<names>, and the documented C<engine>, C<main_document>, and
C<visual_editor> features.

=head2 open_data

Base64-encodes content into a data URI and returns an C<Open in Overleaf> URL.
The default MIME type is C<application/x-tex>; use C<application/zip> for a ZIP
project.

=head2 open_snippet_form

Returns an object describing a POST form to C</docs> with a raw C<snip> field.
This is useful when embedding an C<Open in Overleaf> button in an application.

=head2 project_url

Returns the normal browser/editor URL for a project.

=head2 git_url

Returns the Git bridge URL for a project.

=head2 git_clone, git_pull, git_push, git_remote_add

Run Git using list-form C<system>, avoiding shell interpolation.  Direct module
use leaves authentication to Git or to a caller-supplied C<git_runner>; the
module does not put Overleaf Git authentication tokens on the command line or
in remote URLs.  The bundled C<overleaf> CLI can supply its standardized token
through a temporary C<GIT_ASKPASS> helper.

C<git_push($directory)> retains the ordinary C<git push> behavior.  Additional
arguments are passed to C<git push>, which lets the command-line client use an
explicit Overleaf remote and the remote's discovered default/tracking branch
for its higher-level local compile workflow.

=head1 AUTHENTICATION

Overleaf divides the functionality used by this distribution across two
separate authentication systems.  They are not interchangeable:

=over 4

=item *

The official Git bridge uses a B<Git authentication token>.  The username is
C<git> and the token is the password.  Create tokens in Overleaf Account
Settings under B<Git authentication tokens>; Overleaf also offers token
generation from a project's B<Integrations -> Git> dialog.

=item *

The experimental project-listing, ZIP, compile, PDF, and build-output methods
use the B<C<overleaf_session2>> cookie from an already authenticated browser
session.

=back

The bundled C<overleaf> CLI standardizes these credentials as:

  ~/.overleaf/session
  ~/.overleaf/git-token

and also supports C<OVERLEAF_SESSION> and C<OVERLEAF_GIT_TOKEN>.  Run:

  overleaf --help

for the complete step-by-step setup, credential precedence, permission rules,
independent authentication tests, and the combined Git-push -> Overleaf-compile
-> PDF-download workflow.

=head2 Official Git bridge

For Overleaf Cloud, create a Git authentication token at:

L<https://www.overleaf.com/user/settings>

under B<Git authentication tokens>, then choose B<Generate token> and copy the
complete value when it is displayed.  Overleaf does not display the whole token
again later; generate a new one if the original value is lost.  The first use
of a project's B<Integrations -> Git> dialog can also offer B<Generate token>.

Git uses C<git> as the username and the token as the password.  The same token
can be used across the projects accessible to that account; Overleaf currently
documents a one-year expiration period.  Each collaborator should use their
own token.

Direct module use leaves credential storage to Git or to the caller's
C<git_runner>.  The bundled CLI additionally supports F<~/.overleaf/git-token>
and C<OVERLEAF_GIT_TOKEN>, passed to Git through C<GIT_ASKPASS> so the token is
not embedded in Git URLs or process arguments.

See Overleaf's current token documentation:

L<https://docs.overleaf.com/integrations-and-add-ons/git-integration-and-github-synchronization/git-integration/git-integration-authentication-tokens>

=head2 Experimental browser-session operations

The experimental project-listing, ZIP, compile, PDF, and compile-output methods
use the same authenticated browser session as the Overleaf web application.
The practical authentication method is to copy the value of the
C<overleaf_session2> cookie from a browser in which you are already logged in.

For Firefox, press F12 and open B<Storage -> Cookies ->
https://www.overleaf.com>.  For Chrome, Edge, and other Chromium-family
browsers, open B<Application -> Storage -> Cookies ->
https://www.overleaf.com>.  Find C<overleaf_session2> and copy only its
B<Value>, not the C<overleaf_session2=> prefix.

The copied value can be supplied directly:

    my $ol = Webservice::Overleaf::API->new(
        experimental => 1,
        session      => $session_value,
    );

or through the environment:

    $ENV{OVERLEAF_SESSION} = $session_value;

    my $ol = Webservice::Overleaf::API->new(
        experimental => 1,
    );

The CLI's default F<~/.overleaf/session> file contains that value on exactly one
line.  Treat it like a password.  It grants access as the logged-in Overleaf
user and must not be committed, logged, pasted into bug reports, or otherwise
disclosed.

=head2 Session lifetime

As of the Overleaf Cookie Policy last modified 5 August 2026,
C<overleaf_session2> is an authentication cookie with a documented retention
period of B<5 days>.  A copied session value should therefore be treated as a
short-lived credential and refreshed from the browser when authentication
stops working.

The five-day retention period is not a guarantee that a particular copied
session will remain valid for exactly five days.  Logging out, revocation,
rotation, security changes, or other server-side invalidation may make it stop
working earlier.

See L<https://www.overleaf.com/legal> for Overleaf's current cookie policy.

=head1 EXPERIMENTAL WEB APPLICATION INTERFACE

These methods require both C<< experimental => 1 >> and an Overleaf session
cookie.  C<OVERLEAF_SESSION> is used when C<session> is not passed directly.
See L</AUTHENTICATION> for the current browser-cookie procedure and session
lifetime.  Treat this cookie like a password and do not commit or log it.

=head2 bootstrap

Fetches the project page and obtains the CSRF token required by state-changing
web application requests.

=head2 projects

Returns the current non-archived, non-trashed projects as a C<Util::H2O::More>
objectified array.  It understands the current prefetched-project metadata and
older metadata shapes used by older/self-hosted Overleaf releases.

=head2 project_zip

Downloads a project ZIP.  With C<< to => $filename >> it writes the bytes to
that file; otherwise it returns the bytes.

=head2 compile

Compiles a project remotely and returns an object containing C<status>,
C<pdf_url>, C<compile_group>, C<clsi_server_id>, and C<output_files>.

An optional C<resource_path> requests that a particular TeX file be treated as
the root document for the compile.

=head2 download_pdf

Compiles and downloads C<output.pdf>, or accepts a previous compile result via
C<< compile => $result >>.  With C<< to => $filename >> it writes the PDF.

=head2 download_output

    $ol->download_output($compile, 'output.log', to => 'output.log');

Downloads a named compile artifact from a previous C<compile> result.

=head1 COMMAND-LINE CLIENT

The distribution includes C<overleaf>, a command-line companion implemented as
a modulino in F<bin/overleaf>.  It uses C<Util::H2O::More::Getopt2h2o> for
option handling and C<Dispatch::Fu> for command routing.

The CLI exposes the same two broad integration surfaces as the module:

=over 4

=item *

The documented Open in Overleaf interface and Git bridge.

=item *

The explicitly opt-in browser-session interface used for project listing,
project ZIP download, remote compilation, PDF retrieval, and build artifacts.

=back

For day-to-day work, the CLI standardizes its two private credentials under
F<~/.overleaf/>.  Create the directory and files once:

    mkdir -p ~/.overleaf
    chmod 700 ~/.overleaf

    # Copy only the value of the overleaf_session2 browser cookie.
    read -rsp 'Paste overleaf_session2 value: ' OL_SESSION; printf '\n'
    printf '%s\n' "$OL_SESSION" > ~/.overleaf/session
    unset OL_SESSION
    chmod 600 ~/.overleaf/session

    # Copy only the Overleaf Git authentication token.
    read -rsp 'Paste Overleaf Git token: ' OL_GIT_TOKEN; printf '\n'
    printf '%s\n' "$OL_GIT_TOKEN" > ~/.overleaf/git-token
    unset OL_GIT_TOKEN
    chmod 600 ~/.overleaf/git-token

Both files are discovered automatically.  Credential files must live below
F<~/.overleaf/> and should be created with mode C<0600>; the CLI verifies exact
mode where POSIX permissions are enforceable and handles MSYS2/Windows
C<noacl> filesystems specially.  C<OVERLEAF_SESSION> and C<OVERLEAF_GIT_TOKEN>
are supported as environment-variable alternatives.

    overleaf --experimental bootstrap

A successful bootstrap prints:

    authenticated

List projects and choose the project ID you want to work with:

    overleaf --experimental projects

    ID=0123456789abcdef

A project ZIP is the easiest way to inspect the source tree:

    overleaf --experimental \
        --output project.zip \
        zip "$ID"

    unzip -l project.zip
    unzip -l project.zip | grep -Ei '\.tex$'

There are two useful C<compile> forms.  The low-level remote form compiles
whatever is already present in an Overleaf project and lists B<build
artifacts>, not source files:

    overleaf --experimental compile "$ID"

The higher-level local form is intended for ordinary work in an Overleaf Git
checkout.  It discovers the project ID from the Git remote, requires a clean
work tree, pushes the complete committed project to Overleaf, compiles the
requested root document, and downloads the resulting PDF:

    cd my-paper
    git add .
    git commit -m 'revise paper'

    overleaf --experimental compile main.tex

The local workflow discovers the Overleaf remote branch from the current
branch's upstream or the remote C<HEAD>; it does not hard-code C<master> or
C<main>.  The complete committed project is pushed as C<HEAD:E<lt>branchE<gt>>.

This writes F<main.pdf> by default.  Omitting C<main.tex> uses Overleaf's
configured root and names the PDF from the repository directory.  C<--output>
selects a different local filename, and C<--no-push> deliberately compiles the
existing remote project without synchronizing the local checkout.

The local form treats the Git repository as the working project.  It does not
try to select only C<.tex> or C<.bib> files: LaTeX builds may depend on style
files, classes, images, generated sources, or other tracked resources.  The
project ZIP remains an export/snapshot used for inspection and backup, not an
editable staging mechanism.

The low-level C<compile PROJECT_ID> form prints the compilation status, PDF
URL, and generated files such as C<output.log>, C<output.bbl>,
C<output.chktex>, and C<output.pdf>.

A useful way to discover the root TeX document used by Overleaf is to retrieve
the compilation log and inspect its initial C<**filename.tex> line:

    overleaf --experimental \
        --output output.log \
        output "$ID" output.log

    grep -m1 '^\*\*[^*]' output.log

Once the root is known, it can be requested explicitly:

    ROOT_TEX=user_guide.tex

    overleaf --experimental \
        --resource-path "$ROOT_TEX" \
        compile "$ID"

Download the resulting PDF:

    overleaf --experimental \
        --resource-path "$ROOT_TEX" \
        --output document.pdf \
        pdf "$ID"

On a Linux desktop:

    xdg-open document.pdf >/dev/null 2>&1 &

From MSYS2/Git Bash on Windows:

    start document.pdf

The Git bridge is separate from the browser-session credential.  Git uses
Overleaf's token-based Git authentication and its normal credential handling.
For a project with Git integration enabled:

    overleaf git-url "$ID"
    overleaf clone "$ID" my-paper
    overleaf pull my-paper

After editing and committing locally, a clone whose branch already tracks the
Overleaf remote can normally be pushed with:

    overleaf push my-paper

For an existing local Git repository, add Overleaf as a named remote:

    overleaf remote-add . "$ID" overleaf
    git remote -v

Overleaf's Git bridge represents a single linear project history.  The CLI
discovers the branch tracked/advertised by the selected remote rather than
hard-coding C<master> or C<main>; C<--remote-branch NAME> is available when
local Git metadata is insufficient.

The CLI's standard private credentials are F<~/.overleaf/session> for the
browser session and F<~/.overleaf/git-token> for the Git authentication token.
Both should be created with mode C<0600>.  C<OVERLEAF_SESSION> and
C<OVERLEAF_GIT_TOKEN> are also supported.  See C<overleaf --help> for the
complete setup, MSYS2/Windows permission note, and precedence rules.

C<overleaf --help> contains the complete command reference and a more detailed
start-to-finish walkthrough.

=head1 DISPATCH INTERFACE

=head2 call

    my $projects = $ol->call('projects');
    my $git_url  = $ol->call('git_url', $project_id);

Uses C<Dispatch::Fu> to route a static operation name to the corresponding
method.  Unsupported names throw an exception.

=head1 TESTING

The distribution's tests make no live Overleaf requests.  The HTTP client and
Git runner are injected and mocked so request methods, URLs, headers, compile
bodies, error handling, binary downloads, and dispatch behavior are exercised
deterministically.

=head1 COMPATIBILITY NOTES

Overleaf documents the C<Open in Overleaf> interface and Git integration.  It
does not document the ordinary project web application's browser endpoints as a
stable public API.  The experimental implementation is informed by observable
web-client behavior and by the open-source C<olcli> project, which tracks these
endpoint changes in practice.

=head1 SEE ALSO

L<Dispatch::Fu>, L<Util::H2O::More>, L<HTTP::Tiny>,
L<https://www.overleaf.com/devs>,
L<https://www.overleaf.com/learn/how-to/Git_integration>,
L<https://www.overleaf.com/legal>,
L<https://github.com/aloth/olcli>

=head1 SCIENCE PERL CONTEXT

This distribution is general-purpose, but part of its development grew out of
a practical publishing need.  The author is a member of the Perl Community's
Science Perl Committee and a Co-Editor of the Science Perl Journal, and the
Git/Overleaf workflow supported here is useful for some of the ordinary work
of preparing, reviewing, and editing LaTeX submissions.

Nothing in this module is required in order to write for the Journal; it is
simply tooling that may make an existing Overleaf and Git workflow more
convenient.  Perl programmers doing scientific, engineering, or other
technical work are welcome to learn more about the Science Perl Committee at:

L<https://perlcommunity.org/science/>

The Science Perl Journal can be read online at:

L<https://science.perlcommunity.org/spj>

Prospective authors can find the Journal's submission information at:

L<https://science.perlcommunity.org/spj/about/submissions>

Readers interested in a printed issue can follow the Journal's announcements
for current purchase information:

L<https://science.perlcommunity.org/spj/announcement>

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

Member, Perl Community's Science Perl Committee.

Co-Editor, The Science Perl Journal.

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Brett Estrade.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
