package URI::Template::Restrict;

use 5.008_001;
use strict;
use warnings;
use base 'Class::Accessor::Fast';
use overload '""' => \&template, fallback => 1;
use List::MoreUtils qw(uniq);
use Unicode::Normalize qw(NFKC);
use URI;
use URI::Escape qw(uri_escape_utf8);
use URI::Template::Restrict::Expansion;

our $VERSION = '0.06';

__PACKAGE__->mk_accessors(qw'template segments');

sub new {
    my ($class, $template) = @_;

    my @segments =
        map {
            /^\{(.+?)\}$/
                ? URI::Template::Restrict::Expansion->new($1)
                : $_
        }
        grep { defined && length }
        split /(\{.+?\})/, $template;

    my $self = { template => $template, segments => [@segments] };
    return bless $self, $class;
}

sub expansions {
    return grep { ref $_ } @{ $_[0]->segments };
}

sub variables {
    return
        uniq
        sort
        map { $_->name }
        map { ref $_ eq 'ARRAY' ? @$_ : $_ }
        map { $_->vars }
        $_[0]->expansions;
}

# ----------------------------------------------------------------------
# Draft 03 - 4.4. URI Template Substitution
# ----------------------------------------------------------------------
# * MUST convert every variable value into a sequence of characters in
#   ( unreserved / pct-encoded ).
# * Normalizes the string using NFKC, converts it to UTF-8, and then
#   every octet of the UTF-8 string that falls outside of ( unreserved )
#   MUST be percent-encoded.
# ----------------------------------------------------------------------
sub process {
    my $self = shift;
    return URI->new($self->process_to_string(@_));
}

sub process_to_string {
    my $self = shift;
    my $args = ref $_[0] ? shift : { @_ };
    my $vars = {};

    for my $key (keys %$args) {
        my $value = $args->{$key};
        next if ref $value and ref $value ne 'ARRAY';
        $vars->{$key} = ref $value
            ? [ map { uri_escape_utf8(NFKC($_)) } @$value ]
            : uri_escape_utf8(NFKC($value));
    }

    return join '', map { ref $_ ? $_->process($vars) : $_ } @{ $self->segments };
}

sub extract {
    my ($self, $uri) = @_;

    my $re = join '', map { ref $_ ? '('.$_->pattern.')' : quotemeta $_ } @{ $self->segments };
    my @match = $uri =~ /$re/;

    my @expansions = $self->expansions;
    return unless @match and @match == @expansions;

    my @vars;
    while (@match > 0) {
        my $match = shift @match;
        my $expansion = shift @expansions;
        push @vars, $expansion->extract($match);
    }

    return %{{ @vars }};
}

1;

=head1 NAME

URI::Template::Restrict - restricted URI Templates handler

=head1 SYNOPSIS

    use URI::Template::Restrict;

    my $template = URI::Template::Restrict->new(
        'http://example.com/{foo}'
    );

    my $uri = $template->process(foo => 'y');
    # $uri: "http://example.com/y"

    my %result = $template->extract($uri);
    # %result: (foo => 'y')

=head1 DESCRIPTION

This is a restricted URI Templates handler. URI Templates is described at
L<http://bitworking.org/projects/URI-Templates/>.

This module supports B<draft-gregorio-uritemplate-03> except B<-opt> and
B<-neg> operators.

=head1 METHODS

=head2 new($template)

Creates a new instance with the template.

=head2 process(%vars)

Given a hash of key-value pairs. It will URI escape the values,
substitute them in to the template, and return a L<URI> object.

=head2 process_to_string(%vars)

Processes input like the process method, but doesn't inflate the
result to a L<URI> object.

=head2 extract($uri)

Extracts variables from an uri based on the current template.
Returns a hash with the extracted values.

=head1 PROPERTIES

=head2 template

Returns the original template string.

=head2 variables

Returns a list of unique variable names found in the template.

=head2 expansions

Returns a list of L<URI::Template::Restrict::Expansion> objects found
in the template.

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<URI::Template>, L<http://bitworking.org/projects/URI-Templates/>

=cut
