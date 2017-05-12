# NAME

XMLRPC::Fast - fast XML-RPC encoder/decoder


# SYNOPSIS

```
use XMLRPC::Fast;

my $xml = encode_xmlrpc_request("auth.login" => {
    username => "cjohnson", password => "tier3"
});

my $rpc = decode_xmlrpc($xml);
```


# DESCRIPTION

XMLRPC::Fast, as its names suggests, tries to be a fast XML-RPC
encoder & decoder. Contrary to most other XML-RPC modules on the CPAN,
it doesn't offer a RPC-oriented framework, and instead behaves more like
a serialization module with a purely functional interface. In order to
DWIM and keep things simple for the user, it doesn't relies on regexps
to detect scalar types, and instead check Perl's internal flags.


# CREDITS

The XML-RPC standard is Copyright 1998-2004 UserLand Software, Inc.
See <http://www.xmlrpc.com/> for more information about the XML-RPC
specification.

# AUTHOR

Sébastien Aperghis-Tramoni <saper@cpan.org>

