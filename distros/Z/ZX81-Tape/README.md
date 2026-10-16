# NAME

ZX81::Tape - Create ZX81 tape image files

# SYNOPSIS

    use ZX81::Tape qw(make_p);
    make_p($basic_filename, $p_filename);
        dump_p($p_filename[, $dump_filename]);

# DESCRIPTION

This module converts a BASIC source file to a ZX81 .p tape file.

# FUNCTIONS

## make\_p

    make_p($basic_filename, $p_filename);

Reads the given source BASIC file and builds a binary tape image file.p\_filename 
with the given file name.

## dump\_p

    dump_p($p_filename[, $dump_filename]);

Reads the given binary tape image file and dumps its contents to the 
standard output or a specified file with the given file name.

# SEE ALSO

[ZX81](https://metacpan.org/pod/ZX81)
[https://freestuff.grok.co.uk/zxtext2p/index.html](https://freestuff.grok.co.uk/zxtext2p/index.html)

# AUTHOR

Paulo Custodio

# COPYRIGHT AND LICENSE

Copyright (C) 2026 Paulo Custodio.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
