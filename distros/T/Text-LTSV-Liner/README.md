# NAME

Text::LTSV::Liner - Line filter of LTSV text

# SYNOPSIS

    use Text::LTSV::Liner;
    my $liner = Text::LTSV::Liner->new( key => \@keys );
    while(<>) {
        $liner->run($_);
    }

# DESCRIPTION

Labeled Tab-separated Values (LTSV) format is a variant of Tab-separated
Values (TSV). (cf: [http://ltsv.org/](http://ltsv.org/))
This module simply filters text whose format is LTSV by specified keys.

# METHODS

## new

Constructor.
You can specify some options to filter lines.

- __key__

    You can choose keys as array reference which you want to see in filtered output.

- __no-color__

    If you prefer no-colorized output, specify this option.

- __no-key__

    If you don't need to see keys in the output, specify this option.
    Then you'll see values only in the output.

## run

Process lines and print output to STDOUT.

## parse

    my $liner = Text::LTSV::Liner->new( key => \@keys );
    for my $line (@lines) {
        my $parsed = $liner->parse($line);
    }

This method is convinent if you want to use the filtered output in your codes.

# AUTHORS

YASUTAKE Kiyoshi <yasutake.kiyoshi@gmail.com>

# LICENSE

Copyright (C) 2013 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.
