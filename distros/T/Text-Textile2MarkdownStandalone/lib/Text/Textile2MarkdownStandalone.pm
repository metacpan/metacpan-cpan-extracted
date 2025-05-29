package Text::Textile2MarkdownStandalone;
use 5.008001;
use strict;
use warnings;

use Carp;

our $VERSION = "0.11";

sub new {
    my ($class, %opt) = @_;
    return bless {
        input_file  => $opt{input_file} // "",
        output_file => $opt{output_file} // "",
    }, $class;
}

sub input_file {
    my ($self, $file) = @_;
    $self->{input_file} = $file if $file;
    return $self->{input_file};
}

sub output_file {
    my ($self, $file) = @_;
    $self->{output_file} = $file if $file;
    return $self->{output_file};
}

sub convert {
    my ($self) = @_;
    my $text = $self->_read_file($self->input_file);
    my $markdown = $self->textile_2_markdown($text);
    if ($self->output_file) {
        $self->_save_file($self->output_file, $markdown);
    }
    else {
        return $markdown;
    }
}

sub _read_file {
    my ($self, $input_file) = @_;
    open(my $fh, "<:encoding(utf8)", $input_file) || die "cannot open file ". $input_file;
    my @line = <$fh>;
    close($fh);
    my $string = join("", @line);
    return $string;
}

sub _save_file {
    my ($self, $output_file, $string) = @_;
    unless ($string) {
       croak "notfound string $string .";
    }
    unless ($output_file) {
       croak "notfound output_file $output_file .";
    }
    open (my $fh, ">:encoding(utf8)", $output_file) || die "cannot open file ".$output_file;
    binmode($fh, ":utf8");
    print $fh $string;
    close($fh);
}

sub textile_2_markdown {
    my ($self, $text) = @_;

    # Protect URLs completely first - execute before other conversions
    my @urls;
    my @url_positions;
    my $counter = 0;

    # Detect URLs and replace them with placeholders
    while ($text =~ m{(https?://[^\s"<>\(\))\]]+)}g) {
        my $url = $1;
        my $placeholder = "URL_PLACEHOLDER_${counter}";
        my $pos = pos($text) - length($url);

        push @urls, $url;
        push @url_positions, [$pos, $placeholder];
        $counter++;
    }

    # Replace with placeholders (process from end to avoid offset issues)
    foreach my $url_info (reverse @url_positions) {
        my ($pos, $placeholder) = @$url_info;
        my $url_length = length($urls[$counter - 1]);
        substr($text, $pos, $url_length) = $placeholder;
        $counter--;
    }

    # Process nested ordered lists
    $text = $self->_convert_list_number($text);

    # Process bulleted lists
    $text =~ s/^(\s*)\*\s+(.+)$/$1* $2/gm;
    $text =~ s/^(\s*)\*\*\s+(.+)$/$1  * $2/gm;
    $text =~ s/^(\s*)\*\*\*\s+(.+)$/$1    * $2/gm;

    # Convert headings with correct depth mapping
    $text =~ s/^\s*h1\.\s+(.+)$/# $1/gm;
    $text =~ s/^\s*h2\.\s+(.+)$/## $1/gm;
    $text =~ s/^\s*h3\.\s+(.+)$/### $1/gm;
    $text =~ s/^\s*h4\.\s+(.+)$/#### $1/gm;
    $text =~ s/^\s*h5\.\s+(.+)$/##### $1/gm;
    $text =~ s/^\s*h6\.\s+(.+)$/###### $1/gm;

    # Convert single emphasis to double (**text**)
    $text =~ s/\*([^\*\n]+)\*/\*\*$1\*\*/g;

    # Convert strikethrough (excluding URLs)
    $text =~ s/-([^-\n]+)-/~~$1~~/g;

    # Remove paragraph markers
    $text =~ s/^p\.\s*(.+)$/ $1\n\n/gm;

    # Convert horizontal rules
    $text =~ s/^-{3,}$/---/gm;

    # Process text color markup
    $text =~ s/%\{color:(.*?)\}(.*?)%/**$2**/g;

    # Blockquote conversion
    $text =~ s/^bq\.\s+(.+)$/> $1/gm;

    # Convert links
    $text =~ s/"([^"]+)":([^\s]+)/[$1]($2)/g;

    # Convert images
    $text =~ s/!([^!(]+)\(([^!)]+)\)!/![$2]($1)/g;

    # Convert inline code
    $text =~ s/@([^@]+)@/`$1`/g;

    # Collapse block processing
    $text =~ s/\{\{collapse\s*(.*?)\}\}/
        my $content = $1;
        "<details>\n<summary>詳細情報<\/summary>\n\n$content\n<\/details>"
    /gse;

    # Convert code blocks
    $text =~ s/<pre>(.*?)<\/pre>/```\n$1\n```/gs;
    $text =~ s/^pre\.\s*\n(.*?)(?=\n\n|\z)/```\n$1\n```/gms;
    $text =~ s/^bc\.*\s*\n(.*?)(?=\n\n|\z|\n[^\s]+)/```\n$1\n```/gms;

    # Improved table conversion
    $text = $self->_convert_textile_tables_improved($text);

    # Internal link conversion
    $text =~ s/\[\[([^|]+)\|([^\]]+)\]\]/[$2]($1)/g;
    $text =~ s/\[\[([^\]]+)\]\]/[$1]($1)/g;

    # Email address handling
    $text =~ s/([a-zA-Z0-9._%+-]+)\@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/$1\@$2/g;

    # Line break processing
    $text =~ s/<br\s*\/?>/\n\n/gi;

    # Restore URL placeholders
    $counter = 0;
    foreach my $url (@urls) {
        my $placeholder = "URL_PLACEHOLDER_${counter}";
        $text =~ s/$placeholder/$url/g;
        $counter++;
    }

    # Remove consecutive blank lines
    $text =~ s/\n{3,}/\n\n/g;

    my $after_string = $text;
    return $after_string;
}

sub _convert_list_number {
    my ($self, $text) = @_;

    my @counters;
    my @result;
    my @line = split("\n", $text);
    for my $l (@line) {
        chomp $l;
        if ($l =~ /^(#+)\s*(.*)/) {
            my $level = length($1);
            my $text  = $2;
            # Trim deeper levels
            splice @counters, $level;
            # Initialize or increment the counter for the current level
            if (!defined $counters[$level-1]) {
                $counters[$level-1] = 1;
            } else {
                $counters[$level-1]++;
            }
            # Indent by (4*level - 1) spaces
            my $indent = ' ' x (4 * $level - 1);
            push @result, "$indent$counters[$level-1]. $text";
        } else {
            @counters = ();
            push @result, $l;
        }
    }

    return join("\n", @result);
}

sub _convert_textile_tables_improved {
    my ($self, $text) = @_;
    my @lines = split(/\n/, $text);
    my @result;
    my $in_table = 0;
    my $header_detected = 0;
    my @table_rows = ();
    my $current_cell = "";
    my $processing_multiline_cell = 0;

    for (my $i = 0; $i < scalar @lines; $i++) {
        my $line = $lines[$i];

        # Detect table start line (starts with '|')
        if (!$in_table && $line =~ /^\|/) {
            # Insert blank line before table if previous line is not blank
            if ($i > 0 && $lines[$i-1] !~ /^\s*$/) {
                push @result, "";
            }

            $in_table = 1;
            @table_rows = ();
        }

        # When processing a multiline cell
        if ($processing_multiline_cell) {
            # Detect next cell boundary or end of line
            if ($line =~ /^\|/ || $line =~ /^$/) {
                $processing_multiline_cell = 0;
                push @{$table_rows[-1]}, $current_cell;
                $current_cell = "";

                # When a new row starts, process normally
                if ($line =~ /^\|/) {
                    # Remove leading '|'
                    $line =~ s/^\|//g;
                    my @cells = split(/\|/, $line);
                    push @table_rows, [];

                    # Process each cell
                    foreach my $cell (@cells) {
                        # If last cell ends with '<br>', enter multiline mode
                        if ($cell =~ /<br>$/) {
                            $current_cell = $cell;
                            $processing_multiline_cell = 1;
                        } else {
                            # Detect header cell and process
                            if ($cell =~ /^_\.(.*)$/) {
                                $header_detected = 1;
                                push @{$table_rows[-1]}, $1;
                            } else {
                                push @{$table_rows[-1]}, $cell;
                            }
                        }
                    }
                } else {
                    # On blank line, end table processing
                    $in_table = 0;
                    $self->output_table(\@result, \@table_rows);
                    @table_rows = ();
                    push @result, $line;
                }
            } else {
                # Add text to current cell during multiline processing
                $current_cell .= " " . $line;
            }
        }
        # Normal row processing (no '<br>')
        elsif ($line =~ /^\|/) {
            if (!$in_table) {
                $in_table = 1;
                @table_rows = ();
            }

            # Check for '<br>'
            if ($line =~ /<br>/) {
                # Process cells before and after '<br>'
                my @parts = split(/<br>/, $line, 2);
                my @cells = split(/\|/, $parts[0]);

                # Add new row
                push @table_rows, [];

                # Process normal cells
                for (my $j = 0; $j < scalar(@cells) - 1; $j++) {
                    my $cell = $cells[$j];
                    # Detect header cell and process
                    if ($cell =~ /^_\.(.*)$/) {
                        $header_detected = 1;
                        push @{$table_rows[-1]}, $1;
                    } else {
                        push @{$table_rows[-1]}, $cell;
                    }
                }

                # Process cell containing '<br>'
                $current_cell = $cells[-1] . "<br>" . $parts[1];
                $current_cell =~ s/<br>/ /g;
                push @{$table_rows[-1]}, $current_cell;
            } else {
                # Normal row processing
                $line =~ s/\|$//g;
                my @cells = split(/\|/, $line);

                # Add new row
                push @table_rows, [];

                # Process each cell
                foreach my $cell (@cells) {
                    # Detect header cell and process
                    if ($cell =~ /^_\.(.*)$/) {
                        $header_detected = 1;
                        push @{$table_rows[-1]}, $1;
                    } else {
                        push @{$table_rows[-1]}, $cell;
                    }
                }
            }
        } else {
            # When encountering a non-table line
            if ($in_table) {
                $in_table = 0;
                $self->output_table(\@result, \@table_rows);
                @table_rows = ();

                # Insert blank line after table if next line is not blank
                if ($line !~ /^\s*$/) {
                    push @result, "";
                }
            }
            push @result, $line;
        }
    }

    # Handle end-of-file table closure
    if ($in_table && @table_rows) {
        $self->output_table(\@result, \@table_rows);
        push @result, "";
    }

    return join("\n", @result);
}


sub output_table {
    my ($self, $result, $table_rows) = @_;

    if (@$table_rows) {
        # Process header row
        my $first_row = shift @$table_rows;
        my $header_row = "| " . join(" | ", @$first_row) . " |";
        push @$result, $header_row;

        # Add separator row
        my $separator = "|";
        foreach my $cell (@$first_row) {
            $separator .= " --- |";
        }
        push @$result, $separator;

        # Process data rows (convert '<br>' to space)
        foreach my $row (@$table_rows) {
            my @processed_cells = map { s/<br>/ /g; $_ } @$row;
            push @$result, "| " . join(" | ", @processed_cells) . " |";
        }
    }
}


1;
__END__
+=encoding utf8

=pod

=head1 NAME

Text::Textile2MarkdownStandalone - Standalone converter from Textile markup to Markdown

=head1 VERSION

version 0.11

=head1 SYNOPSIS

  use Text::Textile2MarkdownStandalone;

  # Convert a Textile file to a Markdown file
  my $converter = Text::Textile2MarkdownStandalone->new(
    input_file  => 'input.textile',
    output_file => 'output.md',
  );
  $converter->convert;

  # Get the Markdown output as a string
  my $markdown = Text::Textile2MarkdownStandalone->new(
    input_file => 'input.textile'
  )->convert;

=head1 DESCRIPTION

Text::Textile2MarkdownStandalone provides a simple, standalone tool to convert Textile-formatted text into Markdown. It supports:

Module rename history:

Originally released as Text-Textile2MarcdownStandalone (typo in Marcdown).
Renamed to Text-Textile2MarkdownStandalone in version 0.03 to correct the typo and improve clarity.

=over 4

=item *

- Headings (h1-h6)

=item *

Ordered and unordered lists with nesting

=item *

Emphasis, strong emphasis, and strikethrough

=item *

Code spans and code blocks

=item *

Blockquotes

=item *

Links and images

=item *

Tables, including cells spanning multiple lines

=item *

Horizontal rules and URL protection

=back

=head1 METHODS

=over 4

=item new(%options)

Create a new converter object. Options:

  input_file  => path to the input Textile file
  output_file => path to write the output Markdown file
                  (if omitted, convert() returns the Markdown string)

=item input_file([$file])

Get or set the input file path.

=item output_file([$file])

Get or set the output file path.

=item convert

Execute the conversion. Reads the input file, converts its content to Markdown, and either writes it to the output file or returns it as a string.

=back

=head1 cli

=over 4

Use the helper script included with this distribution to run from the command line:

  perl script/textile2markdown.pl --input input.textile --output output.md

If only an input file is provided, the Markdown output will be printed to STDOUT.

=back

=head1 AUTHOR

Akihito Takeda <takeda.akihito@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 Akihito Takeda

This software is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut

