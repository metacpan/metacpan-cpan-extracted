use Test::More tests => 2;

use strict;
use XML::Parser::GlobEvents qw(parse);

(my $file = __FILE__) =~ s/[\w.`]+$/uploads.rdf/;

my $expected = <<'EXPECTED';
Parse-Gnaw-0.40 (Greg London): An extensible parser. Define grammars using subroutine calls. Define your own grammar extensions by defining new subroutines. Parse text in memory or from/to files or other streams.
Math-Symbolic-0.601 (Steffen Müller): Symbolic calculations
EXPECTED

{
	my $output;

	parse($file,
        'item' => sub {
            my($node) = @_;
            # use Data::Dumper; print Dumper $node;
            $node->{description}{-text} ||= '[no description]';
            $output .= <<"ITEM";
$node->{title}{-text} ($node->{'dc:creator'}{-text}): $node->{description}{-text}
ITEM
        }
    );

	is($output, $expected, 'node tree is as expected');

	# print $output;
}


{
	my $output;
	my %row;

    parse($file,
        'item' => {
            Start => sub {
                %row = ( 'description' => '[no description]' );
            },
            End => sub {
                $output .= <<"ITEM";
$row{title} ($row{'dc:creator'}): $row{description}
ITEM
            }
        },
        'item/*' => sub {
            my($node) = @_;
            $row{ $node->{-name} } = $node->{-text};
        }
      );

	is($output, $expected, 'event call sequence is as expected');

	# print $output;
}
