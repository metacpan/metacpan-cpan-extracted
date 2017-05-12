use Test;
use XML::SAX::Writer;

my $v_ok = ! ( defined $XML::SAX::Writer::VERSION 
    && $XML::SAX::Writer::VERSION == 0.41
);

unless ( $v_ok ) {
    warn <<TOHERE;

** WARNING **** WARNING **** WARNING **** WARNING **** WARNING **** WARNING **

XML::SAX::Writer v$XML::SAX::Writer::VERSION is too buggy for production
use, please upgrade if a new one is available or downgrade to 0.39.

TOHERE
}

plan tests => 1;

ok $v_ok;
