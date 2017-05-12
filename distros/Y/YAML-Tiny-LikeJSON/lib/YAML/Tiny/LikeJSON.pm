package YAML::Tiny::LikeJSON;
BEGIN {
  $YAML::Tiny::LikeJSON::VERSION = '0.0011';
}
# ABSTRACT: Use YAML::Tiny like JSON


use strict;
use warnings;

use YAML::Tiny;
use Carp;

sub new { return bless {}, shift }

sub decode {
    my $self = shift;
    my $YAML = YAML::Tiny->read_string( $_[0] );
    if ( ( my $size = @$YAML ) > 1 ) {
        carp "Decoded more than 1 document (actually $size, but only returning the first)"
    }
    return $YAML->[0];
}

sub encode {
    my $self = shift;
    my $YAML = YAML::Tiny->new( $_[0] );
    my $content = $YAML->write_string;
    $content =~ s/\A\s*---\s*\n+//sm;
    return $content;
}

1;

__END__
=pod

=head1 NAME

YAML::Tiny::LikeJSON - Use YAML::Tiny like JSON

=head1 VERSION

version 0.0011

=head1 SYNOPSIS

    use YAML::Tiny::LikeJSON;

    my $yaml = YAML::Tiny::LikeJSON->new;

    my $data = $yaml->decode( <<_END_ );
    apple: 1
    banana:
        - 1
        - 2
        - 3
    _END_

    print $yaml->encode( $data );
    # Prints out the following: (without the '---' document separator)
    # apple: 1
    # banana:
    #     - 1
    #     - 2
    #     - 3
    _END_

=head1 DESCRIPTION

YAML::Tiny::LikeJSON provides a way to encode/decode YAML (Tiny) in a way similar to how JSON.pm works.

It will only deal with one YAML document at a time, so if you try to decode more than one document, it will ignore every document but the first (and issue a warning at the same time). For example:

    YAML::Tiny::LikeJSON->decode( <<_END_ );
    apple: 1
    ---
    banana: 2
    _END_

    # The above will emit the following warning:

    Decoded more than 1 document (actually 2, but only returning the first)

=head1 USAGE

=head2 $yaml = YAML::Tiny::LikeJSON->new

Create a handle for invoking C<encode>/C<decode>

Does not accept any arguments or options (for now)

=head2 $document = YAML::Tiny::LikeJSON->encode( $data )

=head2 $document = $yaml->encode( $data )

Return a YAML encoded string representing $data

The returned string will not have the leading YAML document separator (---)

=head2 $data = YAML::Tiny::LikeJSON->decode( $document )

=head2 $data = $yaml->encode( $document )

Return some Perl data representing $document

Will only return data from the first document. Data from following documents will be discarded (with a warning)

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

