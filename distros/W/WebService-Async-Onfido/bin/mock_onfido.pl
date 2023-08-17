## no critic (RequireExplicitPackage RequireEndWithOne)

use strict;
use warnings;

use Clone 'clone';
use Date::Utility;
use Data::UUID;
use File::Basename;
use Path::Tiny;
use JSON::MaybeUTF8 qw(:v1);

# New HTTP server implementation
use Net::Async::HTTP::Server;
use IO::Async::Loop;
use HTTP::Response;

# This is the server in-memory storage
my %applicants;
my %deleted_applicants;
my %documents;
my %photos;
my %files;
my %reports;
my %checks;
my @sdk_tokens;

# storage utilities

sub create_report {
    my ($params, $check_id, $applicant_id) = @_;
    my @reports;
    my @document_ids =
        map { $_->{id} }
        grep { $_->{_applicant_id} eq $applicant_id } values %documents;
    for my $req ($params->{report_names}->@*) {
        my $report_id = Data::UUID->new->create_str();
        my $report    = {
            id         => $report_id,
            _check_id  => $check_id,
            created_at => Date::Utility->new()->datetime_iso8601,
            name       => $req,
            status     => 'complete',
            result     => 'clear',
            breakdown  => {},
            properties => {document_type => 'passport'},
            $req eq 'document'
            ? (documents => [map { {id => $_} } @document_ids])
            : (),
        };
        $reports{$report_id} = $report;
        push @reports, $report_id;
    }
    return [map { clone_and_remove_private($_) } @reports];
}

sub clone_and_remove_private {
    my $result = shift;

    return $result unless $result && ref($result) eq 'HASH';
    $result = clone($result);
    for my $k (keys %$result) {
        if ($k =~ /^_/) {
            delete $result->{$k};
        }
    }

    return $result;
}

# Router for the HTTP server
# nested hashref: http method -> path -> controller

my $router = {
    post => {
        '/v3.4/applicants' => sub {
            my $req       = shift;
            my $data      = decode_json_utf8($req->body);
            my $id        = Data::UUID->new->create_str();
            my $applicant = {
                id         => $id,
                created_at => Date::Utility->new()->datetime_iso8601,
                href       => "v3.4/applicants/$id",
            };
            for my $k (keys %$data) {
                $applicant->{$k} = $data->{$k};
            }
            $applicants{$id} = $applicant;

            return json_response($req, $applicant);
        },
        '/v3.4/documents' => sub {
            my $req          = shift;
            my $data         = multipart_data($req);
            my $applicant_id = $data->{applicant_id}->{value};
            my $document_id  = Data::UUID->new->create_str();
            my $file         = $data->{file};
            my $document     = {
                id            => $document_id,
                created_at    => Date::Utility->new()->datetime_iso8601,
                href          => "/v3.4/documents/$document_id",
                download_href => "/v3.4/documents/$document_id/download",
                _applicant_id => $applicant_id,
                file_name     => basename($data->{file}->{filename}),
                file_size     => length $data->{file}->{value},
                file_type     => $data->{file}->{headers}->{'Content-Type'},
            };
            for my $param (qw(type side issuing_country)) {
                $document->{$param} = $data->{$param}->{value};
            }

            $files{$document_id} = Path::Tiny->tempfile;
            $files{$document_id}->spew_raw($data->{file}->{value});
            $documents{$document_id} = $document;
            return json_response($req, clone_and_remove_private($document));
        },
        '/v3.4/live_photos' => sub {
            my $req          = shift;
            my $data         = multipart_data($req);
            my $applicant_id = $data->{applicant_id}->{value};

            # don't know how to used yet
            #my $advanced_validation = $c->param('advanced_validation');
            my $photo_id = Data::UUID->new->create_str();
            my $photo    = {
                id            => $photo_id,
                created_at    => Date::Utility->new()->datetime_iso8601,
                href          => "/v3.4/live_photos/$photo_id",
                download_href => "/v3.4/live_photos/$photo_id/download",
            };
            my $file = $data->{file};
            $photo->{file_name} = basename($data->{file}->{filename});
            $photo->{file_size} = length $data->{file}->{value};
            $photo->{file_type} = $data->{file}->{headers}->{'Content-Type'};
            $files{$photo_id}   = Path::Tiny->tempfile;
            $files{$photo_id}->spew_raw($data->{file}->{value});
            $photo->{_applicant_id} = $applicant_id;
            $photos{$photo_id} = $photo;

            return json_response($req, clone_and_remove_private($photo));
        },
        '/v3.4/checks' => sub {
            my $req          = shift;
            my $data         = decode_json_utf8($req->body);
            my $applicant_id = $data->{applicant_id};
            my $check_id     = Data::UUID->new->create_str();
            my $check        = {
                id           => $check_id,
                created_at   => Date::Utility->new()->datetime_iso8601,
                href         => "/v3.4/checks/$check_id",
                status       => 'in_progress',
                result       => 'clear',
                redirect_uri => 'https://somewhere.else',
                results_uri  => "https://onfido.com/dashboard/information_requests/<REQUEST_ID>",
                reports_ids  => create_report($data, $check_id, $applicant_id),
                tags         => $data->{tags},
                applicant_id => $applicant_id,
            };
            $checks{$check_id} = $check;

            return json_response($req, clone_and_remove_private($check));
        },
        '/v3.4/sdk_token' => sub {
            my $req          = shift;
            my $data         = decode_json_utf8($req->body);
            my $applicant_id = $data->{applicant_id};
            my $referrer     = $data->{referrer};
            unless (exists($applicants{$applicant_id}) && $referrer) {
                return json_response($req, {status => 'Not Found'});
            }
            my $sdk_token = {
                token        => Data::UUID->new->create_str(),
                applicant_id => $applicant_id,
                referrer     => $referrer,
            };
            push @sdk_tokens, $sdk_token;
            return json_response($req, $sdk_token);
        },
    },
    get => {
        '/v3.4/applicants' => sub {
            my $req = shift;
            return json_response($req, {applicants => [sort { $b->{created_at} cmp $a->{created_at} } values %applicants]});
        },
        '/v3.4/applicants/:id' => sub {
            my $req   = shift;
            my @stash = route_params($req);
            my $id    = $stash[2];

# There is no description that what result should be if there is no such applicant.
# So return 'Not Found' temporarily
            my $applicant = $applicants{$id} // {status => 'Not Found'};

            return json_response($req, $applicant);
        },
        '/v3.4/documents' => sub {
            my $req          = shift;
            my $query        = +{$req->query_form};
            my $applicant_id = $query->{applicant_id};

            my @documents =
                sort { $b->{created_at} cmp $a->{created_at} }
                map  { clone_and_remove_private($_) }
                grep { $_->{_applicant_id} eq $applicant_id } values %documents;

            return json_response($req, {documents => \@documents});
        },
        '/v3.4/documents/:id' => sub {
            my $req         = shift;
            my @stash       = route_params($req);
            my $document_id = $stash[2];

            unless (exists($documents{$document_id})) {
                return json_response($req, {status => 'Not Found'});
            }

            return json_response($req, clone_and_remove_private($documents{$document_id}));
        },
        '/v3.4/documents/:document_id/download' => sub {
            my $req         = shift;
            my @stash       = route_params($req);
            my $document_id = $stash[2];

            unless (exists($documents{$document_id})) {
                return json_response($req, {status => 'Not Found'});
            }

            return file_response($req, $document_id);
        },
        '/v3.4/live_photos' => sub {
            my $req          = shift;
            my $query        = +{$req->query_form};
            my $applicant_id = $query->{applicant_id};

            my @photos =
                sort { $b->{created_at} cmp $a->{created_at} }
                map  { clone_and_remove_private($_) }
                grep { $_->{_applicant_id} eq $applicant_id } values %photos;

            return json_response($req, {live_photos => \@photos});
        },
        '/v3.4/live_photos/:photo_id' => sub {
            my $req      = shift;
            my @stash    = route_params($req);
            my $photo_id = $stash[2];

            unless (exists($photos{$photo_id})) {
                return json_response($req, {status => 'Not Found'});
            }

            return json_response($req, clone_and_remove_private($photos{$photo_id}));
        },
        '/v3.4/live_photos/:photo_id/download' => sub {
            my $req      = shift;
            my @stash    = route_params($req);
            my $photo_id = $stash[2];

            unless (exists($photos{$photo_id})) {
                return json_response($req, {status => 'Not Found'});
            }

            return file_response($req, $photo_id);
        },
        '/v3.4/checks/:check_id' => sub {
            my $req      = shift;
            my @stash    = route_params($req);
            my $check_id = $stash[2];

            unless (exists($checks{$check_id})) {
                return json_response($req, {status => 'Not Found'});
            }
            $checks{$check_id}{status} = 'complete';
            return json_response($req, clone_and_remove_private($checks{$check_id}));
        },
        '/v3.4/checks' => sub {
            my $req          = shift;
            my $query        = +{$req->query_form};
            my $applicant_id = $query->{applicant_id};

            my @checks =
                sort { $b->{created_at} cmp $a->{created_at} }
                map  { clone_and_remove_private($_) }
                grep { $_->{applicant_id} eq $applicant_id } values %checks;
            return json_response($req, {checks => \@checks});
        },
        '/v3.4/reports' => sub {
            my $req      = shift;
            my $query    = +{$req->query_form};
            my $check_id = $query->{check_id};

            my @reports =
                sort { $b->{created_at} cmp $a->{created_at} }
                map  { clone_and_remove_private($_) }
                grep { $_->{_check_id} eq $check_id } values %reports;
            return json_response($req, {reports => \@reports});
        },
        '/v3.4/reports/:report_id' => sub {
            my $req       = shift;
            my @stash     = route_params($req);
            my $report_id = $stash[2];
            unless (exists($reports{$report_id})) {
                return json_response($req, {status => 'Not Found'});
            }
            return json_response($req, clone_and_remove_private($reports{$report_id}));
        },
    },
    put => {
        '/v3.4/applicants/:id' => sub {
            my $req       = shift;
            my @stash     = route_params($req);
            my $id        = $stash[2];
            my $applicant = $applicants{$id};
            my $data      = decode_json_utf8($req->body);
            for my $k (keys %$data) {
                $applicant->{$k} = $data->{$k};
            }

            return json_response($req, $applicant);
        }
    },
    delete => {
        '/v3.4/applicants/:id' => sub {
            my $req   = shift;
            my @stash = route_params($req);
            my $id    = $stash[2];

            if (exists $applicants{$id}) {
                $deleted_applicants{$id} = delete $applicants{$id};
                $deleted_applicants{$id}->{delete_at} =
                    Date::Utility->new()->datetime_iso8601;
            }

            # no content
            return HTTP::Response->new(204);
        }
    }};

# here lies the http server

my $httpserver = Net::Async::HTTP::Server->new(
    on_request => sub {
        my $self = shift;
        my ($req) = @_;

        my $controller = $router->{lc $req->method}->{$req->path};

        # parametric route pairing
        # if some route is parametric (e.g: /:document_id)
        # we will split that path and compare coincidences against the router
        # a full coincidence would resolve to that controller
        unless ($controller) {
            for my $route (keys $router->{lc $req->method}->%*) {
                my @path_chunks  = split /\//, $req->path;
                my @route_chunks = split /\//, $route;

                next unless scalar @route_chunks == scalar @path_chunks;

                my @matching_chunks = grep {
                    my $path_chunk = shift @path_chunks;

# a parametric path can be considered a coincidence regardless of the actual path value
# at that position
                    $_ =~ /^:.*/ ? 1 : $_ eq $path_chunk;
                } @route_chunks;

                $controller = $router->{lc $req->method}->{$route}
                    if scalar @matching_chunks == scalar @route_chunks;

                last if $controller;
            }
        }

        $controller
            ? $req->respond($controller->($req))
            : $req->respond(HTTP::Response->new(404));
    },
);

# Run the HTTP server

my $loop = IO::Async::Loop->new();
$loop->add($httpserver);

$httpserver->listen(
    addr => {
        family   => "inet6",
        socktype => "stream",
        port     => 3000
    },
)->get;

$loop->run;

sub END {
    for my $f (values %files) {
        print "removing $f\n";
        $f->remove;
    }

    $loop->stop;
}

# HTTP SERVER UTILITIES

# sends a json response

sub json_response {
    my ($req, $payload) = @_;

    my $response = HTTP::Response->new(200);
    my $json     = encode_json_utf8($payload);

    $response->add_content($json);
    $response->content_type('application/json');
    $response->content_length(length $response->content);

    return $response;
}

# dumps a file

sub file_response {
    my ($req, $id) = @_;

    my $response = HTTP::Response->new(200);
    $response->add_content($files{$id}->slurp_raw);

    my $data = $documents{$id} // $photos{$id};

    $response->content_type($data->{file_type});
    $response->content_length($data->{file_size});
    $response->header('content-disposition' => 'attachment; filename="' . $data->{file_name} . '";');

    return $response;
}

# fetch route params

sub route_params {
    my ($req) = @_;

    return grep { $_ ne '' } split /\//, $req->path;
}

# fetch mulitpart form data

sub multipart_data {
    my ($req) = @_;

    my $content_type = +{map { @$_ } $req->headers}->{'Content-Type'};

    my ($boundary) = $content_type =~ /^multipart\/form-data; boundary=(.*)$/;

    return {} unless $boundary;

    my @parts       = split /[\r\n]/, $req->body;
    my $blanks      = 0;
    my $blank_spree = 0;
    my $is_blank;
    my $is_at_boundary;
    my $header;
    my $value;
    my $name;
    my $data      = {};
    my $headers   = {};
    my $meta      = {};
    my $body_mode = 0;

    # a good enough multipart parser

    for my $part (@parts) {
        $is_at_boundary = $part eq "--$boundary" || $part eq "--$boundary--";

        # clean up if at boundary
        $data->{$name} = {
            value   => $value,
            headers => {$headers->%*},
            $meta->%*
            }
            if $name && $value;
        $blanks      = 0     if $is_at_boundary;
        $blank_spree = 0     if $is_at_boundary;
        $body_mode   = 0     if $is_at_boundary;
        $name        = undef if $is_at_boundary;
        $value       = ''    if $is_at_boundary;
        $headers     = {}    if $is_at_boundary;
        $meta        = {}    if $is_at_boundary;

        next if $is_at_boundary;

        # blanks counter
        $is_blank = $part eq '';

        $blanks++ if $is_blank;

        $blank_spree++ if $is_blank;

        $blank_spree = 0 unless $is_blank;

        # activate body mode

        $body_mode = 1 if $blank_spree > 2;

        next if $is_blank;

        # while body mode is off, process the headers

        $header = $part unless $body_mode;

        $header = undef if $body_mode;

        # specific name of the field
        my $field_name;

        ($field_name) = $header =~ /^Content-Disposition: form-data; name=\"(.*?)\"/
            if $header;

        # extract the file name if any
        my $file_name;

        ($file_name) = $header =~ /^Content-Disposition: form-data;.*filename=\"(.*?)\"/
            if $header;

        # process the headers

        my $header_name;
        my $header_value;
        ($header_name, $header_value) = split ': ', $header if $header;

        $headers->{$header_name} = $header_value if $header;

        $name             = $field_name if $field_name;
        $meta->{filename} = $file_name  if $file_name;

        next unless $name;

        # while body mode is on, add to the field value

        $value .= $part if $body_mode;
    }

    return $data;
}
