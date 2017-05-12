package Test::JSON::RPC::Autodoc;
use 5.008001;
use strict;
use warnings;
use File::ShareDir;
use Path::Tiny qw/path/;
use Text::Xslate;
use Test::JSON::RPC::Autodoc::Request;

our $VERSION = "0.15";

sub new {
    my ($class, %opt) = @_;
    my $app = $opt{app} or die 'app parameter must not be null!';
    my $self = bless {
        app => $app,
        document_root => $opt{document_root} || 'docs',
        path => $opt{path} || '/',
        requests => [],
        index_file => $opt{index_file} || undef,
    }, $class;
    return $self;
}

sub new_request {
    my ($self, $label) = @_;
    my $req = Test::JSON::RPC::Autodoc::Request->new(
        app => $self->{app},
        path => $self->{path},
        label => $label || '',
    );
    push @{$self->{requests}}, $req;
    return $req;
}

sub write {
    my ($self, $filename) = @_;
    my $tx = $self->load_tx();
    my $text = $tx->render('template.tx', { requests => $self->{requests} });
    path($self->{document_root}, $filename)->spew_utf8($text);
    $self->append_to_index($filename) if $self->{index_file};
}

sub append_to_index {
    my ($self, $filename) = @_;
    my $tx = $self->load_tx();
    my $text = $tx->render('index_part.tx', {
        requests => $self->{requests},
        path => path($filename),
    });
    my $path = path($self->{document_root}, $self->{index_file});
    $path->append_utf8($text);
}

sub load_tx {
    my $dir = './share';
    $dir = File::ShareDir::dist_dir('Test-JSON-RPC-Autodoc') unless -d $dir;
    return Text::Xslate->new( path => $dir );
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::JSON::RPC::Autodoc - Testing tools for auto generating documents of JSON-RPC applications

=head1 SYNOPSIS

    use Test::More;
    use Plack::Request;
    use JSON qw/to_json from_json/;
    use Test::JSON::RPC::Autodoc;

    # Making a PSGI-based JSON-RPC application
    my $app = sub {
        my $env  = shift;
        my $req  = Plack::Request->new($env);
        my $ref  = from_json( $req->content );
        my $data = {
            jsonrpc => '2.0',
            id      => 1,
            result  => $ref->{params},
        };
        my $json = to_json($data);
        return [ 200, [ 'Content-Type' => 'application/json' ], [$json] ];
    };

    # Let's test
    my $test = Test::JSON::RPC::Autodoc->new(
        document_root => './docs',
        app           => $app,
        path          => '/rpc'
    );

    my $rpc_req = $test->new_request();
    $rpc_req->params(
        language => { isa => 'Str', default => 'English', required => 1 },
        country  => { isa => 'Str', documentation => 'Your country' }
    );
    $rpc_req->post_ok( 'echo', { language => 'Perl', country => 'Japan' } );
    my $res  = $rpc_req->response();
    my $data = $res->from_json();
    is_deeply $data->{result}, { language => 'Perl', country => 'Japan' };

    $test->write('echo.md');
    done_testing();

=head1 DESCRIPTION

B<Test::JSON::RPC::Autodoc> is a software for testing JSON-RPC Web applications. These modules generate the Markdown formatted documentations about RPC parameters, requests, and responses. Using B<Test::JSON::RPC::Autodoc>, we just write and run the integrated tests, then documents will be generated. So it will be useful to share the JSON-RPC parameter rules with other developers.

=head1 METHODS

=head2 Test::JSON::RPC::Autodoc

=head3 B<< new(%options) >>

    my $test = Test::JSON::RPC::Autodoc->new(
        app => $app,
        document_root => './documents',
        path => '/rpc'
    );

Create a new Test::JSON::RPC::Autodoc instance. Possible options are:

=over

=item C<< app => $app >>

PSGI application, required.

=item C<< document_root => './documents' >>

Output directory for documents, optional, default is './docs'.

=item C<< path => '/rpc' >>

JSON-RPC endpoint path, optional, default is '/'.

=back

=head3 B<< new_request() >>

Return a new Test::JSON::RPC::Autodoc::Request instance.

=head3 B<< write('echo.md') >>

Save the document named as a given parameter filename.

=head2 Test::JSON::RPC::Autodoc::Request

Test::JSON::RPC::Autodoc::Request is a sub-class of L<HTTP::Request>. Extended with these methods.

=head3 B<< $request->params(%options) >>

    $request->params(
        language => { isa => 'Str', default => 'English', required => 1, documentation => 'Your language' },
        country => { isa => 'Str', documentation => 'Your country' }
    );

Take parameters with the rules for calling JSON-RPC a method.
To validate parameters this module use L<Data::Validator> module internal.
Attributes of rules are below:

=over

=item C<< isa => $type: Str >>

The type of the property, which can be C<Mouse> Type constraint name.

=item C<< required => $value: Bool >>

If true, the parameter must be set.

=item C<< default => $value: Str >>

The default value for the parameter. If the argument is blank, this value will be used.

=item C<< documentation => $doc: Str >>

Description of the parameter. This will be used when the Markdown documents are generated.

=back

=head3 B<< $request->post_ok($method, $params) >>

    $request->post_ok('echo', { language => 'Perl', country => 'Japan' });

Post parameters to the specified method on your JSON-RPC application and check the parameters as tests.
If the response code is 200, it will return C<OK>.

=head3 B<< $request->post_not_ok($method, $params) >>

If the parameters are not valid or the response code is not C<200>, it will be passed.

=head3 B<< $request->response() >>

Return the last response as a Test::JSON::RPC::Autodoc::Response instance.

=head2 Test::JSON::RPC::Autodoc::Response

This module extends L<HTTP::Response> with the methods below:

=head3 B<< $response->from_json() >>

Return a Perl-Object of the JSON response content. That is parsed by JSON parser.

=head1 SEE ALSO

=over

=item L<Test::JsonAPI::Autodoc>

=item L<https://github.com/r7kamura/autodoc>

=item L<Shodo>

=item L<Data::Validator>

=back

=head1 LICENSE

Copyright (C) Yusuke Wada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Wada E<lt>yusuke@kamawada.comE<gt>

=cut

