#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

use XML::Rules;

my $XML = '<root>
	<someroot2>
		<some id="mixed1"> a <empty/>b<nonempty>hello</nonempty>c</some>
	</someroot2>
</root>
';

my $good = {
          'root' => {
                    'someroot2' => {
                                   'mixed1' => 'ab(hello)c'
                                 }
                  }
        };

use Data::Dumper;
		my $parser = XML::Rules->new(
			stripspaces => 14,
			normalizespaces => 0,
			rules => [
				'subtag,nonempty' => sub {'(' . $_[1]->{_content} . ')'},
				'empty' => sub {return},
				'other,some' => sub { $_[1]->{id} => $_[1]->{_content}},
				tag => 'content',
				'root,otherroot,someroot,someroot2' => 'no content',
			],
		);
		my $got = $parser->parse($XML);

#print Dumper($got);

		is_deeply( $got, $good, "what's up?");

#exit if $stripspaces == 1;

