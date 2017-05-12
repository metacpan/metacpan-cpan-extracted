package XML::Grammar::Fortune::ToText;

use warnings;
use strict;

use XML::LibXML;
use Text::Format;
use List::Util (qw(max));

use Carp ();

use MooX qw/late/;

has '_formatter' => (is => 'rw',
    default => sub {
        return Text::Format->new(
            {
                columns => 78,
                firstIndent => 0,
                leftMargin => 0,
            }
        );
    },
);
has '_is_first_line' => (isa => "Bool", is => 'rw');
has '_input' => (is => 'rw', init_arg => 'input', required => 1,);
has '_output' => (is => 'rw', init_arg => 'output', required => 1,);
has '_this_line' => (isa => 'Str', is => 'rw', default => '', );
has '_buf' => (isa => 'ScalarRef[Str]', is => 'rw',
    default => sub { my $s = ''; return \$s; });

=head1 NAME

XML::Grammar::Fortune::ToText - convert the FortunesXML grammar to plaintext.

=head1 VERSION

Version 0.0600

=cut

our $VERSION = '0.0600';


=head1 SYNOPSIS

    use XML::Grammar::Fortune::ToText;

    open my $out_fh, '>', 'my-fortunes.txt'
        or die "Cannot open 'my-fortunes.txt' for writing - $!";
    my $converter = XML::Grammar::Fortune::ToText->new(
        {
            'input' => "my-fortunes.fortune-xml.xml",
            'output' => $out_fh,
        }
    );

    $converter->run();

    close($out_fh);

=head1 FUNCTIONS

=head2 my $processor = XML::Grammar::Fortune::ToText->new({input => "path/to/file.xml", output => \*STDOUT,});

Creates a new processor with input and output files.

=cut

sub _out
{
    my $self = shift;

    ${$self->_buf()} .= join('', @_);

    return;
}

sub _start_new_line
{
    my ($self) = @_;

    return $self->_out("\n");
}

sub _render_single_fortune_cookie
{
    my ($self, $fortune_node) = @_;

    my ($node) = $fortune_node->findnodes("raw|irc|screenplay|quote");

    my $method = sprintf("_process_%s_node", $node->localname());

    $self->$method($node);

    $self->_render_info_if_exists($fortune_node);

    return;
}

sub _output_next_fortune_delim
{
    my $self = shift;

    return $self->_out("%\n");
}

sub _do_nothing {}

sub _iterate_on_child_elems
{
    my ($self, $top_elem, $xpath, $args) = @_;

    my $process = $args->{'process'};
    my $if_remainaing_meth = $args->{'if_more'};
    my $continue_cb = ($args->{'cont'} || \&_do_nothing);

    my $process_cb =
    (
        (ref($process) eq "CODE")
        ? $process
        : sub { return $self->$process(shift); }
    );

    my $list = $top_elem->findnodes($xpath);

    while (my $elem = $list->shift())
    {
        $process_cb->($elem);
    }
    continue
    {
        $continue_cb->();

        if ($list->size())
        {
            $self->$if_remainaing_meth();
        }
    }

    return;
}

=head2 $self->run()

Runs the processor.

=cut

sub run
{
    my $self = shift;

    my $xml = XML::LibXML->new->parse_file($self->_input());

    $self->_iterate_on_child_elems(
        $xml,
        "//fortune",
        {
            process => '_render_single_fortune_cookie',
            if_more => '_output_next_fortune_delim',
        }
    );

    my $buf = ${$self->_buf()};

    $buf =~ s/[ \t]+$//gms;

    print { $self->_output() } $buf;

    return;
}

sub _render_info_if_exists
{
    my ($self, $fortune_node) = @_;

    if (my ($info_node) = $fortune_node->findnodes("descendant::info"))
    {
        $self->_render_info_node($info_node);
    }

    return;
}

sub _process_raw_node
{
    my ($self, $raw_node) = @_;

    my ($text_node) = $raw_node->findnodes("body/text");

    my @text_childs = $text_node->childNodes();

    if (@text_childs != 1)
    {
        Carp::confess('@cdata is not 1');
    }

    my $cdata = $text_childs[0];

    if ($cdata->nodeType() != XML_CDATA_SECTION_NODE())
    {
        Carp::confess("Not a cdata");
    }

    my $value = $cdata->nodeValue();

    $value =~ s{\n+\z}{}g;
    $self->_out("$value\n");

    return;
}

sub _process_irc_node
{
    my ($self, $irc_node) = @_;

    my ($body_node) = $irc_node->findnodes("body");

    my @lines_list = $body_node->findnodes("saying|me_is|joins|leaves");

    use List::Util qw(max);

    my $longest_nick_len = 0;
    my @messages;
    foreach my $line (@lines_list)
    {
        if ($line->localname() eq "saying")
        {
            my $nick = $line->getAttribute("who");
            push @messages,
                {
                    type => "say",
                    nick => $nick,
                    msg => $line->textContent(),
                };

            $longest_nick_len = max($longest_nick_len, length($nick));
        }
        elsif ($line->localname() eq "me_is")
        {
            my $nick = $line->getAttribute("who");
            push @messages,
                {
                    type => "me_is",
                    nick => $nick,
                    msg => $line->textContent(),
                };

            $longest_nick_len = max($longest_nick_len, length("*"));
        }
        elsif ($line->localname() eq "joins")
        {
            my $nick = $line->getAttribute("who");
            push @messages,
                {
                    type => "joins",
                    nick => $nick,
                    msg => $line->textContent(),
                };

            $longest_nick_len = max($longest_nick_len, length("<--"));
        }
        elsif ($line->localname() eq "leaves")
        {
            my $nick = $line->getAttribute("who");
            push @messages,
                {
                    type => "leaves",
                    nick => $nick,
                    msg => $line->textContent(),
                };

            $longest_nick_len = max($longest_nick_len, length("-->"));
        }
        else
        {
            Carp::confess(
                'Unimplemented localname "' . $line->localname() . '"'
            );
        }
    }

=begin nothing

    {
        elsif (m{^[^\-]* ---\t(\S+) is now known as (\S+)})
        {
            my ($old_nick, $new_nick) = ($1, $2);
            push @messages,
                {'type' => "change_nick", 'old' => $old_nick, 'new' => $new_nick};
            $longest_nick_len =
                max($longest_nick_len, length($old_nick), length($new_nick));
        }
        else
        {
           push @messages, {'type' => "raw", 'msg' => $_};
        }
    }

=end nothing

=cut

    my $formatter =
        Text::Format->new(
            {
                columns => 72-1-2-$longest_nick_len,
                firstIndent => 0,
                leftMargin => 0,
            }
        );

    my $line_starts_at = $longest_nick_len
        + 1  # For the <
        + 1  # For the >
        + 1  # For the space at the beginning
        + 2  # For the space after the nick.
        ;

    my $nick_len_with_delim = $longest_nick_len+2;

    foreach my $m (@messages)
    {
        my %cmds = ("me_is" => "*", "joins" => "-->", "leaves" => "<--",);

        if ($m->{'type'} eq "say")
        {
            my @lines = ($formatter->format([$m->{'msg'}]));
            $self->_out(" " . sprintf("%${nick_len_with_delim}s", "<" . $m->{'nick'} . ">") .
                "  " . $lines[0]);
            $self->_out(join("",
                    map { (" " x $line_starts_at) . $_ }
                    @lines[1..$#lines]
                )
            );
        }
        elsif ($m->{'type'} eq "raw")
        {
            $self->_out($m->{'msg'}. "\n");
        }
        elsif ($m->{'type'} eq "change_nick")
        {
            $self->_out((" " x ($line_starts_at)) .
                $m->{'old'} ." is now known as " . $m->{'new'} . "\n");
        }
        elsif (exists($cmds{$m->{'type'}}))
        {
            my @lines = $formatter->format(
                    [$m->{'nick'} . " " . $m->{'msg'}]
            );

            $self->_out(" " . sprintf("%${nick_len_with_delim}s",
                    $cmds{$m->{'type'}}) . "  " . $lines[0]);

            $self->_out(join("",
                    map { (" " x $line_starts_at) . $_ }
                    @lines[1..$#lines]
                )
            );
        }
    }

    return;
}

sub _render_screenplay_paras
{
    my ($self, $portion) = @_;
    return $self->_render_portion_paras($portion, {para_is => "para"});
}

sub _is_portion_desc
{
    my ($self, $portion) = @_;

    return ($portion->localname() eq "description");
}

sub _get_screenplay_portion_opening
{
    my ($self, $portion) = @_;

    return $self->_is_portion_desc($portion)
        ? "["
        # A saying.
        : ($portion->getAttribute("character") . ": ")
        ;
}

sub _handle_screenplay_portion
{
    my ($self, $portion) = @_;

    $self->_this_line(
        $self->_get_screenplay_portion_opening($portion)
    );

    $self->_render_screenplay_paras($portion);

    if ($self->_is_portion_desc($portion))
    {
        $self->_out("]");
    }

    $self->_start_new_line;

    return;
}

sub _process_screenplay_node
{
    my ($self, $play_node) = @_;

    my ($body_node) = $play_node->findnodes("body");

    $self->_iterate_on_child_elems(
        $body_node,
        "description|saying",
        {
            process => '_handle_screenplay_portion',
            if_more => '_start_new_line',
        }
    );

    return;
}

sub _out_formatted_line
{
    my $self = shift;
    my $text = $self->_this_line();

    $text =~ s{\A\n+}{}ms;
    $text =~ s{\n+\z}{}ms;
    $text =~ s{\s+}{ }gms;

    if ($self->_is_first_line())
    {
        $self->_is_first_line(0);
    }
    else
    {
        $self->_start_new_line;
    }

    my $output_string = $self->_formatter->format($text);

    # Text::Format inserts a new line - remove it.
    chomp($output_string);

    $self->_out($output_string);

    $self->_this_line("");

    return;
}

sub _append_to_this_line
{
    my ($self, $more_text) = @_;

    $self->_this_line($self->_this_line() . $more_text);
}

sub _append_different_formatting_node
{
    my ($self, $prefix, $suffix, $node) = @_;

    return
        $self->_append_to_this_line(
            $prefix . $node->textContent() . $suffix
        );
}

{
    my @_highlights = (['/', [qw(em i italics)]], ['*', [qw(b bold strong)]]);

    my %_formats_map =
    (
        (
            map { my ($f, $tags) = @$_; map { $_ => [($f)x2] } @$tags }
            @_highlights
        ),
        'inlinedesc' => ['[', ']'],
    );

    sub _get_node_formatting_delims
    {
        my ($self, $node) = @_;

        my $name = $node->localname();

        return exists($_formats_map{$name})
            ? $_formats_map{$name}
            : [(q{}) x 2]
            ;
    }
}

sub _handle_format_node
{
    my ($self, $node) = @_;

    $self->_append_different_formatting_node(
        @{$self->_get_node_formatting_delims($node)},
        $node,
    );

    return;
}

sub _get_formatted_node_text
{
    my $self = shift;
    my $node = shift;

    my $text = $node->textContent();

    # Intent: format the text.
    # Trim leading and trailing nelines.
    # $text =~ s{\A\n+}{}ms;
    # $text =~ s{\n+\z}{}ms;

    # Convert a sequence of spaces to a single space.
    $text =~ s{\s+}{ }gms;

    return $text;
}

sub _render_para
{
    my ($self, $para) = @_;

    my $first_text = 1;

    foreach my $node ($para->childNodes())
    {
        if ($node->nodeType() == XML_ELEMENT_NODE())
        {
            my $name = $node->localname();

            if ($name eq "br")
            {
                $self->_out_formatted_line();
            }
            elsif ($name eq "a")
            {
                $self->_append_different_formatting_node(
                    "[",
                    ("](". $node->getAttribute("href") . ")"),
                    $node
                );
            }
            else
            {
                $self->_handle_format_node($node);
            }
        }
        elsif ($node->nodeType() == XML_TEXT_NODE())
        {
            my $text = $self->_get_formatted_node_text($node);

            if ($first_text)
            {
                $text =~ s/\A\s+//;
            }

            $self->_append_to_this_line( $text );
        }
    }
    continue
    {
        $first_text = 0;
    }
}

sub _render_quote_list
{
    my ($self, $ul) = @_;

    my $is_bullets = ($ul->localname() eq "ul");

    my $idx = 1;

    $self->_iterate_on_child_elems(
        $ul,
        "li",
        {
            process => sub {
                my $li = shift;

                $self->_append_to_this_line(
                    ($is_bullets ? "*" : "$idx.") . " "
                );

                $self->_render_para($li);

                return;
            },
            cont => sub {
                $idx++;

                $self->_out_formatted_line();

                return;
            },
            if_more => '_start_new_line',
        }
    );

    return;
}

sub _render_quote_portion_paras
{
    my ($self, $node) = @_;

    $self->_render_portion_paras(
        $node, { para_is => "blockquote|p|ol|ul" }
    );

    return;
}

sub _render_quote_blockquote
{
    my ($self, $node) = @_;

    $self->_out("<<<\n\n");

    $self->_render_quote_portion_paras($node);

    $self->_out("\n\n>>>");
}

sub _start_new_para
{
    my ($self) = @_;

    return $self->_out("\n\n");
}

sub _render_generalized_para
{
    my ($self, $para) = @_;

    return
    (
          (($para->localname() eq "ul") || ($para->localname() eq "ol"))
        ? $self->_render_quote_list($para)
        : ($para->localname() eq "blockquote")
        ? $self->_render_quote_blockquote($para)
        : $self->_render_para($para)
    );
}

sub _move_to_next_line
{
    my $self = shift;

    if ($self->_this_line() =~ m{\S})
    {
        $self->_out_formatted_line();
        $self->_this_line("");
    }

    return;
}

sub _handle_portion_paragraph
{
    my ($self, $para) = @_;

    $self->_is_first_line(1);

    $self->_render_generalized_para($para);

    $self->_move_to_next_line;

    return;
}

sub _render_portion_paras
{
    my ($self, $portion, $args) = @_;

    my $para_name = $args->{para_is};

    $self->_iterate_on_child_elems(
        $portion,
        $para_name,
        {
            process => '_handle_portion_paragraph',
            if_more => '_start_new_para',
        }
    );

    return;
}

sub _process_quote_node
{
    my ($self, $quote_node) = @_;

    my ($body_node) = $quote_node->findnodes("body");

    $self->_render_quote_portion_paras($body_node);

    $self->_start_new_line;

    return;
}

my @info_fields_order = (qw(work author channel tagline));

my %info_fields_order_map =
(map { $info_fields_order[$_] => $_+1 } (0 .. $#info_fields_order));

sub _info_field_value
{
    my $self = shift;
    my $field = shift;

    return $info_fields_order_map{$field->localname()} || (-1);
}

sub _calc_info_field_processed_content
{
    my $self = shift;
    my $field_node = shift;

    my $content = $field_node->textContent();

    # Squash whitespace including newlines into a single space.
    $content =~ s{\s+}{ }g;

    # Remove leading and trailing space - it is not desirable here
    # because we want it formatted consistently.
    $content =~ s{\A\s+}{};
    $content =~ s{\s+\z}{};

    return $content;
}

sub _output_info_value
{
    my ($self, $string) = @_;

    return $self->_out((' ' x 4) . '-- ' . $string . "\n");
}

sub _out_info_field_node
{
    my ($self, $info_node, $field_node) = @_;

    my $name = $field_node->localname();
    my $value = $self->_calc_info_field_processed_content($field_node);

    if ($name eq "author")
    {
        $self->_output_info_value($value);
    }
    elsif (($name eq "work") || ($name eq "tagline"))
    {
        my $url = "";

        if ($field_node->hasAttribute("href"))
        {
            $url = " ( " . $field_node->getAttribute("href") . " )";
        }

        $self->_output_info_value($value.$url);
    }
    elsif ($name eq "channel")
    {
        my $channel = $field_node->textContent();
        my $network = $info_node->findnodes("network")->shift()->textContent();

        $self->_output_info_value( "$channel, $network" );
    }

    return;
}

sub _get_info_node_fields
{
    my ($self, $info_node) = @_;

    return
        reverse
        sort {
            $self->_info_field_value($a) <=> $self->_info_field_value($b)
        }
        $info_node->findnodes("*")
    ;

}

sub _render_info_node
{
    my ($self, $info_node) = @_;

    if (my @f = $self->_get_info_node_fields($info_node))
    {
        $self->_start_new_line;

        foreach my $field_node (@f)
        {
            $self->_out_info_field_node($info_node, $field_node);
        }
    }

    return;
}

1;

__END__

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-grammar-fortune at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Grammar-Fortune>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Grammar::Fortune


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Grammar-Fortune>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Grammar-Fortune>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Grammar-Fortune>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Grammar-Fortune>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 by Shlomi Fish

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
