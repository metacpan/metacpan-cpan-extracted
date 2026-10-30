use strict;
use warnings;
use Test::More tests => 14;
use Tk::Markdown;

our $executed = 0;
my @documents = (
    q{<% $main::executed = 1 %>plain},
    q{<%= do { $main::executed = 1; 'replacement' } %>},
    "before\n<%\n\$main::executed = 1;\n%>\nafter",
    "before\n<%=\ndo { \$main::executed = 1; 'replacement' }\n%>\nafter",
    q{`<% $main::executed = 1 %>`},
    q{<% die 'must not run' %><%= die 'must not run' %>},
);
for my $document (@documents) {
    is(Tk::Markdown::FormatMarkdown($document), $document,
        'embedded Perl is preserved as literal text');
    is($executed, 0, 'formatting does not execute document code');
}
is(Tk::Markdown::FormatMarkdown("# Heading\n\nordinary text"),
    "# Heading\n\nordinary text", 'ordinary Markdown remains unchanged');
is(Tk::Markdown::FormatMarkdown("| a | longer |\n| bb | c |\n\nafter"),
    "| a  | longer |\n| bb | c      |\n\nafter", 'table formatting still works');
