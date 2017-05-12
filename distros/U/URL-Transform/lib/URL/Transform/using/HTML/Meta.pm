package URL::Transform::using::HTML::Meta;

=head1 NAME

URL::Transform::using::HTML::Meta - regular expression parsing of the meta content attribute for url transformation

=head1 SYNOPSIS

    my $urlt = URL::Transform::using::HTML::Meta->new(
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => sub { return (join '|', @_) },
    );
    $urlt->parse_string("0;url = 'some other link'");

    print "and this is the output: ", $output;


=head1 DESCRIPTION

Using module you can performs an url transformation on the HTML META
content attribute string.

This module is used by L<URL::Transform>.

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use Carp::Clan;

use base 'Class::Accessor::Fast';


my $META_URL_REGEXP = qr{    # ex. "0;URL=http://some.server.com/"
    ^ (           # capture non url path of the string
        \s*
        [0-9]+    # number of seconds after which to refresh
        \s*
        ;
        \s*
        url\s*=      # url= (case insensitive)
        \s*
        ['"]?
    )
    (             # the rest is url
        .+
    )
    (
        ['"]?
        \s*
    )
    $
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

=cut


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
    
    if ($string =~ $META_URL_REGEXP) {
        my $meta_content_start = $1;
        my $url                = $2;
        my $meta_content_end   = $3;
        
        $url = $self->transform_function->(
            'tag_name'       => 'meta',
            'attribute_name' => 'content',
            'url'            => $url,
        );
        
        $self->output_function->(
            $meta_content_start.$url.$meta_content_end
        );
    }
    else {        
        $self->output_function->($string);
    }

}


=head2 parse_file($file_name)

makes no sense in this case.

=cut

sub parse_file {
    my $self = shift;
    
    die 'makes no sence...';
}


1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
