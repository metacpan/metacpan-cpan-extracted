use strict;
use warnings;
use Test::More;
use Text::Amuse;
use File::Spec::Functions;
use Data::Dumper;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";


plan tests => 208;

my $list = Text::Amuse->new(file => catfile(t => testfiles => 'lists.muse'));

my @expected = (
                {
                 'string' => 'Normal text.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'ul',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 1, bullet item one, this is the first paragraph. I can break
the line, keeping the same amount of indentation
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'oln',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 2, enum item one. i can break the line, keeping the same
amount of indentation
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 2, enum item two
which continues
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'oln',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 1, bullet item two
which continues
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'oln',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 2, enum item one
which continues
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 2, enum item two
which continues
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'oli',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 3, enum item i
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues
the item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 3, enum item ii
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues
the item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'oli',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Level 2, enum item three
which continues
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'oln',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Back to Level 1, third bullet
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'ola',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => "Level 2, enum item \x{201c}a\x{201d}
which continues
",
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => "Level 2, enum item \x{201c}b\x{201d}
which continues
",
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'olI',
                 'type' => 'startblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => "Level 3, enum item \x{201c}I\x{201d}
",
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'olI',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'ola',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'startblock'
                },
                {
                 'string' => 'Back to the bullets
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => 'Here I have the same amount of indentation, and it continues the
item above.
',
                 'block' => 'regular',
                 'type' => 'regular'
                },
                {
                 'string' => '',
                 'block' => 'li',
                 'type' => 'stopblock'
                },
                {
                 'string' => '',
                 'block' => 'ul',
                 'type' => 'stopblock'
                }
               );

my @good = grep { $_->type ne 'null' } $list->document->elements;

is scalar(@good), scalar(@expected), "Element count is ok";
my $count = 0;
while (my $exp = shift @expected) {
    my $el = shift @good;
    # diag "testing " . ++$count . ' ' .  $el->rawline;
    is $el->type, $exp->{type}, "type $exp->{type}" or die Dumper($el, $exp);
    is $el->block, $exp->{block}, "block $exp->{block}" or die Dumper($el, $exp);
    is $el->string, $exp->{string}, "string $exp->{string}" or die Dumper($el, $exp);
}


# dump_doc($list);

sub dump_doc {
    my $obj = shift;
    print q{
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"
      xml:lang="en" lang="en">
  <head>
<title>test</title>
</head>
<body>
};
    foreach my $el ($obj->elements) {
        my $block = $el->block;
        if ($block =~ m/(ol)/) {
            $block = $1;
        }
        if ($el->type eq 'startblock') {
            print '<' . $block . '>' . "\n";
        }
        elsif ($el->type eq 'stopblock')  {
            print '</' . $block . '>' . "\n";
        }
        elsif ($el->type ne 'null') {
            print '<p>', $el->string, '</p>';
        }
    }
    print "</body></html>\n";
}
