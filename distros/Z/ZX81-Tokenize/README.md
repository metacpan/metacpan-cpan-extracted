# NAME

ZX81::Tokenize - Tokenize and convert to ZX81 encoding

# SYNOPSIS

    use ZX81::Tokenize qw(tokenize_basic encode_chars);

    my $bytes = tokenize_basic(<<END);
    10 PRINT "HELLO"
    20 GOTO 10
    END
    
    my $bytes = encode_chars("HELLO");

    my $bytes = encode_float(3.141592654);

# DESCRIPTION

Convert ZX81 BASIC source text into the tokenized internal format
used by the Sinclair ZX81.

This module provides the low-level tokenizer used to convert ZX81
BASIC source code into the encoded format used by ZX81 programs.

Modules such as [ZX81::Tape](https://metacpan.org/pod/ZX81%3A%3ATape) can use this encoding to create
complete ZX81 program and tape-image files.

# FUNCTIONS

## tokenize\_basic

    my $bytes = tokenize_basic($source);

Convert ZX81 BASIC source code into the tokenized internal format
used by ZX81 programs.

## encode\_chars

    my $bytes = encode_chars($text);

Convert text into the ZX81 character encoding without performing
BASIC keyword tokenization.

## encode\_float

    my $bytes = encode_float(3.141592654);

Convert a floating point number to the 5-byte representation used 
by the ZX81.

# SEE ALSO

[ZX81](https://metacpan.org/pod/ZX81)

# AUTHOR

Paulo Custodio

# COPYRIGHT AND LICENSE

Copyright (C) 2026 Paulo Custodio.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
