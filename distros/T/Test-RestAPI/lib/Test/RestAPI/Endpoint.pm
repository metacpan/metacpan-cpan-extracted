package Test::RestAPI::Endpoint;
use Moo;

use Types::Standard qw(Enum Str);
use Data::Dumper;

use parent 'Exporter';

our @EXPORT_OK = qw(convert_path_to_filename);

=head1 NAME

Test::RestAPI::Endpoint - API endpoint

=head1 DESCRIPTION

This class describe API endpoint.

=head1 FUNCTIONS

=head2 convert_path_to_filename($path)

=cut
sub convert_path_to_filename {
    my ($path) = @_;

    $path =~ s/\W+/_/g;

    return $path;
}

=head1 METHODS

=head2 new(%attribute)

=head3 %attribute

=head4 path

L<Mojolicious::Routes> paths

for more examples see L<Mojolicious::Guides::Routing>

default is '/' (root)

=cut
has 'path' => (
    is      => 'ro',
    isa     => Str,
    default => '/',
);

=head4 method

HTTP method

support are C<get>|C<head>|C<options>|C<patch>|C<post>|C<put>|C<any>

default is C<get>

=cut
has 'method' => (
    is      => 'ro',
    isa     => Enum [qw(get head options path post put any)],
    default => 'get',
);

=head4 render

same arguments as L<Mojolicious::Renderer> C<render> method

=cut
has 'render' => (
    is => 'ro',
);

=head2 render_as_string

=cut
sub render_as_string {
    my ($self) = @_;

    my $dumper = Data::Dumper->new([$self->render]);
    $dumper->Indent(0);
    $dumper->Terse(1);

    return $dumper->Dump();
}

=head2 path_as_filename

=cut
sub path_as_filename {
    my ($self) = @_;

    return convert_path_to_filename($self->path);
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
