
use strict;
use Test::More tests => 21;
use XML::TinyXML;
use XML::TinyXML::Selector;
use XML::TinyXML::Selector::XPath;
BEGIN { use_ok('XML::TinyXML::Selector::XPath::Functions') };

my $txml = XML::TinyXML->new();
my $selector = XML::TinyXML::Selector->new($txml, "XPath");

my @functions = $selector->functions;
# check if calling functions() in array context 
# gives us back the list of all available functions
is_deeply(\@functions, \@XML::TinyXML::Selector::XPath::AllFunctions);

# contains()
is ($selector->functions->contains($selector->context, "TEST", "ES"), 1);
is ($selector->functions->contains($selector->context, "TEST", "es"), 0);

# starts-with()
is ($selector->functions->starts_with($selector->context, "TEST", "TE"), 1);
is ($selector->functions->starts_with($selector->context, "TEST", "ST"), 0);

# translate()
is ($selector->functions->translate($selector->context, "bar", "abc", "ABC"), "BAr");
is ($selector->functions->translate($selector->context, "--aaa--","abc-","ABC"), "AAA");

# substring-before()
is ($selector->functions->substring_before($selector->context, "1999/04/01", "/"), "1999");

# substring-after()
is ($selector->functions->substring_after($selector->context, "1999/04/01", "/"), "04/01");
is ($selector->functions->substring_after($selector->context, "1999/04/01", "19"), "99/04/01");

# substring()
is ($selector->functions->substring($selector->context, "12345", 2), "2345");
is ($selector->functions->substring($selector->context, "12345", 0, 3), "12");
is ($selector->functions->substring($selector->context, "12345",2,3), "234");
is ($selector->functions->substring($selector->context, "12345", 1.5, 2.6), "234");
is ($selector->functions->substring($selector->context, "12345", "5 div 5", 2), "12");
is ($selector->functions->substring($selector->context, "12345", "0 div 3", 2), "12");
is ($selector->functions->substring($selector->context, "12345", "0 div 0", 3), "");
is ($selector->functions->substring($selector->context, "12345", 1, "0 div 0"), "");
is ($selector->functions->substring($selector->context, "12345", -42, "0 div 0"), "12345");
is ($selector->functions->substring($selector->context, "12345", "-1 div 0", "1 div 0"), "");

