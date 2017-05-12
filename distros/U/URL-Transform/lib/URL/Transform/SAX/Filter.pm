package URL::Transform::SAX::Filter;

=head1 NAME

URL::Transform::SAX::Filter - SAX filter to execute url transformation function when an attribute with url is found

=head1 SYNOPSIS

    my $writer = XML::SAX::Writer->new( Output => sub {
        my $type = shift;
        $output_function->(@_);
    } );
    my $filter = URL::Transform::SAX::Filter->new(
        Handler            => $writer,
        transform_function => sub { return join('|', @_) },
    );
    
    my $sax_parser = XML::SAX::ParserFactory->parser(
        'Handler' => $filter,
    );
    
    $sax_parser->parse_file('test.html');

=head1 DESCRIPTION

This filter examines every start tag for a presence of tags and their
attributes which may hold link attributes. (SEE L<HTML::Tagset::linkElements>)

For each of them the 'transform_function' is triggered which can
modify the url. This function receives following arguments:

    $self->{'transform_function'}->(
        'tag_name'       => 'img',
        'attribute_name' => 'src',
        'url'            => 'http://search.cpan.org/s/img/cpan_banner.png',
    );

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use URL::Transform ();
use List::Util 'first';
use Carp::Clan 'croak';

# Construct a hash of tag names that may have links.
my $_link_tags = URL::Transform::link_tags();

use base 'XML::SAX::Base';

=head1 METHODS


=head2 new()

Object constructor.

Requires the 'transform_function' as the argument.

=cut

sub new {
    my $class = shift;
    my %args  = @_;
    
    my $transform_function = delete $args{'transform_function'}
        or croak 'pass "transform_function" os an argument';
    
    my $self = $class->SUPER::new(%args);
    
    $self->{'transform_function'} = $transform_function;
    
    return $self;
}


=head2 start_element()

This function handles the 'transform_function' triggering with a proper
arguments.

=cut

sub start_element {
    my $self = shift;
    my $data = shift;

    my $attr = $data->{Attributes};
    my $tag_name = lc $data->{'LocalName'};

    # if the tag belongs to the list of tags that can have a link
    if (my $link_tag = $_link_tags->{$tag_name}) {
        # loop through it's attributes
        foreach my $ns_attribute_name (keys %$attr) {
            # extract the attribute name and it's namespace
            die 'unknown formated attribute name "'.$ns_attribute_name.'"'
                if not $ns_attribute_name =~ m/^{([^}]*)}(.+)$/;
            my $attribute_ns   = $1;    #we don't use it for the moment
            my $attribute_name = $2;
            
            # if the attribute is link attribute then execute transform function
            if ($link_tag->{$attribute_name}) {
                $attr->{$ns_attribute_name}->{'Value'} =
                    $self->{'transform_function'}->(
                        'tag_name'       => $tag_name,
                        'attribute_name' => $attribute_name,
                        'url'            => $attr->{$ns_attribute_name}->{'Value'},
                    );
            }
        }
    }

    return $self->SUPER::start_element($data);
}


=head2 xml_decl

Just ignoring xml declaration. Otherwise we'll end-up with
C<< <?xml version="1.0"?> >> added to all documents.

=cut

sub xml_decl {
    return;
    
}


1;


__END__

=head1 SEE ALSO

L<URL::Transform>, L<URL::Transform::using::XML::SAX>, L<XML::SAX::Base>

=head1 AUTHOR

Jozef Kutej

=cut
