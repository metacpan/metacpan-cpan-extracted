use strict;
use Test::Base;

use XML::SAX::SimpleDispatcher;
use XML::SAX::ParserFactory;

plan('no_plan');
ok 1;
run_is 'input' => 'expected';

sub get_titles {
    my ($input) = @_;
    my ($xml, $path, @children) = @$input;
    my $stash;
    my $handler = XML::SAX::SimpleDispatcher->new(
        process => {
          $path => [ sub { push @$stash, $_[0]}, \@children ],
        }
    );
    my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
    $parser->parse_string($xml);
    require YAML;
    return YAML::Dump($stash);
}

__END__

=== capture title tag
--- input yaml get_titles
---
- |
   <Books>
    <Book>
     <Title>Learning Perl</Title>
    </Book>
    <Book>
     <Title>Learning Python</Title>
    </Book>
    <Book>
     <Title>Learning PHP</Title>
    </Book>
   </Books>
- /Books/Book
- Title
--- expected
---
- Learning Perl
- Learning Python
- Learning PHP
