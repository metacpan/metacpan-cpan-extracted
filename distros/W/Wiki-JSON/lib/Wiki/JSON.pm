package Wiki::JSON;

use v5.38.2;

use strict;
use warnings;

use Moo;
use Data::Dumper;

our $VERSION = "0.0.7";

my $LIST_ELEMENT_DELIMITER = "\n* ";

sub parse( $self, $wiki_text ) {
    my @output;
    $self->_parse_in_array( \@output, $wiki_text );
    return \@output;
}

sub _search_interrupt( $self, $output, $buffer, $wiki_text, $i, $interrupt ) {
    my $new_i = $interrupt->( $wiki_text, $i );
    if ( !defined $new_i ) {
        return;
    }
    $i = $new_i;
    return $i;
}

sub _break_lines_template( $self, $output, $buffer, $current_char, $i ) {
    if ( $current_char eq "|" ) {
        push @$output, $buffer;
        return ( 1, '', $i );
    }
    return ( 0, $buffer, $i );
}

sub _break_lines( $self, $output, $buffer, $i, $current_char,
    $options, $current_list_output )
{
    if ( $options->{is_template} ) {
        return $self->_break_lines_template( $output, $buffer, $current_char,
            $i );
    }
    if ( $options->{is_unordered_list} ) {
        return ( 0, $buffer, $i );
    }
    return $self->_break_lines_on_newline( $output, $buffer, $current_char,
        $i );
}

sub _break_lines_on_newline( $self, $output, $buffer, $current_char, $i ) {
    if ( $current_char eq "\n" ) {
        push @$output, $buffer;
        return ( 1, '', $i );
    }
    return ( 0, $buffer, $i );
}

sub _if_interrupted( $self, $output, $buffer, $current_list_output, $options ) {
    if ( $options->{is_unordered_list} ) {
        return $self->_if_interrupted_unordered_list( $output, $buffer,
            $current_list_output, $options );
    }
    if ( !$options->{is_nowiki} ) {
        push @$output, $buffer;
        $buffer = '';
    }
    return ( $buffer, $current_list_output );
}

sub _insert_list_element_never_appending( $self, $output, $buffer,
    $current_list_output )
{
    push @$output, { type => 'list_element', output => [$buffer] };
    $current_list_output = $output->[-1]{output};
    $buffer              = '';
    return ( $buffer, $current_list_output );
}

sub _if_interrupted_unordered_list( $self, $output, $buffer,
    $current_list_output, $options )
{
    if ( length $buffer ) {
        ( $buffer, $current_list_output ) =
          $self->_insert_list_element_never_appending( $output, $buffer,
            $current_list_output );
    }
    delete $options->{br_found};
    delete $options->{is_unordered_list};
    return ( $buffer, $current_list_output );
}

sub _insert_list_appending_if_possible( $self, $output, $buffer,
    $current_list_output, $options )
{
    if ( defined $current_list_output ) {
        push @$current_list_output, $buffer;
        $buffer = '';
        return ( $buffer, $current_list_output );
    }
    ( $buffer, $current_list_output ) =
      $self->_insert_list_element_never_appending( $output, $buffer,
        $current_list_output );
    return ( $buffer, $current_list_output );
}

sub _insert_new_list_element_after_asterisk( $self, $output, $buffer, $i,
    $current_list_output, $options )
{
    my $searched    = $LIST_ELEMENT_DELIMITER;
    my $size_search = length $searched;
    if ( length $buffer ) {
        if ( $options->{'br_found'} ) {
            ( $buffer, $current_list_output ) =
              $self->_insert_list_appending_if_possible( $output, $buffer,
                $current_list_output, $options );
        }
        else {
            ( $buffer, $current_list_output ) =
              $self->_insert_list_element_never_appending( $output, $buffer,
                $current_list_output );
        }
    }
    delete $options->{br_found};
    $buffer = '';
    $i += $size_search;
    return ( $i, $buffer, $current_list_output );
}

sub _needs_interruption( $self, $output, $buffer, $wiki_text, $i, $interrupt,
    $current_list_output, $options )
{
    my $new_i;
    my $needs_interruption;
    $new_i =
      $self->_search_interrupt( $output, $buffer, $wiki_text, $i, $interrupt );
    if ( defined $new_i ) {
        ( $buffer, $current_list_output ) =
          $self->_if_interrupted( $output, $buffer, $current_list_output,
            $options );
        $needs_interruption = 1;
        return ( $needs_interruption, $new_i, $buffer );
    }
    return ( $needs_interruption, $i, $buffer );
}

sub _unordered_list_pre_syntax_parsing_newline_logic( $self, $output, $buffer,
    $wiki_text, $current_list_output, $i, $options )
{
    if ( !$options->{is_unordered_list} ) {
        return ( $i, $buffer, $current_list_output );
    }
    ( $i, $buffer, $current_list_output ) =
      $self->_unordered_list_pre_syntax_parsing_newline_logic_real_line(
        $output, $buffer, $wiki_text, $i, $current_list_output, $options );
    ( $i, $buffer, $current_list_output ) =
      $self->_unordered_list_pre_syntax_parsing_newline_logic_br( $output,
        $buffer, $wiki_text, $i, $current_list_output, $options );
    return ( $i, $buffer, $current_list_output );
}

sub _unordered_list_pre_syntax_parsing_newline_logic_br( $self, $output,
    $buffer, $wiki_text, $i, $current_list_output, $options )
{
    my $searched    = '<br>';
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word eq $searched ) {
        $options->{'br_found'} = 1;
        if ( length $buffer ) {
            if ( defined $current_list_output ) {
                push @$current_list_output, $buffer;
            }
            else {
                push @$output, { type => 'list_element', output => [$buffer] };
                $current_list_output = $output->[-1]{output};
            }
        }
        $buffer = '';
        $i += $size_search;
    }
    return ( $i, $buffer, $current_list_output );
}

sub _unordered_list_pre_syntax_parsing_newline_logic_real_line( $self, $output,
    $buffer, $wiki_text, $i, $current_list_output, $options )
{
    my $searched    = $LIST_ELEMENT_DELIMITER;
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word eq $searched ) {
        ( $i, $buffer, $current_list_output ) =
          $self->_insert_new_list_element_after_asterisk( $output,
            $buffer, $i, $current_list_output, $options );
    }
    return ( $i, $buffer, $current_list_output );
}

sub _parse_in_array_pre_char_checks( $self, $output, $buffer, $wiki_text, $i,
    $interrupt, $current_list_output, $options )
{
    my ( $needs_interruption, $new_i );
    ( $needs_interruption, $new_i, $buffer ) =
      $self->_needs_interruption( $output, $buffer, $wiki_text, $i,
        $interrupt, $current_list_output, $options );
    if ($needs_interruption) {
        return ( $needs_interruption, $buffer, $new_i, $current_list_output );
    }
    ( $i, $buffer, $current_list_output ) =
      $self->_unordered_list_pre_syntax_parsing_newline_logic( $output,
        $buffer, $wiki_text, $current_list_output, $i, $options );
    return ( $needs_interruption, $buffer, $i, $current_list_output );
}

sub _parse_in_array_pre_new_element_parsing( $self, $output, $buffer,
    $wiki_text, $i, $interrupt, $current_list_output, $options )
{
    my ( $needs_next, $needs_return, $current_char );
    ( $needs_return, $buffer, $i, $current_list_output ) =
      $self->_parse_in_array_pre_char_checks( $output, $buffer, $wiki_text, $i,
        $interrupt, $current_list_output, $options );
    if ($needs_return) {
        return ( $needs_next, $needs_return, $i, $buffer, $current_char,
            $current_list_output );
    }
    $current_char = substr $wiki_text, $i, 1;
    ( $needs_next, $buffer, $i ) =
      $self->_break_lines( $output, $buffer, $i, $current_char,
        $options, \$current_list_output );
    return ( $needs_next, $needs_return, $i, $buffer, $current_char,
        $current_list_output );
}

sub _parse_in_array_search_new_elements( $self, $output, $buffer, $wiki_text,
    $i, $options )
{
    my ($needs_next);
    if ( !$options->{is_nowiki} ) {
        {
            if ( !$options->{is_header} ) {
                ( $needs_next, $i, $buffer ) =
                  $self->_try_parse_header( $output, $wiki_text, $buffer, $i,
                    $options );
                next if $needs_next;
            }
            ( $needs_next, $i, $buffer ) =
              $self->_try_parse_bold( $output, $wiki_text, $buffer, $i,
                $options );
            next if $needs_next;
            ( $needs_next, $i, $buffer ) =
              $self->_try_parse_italic( $output, $wiki_text, $buffer, $i,
                $options );
            next if $needs_next;
            if ( !$options->{is_unordered_list} ) {
                ( $needs_next, $i, $buffer ) =
                  $self->_try_parse_unordered_list( $output, $wiki_text,
                    $buffer, $i, $options );
                next if $needs_next;
            }
            ( $needs_next, $i, $buffer ) =
              $self->_try_parse_template( $output, $wiki_text, $buffer, $i,
                $options );
            next if $needs_next;
            ( $needs_next, $i, $buffer ) =
              $self->_try_parse_nowiki( $output, $wiki_text, $buffer, $i,
                $options );
            next if $needs_next;
            ( $needs_next, $i, $buffer ) =
              $self->_try_parse_image( $output, $wiki_text, $buffer, $i,
                $options );
            next if $needs_next;
            ( $needs_next, $i, $buffer ) =
              $self->_try_parse_link( $output, $wiki_text, $buffer, $i,
                $options );
            next if $needs_next;
        }
    }
    return ( $needs_next, $i, $buffer, );
}

sub _parse_in_array(
    $self, $output, $wiki_text, $i = 0,
    $buffer    = '',
    $interrupt = sub { return; },
    $options   = {}
  )
{
    my $current_list_output;
    for ( ; $i < length $wiki_text ; $i++ ) {
        my ( $needs_next, $needs_return, $current_char );
        (
            $needs_next, $needs_return, $i, $buffer, $current_char,
            $current_list_output
          )
          = $self->_parse_in_array_pre_new_element_parsing( $output, $buffer,
            $wiki_text, $i, $interrupt, $current_list_output, $options );
        if ($needs_next) {
            next;
        }
        if ($needs_return) {
            return ( $i, $buffer );
        }
        ( $needs_next, $i, $buffer ) =
          $self->_parse_in_array_search_new_elements( $output, $buffer,
            $wiki_text, $i, $options );
        if ($needs_next) {
            next;
        }
        $buffer .= $current_char;
    }
    if ( !$options->{is_nowiki} && length $buffer ) {
        {
            if ( $options->{is_unordered_list} ) {
                if ( length $buffer ) {
                    push @$output,
                      { type => 'list_element', output => [$buffer] };
                }
                next;
            }
            push @$output, $buffer;
        }
        $buffer = '';
    }
    return ( $i, $buffer );
}

sub _try_parse_nowiki( $self, $output, $wiki_text, $buffer, $i, $options ) {
    my $tag       = '<nowiki>';
    my $next_word = substr $wiki_text, $i, length $tag;
    if ( $tag ne $next_word ) {
        return ( 0, $i, $buffer );
    }
    $i += length $tag;
    ( $i, $buffer ) = $self->_parse_in_array(
        $output,
        $wiki_text,
        $i, $buffer,
        sub ( $wiki_text, $i ) {
            my $tag       = '</nowiki>';
            my $next_word = substr $wiki_text, $i, length $tag;
            if ( $tag ne $next_word ) {
                return;
            }
            return $i + ( length $tag ) - 1;
        },
        { is_nowiki => 1 }
    );
    return ( 1, $i, $buffer );
}

sub _try_parse_italic( $self, $output, $wiki_text, $buffer, $i, $options ) {
    my $searched    = q/''/;
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    my $is_bold_and_italic_single_step =
      $self->_check_bold_and_italic_in_single_step( $wiki_text, $i );
    if ( !$is_bold_and_italic_single_step ) {
        if ( $last_word ne $searched ) {
            return ( 0, $i, $buffer, $options );
        }
    }
    if ( $last_word ne $searched ) {
        return ( 0, $i, $buffer, $options );
    }
    $options->{is_italic} = 1;
    if ($is_bold_and_italic_single_step) {
        $options->{is_bold} = 1;
    }
    $i += $size_search;
    $i += 3 if $is_bold_and_italic_single_step;
    return $self->_recurse_pending_bold_or_italic( $output, $wiki_text, $i,
        $buffer, $options );

}

sub _check_bold_and_italic_in_single_step( $self, $wiki_text, $i ) {
    my $searched    = q/'''''/;
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word eq $searched ) {
        return 1;
    }
    return;
}

sub _try_parse_unordered_list( $self, $output, $wiki_text, $buffer, $i,
    $options )
{
    if ( 0 < length $buffer ) {
        return ( 0, $i, $buffer, $options );
    }
    my $searched    = q/* /;
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word ne $searched ) {
        return ( 0, $i, $buffer, $options );
    }
    $i += $size_search;
    $options->{is_unordered_list} = 1;
    my $element = { type => 'unordered_list', output => [], };
    ( $i, $buffer ) = $self->_parse_in_array(
        $element->{output},
        $wiki_text,
        $i, $buffer,
        sub ( $wiki_text, $i ) {
            my $searched    = "\n";
            my $size_search = length $searched;
            my $last_word   = substr $wiki_text, $i, $size_search;
            if ( $last_word ne $searched ) {
                return;
            }
            $searched    = $LIST_ELEMENT_DELIMITER;
            $size_search = length $searched;
            $last_word   = substr $wiki_text, $i, $size_search;
            if ( $last_word ne $searched ) {
                return $i + $size_search - 3;
            }
            return;
        },
        $options,
    );
    push @$output, $element;
    return ( 1, $i, $buffer, $options );
}

sub _save_before_new_element( $self, $output, $buffer, $options ) {
    if ( !length $buffer ) {
        return ( $output, $buffer );
    }
    if ( $options->{is_unordered_list} ) {
        push @$output, { type => 'list_element', output => [] };
        $output = $output->[-1]{output};
    }
    if ( length $buffer ) {
        push @$output, $buffer;
        $buffer = '';
    }
    return ( $output, $buffer );
}

sub _try_parse_bold( $self, $output, $wiki_text, $buffer, $i, $options ) {
    my $searched    = q/'''/;
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    my $is_bold_and_italic_single_step =
      $self->_check_bold_and_italic_in_single_step( $wiki_text, $i );
    if ( !$is_bold_and_italic_single_step ) {
        if ( $last_word ne $searched ) {
            return ( 0, $i, $buffer, $options );
        }
    }
    $options->{is_bold} = 1;
    if ($is_bold_and_italic_single_step) {
        $options->{is_italic} = 1;
    }
    $i += $size_search;
    $i += 2 if $is_bold_and_italic_single_step;
    my @return =
      $self->_recurse_pending_bold_or_italic( $output, $wiki_text, $i, $buffer,
        $options );
    $return[0] = 1;
    return @return;
}

sub _calculate_bold_or_italic_type( $self, $element, $options ) {
    if ( $options->{is_italic} ) {
        $element->{type} = 'italic';
    }
    if ( $options->{is_bold} ) {
        $element->{type} = 'bold';
    }
    my $is_bold_and_italic = $options->{is_italic} && $options->{is_bold};
    if ($is_bold_and_italic) {
        $element->{type} = 'bold_and_italic';
    }
    return $is_bold_and_italic;
}

sub _recurse_pending_bold_or_italic( $self, $output, $wiki_text, $i, $buffer,
    $options )
{
    my $element = { output => [], };
    my $is_bold_and_italic =
      $self->_calculate_bold_or_italic_type( $element, $options );
    if ( !defined $element->{type} ) {
        return ( 0, $i, $buffer, $options );
    }
    ( $output, $buffer ) =
      $self->_save_before_new_element( $output, $buffer, $options );
    ( $i, $buffer ) = $self->_parse_in_array(
        $element->{output},
        $wiki_text,
        $i, $buffer,
        sub ( $wiki_text, $i ) {
            if ($is_bold_and_italic) {
                my $searched    = q/'''''/;
                my $size_search = length $searched;
                my $last_word   = substr $wiki_text, $i, $size_search;
                if ( $last_word eq $searched ) {
                    delete $options->{is_bold};
                    delete $options->{is_italic};
                    return $i + $size_search - 1;
                }
            }
            my $searched    = q/'''/;
            my $size_search = length $searched;
            my $last_word   = substr $wiki_text, $i, $size_search;
            if ( $last_word eq $searched ) {
                $options->{is_bold} = !$options->{is_bold};
                $i++ if $options->{is_italic};
                return $i + $size_search - 1;
            }
            $searched    = q/''/;
            $size_search = length $searched;
            $last_word   = substr $wiki_text, $i, $size_search;
            if ( $last_word eq $searched ) {
                $options->{is_italic} = !$options->{is_italic};
                $i++ if $options->{is_bold};
                return $i + $size_search - 1;
            }
            return;
        },
        {
            is_italic => $options->{is_italic},
            is_bold   => $options->{is_bold},
        }
    );
    push @$output, $element;
    if ( $i + 1 >= length $wiki_text ) {
        return ( 1, $i, $buffer, $options );
    }
    my @return =
      $self->_recurse_pending_bold_or_italic( $output, $wiki_text, $i, $buffer,
        $options );
    $return[0] = 1;
    return @return;
}

sub _try_parse_image( $self, $output, $wiki_text, $buffer, $i, $options ) {
    my $searched    = '[[File:';
    my $size_search = length $searched;
    my $orig_size_search = $size_search;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word ne $searched ) {
        return ( 0, $i, $buffer );
    }
    my $valid_characters =
qr/[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\-._~:\/?#@!\$&\'\(\)\*\+,;= ]/;
    for ( $size_search = $size_search + 1 ; ; $size_search++ ) {
        my $last_word = substr $wiki_text, $i, $size_search;
        if ( $last_word !~ /^\[\[File:$valid_characters+$/ ) {
            last;
        }
    }
    $size_search--;
    if ( $size_search < $orig_size_search + 1 ) {
        return ( 0, $i, $buffer );
    }
    $last_word = substr $wiki_text, $i, $size_search + 2;
    if ( $last_word =~ /^\[\[File:($valid_characters+)\]\]$/ ) {
        ( $output, $buffer ) =
          $self->_save_before_new_element( $output, $buffer, $options );
        push @$output,
          {
            type  => 'image',
            link  => $1,
            caption => '',
            options => {},
          };
        return ( 1, $i + $size_search + 2, $buffer );
    }
    $last_word = substr $wiki_text, $i, $size_search + 1;
    if ( $last_word !~ /^\[\[File:($valid_characters+)\|/ ) {
        return ( 0, $i, $buffer );
    }
    my $link = $1;

    ( $output, $buffer ) =
      $self->_save_before_new_element( $output, $buffer, $options );

    my $tmp_buffer = '';
    my $is_caption = 0;
    my $element_options = {};
    my $caption;
    for ( $i = $i + $size_search + 1 ; $i < length $wiki_text ; $i++ ) {
        my $searched    = ']]';
        my $size_search = length $searched;
        my $last_word   = substr $wiki_text, $i, $size_search;
        if ( $searched eq $last_word ) {
            ($caption) = $self->_try_parse_link_component($tmp_buffer, $caption, $element_options);
            $tmp_buffer = '';
            last;
        }
        $searched = '|';
        $size_search = length $searched;
        $last_word   = substr $wiki_text, $i, $size_search;
        if ($searched eq $last_word) {
            ($caption) = $self->_try_parse_link_component($tmp_buffer, $caption, $element_options);
            $tmp_buffer = '';
            next;
        }
        my $need_next;
        ( $need_next, $i, $buffer ) =
          $self->_try_parse_nowiki( $output, $wiki_text, $buffer, $i,
            $options );
        $is_caption = 1 if $need_next;
        next if $need_next;

        $tmp_buffer .= substr $wiki_text, $i, 1;
    }

    my $template = {
        type  => 'image',
        link  => $link,
        caption => $caption,
        options => $element_options,
    };
    push @$output, $template;
    $i += 1;
    $buffer = '';
    return ( 1, $i, $buffer );
}

sub _is_defined_image_format_exclusive($self, $element_options) {
    for my $option (qw/frameless frame framed thumb thumbnail/) {
        if (defined $element_options->{format}{$option}) {
            return 1;
        }
    }
    return;
}

sub _try_parse_link_component($self, $tmp_buffer, $caption, $element_options) {
    if ($tmp_buffer =~ /^border$/) {
        $element_options->{format}{border} = 1; 
        return $caption;
    }
    if ($tmp_buffer =~ /^frameless$/) {
        return $caption if $self->_is_defined_image_format_exclusive($element_options);
        $element_options->{format}{frameless} = 1; 
        return $caption;
    }
    if ($tmp_buffer =~ /^frame$/) {
        return $caption if $self->_is_defined_image_format_exclusive($element_options);
        $element_options->{format}{frame} = 1; 
        return $caption;
    }
    if ($tmp_buffer =~ /^framed$/) {
        return $caption if $self->_is_defined_image_format_exclusive($element_options);
        $element_options->{format}{frame} = 1; 
        return $caption;
    }
    if ($tmp_buffer =~ /^thumb$/) {
        return $caption if $self->_is_defined_image_format_exclusive($element_options);
        $element_options->{format}{thumb} = 1; 
        return $caption;
    }
    if ($tmp_buffer =~ /^thumbnail$/) {
        return $caption if $self->_is_defined_image_format_exclusive($element_options);
        $element_options->{format}{thumb} = 1; 
        return $caption;
    }
    my $return_now;
    ($return_now) = $self->_try_parse_image_resizing($tmp_buffer, $element_options);
    return $caption if $return_now;
    if ($tmp_buffer =~ /^left$/) {
        return $caption if $self->_is_defined_image_halign_exclusive($element_options);
        $element_options->{halign} = 'left';
        return $caption;
    }
    if ($tmp_buffer =~ /^right$/) {
        return $caption if $self->_is_defined_image_halign_exclusive($element_options);
        $element_options->{halign} = 'right';
        return $caption;
    }    
    if ($tmp_buffer =~ /^center$/) {
        return $caption if $self->_is_defined_image_halign_exclusive($element_options);
        $element_options->{halign} = 'center';
        return $caption;
    }
    if ($tmp_buffer =~ /^none$/) {
        return $caption if $self->_is_defined_image_halign_exclusive($element_options);
        $element_options->{halign} = 'none';
        return $caption;
    }
    if ($tmp_buffer =~ /^baseline$/) {
        return $caption if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'baseline';
        return $caption;
    }
    if ($tmp_buffer =~ /^sub$/) {
        return $caption if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'sub';
        return $caption;
    }    
    if ($tmp_buffer =~ /^super$/) {
        return $caption if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'super';
        return $caption;
    }
    if ($tmp_buffer =~ /^top$/) {
        return $caption if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'top';
        return $caption;
    }
    if ($tmp_buffer =~ /^text-top$/) {
        return $caption if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'text-top';
        return $caption;
    }
    if ($tmp_buffer =~ /^middle$/) {
        return $caption if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'middle';
        return $caption;
    }
    if ($tmp_buffer =~ /^bottom$/) {
        return $caption if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'bottom';
        return $caption;
    }
    if ($tmp_buffer =~ /^text-bottom$/) {
        return $caption if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'text-bottom';
        return $caption;
    }
    if (my ($link) = $tmp_buffer =~ /^link=(.*)$/) {
        return $caption if defined $element_options->{link};
        $element_options->{link} = $link;
        return $caption;
    }
    if (my ($alt) = $tmp_buffer =~ /^alt=(.*)$/) {
        return $caption if defined $element_options->{alt};
        $element_options->{alt} = $alt;
        return $caption;
    }
    if (my ($page) = $tmp_buffer =~ /^page=(\d+)$/) {
        return $caption if defined $element_options->{page};
        $element_options->{page} = $page;
        return $caption;
    }
    if (my ($thumbtime) = $tmp_buffer =~ /^thumbtime=((?:\d+:)?(?:\d+:)\d+)$/) {
        return $caption if defined $element_options->{thumbtime};
        $element_options->{thumbtime} = $thumbtime;
        return $caption;
    }
    if (my ($start) = $tmp_buffer =~ /^start=((?:\d+:)?(?:\d+:)\d+)$/) {
        return $caption if defined $element_options->{start};
        $element_options->{start} = $start;
        return $caption;
    }
    if ($tmp_buffer =~ /^muted$/) {
        return $caption if defined $element_options->{muted};
        $element_options->{muted} = 1;
        return $caption;
    }
    if ($tmp_buffer =~ /^loop$/) {
        return $caption if defined $element_options->{loop};
        $element_options->{loop} = 1;
        return $caption;
    }
    if (my ($loosy) = $tmp_buffer =~ /^loosy=(.*)$/) {
        return $caption if ($loosy ne 'false');
        return $caption if defined $element_options->{not_loosy};
        $element_options->{not_loosy} = 1;
        return $caption;
    }
    if (my ($class_string) = $tmp_buffer =~ /^class=(.*)$/) {
        return $caption if defined $element_options->{classes};
        $element_options->{classes} = [];
        for my $class (split /\s+/, $class_string) {
            push @{$element_options->{classes}}, $class;
        }
        return $caption;
    }

    if (!defined $caption) {
        return $tmp_buffer;
    }
    return $caption;
}

sub _is_defined_image_valign_exclusive($self, $element_options) {
    if (defined $element_options->{valign}) {
        return 1;
    }
    return 0;
}

sub _is_defined_image_halign_exclusive($self, $element_options) {
    if (defined $element_options->{halign}) {
        return 1;
    }
    return 0;
}

sub _is_defined_image_resizing_exclusive($self, $element_options) {
    for my $option (qw/width height upright/) {
        if (defined $element_options->{resize}{$option}) {
            return 1;
        }
    }
    return 0;
}

sub _try_parse_image_resizing($self, $tmp_buffer, $element_options) {
    if (my ($width) = $tmp_buffer =~ /^(\d+)(?: |)px$/) {
        return 1 if $self->_is_defined_image_resizing_exclusive($element_options);
        $element_options->{resize}{width} = 0+$width;
        return 1;
    }
    if (my ($height) = $tmp_buffer =~ /^x(\d+)(?: |)px$/) {
        return 1 if $self->_is_defined_image_resizing_exclusive($element_options);
        $element_options->{resize}{height} = 0+$height;
        return 1;
    }
    if (my ($width, $height) = $tmp_buffer =~ /^(\d+)x(\d+)(?: |)px$/) {
        return 1 if $self->_is_defined_image_resizing_exclusive($element_options);
        $element_options->{resize}{width} = 0+$width;
        $element_options->{resize}{height} = 0+$height;
        return 1;
    }
    if (my ($upright) = $tmp_buffer =~ /^upright(?: |=)(\d+\.\d+)$/) {
        return 1 if $self->_is_defined_image_resizing_exclusive($element_options);
        $element_options->{resize}{upright} = $upright;
        return 1;
    }
    return 0;
}

sub _try_parse_link( $self, $output, $wiki_text, $buffer, $i, $options ) {
    my $searched    = '[[';
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word ne $searched ) {
        return ( 0, $i, $buffer );
    }
    my $valid_characters =
qr/[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\-._~:\/?#@!\$&\'\(\)\*\+,;= ]/;
    for ( $size_search = 3 ; ; $size_search++ ) {
        my $last_word = substr $wiki_text, $i, $size_search;
        if ( $last_word !~ /^\[\[$valid_characters+$/ ) {
            last;
        }
    }
    $size_search--;
    if ( $size_search < 3 ) {
        return ( 0, $i, $buffer );
    }
    $last_word = substr $wiki_text, $i, $size_search + 2;
    if ( $last_word =~ /^\[\[($valid_characters+)\]\]$/ ) {
        ( $output, $buffer ) =
          $self->_save_before_new_element( $output, $buffer, $options );
        push @$output,
          {
            type  => 'link',
            link  => $1,
            title => $1,
          };
        return ( 1, $i + $size_search + 2, $buffer );
    }
    $last_word = substr $wiki_text, $i, $size_search + 1;
    if ( $last_word !~ /^\[\[($valid_characters+)\|/ ) {
        return ( 0, $i, $buffer );
    }
    my $link = $1;

    ( $output, $buffer ) =
      $self->_save_before_new_element( $output, $buffer, $options );

    for ( $i = $i + $size_search + 1 ; $i < length $wiki_text ; $i++ ) {
        my $searched    = ']]';
        my $size_search = length $searched;
        my $last_word   = substr $wiki_text, $i, $size_search;
        if ( $searched eq $last_word ) {
            last;
        }
        my $need_next;
        ( $need_next, $i, $buffer ) =
          $self->_try_parse_nowiki( $output, $wiki_text, $buffer, $i,
            $options );
        next if $need_next;

        $buffer .= substr $wiki_text, $i, 1;
    }

    my $template = {
        type  => 'link',
        link  => $link,
        title => $buffer || $link,
    };
    push @$output, $template;
    $i += 1;
    $buffer = '';
    return ( 1, $i, $buffer );
}

sub _try_parse_template( $self, $output, $wiki_text, $buffer, $i, $options ) {
    my $searched    = '{{';
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word ne $searched ) {
        return ( 0, $i, $buffer );
    }
    for ( $size_search = 3 ; ; $size_search++ ) {
        my $last_word = substr $wiki_text, $i, $size_search;
        if ( $last_word !~ /^\{\{[a-zA-Z]+$/ ) {
            last;
        }
    }
    $size_search--;
    if ( $size_search < 3 ) {
        return ( 0, $i, $buffer );
    }
    $last_word = substr $wiki_text, $i, $size_search + 2;
    if ( $last_word =~ /^\{\{([a-zA-Z]+)}}$/ ) {
        ( $output, $buffer ) =
          $self->_save_before_new_element( $output, $buffer, $options );
        push @$output,
          {
            type          => 'template',
            template_name => $1,
            output        => [],
          };
        return ( 1, $i + $size_search + 2, $buffer );
    }
    $last_word = substr $wiki_text, $i, $size_search + 1;
    if ( $last_word !~ /^\{\{([a-zA-Z]+)\|/ ) {
        return ( 0, $i, $buffer );
    }

    ( $output, $buffer ) =
      $self->_save_before_new_element( $output, $buffer, $options );

    my $template = {
        type          => 'template',
        template_name => $1,
        output        => [],
    };
    $i += $size_search + 1;
    ( $i, $buffer ) = $self->_parse_in_array(
        $template->{output},
        $wiki_text,
        $i, $buffer,
        sub ( $wiki_text, $i ) {
            my $last_word = substr $wiki_text, $i, 2;
            if ( $last_word ne "}}" ) {
                return;
            }
            return $i + 1;
        },
        { is_template => 1 }
    );
    push @$output, $template;
    return ( 1, $i, $buffer );

}

sub _try_parse_header( $self, $output, $wiki_text, $buffer, $i, $options ) {
    my $last_char = substr $wiki_text, $i, 1;
    if ( $last_char ne '=' ) {
        return ( 0, $i, $buffer );
    }
    ( $output, $buffer ) =
      $self->_save_before_new_element( $output, $buffer, $options );
    my $matching = 1;
    while (1) {
        my $last_chars = substr $wiki_text, $i, $matching + 1;
        if ( $last_chars ne ( '=' x ( $matching + 1 ) ) ) {
            last;
        }
        $matching++;
        if ( $matching > 6 ) {
            $matching = 6;
            last;
        }
        if ( $i + $matching > length $wiki_text ) {
            $matching--;
            last;
        }
    }
    $i += $matching;
    my $header = {
        hx_level => $matching,
        output   => [],
        type     => 'hx',
    };
    ( $i, $buffer ) = $self->_parse_in_array(
        $header->{output},
        $wiki_text,
        $i, $buffer,
        sub ( $wiki_text, $i ) {
            my $char = substr $wiki_text, $i, 1;
            if ( $char eq "\n" ) {
                return $i;
            }
            if ( $char ne '=' ) {
                return;
            }
            for ( ; $i < length $wiki_text ; $i++ ) {
                if ( "\n" eq substr $wiki_text, $i, 1 ) {
                    return $i;
                }

                if ( '=' ne substr $wiki_text, $i, 1 ) {
                    return --$i;
                }
            }
            return $i;
        },
        { is_header => 1 }
    );
    push @$output, $header;
    return ( 1, $i, $buffer );
}
1;

=encoding utf8

=head1 NAME

Wiki::JSON - Parse wiki-like articles to a data-structure transformable to JSON.

=head1 SYNOPSIS

    use Wiki::JSON;

    my $structure = Wiki::JSON->new->parse(<<'EOF');
    = This is a wiki title =
    '''This is bold'''
    ''This is italic''
    '''''This is bold and italic'''''
    == This is a smaller title, the user can use no more than 6 equal signs ==
    <nowiki>''This is printed without expanding the special characters</nowiki>
    * This
    * Is
    * A
    * Bullet
    * Point
    * List
    {{foo|Templates are generated|with their arguments}}
    {{stub|This is under heavy development}}
    The parser has some quirks == This will generate a title ==
    ''' == '' Unterminated syntaxes will still be parsed until the end of file
    This is a link to a wiki article: [[Cool Article]]
    This is a link to a wiki article with an alias: [[Cool Article|cool article]]
    This is a link to a URL with an alias: [[https://example.com/cool-source.html|cool article]]
    This is a link to a Image [[File:https:/example.com/img.png|50x50px|frame|This is a caption]]
    EOF

=head1 DESCRIPTION

A parser for a subset of a mediawiki-like syntax, quirks include some
supposedly inline elements are parsed multi-line like headers, templates*,
italic and bolds.

=head1 DESCRIPTION

A parser for a subset of a mediawiki-like syntax, quirks include some
supposedly inline elements are parsed multi-line like headers, templates*,
italic and bolds.

Lists are only one level and not everything in mediawiki is supported by the
moment.

=head2 INSTALLING

    cpanm https://github.com/sergiotarxz/Perl-Wiki-JSON.git

=head2 USING AS A COMMAND

    wiki2json file.wiki > output.json

=head1 INSTANCE_METHODS

=head2 new

    my $wiki_parser = Wiki::JSON->new;

=head1 METHODS

=head2 parse

    my $structure = $wiki_parser->parse($wiki_string);

Parses the wiki format into a serializable to JSON or YAML Perl data structure.

=head1 RETURN FROM METHODS

=head2 parse

The return is an ArrayRef in which each element is either a string or a HashRef.

HashRefs can be classified by the key type which can be one of these:

=head3 hx

A header to be printed as h1..h6 in HTML, has the following fields:

=over

=item hx_level

A number from 1 to 6 defining the header level.

=item output

An ArrayRef defined by the return from parse.

=back

=head3 template

A template thought for developer defined expansions of how some data shoudl be represented.

=over

=item template_name

The name of the template.

=item output

An ArrayRef defined by the return from parse.

=back

=head3 bold

A set of elements that must be represented as bold text.

=over

=item output

An ArrayRef defined by the return from parse.

=back

=head3 italic

A set of elements that must be represented as italic text.

=over

=item output

An ArrayRef defined by the return from parse.

=back

=head3 bold_and_italic

A set of elements that must be represented as bold and italic text.

=over

=item output

An ArrayRef defined by the return from parse.

=back

=head3 unordered_list

A bullet point list.

=over

=item output

A ArrayRef of HashRefs from the type list_element.

=back

=head3 list_element

An element in a list, this element must not appear outside of the output element of a list.

=over

=item output

An ArrayRef defined by the return from parse.

=back

=head3 link

An URL or a link to other Wiki Article.

=over

=item link

The String containing the URL or link to other Wiki Article.

=item title

The text that should be used while showing this URL to point the user where it is going to be directed.

=back

=head3 image

An Image, PDF, or Video.

=over

=item link

Where to find the File.

=item caption

What to show the user if the image is requested to explain to the user what he is seeing.

=item options

=back

Undocumented by the moment.

=head1 BUGS

The author thinks it is possible the parser hanging forever, use it in
a subprocess the program can kill if it takes too long.

The developer can use fork, waitpid, pipe, and non-blocking IO for that.

=head1 LEGAL

Copyright ©Sergiotarxz (2025)

You can use this software under the terms of the GPLv3 license or a new later
version provided by the FSF or the GNU project.

=head1 SEE ALSO

Look what is supported and how in the tests: L<https://github.com/sergiotarxz/Perl-Wiki-JSON/tree/main/t>

=cut
