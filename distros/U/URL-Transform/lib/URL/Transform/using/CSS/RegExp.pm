package URL::Transform::using::CSS::RegExp;

=head1 NAME

URL::Transform::using::CSS::RegExp - regular expression parsing of the C<text/css> for url transformation

=head1 SYNOPSIS

    my $urlt = URL::Transform::using::CSS::RegExp->new(
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => sub { return (join '|', @_) },
    );
    $urlt->parse_string("background: transparent url(/site/images/logo.png)");

    print "and this is the output: ", $output;


=head1 DESCRIPTION

Performs an url transformation inside C<text/css> using regular expressions.

This module is used by L<URL::Transform>.

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use Carp::Clan;

use base 'Class::Accessor::Fast';


our $STYLE_URL_REGEXP = qr{
    (?:
        # ex. "url('/site.css')"
        (             # capture non url path of the string
            url       # url
            \s*       #
            \(        # (
            \s*       #
            (['"]?)   # opening ' or "
        )
        (             # the rest is url
            .+?       # non greedy "everything"
        )
        (
            \2        # closing ' or "
            \s*       #
            \)        # )
        )
    |
        # ex. "@import '/site.css'"
        (             # capture non url path of the string
            \@import  # @import
            \s+       #
            (['"])    # opening ' or "
        )
        (             # the rest is url
            .+?       # non greedy "everything"
        )
        (
            \6        # closing ' or "
        )
    )
}xmsi;


=head1 PROPERTIES

    output_function
    transform_function

=cut

__PACKAGE__->mk_accessors(qw{
    output_function
    transform_function
});

=head1 METHODS

=head2 new

Object constructor.

Requires:

    output_function
    transform_function

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new({ @_ });

    my $output_function    = $self->output_function;
    my $transform_function = $self->transform_function;
    
    croak 'pass print function'
        if not (ref $output_function eq 'CODE');
    
    croak 'pass transform url function'
        if not (ref $transform_function eq 'CODE');
    
    return $self;
}


=head2 parse_string($string)

Submit meta content string for parsing.

=cut

sub parse_string {
    my $self   = shift;
    my $string = shift;
    
    # match css url-s and store the matches for later replacement
    my @found_urls;
    while ($string =~ m/$STYLE_URL_REGEXP/g) {
        push @found_urls, {
            'url' => $3 || $7,
            'pos' => (pos $string)-length($3 || $7)-length($4 || $8),
        };        
    }
    
    # replace the url-s backwards in the string
    while (my $url_with_pos = pop @found_urls) {
        # transform the url
        my $original_url = $url_with_pos->{'url'};
        my $url = $self->transform_function->(
            'url' => $original_url,
        );
        
        # replace the original url with the new one
        substr(
            $string,
            $url_with_pos->{'pos'},
            length($original_url)
        ) = $url;
    }
    
    $self->output_function->($string);
}


=head2 parse_file($file_name)

Slurps the file and call $self->parse_string($content).

=cut

sub parse_file {
    my $self      = shift;
    my $file_name = shift;

    open my $fh, '<', $file_name or croak 'Can not open '.$file_name.': '.$!;
    my $string = do { local $/; <$fh> }; # slurp!
    $self->parse_string($string);
}


1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
