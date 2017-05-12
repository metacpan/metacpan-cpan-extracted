# NAME

Text::Parts - split text file to some parts(from one line start to another/same line end)

# SYNOPSIS

If you want to split a text file to some number of parts:

    use Text::Parts;
    

    my $splitter = Text::Parts->new(file => $file);
    my (@parts) = $splitter->split(num => 4);

    foreach my $part (@parts) {
       while(my $l = $part->getline) { # or <$part>
          # ...
       }
    }

If you want to split a text file by about specified size:

    use Text::Parts;
    

    my $splitter = Text::Parts->new(file => $file);
    my (@parts) = $splitter->split(size => 10); # size of part will be more than 10.
    # same as the previous example

If you want to split CSV file:

    use Text::Parts;
    use Text::CSV_XS; # don't work with Text::CSV_PP if you want to use {binary => 1} option
                      # I don't recommend to use it for CSV which has multiline lines in columns.
    

    my $csv = Text::CSV_XS->new();
    my $splitter = Text::Parts->new(file => $file, parser => $csv);
    my (@parts) = $splitter->split(num => 4);
    

    foreach my $part (@parts) {
       while(my $col = $part->getline_parser) { # getline_parser returns parsed result
          print join "\t", @$col;
          # ...
       }
    }

Write splitted parts to files:

    $splitter->write_files('file%d.csv', num => 4);
    

    my $i = 0;
    foreach my $part ($splitter->slit(num => 4)) {
      $part->write_file("file" . $i++ . '.csv');
    }

with Parallel::ForkManager:

    my $splitter = Text::Parts->new(file => $file);
    my (@parts) = $splitter->split(num => 4);
    my $pm = new Parallel::ForkManager(4);
    

    foreach my $part (@parts) {
      $pm->start and next; # do the fork
      

      while (my $l = $part->getline) {
        # ...
      }
    }
    

    $pm->wait_all_children;

NOTE THAT: If the file is on the same disk, fork is no use.
Maybe, using fork makes sense when the file is on RAID (I haven't try it).

# DESCRIPTION

This module splits file by specified number of part.
The range of each part is from one line start to another/same line end.
For example, file content is the following:

    1111
    22222222222222222222
    3333
    4444

If `$splitter->split(num => 3)`, split like the following:

1st part:
 1111
 22222222222222222222

2nd part:
 3333

3rd part:
 4444

At first, `split` method tries to split by bytes of file size / 3,
Secondly, tries to split by bytes of rest file size / the number of rest part.
So that:

    1st part : 36 bytes / 3 = 12 byte + bytes to line end(if needed)
    2nd part : (36 - 26 bytes) / 2 = 5 byte + bytes to line end(if needed)
    last part: rest part of file

# METHODS

## new

    $s = Text::Parts->new(file => $filename);
    $s = Text::Parts->new(file => $filename, parser => Text::CSV_XS->new({binary => 1}));

Constructor. It can take following options:

### num

number how many you want to split.

### size

file size how much you want to split.
This value is used for calculating `num`.
If file size is 100 and this value is 25, `num` is 4.

### file

target file which you want to split.

### parser

Pass parser object(like Text::CSV\_XS->new()).
The object must have method which takes filehandle and whose name is `getline` as default.
If the object's method is different name, pass the name to `parser_method` option.

### parser\_method

name of parser's method. default is `getline`.

### check\_line\_start

If this options is true, check line start and move to this position before `<$fh>` or parser's `getline`/`parser_method`.
It may be useful when parser's `getline`/`parser_method` method doesn't work correctly when parsing wrong format.

default value is 0.

### no\_open

If this option is true, don't open file on creating Text::Parts::Part object.
You need to call `open_and_seek` method from the object when you read the file
(But, `all` and `write_file` checks this option, so you don't need to call `open_and_seek`).

This option is required when you pass too much number, which is more than OS's open file limit, to split method.

## file

    my $file = $s->file;
    $s->file($filename);

get/set target file.

## parser

    my $parser_object = $s->parser;
    $s->parser($parser_object);

get/set parser object.

## parser\_method

    my $method = $s->parser_method;
    $s->parser_method($method);

get/set parser method.



## split

    my @parts = $s->split(num => $num);
    my @parts = $s->split(size => $size);
    my @parts = $s->split(num => $num, max_num => 3);

Try to split target file to `$num` of parts. The returned value is array of Text::Parts::Part object.
If you pass `size => bytes`, calculate `$num` from file size / `$size`.

This method doesn't actually split file, only calculate the start and end position of parts.

This returns array of Text::Parts::Part object.
See ["Text::Parts::Part METHODS"](#Text::Parts::Part METHODS).

If you set max\_num, only split number of max\_num.

    my @parts = $s->split(num => 5, max_num => 2);

This tries to split 5 parts, but only 2 parts are returned.
This is useful to try to test a few parts of too many parts.

## eol

    my $eol = $s->eol;
    $s->eol($eol);

get/set end of line string. default value is $/.

## write\_files

    @filenames = $s->write_files('path/to/name%d.txt', num => 4);

`name_format` is the format of filename. %d is replaced by number.
For example:

    path/to/name1.txt
    path/to/name2.txt
    path/to/name3.txt
    path/to/name4.txt

The rest of arguments are as same as `split` except the following 2 options.

- code

    `code` option takes code reference which would be done immediately after file had been written.
    If you pass `code` option as the following:

        @filenames = $s->write_files('path/to/name%d.txt', num => 4, code => \&do_after_split)

    splitted file name is given to &do\_after\_split:

        sub do_after_split {
           my $filename = shift; # 'path/to/name1.txt'
           # ...
           unlink $filename;
        }

- start\_number

        @filenames = $s->write_files('path/to/name%d.txt', num => 4, start_number => 0);
        # $filenames[0] is 'path/to/name0.txt'

    This is used for filename.

    if start\_number is 0.

        path/to/name0.txt
        path/to/name1.txt
        ...

    if start\_number is 1 (default).

        path/to/name1.txt
        path/to/name2.txt
        ...

    if start\_number is 2

        path/to/name2.txt
        path/to/name3.txt
        ...

- last\_number

    If last\_number is specified, stop to split file when number reaches last\_number.
    Note that this option override max\_num.

        @filenames = $s->write_files('path/to/name%d.txt', num => 4, start_number => 0, last_number => 1);
        # $filenames[0] is 'path/to/name0.txt'
        # $filenames[1] is 'path/to/name1.txt'
        # $filenames[2] doesn't exist

# Text::Parts::Part METHODS

Text::Parts::Part objects are returned by `split` method.

## getline

    my $line = $part->getline;

return 1 line.
You can use `<$part>`, also.

    my $line = <$part>

## getline\_parser

    my $parsed = $part->getline_parser;

returns parsed result.

## all

    my $all = $part->all;
    $part->all(\$all);

return all of the part.
just `read` from start to end position.

If scalar reference is passed as argument, the content of the part is into the passed scalar.

This method checks no\_open option.
If no\_open is true, open file before writing file and close file after writing.

## eof

    $part->eof;

If current position is the end of parts, return true.

## write\_file

    $part->write_file($filename);

Write the contents of the part to $filename.

This method checks no\_open option.
If no\_open is true, open file before writing file and close file after writing.

## open\_and\_seek

    $part->open_and_seek;

If the object is created with no\_open true, you need to call this method before reading file.

## close

    $part->close;

close file handle.

## is\_opened

    $part->is_opened;

If file handle is opened, return true.

# AUTHOR

Ktat, `<ktat at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-text-parts at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Parts](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Parts).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Parts

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Parts](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Parts)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Text-Parts](http://annocpan.org/dist/Text-Parts)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Text-Parts](http://cpanratings.perl.org/d/Text-Parts)

- Search CPAN

    [http://search.cpan.org/dist/Text-Parts/](http://search.cpan.org/dist/Text-Parts/)



# ACKNOWLEDGEMENTS



# LICENSE AND COPYRIGHT

Copyright 2011 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


