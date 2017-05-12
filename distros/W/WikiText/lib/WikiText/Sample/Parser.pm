package WikiText::Sample::Parser;
use base 'WikiText::Parser';

sub create_grammar {
    my $all_blocks = [ 'h1',  'h2', 'h3', 'hr', 'p', 'pre' ];

    my $all_phrases = [ 'b', 'i' ];

    return {
        # Parsing starts at the "top" level document
        top => {
            blocks => $all_blocks,  # A document consists of top level blocks
        },
        p => {
            match => qr/^           # Blocks must start at beginning
            (                       # Capture paragraph in $1
                ((?!(?:             # Stop at certain blocks
                    [\=] |          # Headings
                    \s+\S
                ))
                .*\S.*\n)+          # Otherwise, collect non-empty lines
            )
            (?:\s*\n)?              # Eat trailing newlines
            /x,
            phrases => $all_phrases,
            filter => sub { chomp },
        },
        pre => {
            match => qr/^
            (
                ((?!(?:             # Stop at certain blocks
                    \S              # Anything starting with nonspace
                ))
                (?m: ^\ +.*\S.*\n))+ # otherwise grab lines starting with space
            )
            (\s*\n)*   # and all blank lines after
            /x,
            filter => sub { s/^\s*//mg; s/\s*$//mg; },
        },
        h1 => {
            match => re_header(1),
        },
        h2 => {
            match => re_header(2),
        },
        h3 => {
            match => re_header(3),
        },
        hr => {
            match => qr/^----\n(?:\s*\n)?/,
        },
        b => {
            phrases => $all_phrases,
            match => phrase("'''"),
        },
        i => {
            phrases => $all_phrases,
            match => phrase("''"),
        },
    };
}

# Reusable regexp generators used by the grammar
sub phrase {
    my $brace1 = shift;
    my $brace2 = shift || $brace1;

    return qr/
        ${brace1}       # Opening phrase markup
        (.*?'*)           # Capture content in $1
        ${brace2}       # Closing phrase markup
    /x;
}

sub re_header {
    my $level = shift;
    return qr/^         # Block must begin at position 0
        \={$level}      # Proper number of '=' chars
        \ +             # 1 or more spaces
        (.*?)           # Capture header content in $1
        \s*\n           # Eat trailing whitespace and newlines
    /x;
}

1;
