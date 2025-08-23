package Wiki::JSON::HTML;

use v5.16.3;

use strict;
use warnings;

use Moo;
use Mojo::Util qw/xml_escape/;

has _wiki_json => ( is => 'lazy' );

sub pre_html_json {
    my ( $self, $wiki_text, $template_callback, $options) = @_;
    $options //= {};
    my @dom;
    push @dom,
      $self->_open_html_element( 'article', 0, { class => 'wiki-article' } );
    my $json = $self->_wiki_json->parse($wiki_text);

    push @dom, @{ $self->_parse_output($json, $template_callback, $options) };
    push @dom, $self->_close_html_element('article');
    return \@dom;
}

sub _build__wiki_json {
    my $self = shift;
    require Wiki::JSON;
    return Wiki::JSON->new;
}

sub _open_html_element {
    if ( @_ < 2 ) {
        die '_open_html_element needs $self and $tag at least as arguments';
    }
    my ( $self, $tag, $self_closing, $attributes ) = @_;
    $self_closing //= 0;
    $attributes   //= {};
    if ( 'HASH' ne ref $attributes ) {
        die 'HTML attributes are not a HASHREF';
    }
    return {
        tag    => $tag,
        status => $self_closing ? 'self-close' : 'open',
        attrs  => $attributes,
    };
}

sub _close_html_element {
    if ( @_ != 2 ) {
        die
'_close_html_element accepts exactly the following arguments $self and $tag';
    }
    my ( $self, $tag ) = @_;
    return {
        tag    => $tag,
        status => 'close',
    };
}

sub _html_string_content_to_pushable {
    my ( $self, $content ) = @_;
    $content =~ s/(?:\r|\n)/ /gs;
    $content =~ s/ +/ /gs;
    return $content;
}

sub _parse_output_try_parse_plain_text {
    if ( @_ != 6 ) {
        die
'_parse_output_try_parse_plain_text needs $self, $dom, $element, $last_element_inline_element, $needs_closing_parragraph, $options';
    }
    my ( $self, $dom, $element, $last_element_inline_element,
        $needs_closing_parragraph, $options )
      = @_;
    my $needs_next = 0;
    my $found_text;
    if ( 'HASH' ne ref $element ) {
        $found_text = 1;
        if ( !$last_element_inline_element ) {
            ($needs_closing_parragraph) =
              $self->_close_parragraph( $dom, $needs_closing_parragraph,
                $options );
        }
        if ($element) {
            ($needs_closing_parragraph) =
              $self->_open_parragraph( $dom, $needs_closing_parragraph, 0,
                $options );
            push @$dom, $self->_html_string_content_to_pushable($element);
        }
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph, $found_text );
}

sub _parse_output_try_parse_italic {
    if ( @_ < 7 ) {
        die 'Incorrect arguments _parse_output_try_parse_italic';
    }
    my ( $self, $dom, $element, $found_inline_element,
        $needs_closing_parragraph, $template_callback, $options )
      = @_;
    my $needs_next;
    if ( $element->{type} eq 'italic' ) {
        $found_inline_element = 1;
        ($needs_closing_parragraph) =
          $self->_open_parragraph( $dom, $needs_closing_parragraph, $found_inline_element, $options );
        push @$dom, $self->_open_html_element('i');
        push @$dom,
          @{
            $self->_parse_output( $element->{output}, $template_callback,
                { %$options, inside_inline_element => 1 } )
          };
        push @$dom, $self->_close_html_element('i');
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph, $found_inline_element );
}

sub _parse_output_try_parse_bold_and_italic {
    if ( @_ < 7 ) {
        die 'Incorrect arguments _parse_output_try_parse_bold_and_italic';
    }
    my ( $self, $dom, $element, $found_inline_element,
        $needs_closing_parragraph, $template_callback, $options )
      = @_;
    my $needs_next;
    if ( $element->{type} eq 'bold_and_italic' ) {
        $found_inline_element = 1;
        ($needs_closing_parragraph) =
          $self->_open_parragraph( $dom, $needs_closing_parragraph, $found_inline_element, $options );
        push @$dom, $self->_open_html_element('b');
        push @$dom, $self->_open_html_element('i');
        push @$dom,
          @{
            $self->_parse_output( $element->{output}, $template_callback,
                { %$options, inside_inline_element => 1 } )
          };
        push @$dom, $self->_close_html_element('i');
        push @$dom, $self->_close_html_element('b');
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph, $found_inline_element );
}

sub _parse_output_try_parse_bold {
    if ( @_ < 7 ) {
        die 'Incorrect arguments _parse_output_try_parse_bold';
    }
    my ( $self, $dom, $element, $found_inline_element,
        $needs_closing_parragraph, $template_callback, $options )
      = @_;
    my $needs_next;
    if ( $element->{type} eq 'bold' ) {
        $found_inline_element = 1;
        ($needs_closing_parragraph) =
          $self->_open_parragraph( $dom, $needs_closing_parragraph, $found_inline_element, $options );
        push @$dom, $self->_open_html_element('b');
        push @$dom,
          @{
            $self->_parse_output( $element->{output}, $template_callback,
                { %$options, inside_inline_element => 1 } )
          };
        push @$dom, $self->_close_html_element('b');
        $needs_next = 1;
    }

    return ( $needs_next, $needs_closing_parragraph, $found_inline_element );
}

sub _parse_output_try_parse_link {
    if ( @_ < 6 ) {
        die 'Incorrect arguments';
    }
    my ( $self, $dom, $element, $needs_closing_parragraph, $found_inline_element, $options ) = @_;
    my $needs_next;
    if ( $element->{type} eq 'link' ) {
        $found_inline_element = 1;
        ($needs_closing_parragraph) =
          $self->_open_parragraph( $dom, $needs_closing_parragraph, $found_inline_element, $options );
        my $real_link = $element->{link};
        if ( $real_link !~ /^\w:/ && $real_link !~ m@^(?:/|\w+\.)@ ) {

            # TODO: Allow setting a base URL.
            $real_link = '/' . $real_link;
        }
        push @$dom, $self->_open_html_element( 'a', 0, { href => $real_link } );
        push @$dom,
          $self->_html_string_content_to_pushable( $element->{title} );
        push @$dom, $self->_close_html_element('a');
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph, $found_inline_element );
}

sub _parse_output_try_parse_template {
    my ($self, $dom, $element, $needs_closing_parragraph, $found_inline_element, $template_callbacks, $options) = @_;
    my $needs_next;
    if ($element->{type} eq 'template') {
        my $template = $element;
        my $is_inline = $template_callbacks->{is_inline}->($template);
        if ($options->{inside_inline_element} && !$is_inline) {
            warn 'No-inline (block) template found inside inline element';
        }
        if ($is_inline) {
            $found_inline_element = 1;
            ($needs_closing_parragraph) =
            $self->_open_parragraph( $dom, $needs_closing_parragraph, $found_inline_element, $options );
        } else {
            ($needs_closing_parragraph) =
            $self->_close_parragraph( $dom, $needs_closing_parragraph,
            $options );
        }
        my $parse_sub = sub {
            my ($wiki_text, $options) = @_;
            return $self->pre_html_json($wiki_text, $template_callbacks, $options);
        };
        my $open_html_element_sub = sub  {
            my ($tag, $self_closing, $attrs) =@_;
            if (!defined $tag) {
                die 'Tag is not optional';
            }
            $self_closing //= 0;
            $attrs //= {};
            return $self->_open_html_element($tag, $self_closing, $attrs);
        };
        my $close_html_element_sub = sub {
            my ($tag) = @_;
            if (!defined $tag) {
                die 'Tag is not optional';
            }
            return $self->_close_html_element($tag);
        };
        my $new_elements = $template_callbacks->{generate_elements}->($element, $options, $parse_sub, $open_html_element_sub, $close_html_element_sub);
        if (defined $new_elements) {{ 
            if ('ARRAY' ne ref $new_elements) {
                warn 'Return from generate_elements is not an ArrayRef, user error';
                next;
            }
            push @$dom, @$new_elements;
        }}
    }
    return ($needs_next, $needs_closing_parragraph, $found_inline_element);
}

sub _parse_output_try_parse_unordered_list {
    if ( @_ < 6 ) {
        die 'Incorrect number of parameters';
    }
    my ( $self, $dom, $element, $needs_closing_parragraph, $template_callback, $options ) = @_;
    my $needs_next;
    if ( $element->{type} eq 'unordered_list' ) {
        if ( $options->{inside_inline_element} ) {
            warn 'unordered list found when content is expected to be inline';
        }
        ($needs_closing_parragraph) =
          $self->_close_parragraph( $dom, $needs_closing_parragraph,
            $options );
        my $elements = $element->{output};
        push @$dom, $self->_open_html_element('ul');
        for my $element (@$elements) {
            if ('HASH' ne ref $element) {
                die 'List element is text and not hash';
            }
            if ($element->{type} ne 'list_element') {
                die 'List element is not a list_element';
            }
            push @$dom, $self->_open_html_element('li');
            push @$dom,
              @{
                $self->_parse_output( $element->{output}, $template_callback,
                    { %$options, is_list_element => 1 } )
              };
            push @$dom, $self->_close_html_element('li');
        }
        push @$dom, $self->_close_html_element('ul');
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph );
}

sub _parse_output_try_parse_hx {
    if ( @_ < 6 ) {
        die 'Incorrect arguments to _parse_output_try_parse_hx';
    }
    my ( $self, $dom, $element, $needs_closing_parragraph, $template_callback, $options ) = @_;
    my $needs_next;
    if ( $element->{type} eq 'hx' ) {
        if ( $options->{inside_inline_element} ) {
            warn 'HX found when the content is expected to be inline';
        }
        ($needs_closing_parragraph) =
          $self->_close_parragraph( $dom, $needs_closing_parragraph,
            $options );
        my $hx_level = $element->{hx_level};

        push @$dom, $self->_open_html_element( xml_escape "h$hx_level" );
        push @$dom,
          @{
            $self->_parse_output( $element->{output}, $template_callback,
                { %$options, inside_inline_element => 1 } )
          };
        push @$dom, $self->_close_html_element( xml_escape "h$hx_level" );
        $needs_next = 1;
    }
    return ( $needs_next, $needs_closing_parragraph );
}

sub _parse_output {
    if ( @_ < 3 ) {
        die '_parse_output needs at least $self and $output';
    }
    my ( $self, $output, $template_callback, $options ) = @_;
    $options //= {};
    my @dom;
    my $needs_closing_parragraph = 0;
    my $first                    = 1;
    my $last_element_inline_element;
    my $last_element_text;
    for my $element (@$output) {
        my $found_inline_element;
        my $found_text;
        {
            my ($needs_next);
            $options->{first} = $first;
            $options->{last_element_text} = $last_element_text;
            ( $needs_next, $needs_closing_parragraph, $found_text ) =
              $self->_parse_output_try_parse_plain_text( \@dom, $element,
                $last_element_inline_element, $needs_closing_parragraph,
                $options );
            next if $needs_next;

            ( $needs_next, $needs_closing_parragraph, $found_inline_element ) =
              $self->_parse_output_try_parse_bold( \@dom, $element,
                $found_inline_element, $needs_closing_parragraph, $template_callback, $options );
            next if $needs_next;
            ( $needs_next, $needs_closing_parragraph, $found_inline_element ) =
              $self->_parse_output_try_parse_bold_and_italic( \@dom, $element,
                $found_inline_element, $needs_closing_parragraph, $template_callback, $options );
            next if $needs_next;
            ( $needs_next, $needs_closing_parragraph, $found_inline_element ) =
              $self->_parse_output_try_parse_italic( \@dom, $element,
                $found_inline_element, $needs_closing_parragraph, $template_callback, $options );
            next if $needs_next;
            ( $needs_next, $needs_closing_parragraph ) =
              $self->_parse_output_try_parse_hx( \@dom, $element,
                $needs_closing_parragraph, $template_callback, $options );
            next if $needs_next;

            ( $needs_next, $needs_closing_parragraph ) =
              $self->_parse_output_try_parse_unordered_list( \@dom, $element,
                $needs_closing_parragraph, $template_callback, $options );
            next if $needs_next;
            ( $needs_next, $needs_closing_parragraph, $found_inline_element ) =
              $self->_parse_output_try_parse_link( \@dom, $element,
                $needs_closing_parragraph, $found_inline_element, $options );
            next if $needs_next;
            ( $needs_next, $needs_closing_parragraph, $found_inline_element) =
                $self->_parse_output_try_parse_template( \@dom, $element, $needs_closing_parragraph, $found_inline_element, $template_callback, $options);

        }
        $first                       = 0;
        $last_element_inline_element = !!$found_inline_element;
        $last_element_text = !!$found_text;
    }
    ($needs_closing_parragraph) =
      $self->_close_parragraph( \@dom, $needs_closing_parragraph, $options );
    return \@dom;
}

sub _open_parragraph {
    if (@_ < 5) {
        die 'Incorrect arguments';
    }
    my ( $self, $dom, $needs_closing_parragraph, $found_inline_element, $options ) = @_;
    if ( $options->{is_list_element} || $options->{inside_inline_element} ) {
        if ( !$options->{first} && !$found_inline_element) {
            push @$dom, $self->_open_html_element( 'br', 1 );
        }
        return ($needs_closing_parragraph);
    }
    if ( !$needs_closing_parragraph ) {
        push @$dom, $self->_open_html_element('p');
        $needs_closing_parragraph = 1;
    }
    return ($needs_closing_parragraph);
}

sub _close_parragraph {
    my ( $self, $dom, $needs_closing_parragraph, $options ) = @_;
    if ($needs_closing_parragraph) {
        push @$dom, $self->_close_html_element('p');
        $needs_closing_parragraph = 0;
    }
    return ( $needs_closing_parragraph );
}
1
