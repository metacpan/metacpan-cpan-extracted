# DESCRIPTION

Parse files with continuation lines like shell scripts, Dockerfiles, and so forth.

# SYNOPSIS

    package Foo;
    use Text::Continuation::Parser qw(parse_line);

    my $fh = io('?');
    $fh->print('line 1\\', $/);
    $fh->print('and 2', $/);
    $fh->print('line 3\\', $/);
    $fh->print('\\', $/);
    $fh->print('4 and 5', $/);
    $fh->seek(0,0);

    while(my $line = parse_line($fh)) {
        print $line;
        # This prints:
        # line 1 and 2
        # line 3 4 and 5
    }

# METHODS

## parse\_line

This function work on any object that implements `getline`.

It will return all lines, except when lines are continued when a comment
in somewhere in between:

    RUN apt-get update \
        && apt-get install -y perl \
        # This line isn't returned after parsing.
        && echo "this line is"

Lines like these will make sure the function dies:

    RUN apt-get update \
        && apt-get install -y perl \

    RUN echo "We will never get here"

While it may be possible in a shell, this is probably not what you intended and therefore
`parse_line` dies.

## CAVEATS

On older Perl versions, like 5.10 you must do the following:

    use FileHandle;
    # or..
    use IO::File;

    open my $fh, '<', 'myfile';
    parse_line($fh);
