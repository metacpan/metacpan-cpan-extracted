package Web::AssetLib::Output;

use Moo;
use Types::Standard qw/Str HashRef/;

has 'type' => (
    is  => 'rw',
    isa => Str
);

has 'default_html_attrs' => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} }
);

1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::Output - base class for generated output

=head1 SEE ALSO

L<Web::AssetLib::OutputEngine::String>
L<Web::AssetLib::Output::Link>

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut
