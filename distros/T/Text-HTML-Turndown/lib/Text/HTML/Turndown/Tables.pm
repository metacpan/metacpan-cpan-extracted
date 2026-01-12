package Text::HTML::Turndown::Tables 0.10;
use 5.020;
use experimental 'signatures';
use stable 'postderef';
use List::MoreUtils 'all';
use List::Util 'max';
use Text::Table;

=head1 NAME

Text::HTML::Turndown::Tables - rules for Markdown Tables

=head1 SYNOPSIS

  use Text::HTML::Turndown;
  my $turndown = Text::HTML::Turndown->new(%$options);
  $turndown->use('Text::HTML::Turndown::Tables');

  my $markdown = $convert->turndown(<<'HTML');
    <table><tr><td>Hello</td><td>world!</td></tr></table>
  HTML
  # | Hello | world! |
  # | ----- | ------ |

=cut

our %RULES = (

    tableCell => {
        filter => ['th', 'td'],
        replacement => sub( $content, $node, $options, $context ) {
          return cell($content, $node, undef);
        },
    },

    tableRow => {
        filter => 'tr',
        replacement => sub( $content, $node, $options, $context ) {
            my $borderCells = '';
            my $alignMap = { left => ':--', right => '--:', center => ':-:' };

            # Eliminate empty rows
            if( $content =~ m!\A\|(  \|)+\z! ) {
                return '';
            }

            if (isHeadingRow($node)) {
                #warn "Header content: [$content]";
                my @ch = $node->childNodes;
                for my $ch ($node->childNodes) {
                    my $border = '---';
                    my $align = lc(
                        $ch->getAttribute('align') || ''
                    );

                    if ($align) {
                        $border = $alignMap->{$align} || $border;
                    }

                    $borderCells .= cell($border, $ch, undef)
                }
            }
            return "\n" . $content . ($borderCells ? "\n" . $borderCells : '')
        }
    },

    table => {
        filter => ['table'],

        replacement => sub( $content, $node, $options, $context ) {
            # Ensure there are no blank lines
            $content =~ s/\n\n/\n/g;
            $content =~ s/^\s*//;
            # Re-parse and re-layout the table:
            my @table = split /\r?\n/, $content;
            my @new_table;
            my @column_width;
            for my $row (@table) {
                $row =~ s!^\|\s*!!;
                $row =~ s!\s+\|\s*\z!!;
                my @cols = map {s!^\s+!!; s!\s+\z!!r; } split /\|/, $row;
                push @new_table, \@cols;
            };
            my $h = shift @new_table;
            $h = [map { $_, \" | " } $h->@*];
            pop $h->@*;
            unshift $h->@*, \"| ";
            push  $h->@*, \" |";
            my $table = Text::Table->new(
                $h->@*,
            );
            #shift @new_table;
            $table->load( @new_table );
            $content = "\n\n" . $table . "\n\n";
        },

    },

    tableSection => {
        filter => ['thead', 'tbody', 'tfoot'],
        replacement => sub( $content, $node, $options, $context ) {
            return $content
        }
    }
);

# A tr is a heading row if:
# - the parent is a THEAD
# - or if its the first child of the TABLE or the first TBODY (possibly
#   following a blank THEAD)
# - and every cell is a TH
sub isHeadingRow ($tr) {
    return if ! $tr;
    my $parentNode = $tr->parentNode;
    my $n = $tr->can('_node') ? $tr->_node : $tr;
    return (
      uc ($parentNode->nodeName) eq 'THEAD' ||
      (
           $n->isEqual($parentNode->firstChild)
        && (uc $parentNode->nodeName eq 'TABLE' || isFirstTbody($parentNode))
        && all { uc($_->nodeName) eq 'TH' } $tr->childNodes
      )
    )
}

sub isFirstTbody ($element) {
  my $previousSibling = $element->previousSibling;
  return (
    uc $element->nodeName eq 'TBODY'
    && (
      !$previousSibling ||
      (
           uc $previousSibling->nodeName eq 'THEAD'
        && $previousSibling->textContent =~ /^\s*$/
      )
    )
  )
}

sub cell ($content, $node, $escape=1) {
  my $first = !$node->previousSibling;
  my $prefix = ' ';
  if ($first) { $prefix = '| ' };

  # We assume that we have no further HTML tags contained in $content
  # convert all elements in $content into their Markdown equivalents
  if( $escape ) {
    $content = Text::HTML::Turndown->escape( $content );
  }

  # Fix up newlines
  $content =~ s!\r?\n!<br/>!g;

  return $prefix . $content . ' |'
}

sub install ($class, $target) {
    $target->preprocess(sub($tree) {
        # We will likely need other/more rules to turn arbitrary HTML
        # into what a browser has as DOM for tables
        for my $table ($tree->find('//table')->@*) {
            # Turn <table><thead><td>...
            # into <table><thead><tr><td>...
            if( $table->find( './thead/td' )->@* ) {
                my $head = $table->find('./thead',$table)->shift;
                my $tr = $head->ownerDocument->createElement('tr');
                $tr->appendChild($_) for $head->childNodes;
                $head->appendChild( $tr );
            }
        }
        return $tree;
    });
    $target->keep(sub ($node) {
        my $firstRow = $node->find('.//tr')->shift;
        return uc $node->nodeName eq 'TABLE' && !isHeadingRow($firstRow)
    });
    for my $key (keys %RULES) {
        $target->addRule($key, $RULES{$key})
    }
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Text-HTML-Turndown>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Text-HTML-Turndown/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2025- by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the Artistic License 2.0.

=cut
