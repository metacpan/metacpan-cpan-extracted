package Text::CaboCha;
use strict;
use warnings;

our @ISA;
our $VERSION = "0.05";

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

my %BOOLEAN_OPTIONS = (
    map { $_ => 'bool' } qw/--version --help/
);

sub new {
    my $class = shift;
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my @args = ('perl-TextCaboCha');
    while (my ($key, $value) = each %args) {
        $key =~ s/_/-/g;
        $key =~ s/^/--/;

        if (exists $BOOLEAN_OPTIONS{$key}) {
            push @args, $key;
        } else {
            push @args, join('=', $key, $value);
        }
    }

    $class->_xs_create(\@args);
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::CaboCha - Alternate Interface To libcabocha

=head1 SYNOPSIS

    use Text::CaboCha;
    my $cabocha = Text::CaboCha->new({
        output_format => $output_format,
        input_layer   => $input_layer,
        output_layer  => $output_layer,
        ne            => $ne,
        parser_model  => $parser_model_file,
        chunker_model => $chunker_model_file,
        ne_model      => $ne_tagger_model_file,
        posset        => $posset,
        charset       => $encode,
        charset_file  => $charset_file,
        rcfile        => $cabocha_rc_file,
        mecabrc       => $mecab_rc_file,
        mecab_dicdir  => $mecab_dicdir,
        mecab_userdic => $mecab_userdic,
        output        => $output_file
    });

    my $tree = $cabocha->parse($text);
    $tree->tostr(Text::CaboCha::CABOCHA_FORMAT_TREE); # You can check the tree.

    my $token_size = $tree->token_size;

    my $cid = 0;
    for (my $i = 0; $i < $token_size; $i++) {
        my $token = $tree->token($i);
        if ($token->chunk) {
            printf("* %d %dD %d/%d %f\n",
                $cid++,
                $token->chunk->link,
                $token->chunk->head_pos,
                $token->chunk->func_pos,
                $token->chunk->score);
            printf("%s\t%s\t%s\n",
                    $token->surface,
                    $token->feature,
                    $token->ne ? $token->ne : "O");
        }
    }
    printf("EOS\n");

    # use constants
    use Text::CaboCha qw(:all);
    use Text::CaboCha qw(CABOCHA_FORMAT_TREE);
    # check what cabocha version we compiled against?
    print "Compiled with ", Text::CaboCha::CABOCHA_VERSION, "\n";

=head1 DESCRIPTION

This module was created with reference to Text::MeCab.  
Text::CaboCha gives you a more natural, Perl-ish way to access libcabocha!

=head1 PERFORMANCE

You can get to the result of running eg/benchmark.pl.

                        Rate           cabocha      text_cabocha text_cabocha_each
    cabocha           17.2/s                --              -27%              -29%
    text_cabocha      23.5/s               36%                --               -3%
    text_cabocha_each 24.2/s               40%                3%                --

=head1 METHODS

=head2 new HASHREF | LIST

Creates a new Text::CaboCha instance.  
You can either specify a hashref and use named parameters, or you can use the
exact command line arguments that the cabocha command accepts.  
Below is the list of accepted named options. See the man page for cabocha for 
details about each option.

=over 4

=item B<output_format>

=item B<input_layer>

=item B<output_layer>

=item B<ne>

=item B<parser_model>

=item B<chunker_model>

=item B<ne_model>

=item B<posset>

=item B<charset>

=item B<charset_file>

=item B<rcfile>

=item B<mecabrc>

=item B<mecab_dicdir>

=item B<mecab_userdic>

=item B<output>

=back

=head2 $tree = $parser-E<gt>parse(SCALAR)

Parses the given text via CaboCha::Parser, and returns a Text::CaboCha::Tree object.

=head2 $tree = $parser->parse_from_node(Text::MeCab::Node)

Parses the given L<Text::MeCab::Node|Text::MeCab::Node> via CaboCha::Parser, and returns a Text::CaboCha::Tree object.

=head2 $version = Text::CaboCha::version()

The version number, as returned by libcabocha's CaboCha::Parser::version()

=head2 CONSTANTS

=over 4

=item ENCODING

  my $encoding = Text::CaboCha::ENCODING

Returns the encoding of the underlying cabocha library that was detected at
compile time.

=item CABOCHA_VERSION

The version number, same as Text::CaboCha::version().

=item CABOCHA_TARGET_VERSION

The version number detected at compile time of Text::CaboCha. 

=item CABOCHA_TARGET_MAJOR_VERSION

The version number detected at compile time of Text::CaboCha. 

=item CABOCHA_TARGET_MINOR_VERSION

The version number detected at compile time of Text::CaboCha. 

=item CABOCHA_CONFIG

Path to cabocha-config, if available.

=back

=head1 SEE ALSO
https://taku910.github.io/cabocha/  
L<Text::CaboCha|Text::CaboCha>

=head1 LICENSE

Copyright (C) Kei Kamikawa.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See http://www.perl.com/perl/misc/Artistic.html

=head1 AUTHOR

Kei Kamikawa E<lt>x00.x7f@gmail.comE<gt>  
L<@codehex|https://twitter.com/CodeHex>

=cut