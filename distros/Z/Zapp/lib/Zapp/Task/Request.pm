package Zapp::Task::Request;
# ABSTRACT: Make an HTTP Request

#pod =head1 DESCRIPTION
#pod
#pod This task makes an HTTP request for a web site.
#pod
#pod =head2 Output
#pod
#pod     is_success          - True if the response was successful
#pod     code                - The response code (like 200 or 404)
#pod     message             - The HTTP message (like "OK" or "Not Found")
#pod     json                - If the response was JSON, the decoded JSON structure
#pod     file                - If the response was a file, the path to the file
#pod     body                - If the response was anything else, the response body
#pod     headers             - The headers from the response as a hash
#pod         content_type    - The Content-Type header
#pod         location        - The Location header
#pod
#pod =head1 SEE ALSO
#pod
#pod =cut

use Mojo::Base 'Zapp::Task', -signatures;
use Mojo::JSON qw( false true encode_json );

sub schema( $class ) {
    return {
        input => {
            type => 'object',
            required => [qw( url )],
            properties => {
                url => {
                    type => 'string',
                },
                method => {
                    type => 'string',
                    enum => [qw( GET POST PUT DELETE PATCH OPTIONS PROPFIND )],
                    default => 'GET',
                },
                auth => {
                    type => 'object',
                    properties => {
                        type => {
                            type => 'string',
                            enum => [ '', qw( bearer )],
                        },
                        token => {
                            type => 'string',
                        },
                    },
                    additionalProperties => false,
                },
                content_type => {
                    type => 'string',
                    enum => ['', qw( application/octet-stream application/json )],
                    default => '',
                },
                # XXX: Query params / Form params
                # XXX: Request headers
                # XXX: Cookies (must be easily passed between requests,
                # or automatically saved to the context)
                # XXX: JSON subclass that parses JSON responses
                # XXX: DOM subclass that extracts DOM text/attrs
            },
            additionalProperties => false,
        },
        output => {
            type => 'object',
            properties => {
                is_success => {
                    type => 'boolean',
                },
                code => {
                    type => 'integer',
                    minValue => 100,
                    maxValue => 599,
                },
                message => {
                    type => 'string',
                },
                body => {
                    type => 'string',
                },
                headers => {
                    type => 'object',
                    properties => {
                        content_type => {
                            type => 'string',
                        },
                    },
                    additionalProperties => false,
                },
            },
            additionalProperties => false,
        },
    };
}

sub run( $self, $input ) {
    # XXX: Need a way to see what type of input was given so we can
    # decide what to do with it if we need to. Then we wouldn't have to
    # have different input fields for different types...
    my $body;
    if ( $input->{content_type} eq 'application/octet-stream' ) {
        $body = Mojo::Asset::File->new( path => $input->{body}{file} )->slurp;
    }
    elsif ( $input->{content_type} eq 'application/json' ) {
        $body = $input->{body}{json};
        $body = encode_json( $body ) if ref $body;
    }

    my $ua = $self->app->ua;
    $ua->max_redirects( $input->{max_redirects} // 10 );
    #; $self->app->log->debug( 'input: ' . $self->app->dumper( $input ) );
    my %headers;
    if ( $input->{auth} && $input->{auth}{type} eq 'bearer' ) {
        $headers{ Authorization } = join ' ', 'Bearer', $input->{auth}{token};
    }
    if ( $input->{content_type} ) {
        $headers{ 'Content-Type' } = $input->{content_type};
    }

    my $tx = $ua->build_tx(
        $input->{method} => $input->{url},
        \%headers,
        $input->{content_type} ? ( $body ) : (),
    );
    $tx = $ua->start( $tx );
    # ; use Data::Dumper;
    # ; say Dumper $tx->res;
    my $method = !$tx->res->error ? 'finish' : 'fail';

    my @res_body;
    if ( $tx->res->headers->content_type eq 'application/octet-stream' ) {
        my ( $filename ) = grep !!$_, reverse split m{/}, $input->{url};
        if ( $tx->res->headers->content_disposition =~ m{filename\*?=['"]?([^'"]+)['"]?} ) {
            $filename = $1;
        }
        my $path = $self->app->static->paths->[0];
        my $file = Mojo::File->new( $path, 'task', 'request', $self->id, $filename );
        $file->dirname->make_path;
        $file->spurt( $tx->res->body );
        @res_body = (
            file => '/' . $file->to_rel( $self->app->home->child( 'public' ) ),
        );
        #; $self->app->log->debug( 'File content: ' . $file->slurp );
    }
    elsif ( $tx->res->headers->content_type =~ m{^application/json} ) {
        @res_body = ( json => $tx->res->json );
    }
    elsif ( $tx->res->headers->content_type =~ m{^text/} ) {
        @res_body = ( body => $tx->res->body );
    }

    $self->$method({
        is_success => !defined $tx->res->error,
        (
            map { $_ => $tx->res->$_ }
            qw( code message )
        ),
        # XXX: Use $tx->res->headers->to_hash after Formula has a way to
        # look up hash keys with special characters
        headers => {
            map { $_ => $tx->res->headers->$_ }
            grep { $tx->res->headers->$_ }
            qw( content_type location )
        },
        @res_body,
    });
}

1;

=pod

=head1 NAME

Zapp::Task::Request - Make an HTTP Request

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This task makes an HTTP request for a web site.

=head2 Output

    is_success          - True if the response was successful
    code                - The response code (like 200 or 404)
    message             - The HTTP message (like "OK" or "Not Found")
    json                - If the response was JSON, the decoded JSON structure
    file                - If the response was a file, the path to the file
    body                - If the response was anything else, the response body
    headers             - The headers from the response as a hash
        content_type    - The Content-Type header
        location        - The Location header

=head1 SEE ALSO

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

@@ input.html.ep
<%
    my $input = stash( 'input' ) // { method => 'GET' };
    $input->{method} //= 'GET';
    $input->{auth} //= { type => '' };
%>

<div class="form-row">
    <div class="col-auto">
        <label for="method">Method</label>
        <%= select_field method =>
            [ map { $input->{method} eq $_ ? [ $_, $_, selected => 'selected' ] : $_ } qw( GET POST PUT DELETE PATCH ) ],
            class => 'form-control',
        %>
    </div>
    <div class="col">
        <label for="url">URL</label>
        %= text_field 'url', value => $input->{url}, class => 'form-control'
    </div>
</div>

<div class="form-group">
    <label for="max_redirects">Follow Redirects?</label>
    <%= include 'zapp/partials/yes_no_field', name => 'max_redirects',
        yes_value => 10, no_value => 0,
        value => $input->{max_redirects} // 10,
    %>
</div>

<div class="form-row">
    <div class="col">
        <label for="content_type">Request Body Type</label>
        <%= select_field 'content_type' =>
            [
                [ 'None' => '' ],
                [ 'File' => 'application/octet-stream', ($input->{content_type}//'') eq 'application/octet-stream' ? ( selected => 'selected' ) : () ],
                [ 'JSON' => 'application/json', ($input->{content_type}//'') eq 'application/json' ? ( selected => 'selected' ) : () ],
            ],
            class => 'form-control',
        %>
    </div>
</div>
<div data-zapp-if="content_type eq 'application/json'" class="form-row">
    <div class="col">
        <label for="body.json">JSON Body</label>
        <div class="grow-wrap">
            <%= text_area "body.json", $input->{body}{json}, class => 'form-control',
                oninput => 'this.parentNode.dataset.replicatedValue = this.value',
            %>
        </div>
    </div>
</div>
<div data-zapp-if="content_type eq 'application/octet-stream'" class="form-row">
    <div class="col">
        <label for="body.file">File</label>
        <%= text_field "body.file", $input->{body}{file}, class => 'form-control' %>
    </div>
</div>

<div class="form-row">
    <div class="col-auto">
        <label for="auth.type">Authentication</label>
        <%= select_field 'auth.type' =>
            [
                [ 'None' => '' ],
                [ 'Bearer Token' => 'bearer', $input->{auth}{type} eq 'bearer' ? ( selected => 'selected' ) : () ],
            ],
            class => 'form-control',
        %>
    </div>
    <div data-zapp-if="auth.type eq 'bearer'" class="col align-self-end <%= $input->{auth}{type} eq 'bearer' ? 'zapp-visible' : '' %>">
        %= text_field 'auth.token', value => $input->{auth}{token}, class => 'form-control'
    </div>
</div>

@@ output.html.ep
% if ( $task->{output} && !ref $task->{output} ) {
    <h4>Error</h4>
    <div data-error class="alert alert-danger"><%= $task->{output} %></div>
% } elsif ( $task->{output} ) {
    <h4>Response</h4>
    <dl>
        <dt>Code</dt>
        <dd><%= $task->{output}{code} %> <%= $task->{output}{message} %></dd>
        <dt>Content-Type</dt>
        <dd><%= $task->{output}{headers}{content_type} // '' %></dd>
    </dl>
    % if ( my $data = $task->{output}{json} ) {
        <pre data-output class="bg-light border border-secondary p-1"><%= dumper $data %></pre>
    % }
    % elsif ( my $file = $task->{output}{file} ) {
        <a class="btn btn-outline-primary" href="<%= $file %>">Download File</a>
    % }
    % elsif ( my $body = $task->{output}{body} ) {
        <pre class="bg-light border border-secondary p-1"><%= $body %></pre>
    % }
% }
%= include 'zapp/more_info', content => begin
    <h4>Request</h4>
    <pre data-input class="bg-light border border-secondary p-1"><%= $task->{input}{method} %> <%= $task->{input}{url} %></pre>
% end
