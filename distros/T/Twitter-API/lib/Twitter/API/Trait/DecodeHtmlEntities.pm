package Twitter::API::Trait::DecodeHtmlEntities;
# ABSTRACT: Decode HTML entities in strings
$Twitter::API::Trait::DecodeHtmlEntities::VERSION = '0.0112';
use Moo::Role;
use HTML::Entities qw/decode_entities/;
use Scalar::Util qw/refaddr/;
use Ref::Util qw/is_arrayref is_hashref is_ref/;
use namespace::clean;

sub _decode_html_entities {
    my ( $self, $ref, $seen ) = @_;
    $seen //= {};

    # Recursively walk data structure; decode entities is place on strings
    for ( is_arrayref($ref) ? @$ref : is_hashref($ref) ? values %$ref : () ) {
        next unless defined;

        # There shouldn't be any circular references in Twitter results, but
        # guard against it, anyway.
        if ( my $id = refaddr($_) ) {
            $self->_decode_html_entities($_, $seen) unless $$seen{$id}++;
        }
        else {
            # decode in place; happily, numbers remain untouched, no PV created
            decode_entities($_);
        }
    }
}

around inflate_response => sub {
    my ( $orig, $self, $c ) = @_;

    $self->$orig($c);
    $self->_decode_html_entities($c->result);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Twitter::API::Trait::DecodeHtmlEntities - Decode HTML entities in strings

=head1 VERSION

version 0.0112

=head1 SYNOPSIS

    use Twitter::API;
    use open qw/:std :utf8/;

    my $client = Twitter::API->new_with_traits(
        traits => [ qw/ApiMethods DecodeHtmlEntites/ ],
        %other_options
    );

    my $status = $client->show_status(801814387723935744);
    say $status->{text};

    # output:
    # Test DecodeHtmlEntities trait. < & > ⚠️ 🏉 'single' "double"
    #
    # output without the DecodeHtmlEntities trait:
    # Test DecodeHtmlEntities trait. &lt; &amp; &gt; ⚠️ 🏉 'single' "double"

=head1 DESCRIPTION

Twitter has trust issues. They assume you're going to push the text you receive
in API responses to a web page without HTML encoding it. But you HTML encode
all of your output right? And Twitter's lack of trust has you double encoding
entities.

So, include this trait and Twitter::API will decode HTML entities in all of the
text returned by the API.

You're welcome.

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2016 by Marc Mims.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
