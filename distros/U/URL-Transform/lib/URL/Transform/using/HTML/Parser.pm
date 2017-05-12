package URL::Transform::using::HTML::Parser;

=head1 NAME

URL::Transform::using::HTML::Parser - HTML::Parse parsing of the html/xml for url transformation

=head1 SYNOPSIS

    my $urlt = URL::Transform::using::HTML::Parser->new(
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => sub { return (join '|', @_) },
    );
    $urlt->parse_file($Bin.'/data/URL-Transform-01.html');

    print "and this is the output: ", $output;


=head1 DESCRIPTION

Using this module you can performs an url transformation on the HTML/XML documents.

This module is used by L<URL::Transform>.

The url matching algorithm is taken from L<HTML::Parser>/eg/hrefsub example
script.

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use HTML::Parser ();
use Carp::Clan;
use English '$EVAL_ERROR';

use URL::Transform ();


# Construct a hash of tag names that may have links.
my $_link_tags     = URL::Transform::link_tags();
my $_js_attributes = URL::Transform::js_attributes();


use base 'Class::Accessor::Fast';

=head1 PROPERTIES

    output_function
    transform_function
    parser_for

    _html_parser

=cut

__PACKAGE__->mk_accessors(qw{
    output_function
    transform_function
    parser_for

    _html_parser
});

=head1 METHODS

=cut


=head2 new

Object constructor.

Requires:

    output_function
    transform_function

Optional:

    parser_for

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

    $transform_function = sub { $self->transform_function_wrapper(@_) };
    
    my $html_parser = HTML::Parser->new(api_version => 3);

    # The default is to print everything as it is.
    $html_parser->handler(
        default => sub {
            $output_function->(@_);
        }, "text"
    );
    
    # cleanup current tag on every end tag
    # should work fine for our purpouse as we are not interrested in nested tags
    my $current_tag = '';
    $html_parser->handler(
        end   => sub {
    		$current_tag = '';
    		my $text = shift;
    		
    		# rename </noscript> to </span> in case javascript is removed
    		if ($self->parser_for->('application/x-javascript') eq 'Remove') {
        		$text = '</span>' if $text =~ m{^</noscript}i;
            }
    		
            $output_function->($text);
        }, "text"
    );
    
    # Links inside the text of the tag (just <style> for the moment)
    $html_parser->handler(
        text => sub {
    		my $text = shift;
    		if ($_link_tags->{$current_tag} and $_link_tags->{$current_tag}->{''}) {
    			$text = $transform_function->(
    			    'tag_name' => $current_tag,
    			    'url'      => $text,
    			);
    		}
    		
            $output_function->($text);
        }, "text"
    );
    
    # All links are found in start tags.  This handler will evaluate
    # &edit for each link attribute found.
    $html_parser->handler(
        start => sub {
    		my($tagname, $pos, $text) = @_;
    		
    		# note down current tag for 'text' handler if not tag with /> at the end 
    		$current_tag = $tagname
    		    if $text !~ m{/\s?>$};
    		
    		# rename <noscript> to <span> in case javascript is removed
    		if (
    		        ($tagname eq 'noscript')
    		        and ($self->parser_for->('application/x-javascript') eq 'Remove')
    		) {
    		    $text =~ s{^<noscript}{<span}i;
    		}
    
		    while (4 <= @$pos) {
    			# use attribute sets from right to left
    			# to avoid invalidating the offsets
    			# when replacing the values
    			my($k_offset, $k_len, $v_offset, $v_len) =
    			    splice(@$pos, -4);
    			my $attrname = lc(substr($text, $k_offset, $k_len));

                # skip if empty attribute
    			next unless $v_offset; # 0 v_offset means no value
    			
    			# skip if not links attr
    			# skip if tag is not associated with any link attributes
    			#      and the attribute is not a general attribute (like style or onclick)
    			# skip if tag is associated with link attributes but not the current one
    			#      and the attribute is not a general attribute (like style or onclick)
    			my $link_tags = $_link_tags->{$tagname};
    			next if (
    			    ((not $link_tags) or (not $link_tags->{$attrname}))
    			    and (not $_link_tags->{''}->{$attrname})
    			);
    			        			
    			my $v = substr($text, $v_offset, $v_len);
    			
    			# remove attribute quotes
    			$v =~ s/^([\'\"])(.*)\1$/$2/;
    			
    			# get the characted that was used to quote
    			my $quote_char = $1 || '';
    			
    			# call for url transforming
    			my $new_v = $transform_function->(
    			    'tag_name'       => $tagname,
    			    'attribute_name' => $attrname,
    			    'url'            => $v,
    			);
    			
    			# skip if not change
    			next if $new_v eq $v;
    			
                # replace the attribute value with a new one
    			substr($text, $v_offset, $v_len) = $quote_char.$new_v.$quote_char;
		    }
    		$output_function->($text);
        },
        "tagname, tokenpos, text"
    );
    
    $self->_html_parser($html_parser);    

    return $self;
}


=head2 transform_function_wrapper

Wrapper for transform function that can handle special cases of url-s
when hidden inside an attribute. Like meta refresh:

    <meta http-equiv="Refresh" content="0;http://someserver/" />

=cut

sub transform_function_wrapper {
    my $self = shift;
    my %args = @_;
    
    my $tag_name       = $args{'tag_name'};
    my $attribute_name = $args{'attribute_name'};
    
    # special handling
    my $url = $args{'url'};
    if ($tag_name) {
        my $parser;
        # if <meta ...> tag
        if ($tag_name eq 'meta') {
            $parser = $self->parser_for->('text/html/meta-content');
            return $url if not defined $parser;            
        }
        # elsif <style> tag or a tag with 'style' attribute
        elsif (
                (
                    not $attribute_name
                    and ($tag_name eq 'style')
                )
                or (
                    $attribute_name
                    and ($attribute_name eq 'style')
                )
        ) {
            $parser = $self->parser_for->('text/css');
            return $url if not defined $parser;
        }
        # elsif <script> tag or some tag with javascript attribute (onload, onclick, on...)
        elsif (
                (
                    not $attribute_name
                    and ($tag_name eq 'script')
                )
                or (
                    $attribute_name
                    and exists $_js_attributes->{$attribute_name}
                )
        ) {
            $parser = $self->parser_for->('application/x-javascript');
            return $url if not defined $parser;
        }
        
        if (defined $parser) {
            # FIXME should not reconstruct the parser every time
            $parser = 'URL::Transform::using::'.$parser;
            eval 'use '.$parser;
            die $EVAL_ERROR if $EVAL_ERROR;
            my $output = '';
            $parser = $parser->new(
                'transform_function' => $self->transform_function,
                'output_function'    => sub { $output .= "@_"; },
            );
            $parser->parse_string($url);
            
            return $output;
        }
    }

    return $self->transform_function->(%args);
}


=head2 parse_string($string)

Submit document as a string for parsing.

=cut

sub parse_string {
    my $self = shift;
    
    $self->_html_parser->parse(@_);
}


=head2 parse_chunk($chunk)

Submit chunk of a document for parsing.

=cut

sub parse_chunk {
    my $self = shift;
    
    $self->_html_parser->parse(@_);
}


=head2 parse_file($file_name)

Submit file for parsing.

=cut

sub parse_file {
    my $self = shift;
    
    $self->_html_parser->parse_file(@_);
}


1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
