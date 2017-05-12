package Test::RestAPI::MojoGenerator;
use Moo;

use Mojo::Template;
use Path::Tiny;

=head1 NAME

Test::RestAPI::MojoGenerator - class for generate Mojo app

=head1 SYNOPSIS

    my $gen = Test::RestAPI::MojoGenerator->new();

    my $app_path = $gen->create_app([
        Test::RestAPI::Endpoint->new(...)
    ]);

=head1 DESCRIPTION

This class generate mojo application.

Mojo application have /app_mojo_healtcheck endpoint which return text 'OK everytime.

Each endpoint append request body to file.

=head1 METHODS

=head2 new(%attribute)

=head3 %attribute

=cut

=head2 create_app($endpoints)

list (ArrayRef) of L<Test::RestAPI::Endpoint>

create mojo app with C<$endpoints> and return temp file with application

=cut
sub create_app {
    my ($self, $endpoints) = @_;

    my $app_path = Path::Tiny->tempfile();

    $app_path->spew(Mojo::Template->new->render(<<'EOF', $endpoints));
% my ($endpoints) = @_;
use Mojolicious::Lite;
use Path::Tiny;
use Mojo::JSON qw(encode_json);

% foreach my $endpoint (@$endpoints) {
<%= $endpoint->method %> '<%= $endpoint->path %>' => sub {
    my ($c) = @_;

    path(app->home(), "<%= $endpoint->path_as_filename %>")->append(encode_json($c->req->body)."\n");

    $c->render(%{<%= $endpoint->render_as_string %>});
};
% }

any '/app_mojo_healtcheck' => sub {
    my ($c) = @_;

    $c->render(text => 'OK');
};

app->start();
EOF

    return $app_path;
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
