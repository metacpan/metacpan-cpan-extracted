# NAME

XML::LibXML::SAX::ChunkParser - Parse XML Chunks Via LibXML SAX

# SYNOPSIS

    local $XML::SAX::ParserPackage = 'XML::LibXML::SAX::ChunkParser';
    my $parser = XML::SAX::ParserFactory->parser(Handler => $myhandler);

    $parser->parse_chunk($xml_chunk);

# DESCRIPTION

XML::LibXML::SAX::ChunkParser uses XML::LibXML's parse\_chunk (as opposed to
parse\_xml\_chunk/parse\_balanced\_chunk), which XML::LibXML::SAX uses.

Its purpose is to simply keep parsing possibly incomplete XML fragments,
for example, from a socket.

# METHODS

## parse\_chunk

Parses possibly incomplete XML fragment

## finish

Explicitly tell the parser that we're done parsing

# AUTHOR

Daisuke Maki `<daisuke@endeworks.jp>`

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
