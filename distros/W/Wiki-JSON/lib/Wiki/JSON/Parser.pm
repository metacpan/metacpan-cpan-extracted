package Wiki::JSON::Parser;

use v5.16.3;

use strict;
use warnings;

use Moo;
use Data::Dumper;
use Const::Fast;

const my $MAX_HX_SIZE                                           => 6;
const my $EXTRA_CHARACTERS_BOLD_AND_ITALIC_WHEN_ITALIC          => 3;
const my $LIST_ELEMENT_INTERRUPT_NUMBER_OF_CHARACTERS_TO_IGNORE => 3;
const my $MINIMUM_LINK_SEARCH                                   => 3;
const my $MINIMUM_TEMPLATE_SEARCH                               => 3;
const my $LIST_ELEMENT_DELIMITER                                => "\n* ";

has used                 => ( is => 'rw', default => sub { 0 } );
has _current_list_output => ( is => 'rw' );
has _parse_options       => ( is => 'rw' );
has _current_element     => ( is => 'rw', default => sub { [] } );

sub parse {
    my ( $self, $wiki_text, $options ) = @_;
    if ( $self->used ) {
        die 'Parser already used';
    }
    $self->_parse_options($options);
    my @output;
    $self->_parse_in_array( \@output, $wiki_text );
    $self->_strip_all_line_numbers( \@output );
    $self->used(1);
    return \@output;
}

sub _strip_all_line_numbers {
    my ( $self, $output ) = @_;
    if ( $self->_parse_options->{track_lines_for_errors} ) {
        return;
    }
    for my $element (@$output) {
        if ( 'HASH' ne ref $element ) {
            next;
        }
        delete $element->{start_line};
        if ( defined $element->{output} ) {
            @{ $element->{output} } =
              map { $self->_strip_line_numbers_element($_) }
              @{ $element->{output} };
        }
        $self->_strip_all_line_numbers( $element->{output} );
    }
}

sub _search_interrupt {
    my ( $self, $output, $buffer, $wiki_text, $i, $interrupt ) = @_;
    my $new_i = $interrupt->( $wiki_text, $i );
    if ( !defined $new_i ) {
        return;
    }
    $i = $new_i;
    return $i;
}

sub _insert_into_output {
    die 'Wrong number of arguments' if scalar @_ != 3;
    my ( $self, $output, $buffer ) = @_;
    $buffer =~ s/(\n|\A)(\n)/$1/gs;
    if ( $buffer =~ /^$/s ) {
        $buffer = '';
        return ($buffer);
    }
    push @$output, $buffer;
    $buffer = '';
    return ($buffer);
}

sub _break_lines_template {
    my ( $self, $output, $buffer, $current_char, $i ) = @_;
    if ( $current_char eq "|" ) {
        ($buffer) = $self->_insert_into_output( $output, $buffer );
        return ( 1, $buffer, $i );
    }
    return ( 0, $buffer, $i );
}

sub _break_lines {
    my ( $self, $output, $wiki_text, $buffer, $i, $options ) = @_;
    if ( $options->{is_unordered_list} ) {
        return ( 0, $buffer, $i );
    }
    return $self->_break_lines_on_newline( $output, $wiki_text, $buffer, $i, );
}

sub _break_lines_on_newline {
    my ( $self, $output, $wiki_text, $buffer, $i ) = @_;
    my $searched    = "\n\n";
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word eq $searched ) {
        ($buffer) = $self->_insert_into_output( $output, $buffer );
        return ( 1, $buffer, $i + $size_search - 1 );
    }
    $searched    = "\n* ";
    $size_search = length $searched;
    $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word eq $searched ) {
        ($buffer) = $self->_insert_into_output( $output, $buffer );
        return ( 1, $buffer, $i );
    }
    return ( 0, $buffer, $i );
}

sub _if_interrupted {
    my ( $self, $output, $buffer, $options ) = @_;
    if ( $options->{is_unordered_list} ) {
        return $self->_if_interrupted_unordered_list( $output, $buffer,
            $options );
    }
    if ( !$options->{is_nowiki} ) {
        ($buffer) = $self->_insert_into_output( $output, $buffer );
        if ( !$options->{is_bold} && !$options->{is_italic} ) {
            @$output = map { $self->_strip_line_numbers_element($_) } @$output;
        }
    }
    return ($buffer);
}

sub _insert_list_element_never_appending {
    my ( $self, $output, $buffer ) = @_;
    push @$output, { type => 'list_element', output => [$buffer] };
    $self->_current_list_output( $output->[-1]{output} );
    $buffer = '';
    return ($buffer);
}

sub _if_interrupted_unordered_list {
    my ( $self, $output, $buffer, $options ) = @_;
    if ( length $buffer ) {
        if ( $options->{br_found} || $options->{element_found} ) {
            ($buffer) =
              $self->_insert_list_appending_if_possible( $output, $buffer,
                $options );
        }
        else {
            ($buffer) =
              $self->_insert_list_element_never_appending( $output, $buffer );
        }
    }
    delete $options->{br_found};
    delete $options->{element_found};
    delete $options->{is_unordered_list};
    return ($buffer);
}

sub _strip_line_numbers_element {
    my ( $self, $element ) = @_;
    if ( 'HASH' ne ref $element ) {
        return $element;
    }
    delete $element->{start_line};
    return $element;
}

sub _insert_list_appending_if_possible {
    my ( $self, $output, $buffer, $options ) = @_;
    if ( defined $self->_current_list_output ) {
        push @{ $self->_current_list_output }, $buffer;
        $buffer = '';
        return ($buffer);
    }
    ($buffer) =
      $self->_insert_list_element_never_appending( $output, $buffer, );
    return ( $buffer, );
}

sub _insert_new_list_element_after_asterisk {
    my ( $self, $output, $buffer, $i, $options ) = @_;
    my $searched    = $LIST_ELEMENT_DELIMITER;
    my $size_search = length $searched;
    if ( length $buffer ) {
        ($buffer) =
          $self->_insert_list_appending_if_possible( $output, $buffer,
            $options );
        $options->{element_found} = 0;
    }
    delete $options->{br_found};
    delete $options->{element_found};
    $buffer = '';
    $i += $size_search;
    push @$output, { type => 'list_element', output => [] };
    $self->_current_list_output( $output->[-1]{output} );
    $buffer = '';
    return ( $i, $buffer, );
}

sub _needs_interruption {
    my ( $self, $output, $buffer, $wiki_text, $i, $interrupt, $options ) = @_;
    my $new_i;
    my $needs_interruption;
    $new_i =
      $self->_search_interrupt( $output, $buffer, $wiki_text, $i, $interrupt );
    if ( defined $new_i ) {
        ( $buffer, ) = $self->_if_interrupted( $output, $buffer, $options );
        $needs_interruption = 1;
        return ( $needs_interruption, $new_i, $buffer );
    }
    return ( $needs_interruption, $i, $buffer );
}

sub _unordered_list_pre_syntax_parsing_newline_logic {
    my ( $self, $output, $buffer, $wiki_text, $i, $options ) = @_;
    if ( !$options->{is_unordered_list} ) {
        return ( $i, $buffer, );
    }
    ( $i, $buffer, ) =
      $self->_unordered_list_pre_syntax_parsing_newline_logic_real_line(
        $output, $buffer, $wiki_text, $i, $options );
    ( $i, $buffer, ) =
      $self->_unordered_list_pre_syntax_parsing_newline_logic_br( $output,
        $buffer, $wiki_text, $i, $options );
    return ( $i, $buffer, );
}

sub _unordered_list_pre_syntax_parsing_newline_logic_br {
    my ( $self, $output, $buffer, $wiki_text, $i, $options ) = @_;
    my $searched    = '<br>';
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word eq $searched ) {
        $options->{'br_found'} = 1;
        if ( length $buffer ) {
            if ( defined $self->_current_list_output ) {
                push @{ $self->_current_list_output }, $buffer;
            }
            else {
                push @$output, { type => 'list_element', output => [$buffer] };
                $self->_current_list_output( $output->[-1]{output} );
            }
        }
        $buffer = '';
        $i += $size_search;
    }
    return ( $i, $buffer );
}

sub _unordered_list_pre_syntax_parsing_newline_logic_real_line {
    my ( $self, $output, $buffer, $wiki_text, $i, $options ) = @_;
    my $searched    = $LIST_ELEMENT_DELIMITER;
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word eq $searched ) {
        ( $i, $buffer ) =
          $self->_insert_new_list_element_after_asterisk( $output,
            $buffer, $i, $options );
    }
    return ( $i, $buffer );
}

sub _parse_in_array_pre_char_checks {
    my ( $self, $output, $buffer, $wiki_text, $i, $interrupt, $options ) = @_;
    my ( $needs_interruption, $new_i );
    ( $needs_interruption, $new_i, $buffer ) =
      $self->_needs_interruption( $output, $buffer, $wiki_text, $i,
        $interrupt, $options );
    if ($needs_interruption) {
        return ( $needs_interruption, $buffer, $new_i, );
    }
    ( $i, $buffer, ) =
      $self->_unordered_list_pre_syntax_parsing_newline_logic( $output,
        $buffer, $wiki_text, $i, $options );
    return ( $needs_interruption, $buffer, $i, );
}

sub _parse_in_array_pre_new_element_parsing {
    my ( $self, $output, $buffer, $wiki_text, $i, $interrupt, $options ) = @_;
    my ( $needs_next, $needs_return, $current_char );
    ( $needs_return, $buffer, $i, ) =
      $self->_parse_in_array_pre_char_checks( $output, $buffer, $wiki_text, $i,
        $interrupt, $options );
    if ($needs_return) {
        return ( $needs_next, $needs_return, $i, $buffer, $current_char, );
    }
    ( $needs_next, $buffer, $i ) =
      $self->_break_lines( $output, $wiki_text, $buffer, $i, $current_char,
        $options, );
    $current_char = substr $wiki_text, $i, 1;
    return ( $needs_next, $needs_return, $i, $buffer, $current_char, );
}

sub _parse_in_array_search_new_elements {
    my ( $self, $output, $buffer, $wiki_text, $i, $options ) = @_;
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

sub _parse_in_array {
    my ( $self, $output, $wiki_text, $i, $buffer, $interrupt, $options, ) = @_;

    $i         //= 0;
    $buffer    //= '';
    $interrupt //= sub { return };
    $options   //= {};

    for ( ; $i < length $wiki_text ; $i++ ) {
        my ( $needs_next, $needs_return, $current_char );
        ( $needs_next, $needs_return, $i, $buffer, $current_char, ) =
          $self->_parse_in_array_pre_new_element_parsing( $output, $buffer,
            $wiki_text, $i, $interrupt, $options );
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
                if ( $options->{element_found} || $options->{br_found} ) {
                    ($buffer) =
                      $self->_insert_list_appending_if_possible( $output,
                        $buffer, $options );
                    next;
                }
                ($buffer) =
                  $self->_insert_list_element_never_appending( $output,
                    $buffer );
                next;
            }
            ($buffer) = $self->_insert_into_output( $output, $buffer );
        }
        $buffer = '';
    }
    if ( $options->{is_bold} || $options->{is_italic} ) {
        say STDERR 'Detected bold or italic unterminated syntax WIKI_LINE: '
          . $self->_current_element->[-1]{start_line};
    }
    return ( $i, $buffer );
}

sub _try_parse_nowiki {
    my ( $self, $output, $wiki_text, $buffer, $i, $options ) = @_;
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
        sub {
            my ( $wiki_text, $i ) = @_;
            return $self->_try_interrupt_nowiki( $wiki_text, $i );
        },
        { is_nowiki => 1 }
    );
    return ( 1, $i, $buffer );
}

sub _try_interrupt_nowiki {
    my ( $self, $wiki_text, $i ) = @_;
    my $tag       = '</nowiki>';
    my $next_word = substr $wiki_text, $i, length $tag;
    if ( $tag ne $next_word ) {
        return;
    }
    return $i + ( length $tag ) - 1;
}

sub _try_parse_italic {
    my ( $self, $output, $wiki_text, $buffer, $i, $options ) = @_;
    my $searched    = q/''/;
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    my $is_bold_and_italic_single_step =
      $self->_check_bold_and_italic_in_single_step( $wiki_text, $i );
    my $start_bold_or_italic = $i;
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
    if ($is_bold_and_italic_single_step) {
        $i += $EXTRA_CHARACTERS_BOLD_AND_ITALIC_WHEN_ITALIC;
    }
    return $self->_recurse_pending_bold_or_italic( $output, $wiki_text, $i,
        $start_bold_or_italic, $buffer, $options );

}

sub _check_bold_and_italic_in_single_step {
    my ( $self, $wiki_text, $i ) = @_;
    my $searched    = q/'''''/;
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word eq $searched ) {
        return 1;
    }
    return;
}

sub _try_parse_unordered_list {
    my ( $self, $output, $wiki_text, $buffer, $i, $options ) = @_;
    my $start_line =
      scalar @{ [ split "\n", substr( $wiki_text, 0, $i ) ] };
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
    $element->{start_line} = $start_line;
    ( $i, $buffer ) = $self->_parse_in_array(
        $element->{output},
        $wiki_text,
        $i, $buffer,
        sub {
            my ( $wiki_text, $i ) = @_;
            if ( $self->_try_discard_interrupt_list( $wiki_text, $i ) ) {
                return;
            }
            return $self->_try_interrupt_list( $wiki_text, $i );
        },
        $options,
    );
    @{ $element->{output} } =
      grep { @{ $_->{output} } } @{ $element->{output} };
    push @$output, $element;
    return ( 1, $i, $buffer, $options );
}

sub _try_interrupt_list {
    my ( $self, $wiki_text, $i ) = @_;
    my $searched    = $LIST_ELEMENT_DELIMITER;
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word ne $searched ) {
        return $i + $size_search -
          $LIST_ELEMENT_INTERRUPT_NUMBER_OF_CHARACTERS_TO_IGNORE;
    }
    return;
}

sub _try_discard_interrupt_list {
    my ( $self, $wiki_text, $i ) = @_;
    my $searched    = "\n";
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word ne $searched ) {
        return 1;
    }
    return 0;
}

sub _save_before_new_element {
    my ( $self, $output, $buffer, $options ) = @_;
    if ( $options->{is_unordered_list} ) {
        if ( length $buffer || !@$output ) {
            push @$output, { type => 'list_element', output => [] };
        }
        $output = $output->[-1]{output};
        $self->_current_list_output($output);
        $options->{element_found} = 1;
    }
    if ( !length $buffer ) {
        return ( $output, $buffer );
    }
    ($buffer) = $self->_insert_into_output( $output, $buffer );
    return ( $output, $buffer );
}

sub _try_parse_bold {
    my ( $self, $output, $wiki_text, $buffer, $i, $options ) = @_;
    my $searched             = q/'''/;
    my $start_bold_or_italic = $i;
    my $size_search          = length $searched;
    my $last_word            = substr $wiki_text, $i, $size_search;
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
    if ($is_bold_and_italic_single_step) {
        $i += 2;
    }
    my @return =
      $self->_recurse_pending_bold_or_italic( $output, $wiki_text, $i,
        $start_bold_or_italic, $buffer, $options );
    $return[0] = 1;
    return @return;
}

sub _calculate_bold_or_italic_type {
    my ( $self, $element, $options ) = @_;
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

sub _recurse_pending_bold_or_italic {
    my ( $self, $output, $wiki_text, $i, $start_bold_or_italic, $buffer,
        $options )
      = @_;
    my $element = { output => [], };
    my $is_bold_and_italic =
      $self->_calculate_bold_or_italic_type( $element, $options );
    my $start_line =
      scalar @{ [ split "\n", substr( $wiki_text, 0, $start_bold_or_italic ) ]
      };
    push @{ $self->_current_element }, $element;
    $element->{start_line} = $start_line;
    say $element->{start_line} . '';
    if ( !defined $element->{type} ) {
        return ( 0, $i, $buffer, $options );
    }
    ( $output, $buffer ) =
      $self->_save_before_new_element( $output, $buffer, $options );
    ( $i, $buffer ) = $self->_parse_in_array(
        $element->{output},
        $wiki_text,
        $i, $buffer,
        sub {
            my ( $wiki_text, $i ) = @_;
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
                if ( $options->{is_italic} ) {
                    $i++;
                }
                return $i + $size_search - 1;
            }
            $searched    = q/''/;
            $size_search = length $searched;
            $last_word   = substr $wiki_text, $i, $size_search;
            if ( $last_word eq $searched ) {
                $options->{is_italic} = !$options->{is_italic};
                if ( $options->{is_bold} ) {
                    $i++;
                }
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
    pop @{ $self->_current_element };
    my @return =
      $self->_recurse_pending_bold_or_italic( $output, $wiki_text, $i,
        $start_bold_or_italic, $buffer, $options );
    $return[0] = 1;
    return @return;
}

sub _try_parse_image_find_url_size {
    my ( $self, $wiki_text, $valid_characters, $i, $size_search ) = @_;
    for ( $size_search = $size_search + 1 ; ; $size_search++ ) {
        my $last_word = substr $wiki_text, $i, $size_search;
        if ( $last_word !~ /^\[\[File:$valid_characters+$/x ) {
            last;
        }
    }
    return $size_search;
}

sub _try_parse_image {
    my ( $self, $output, $wiki_text, $buffer, $i, $options ) = @_;
    my $searched         = '[[File:';
    my $size_search      = length $searched;
    my $orig_size_search = $size_search;
    my $last_word        = substr $wiki_text, $i, $size_search;
    my $start_line =
      scalar @{ [ split "\n", substr( $wiki_text, 0, $i ) ] };
    if ( $last_word ne $searched ) {
        return ( 0, $i, $buffer );
    }
    my $valid_characters = qr/[A-Za-z0-9\-._~:\/?#@!\$&\'\(\)\*\+,;=\ ]/x;
    ($size_search) =
      $self->_try_parse_image_find_url_size( $wiki_text, $valid_characters, $i,
        $size_search );
    $size_search--;
    if ( $size_search < $orig_size_search + 1 ) {
        return ( 0, $i, $buffer );
    }
    $last_word = substr $wiki_text, $i, $size_search + 2;
    if ( $last_word =~ /^\[\[File:($valid_characters+)\]\]$/x ) {
        ( $output, $buffer ) =
          $self->_save_before_new_element( $output, $buffer, $options );
        push @$output,
          {
            type       => 'image',
            link       => $1,
            caption    => '',
            options    => {},
            start_line => $start_line,
          };
        return ( 1, $i + $size_search + 2, $buffer );
    }
    my ( $got_link, $link ) =
      $self->_try_parse_image_get_url( $wiki_text, $valid_characters, $i,
        $size_search );
    if ( !$got_link ) {
        return ( 0, $i, $buffer );
    }

    ( $output, $buffer ) =
      $self->_save_before_new_element( $output, $buffer, $options );

    my $tmp_buffer      = '';
    my $is_caption      = 0;
    my $element_options = {};
    my $caption;
    for ( $i = $i + $size_search + 1 ; $i < length $wiki_text ; $i++ ) {
        my $last_component;
        ( $last_component, $caption, $tmp_buffer ) =
          $self->_try_parse_image_parse_end( $wiki_text, $tmp_buffer, $i,
            $caption, $element_options );
        if ($last_component) {
            last;
        }
        $searched    = '|';
        $size_search = length $searched;
        $last_word   = substr $wiki_text, $i, $size_search;
        if ( $searched eq $last_word ) {
            ($caption) =
              $self->_try_parse_link_component( $tmp_buffer, $caption,
                $element_options );
            $tmp_buffer = '';
            next;
        }
        my $need_next;
        ( $need_next, $i, $buffer ) =
          $self->_try_parse_nowiki( $output, $wiki_text, $buffer, $i,
            $options );
        if ($need_next) {
            $is_caption = 1;
            next;
        }

        $tmp_buffer .= substr $wiki_text, $i, 1;
    }

    my $template = {
        type       => 'image',
        link       => $link,
        caption    => $caption,
        options    => $element_options,
        start_line => $start_line,
    };
    push @$output, $template;
    $i += 1;
    $buffer = '';
    return ( 1, $i, $buffer );
}

sub _try_parse_image_parse_end {
    my ( $self, $wiki_text, $tmp_buffer, $i, $caption, $element_options ) = @_;
    my $searched    = ']]';
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $searched eq $last_word ) {
        ($caption) =
          $self->_try_parse_link_component( $tmp_buffer, $caption,
            $element_options );
        $tmp_buffer = '';
        return ( 1, $caption, $tmp_buffer );
    }
    return ( 0, $caption, $tmp_buffer );
}

sub _try_parse_image_get_url {
    my ( $self, $wiki_text, $valid_characters, $i, $size_search ) = @_;
    my $last_word = substr $wiki_text, $i, $size_search + 1;
    if ( $last_word =~ /^\[\[File:($valid_characters+)\|/x ) {
        return ( 1, $1 );
    }
    return (0);
}

sub _is_defined_image_format_exclusive {
    my ( $self, $element_options ) = @_;
    for my $option (qw/frameless frame framed thumb thumbnail/) {
        if ( defined $element_options->{format}{$option} ) {
            return 1;
        }
    }
    return;
}

sub _try_parse_link_component_formats {
    my ( $self, $tmp_buffer, $caption, $element_options ) = @_;
    if ( $tmp_buffer =~ /^border$/x ) {
        $element_options->{format}{border} = 1;
        return 1;
    }
    if ( $tmp_buffer =~ /^frameless$/x ) {
        return 1
          if $self->_is_defined_image_format_exclusive($element_options);
        $element_options->{format}{frameless} = 1;
        return 1;
    }
    if ( $tmp_buffer =~ /^frame$/x ) {
        return 1
          if $self->_is_defined_image_format_exclusive($element_options);
        $element_options->{format}{frame} = 1;
        return 1;
    }
    if ( $tmp_buffer =~ /^framed$/x ) {
        return 1
          if $self->_is_defined_image_format_exclusive($element_options);
        $element_options->{format}{frame} = 1;
        return 1;
    }
    if ( $tmp_buffer =~ /^thumb$/x ) {
        return 1
          if $self->_is_defined_image_format_exclusive($element_options);
        $element_options->{format}{thumb} = 1;
        return 1;
    }
    if ( $tmp_buffer =~ /^thumbnail$/x ) {
        return 1
          if $self->_is_defined_image_format_exclusive($element_options);
        $element_options->{format}{thumb} = 1;
        return 1;
    }
    return;
}

sub _try_parse_link_component_halign {
    my ( $self, $tmp_buffer, $caption, $element_options ) = @_;
    if ( $tmp_buffer =~ /^left$/x ) {
        return $caption
          if $self->_is_defined_image_halign_exclusive($element_options);
        $element_options->{halign} = 'left';
        return $caption;
    }
    if ( $tmp_buffer =~ /^right$/x ) {
        return $caption
          if $self->_is_defined_image_halign_exclusive($element_options);
        $element_options->{halign} = 'right';
        return $caption;
    }
    if ( $tmp_buffer =~ /^center$/x ) {
        return $caption
          if $self->_is_defined_image_halign_exclusive($element_options);
        $element_options->{halign} = 'center';
        return $caption;
    }
    if ( $tmp_buffer =~ /^none$/x ) {
        return $caption
          if $self->_is_defined_image_halign_exclusive($element_options);
        $element_options->{halign} = 'none';
        return $caption;
    }
    return;
}

sub _try_parse_link_component_valign {
    my ( $self, $tmp_buffer, $caption, $element_options ) = @_;
    if ( $tmp_buffer =~ /^baseline$/x ) {
        return $caption
          if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'baseline';
        return $caption;
    }
    if ( $tmp_buffer =~ /^sub$/x ) {
        return $caption
          if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'sub';
        return $caption;
    }
    if ( $tmp_buffer =~ /^super$/x ) {
        return $caption
          if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'super';
        return $caption;
    }
    if ( $tmp_buffer =~ /^top$/x ) {
        return $caption
          if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'top';
        return $caption;
    }
    if ( $tmp_buffer =~ /^text-top$/x ) {
        return $caption
          if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'text-top';
        return $caption;
    }
    if ( $tmp_buffer =~ /^middle$/x ) {
        return $caption
          if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'middle';
        return $caption;
    }
    if ( $tmp_buffer =~ /^bottom$/x ) {
        return $caption
          if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'bottom';
        return $caption;
    }
    if ( $tmp_buffer =~ /^text-bottom$/x ) {
        return $caption
          if $self->_is_defined_image_valign_exclusive($element_options);
        $element_options->{valign} = 'text-bottom';
        return $caption;
    }
    return;
}

sub _try_parse_link_component_extra_options_video_controls {
    my ( $self, $tmp_buffer, $caption, $element_options ) = @_;
    if ( my ($thumbtime) =
        $tmp_buffer =~ /^thumbtime=((?:\d+:)?(?:\d+:)\d+)$/x )
    {
        return 1 if defined $element_options->{thumbtime};
        $element_options->{thumbtime} = $thumbtime;
        return 1;
    }
    if ( my ($start) = $tmp_buffer =~ /^start=((?:\d+:)?(?:\d+:)\d+)$/x ) {
        return 1 if defined $element_options->{start};
        $element_options->{start} = $start;
        return 1;
    }
    if ( $tmp_buffer =~ /^muted$/x ) {
        return 1 if defined $element_options->{muted};
        $element_options->{muted} = 1;
        return 1;
    }
    if ( $tmp_buffer =~ /^loop$/x ) {
        return 1 if defined $element_options->{loop};
        $element_options->{loop} = 1;
        return 1;
    }
    return;
}

sub _try_parse_link_component_extra_options {
    my ( $self, $tmp_buffer, $caption, $element_options ) = @_;
    if ( my ($link) = $tmp_buffer =~ /^link=(.*)$/x ) {
        return 1 if defined $element_options->{link};
        $element_options->{link} = $link;
        return 1;
    }
    if ( my ($alt) = $tmp_buffer =~ /^alt=(.*)$/x ) {
        return 1 if defined $element_options->{alt};
        $element_options->{alt} = $alt;
        return 1;
    }
    if ( my ($page) = $tmp_buffer =~ /^page=(\d+)$/x ) {
        return 1 if defined $element_options->{page};
        $element_options->{page} = $page;
        return 1;
    }
    if ( my ($loosy) = $tmp_buffer =~ /^loosy=(.*)$/x ) {
        return 1 if ( $loosy ne 'false' );
        return 1 if defined $element_options->{not_loosy};
        $element_options->{not_loosy} = 1;
        return 1;
    }
    if ( my ($class_string) = $tmp_buffer =~ /^class=(.*)$/x ) {
        return 1 if defined $element_options->{classes};
        $element_options->{classes} = [];
        for my $class ( split /\s+/x, $class_string ) {
            push @{ $element_options->{classes} }, $class;
        }
        return 1;
    }
    my $return_video =
      $self->_try_parse_link_component_extra_options_video_controls(
        $tmp_buffer, $caption, $element_options );
    return 1 if defined $return_video;
    return;
}

sub _try_parse_link_component {
    my ( $self, $tmp_buffer, $caption, $element_options ) = @_;
    my $found_something =
      $self->_try_parse_link_component_formats( $tmp_buffer, $caption,
        $element_options );
    if ( defined $found_something ) {
        return $caption;
    }
    my $return_now;
    ($return_now) =
      $self->_try_parse_image_resizing( $tmp_buffer, $element_options );
    return $caption if $return_now;
    my $return_caption_halign =
      $self->_try_parse_link_component_halign( $tmp_buffer, $caption,
        $element_options );
    return $return_caption_halign if defined $return_caption_halign;
    my $return_caption_valign =
      $self->_try_parse_link_component_valign( $tmp_buffer, $caption,
        $element_options );
    return $return_caption_valign if defined $return_caption_halign;
    my $return_component_extra =
      $self->_try_parse_link_component_extra_options( $tmp_buffer, $caption,
        $element_options );
    return $caption if defined $return_component_extra;

    if ( !defined $caption ) {
        return $tmp_buffer;
    }
    return $caption;
}

sub _is_defined_image_valign_exclusive {
    my ( $self, $element_options ) = @_;
    if ( defined $element_options->{valign} ) {
        return 1;
    }
    return 0;
}

sub _is_defined_image_halign_exclusive {
    my ( $self, $element_options ) = @_;
    if ( defined $element_options->{halign} ) {
        return 1;
    }
    return 0;
}

sub _is_defined_image_resizing_exclusive {
    my ( $self, $element_options ) = @_;
    for my $option (qw/width height upright/) {
        if ( defined $element_options->{resize}{$option} ) {
            return 1;
        }
    }
    return 0;
}

sub _try_parse_image_resizing {
    my ( $self, $tmp_buffer, $element_options ) = @_;
    if ( my ($width) = $tmp_buffer =~ /^(\d+)(?:\ |)px$/x ) {
        return 1
          if $self->_is_defined_image_resizing_exclusive($element_options);
        $element_options->{resize}{width} = 0 + $width;
        return 1;
    }
    if ( my ($height) = $tmp_buffer =~ /^x(\d+)(?:\ |)px$/x ) {
        return 1
          if $self->_is_defined_image_resizing_exclusive($element_options);
        $element_options->{resize}{height} = 0 + $height;
        return 1;
    }
    if ( my ( $width, $height ) = $tmp_buffer =~ /^(\d+)x(\d+)(?:\ |)px$/x ) {
        return 1
          if $self->_is_defined_image_resizing_exclusive($element_options);
        $element_options->{resize}{width}  = 0 + $width;
        $element_options->{resize}{height} = 0 + $height;
        return 1;
    }
    if ( my ($upright) = $tmp_buffer =~ /^upright(?:\ |=)(\d+\.\d+)$/x ) {
        return 1
          if $self->_is_defined_image_resizing_exclusive($element_options);
        $element_options->{resize}{upright} = $upright;
        return 1;
    }
    return 0;
}

sub _try_parse_link_find_size_url {
    my ( $self, $wiki_text, $valid_characters, $i ) = @_;
    my $size_search;
    for ( $size_search = $MINIMUM_LINK_SEARCH ; ; $size_search++ ) {
        my $last_word = substr $wiki_text, $i, $size_search;
        if ( $last_word !~ /^\[\[$valid_characters+$/x ) {
            last;
        }
    }
    return $size_search;
}

sub _try_parse_link_try_determine_url {
    my ( $self, $wiki_text, $valid_characters, $i, $size_search ) = @_;
    my $last_word = substr $wiki_text, $i, $size_search + 1;
    if ( $last_word =~ /^\[\[($valid_characters+)\|/x ) {
        return ( 1, $1 );
    }
    return (0);
}

sub _try_parse_link {
    my ( $self, $output, $wiki_text, $buffer, $i, $options ) = @_;
    my $searched    = '[[';
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $last_word ne $searched ) {
        return ( 0, $i, $buffer );
    }
    my $valid_characters = qr/[A-Za-z0-9\-._~:\/?#@!\$&\'\(\)\*\+,;=\ ]/x;
    $size_search =
      $self->_try_parse_link_find_size_url( $wiki_text, $valid_characters, $i );
    $size_search--;
    if ( $size_search < $MINIMUM_LINK_SEARCH ) {
        return ( 0, $i, $buffer );
    }
    $last_word = substr $wiki_text, $i, $size_search + 2;
    if ( $last_word =~ /^\[\[($valid_characters+)\]\]$/x ) {
        ( $output, $buffer ) =
          $self->_save_before_new_element( $output, $buffer, $options );
        push @$output,
          {
            type  => 'link',
            link  => $1,
            title => $1,
          };
        return ( 1, $i + $size_search + 1, $buffer );
    }
    my ( $got_url, $link ) =
      $self->_try_parse_link_try_determine_url( $wiki_text, $valid_characters,
        $i, $size_search );
    if ( !$got_url ) {
        return ( 0, $i, $buffer );
    }

    ( $output, $buffer ) =
      $self->_save_before_new_element( $output, $buffer, $options );

    for ( $i = $i + $size_search + 1 ; $i < length $wiki_text ; $i++ ) {
        last if $self->_try_parse_link_find_end_title( $wiki_text, $i );
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
    $buffer = '';
    $i += 1;
    return ( 1, $i, $buffer );
}

sub _try_parse_link_find_end_title {
    my ( $self, $wiki_text, $i ) = @_;
    my $searched    = ']]';
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    if ( $searched eq $last_word ) {
        return 1;
    }
    return 0;
}

sub _try_parse_template_find_size_name_template {
    my ( $self, $wiki_text, $i ) = @_;
    my $size_search;
    for ( $size_search = $MINIMUM_TEMPLATE_SEARCH ; ; $size_search++ ) {
        my $last_word = substr $wiki_text, $i, $size_search;
        if ( $last_word !~ /^\{\{[a-zA-Z]+$/x ) {
            last;
        }
    }
    return $size_search;
}

sub _try_parse_template {
    my ( $self, $output, $wiki_text, $buffer, $i, $options ) = @_;
    my $searched    = '{{';
    my $size_search = length $searched;
    my $last_word   = substr $wiki_text, $i, $size_search;
    my $start_line =
      scalar @{ [ split "\n", substr( $wiki_text, 0, $i ) ] };
    if ( $last_word ne $searched ) {
        return ( 0, $i, $buffer );
    }
    $size_search =
      $self->_try_parse_template_find_size_name_template( $wiki_text, $i );
    $size_search--;
    if ( $size_search < $MINIMUM_TEMPLATE_SEARCH ) {
        return ( 0, $i, $buffer );
    }
    $last_word = substr $wiki_text, $i, $size_search + 2;
    if ( $last_word =~ /^\{\{([a-zA-Z]+)}}$/x ) {
        ( $output, $buffer ) =
          $self->_save_before_new_element( $output, $buffer, $options );
        push @$output,
          {
            type          => 'template',
            template_name => $1,
            output        => [],
            start_line    => $start_line,
          };
        return ( 1, $i + $size_search + 1, $buffer );
    }
    my ( $got_template_name, $template_name ) =
      $self->_try_parse_template_get_template_name( $wiki_text, $i,
        $size_search );
    if ( !$got_template_name ) {
        return ( 0, $i, $buffer );
    }

    ( $output, $buffer ) =
      $self->_save_before_new_element( $output, $buffer, $options );

    my $template = {
        type          => 'template',
        template_name => $template_name,
        output        => [],
        start_line    => $start_line,
    };
    my $current_buffer = '';
    my $needs_arg      = 0;
    for ( $i += $size_search + 1 ; $i < length $wiki_text ; $i++ ) {
        my $searched    = '|';
        my $size_search = length $searched;
        my $last_word   = substr $wiki_text, $i, $size_search;
        if ( $searched eq $last_word ) {
            push @{ $template->{output} }, $current_buffer;
            $current_buffer = '';
            $needs_arg      = 1;
            next;
        }
        $needs_arg   = 0;
        $searched    = '}}';
        $size_search = length $searched;
        $last_word   = substr $wiki_text, $i, $size_search;
        if ( $searched eq $last_word ) {
            push @{ $template->{output} }, $current_buffer;
            $current_buffer = '';
            $i += 1;
            last;
        }
        my $needs_next;
        ( $needs_next, $i, $current_buffer ) =
          $self->_try_parse_nowiki( $template->{output}, $wiki_text,
            $current_buffer, $i, {} );
        next if $needs_next;
        $current_buffer .= substr $wiki_text, $i, 1;
    }
    if ( length $current_buffer || $needs_arg ) {
        push @{ $template->{output} }, $current_buffer;
        $current_buffer = '';
    }
    push @$output, $template;
    return ( 1, $i, $buffer );
}

sub _try_parse_template_try_to_interrupt {
    my ( $self, $wiki_text, $i ) = @_;
    my $last_word = substr $wiki_text, $i, 2;
    if ( $last_word ne "}}" ) {
        return;
    }
    return $i + 1;
}

sub _try_parse_template_get_template_name {
    my ( $self, $wiki_text, $i, $size_search ) = @_;
    my $last_word = substr $wiki_text, $i, $size_search + 1;
    if ( $last_word =~ /^\{\{([a-zA-Z]+)\|/x ) {
        return ( 1, $1 );
    }
    return (0);
}

sub _try_parse_header {
    my ( $self, $output, $wiki_text, $buffer, $i, $options ) = @_;
    my $last_char = substr $wiki_text, $i, 1;
    if ( $last_char ne '=' ) {
        return ( 0, $i, $buffer );
    }
    my $start_line =
      scalar @{ [ split "\n", substr( $wiki_text, 0, $i ) ] };
    ( $output, $buffer ) =
      $self->_save_before_new_element( $output, $buffer, $options );
    my $matching = 1;
    while (1) {
        my $last_chars = substr $wiki_text, $i, $matching + 1;
        if ( $last_chars ne ( '=' x ( $matching + 1 ) ) ) {
            last;
        }
        $matching++;
        if ( $matching > $MAX_HX_SIZE ) {
            $matching = $MAX_HX_SIZE;
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
    $header->{start_line} = $start_line;
    ( $i, $buffer ) = $self->_parse_in_array(
        $header->{output},
        $wiki_text,
        $i, $buffer,
        sub {
            my ( $wiki_text, $i ) = @_;
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
    if ( scalar @{ $header->{output} } ) {
        if ( !ref $header->{output}[0] ) {
            ( $header->{output}[0] ) = $header->{output}[0] =~ /^\s*(.*?)$/;
            if ( !$header->{output}[0] ) {
                @{ $header->{output} } = splice @{ $header->{output} }, 1;
            }
        }
        my $last_index   = -1 + scalar @{ $header->{output} };
        my $last_element = $header->{output}[$last_index];
        if ( defined $last_element && !ref $last_element ) {
            ( $header->{output}[$last_index] ) =
              $header->{output}[$last_index] =~ /^(.*?)\s*$/;
            if ( !$header->{output}[$last_index] ) {
                @{ $header->{output} } = splice @{ $header->{output} }, 0,
                  $last_index;
            }
        }
    }
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

           =head1 INSTANCE METHODS

           =head2 new

           my $wiki_parser = Wiki::JSON->new;

           =head1 SUBROUTINES/METHODS

           =head2 parse

           my $structure = $wiki_parser->parse($wiki_string);

           Parses the wiki format into a serializable to JSON or YAML Perl data structure.

           =head1 RETURN FROM METHODS

           =head2 parse

           The return is an ArrayRef in which each element is either a string or a HashRef.

           HashRefs can be classified by the key type which can be one of these:

           =head3 hx

           A header to be printed as h1..h6 in HTML, has the following fields:

           =over 4

           =item hx_level

           A number from 1 to 6 defining the header level.

           =item output

           An ArrayRef defined by the return from parse.

           =back

           =head3 template

           A template thought for developer defined expansions of how some data shoudl be represented.

           =over 4

           =item template_name

           The name of the template.

           =item output

           An ArrayRef defined by the return from parse.

           =back

           =head3 bold

           A set of elements that must be represented as bold text.

           =over 4

           =item output

           An ArrayRef defined by the return from parse.

           =back

           =head3 italic

           A set of elements that must be represented as italic text.

           =over 4

           =item output

           An ArrayRef defined by the return from parse.

           =back

           =head3 bold_and_italic

           A set of elements that must be represented as bold and italic text.

           =over 4

           =item output

           An ArrayRef defined by the return from parse.

           =back

           =head3 unordered_list

           A bullet point list.

           =over 4

           =item output

           A ArrayRef of HashRefs from the type list_element.

           =back

           =head3 list_element

           An element in a list, this element must not appear outside of the output element of a list.

           =over 4

           =item output

An ArrayRef defined by the return from parse.

=back

=head3 link

An URL or a link to other Wiki Article.

=over 4

=item link

The String containing the URL or link to other Wiki Article.

=item title

The text that should be used while showing this URL to point the user where it is going to be directed.

=back

=head3 image

An Image, PDF, or Video.

=over 4

=item link

Where to find the File.

=item caption

What to show the user if the image is requested to explain to the user what he is seeing.

=item options

=back

Undocumented by the moment.

=head1 DEPENDENCIES

The module will pull all the dependencies it needs on install, the minimum supported Perl is v5.38.2.

=head1 CONFIGURATION AND ENVIRONMENT

If your OS Perl is too old perlbrew can be used instead.

=head1 BUGS AND LIMITATIONS

The author thinks it is possible the parser hanging forever, use it in
a subprocess the program can kill if it takes too long.

The developer can use fork, waitpid, pipe, and non-blocking IO for that.

=head1 DIAGNOSTICS

If a string halting forever this module is found, send it to me in the Github issue tracker.

=head1 LICENSE AND COPYRIGHT

    Copyright ©Sergiotarxz (2025)

Licensed under the The GNU General Public License, Version 3, June 2007 L<http://www.gnu.org/licenses/gpl-3.0.txt>.

You can use this software under the terms of the GPLv3 license or a new later
version provided by the FSF or the GNU project.

=head1 INCOMPATIBILITIES

None known.

=head1 VERSION

0.0.x

=head1 AUTHOR

Sergio Iglesias

=head1 SEE ALSO

Look what is supported and how in the tests: L<https://github.com/sergiotarxz/Perl-Wiki-JSON/tree/main/t>

=cut
