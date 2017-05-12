package WWW::Tumblr::ThemeParser;
use strict;
use base qw( Class::Accessor::Fast );

use 5.008_001;
use HTML::TokeParser;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors( qw( tokens index settings ) );

my $Tags = qr/(\{(\/?[\w\s\-:]+)\})/;

sub new {
    my $class = shift;
    my( $data ) = @_;
    my $parser = $class->SUPER::new( {
        tokens      => [],
        settings    => {},
        index       => 0,
    } );
    if ( defined $data ) {
        $parser->_tokenize( $data );
        $parser->_extract_settings( $data );
    }
    return $parser;
}

sub _tokenize {
    my $parser = shift;
    my( $text_ref ) = @_;

    my @tokens;
    my $pos = 0;

    my %in;
    while ( $$text_ref =~ /$Tags/gs ) {
        my( $match, $tag ) = ( $1, $2 );
        my $tag_start = pos( $$text_ref ) - length $match;

        # Is there any text between the last tag and this one? If so,
        # grab it and create a Text token.
        if ( $pos < $tag_start ) {
            push @tokens, [ 'TEXT', substr( $$text_ref, $pos, $tag_start - $pos ) ];
        }

        if ( $tag =~ /^(\/?)block:/ ) {            
            my $type = $1 ? 'EBLOCK' : 'SBLOCK';

            # Tumblr's parser doesn't allow nested block tags, so with HTML
            # like "{block:Title}...{block:Title}", the second "{block:Title}"
            # is treated as an end tag, even though it doesn't have a slash.
            # Implement the same behavior here by tracking which blocks
            # we're inside of, and turning what would appear to be nested
            # blocks into a single contained block.
            if ( $type eq 'SBLOCK' && exists $in{ $tag } ) {
                $type = 'EBLOCK';
                $tag = '/' . $tag;
            }

            if ( $type eq 'SBLOCK' ) {
                $in{ $tag }++;
            } else {
                # $tag will look like "/block:Foo", so use substr to
                # strip off the leading "/".
                delete $in{ substr $tag, 1 };
            }

            push @tokens, [ $type, $tag ];
        } elsif ( $tag =~ /^(\w+):([\w\s]+)$/ ) {
            push @tokens, [ 'SETTING', $1, $2 ];
        } else {
            push @tokens, [ 'VAR', $tag ];
        }

        $pos = pos( $$text_ref );
    }

    if ( $pos < length $$text_ref ) {
        push @tokens, [ 'TEXT', substr( $$text_ref, $pos ) ];
    }

    $parser->tokens( \@tokens );
}

sub _extract_settings {
    my $parser = shift;
    my( $text_ref ) = @_;

    my $settings = $parser->settings;

    my $hp = HTML::TokeParser->new( $text_ref );
    while ( my $tag = $hp->get_tag( 'meta' ) ) {
        if ( $tag->[1]{name} && $tag->[1]{name} =~ /^(\w+):([\w\s]+)$/ ) {
            $settings->{ $1 }{ $2 } = $tag->[1]{content};
        }
    }
}

sub get_token {
    my $parser = shift;
    my $token = $parser->tokens->[ $parser->index || 0 ];
    $parser->index( $parser->index + 1 );
    return $token;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

WWW::Tumblr::ThemeParser - Parse Tumblr custom themes

=head1 SYNOPSIS

    use WWW::Tumblr::ThemeParser;
    my $html;
    my $p = WWW::Tumblr::ThemeParser->new( \$html );
    while ( my $t = $p->get_token ) {
        # ...
    }

=head1 DESCRIPTION

I<WWW::Tumblr::ThemeParser> is a token-based parser for Tumblr's custom theme
tag format. Parsing a Tumblr theme constructs a list of tokens--very similar
to the list of tokens provided by I<HTML::TokeParser>--that can be processed
by the caller.

=head1 AUTHOR

Benjamin Trott E<lt>ben@sixapart.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
