# -*- perl -*-
use Test::More tests => 2;

use strict;
use warnings;

BEGIN {
    use_ok('Text::Smart');
};


package MyProc;

use base qw(Text::Smart);

sub generate_divider {
    my $self = shift;

    return "divider\n";
}

sub generate_itemize {
    my $self = shift;

    return "item_" . join ("", map { "item_" . $_ ."\n" } @_);
}

sub generate_enumeration {
    my $self = shift;

    return "enum_" . join ("", map { "item_" . $_ ."\n" } @_);
}

sub generate_heading {
    my $self = shift;
    my $level = shift;
    my $text = shift;

    return "heading_" . $level . "_" . $text . "\n";
}

sub generate_paragraph {
    my $self = shift;
    my $text = shift;

    return "para_$text\n";
}

sub generate_bold {
    my $self = shift;
    my $text = shift;

    return "bold_$text\n";
}


sub generate_italic {
    my $self = shift;
    my $text = shift;

    return "italic_$text\n";
}

sub generate_monospace {
    my $self = shift;
    my $text = shift;

    return "monospace_$text\n";
}

sub generate_link {
    my $self = shift;
    my $url = shift;
    my $text = shift;

    return "link_" . $url. "_" . $text . "\n";
}

sub generate_entity {
    my $self = shift;
    my $name = shift;

    return "entity_$name\n";
}

sub escape {
    my $self = shift;

    return "escaped";
}

package main;

my $proc = MyProc->new();

my $input = <<EOF;
This is some =text= and this is *some*
more text in the same paragraph

We can have /some/ emphasised text and 1/2
or 3/4 or 1/4 or (C) and (R) or (TM)

* a list of stuff
* more items
* yet more

Or another para

----

+ one numbered list
+ here

&title(main heading)

&subtitle(sub heading)

&section(in here)

&subsection(or here)

&subsection(yes here)

&paragraph(final)

Thats all folks apart from \@this link to(nowhere) for a
final text
EOF

my $output = $proc->process($input);

my $expected = <<EOF;
para_escaped



para_escaped



item_item_escaped
item_escaped
item_escaped



para_escaped



divider



enum_item_escaped
item_escaped



heading_escaped_title



heading_escaped_subtitle



heading_escaped_section



heading_escaped_subsection



heading_escaped_subsection



heading_escaped_paragraph



para_escaped
EOF

is($output, $expected, "output matches");


