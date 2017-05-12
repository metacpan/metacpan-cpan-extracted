package Web::AssetLib::OutputEngine::String;

use Method::Signatures;
use Moose;
use Carp;

use Web::AssetLib::Util;
use Web::AssetLib::Output::Link;
use Web::AssetLib::Output::Content;

use v5.14;
no if $] >= 5.018, warnings => "experimental";

extends 'Web::AssetLib::OutputEngine';

method export (:$assets!, :$minifier?) {
    my $types  = {};
    my $output = [];

    # categorize into type groups, and seperate concatenated
    # assets from those that stand alone

    foreach my $asset ( sort { $a->rank <=> $b->rank } @$assets ) {
        if ( $asset->isPassthru ) {
            push @$output,
                Web::AssetLib::Output::Link->new(
                type => $asset->type,
                src  => $asset->link_path
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

            if ($minifier) {
                $output_contents = $minifier->minify(
                    contents => $output_contents,
                    type     => $type
                );
            }

            push @$output,
                Web::AssetLib::Output::Content->new(
                type    => $type,
                content => $output_contents
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

Web::AssetLib::OutputEngine::String - allows exporting an asset or bundle to a string

=head1 SYNOPSIS

    my $library = My::AssetLib::Library->new(
        output_engines => [
            Web::AssetLib::OutputEngine::String->new()
        ]
    );

=head1 USAGE

Include in your library's output engine list.

=head1 SEE ALSO

L<Web::AssetLib::OutputEngine>

=head1 AUTHOR
 
Ryan Lang <rlang@cpan.org>

=cut
