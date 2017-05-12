package Web::AssetLib::OutputEngine::LocalFile;

use Method::Signatures;
use Moose;
use Carp;

use Web::AssetLib::Util;
use Web::AssetLib::Output::Link;

use Path::Tiny;

use v5.14;
no if $] >= 5.018, warnings => "experimental";

extends 'Web::AssetLib::OutputEngine';

has 'output_path' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

# should correspond with the root of output_path
has 'link_path' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

method export (:$assets!, :$minifier?) {
    my $types  = {};
    my $output = [];

    # categorize into type groups, and seperate concatenated
    # assets from those that stand alone

    foreach my $asset ( sort { $a->rank <=> $b->rank } @$assets ) {
        if ( $asset->isPassthru ) {
            push @$output,
                Web::AssetLib::Output::Link->new(
                src                => $asset->link_path,
                type               => $asset->type,
                default_html_attrs => $asset->default_html_attrs
                );
        }
        else {
            for ( $asset->type ) {
                when (/css|js/) {

                    # should concatenate
                    $$types{ $asset->type }{_CONCAT_}
                        .= $asset->contents . "\n\r\n\r";
                }
                default {
                    $$types{ $asset->type }{ $asset->digest }
                        = $asset->contents;
                }
            }
        }
    }

    foreach my $type ( keys %$types ) {
        foreach my $id ( keys %{ $$types{$type} } ) {
            my $output_contents = $$types{$type}{$id};

            my $digest
                = $id eq '_CONCAT_'
                ? $self->generateDigest($output_contents)
                : $id;

            my $filename    = "$digest.$type";
            my $output_path = path( $self->output_path )->child($filename);
            my $link_path   = path( $self->link_path )->child($filename);

# # output pre-minify
# my $output_path_debug = path( $self->output_path )->child($filename.".orig.$type");
# unless($output_path_debug->exists){
#     $output_path_debug->touchpath;
#     $output_path_debug->spew_utf8($output_contents);
# }

            unless ( $output_path->exists ) {
                $output_path->touchpath;

                if ($minifier) {
                    $output_contents = $minifier->minify(
                        contents => $output_contents,
                        type     => $type
                    );
                }

                $output_path->spew_utf8($output_contents);
            }

            push @$output,
                Web::AssetLib::Output::Link->new(
                src  => "$link_path",
                type => $type
                );
        }
    }

    return $output;
}

no Moose;
1;

=pod
 
=encoding UTF-8
 
=head1 NAME

Web::AssetLib::OutputEngine::LocalFile - allows exporting an asset or bundle to your local filesystem

=head1 SYNOPSIS

    my $library = My::AssetLib::Library->new(
        output_engines => [
            Web::AssetLib::OutputEngine::LocalFile->new(
                output_path => '/my/local/output/path',
                link_path => '/output/path/relative/to/webserver'
            )
        ]
    );

=head1 USAGE

Instantiate with C<< output_path >> and C<< link_path >> parameters, and include in your library's
output engine list.

=head1 ATTRIBUTES
 
=head2 output_path
 
String; the absolute path that the compiled assets should be exported to

=head2 link_path
 
String; the path relative to your webserver root, which points to the L<< /output_path >>.
Used in generating HTML tags.

=head1 SEE ALSO

L<Web::AssetLib::OutputEngine>

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut
