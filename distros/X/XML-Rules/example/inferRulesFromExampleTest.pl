use strict;
use XML::Rules;
use Data::Dumper;

my %rules;

my $parser = XML::Rules->new(
	rules => {
		_default => sub {
			my ($tag, $attrs, $context, $parent_data, $parser) = @_;
			my $repeated = (exists $parent_data->[-1] and exists $parent_data->[-1]{$tag});
			my $has_content = (exists $attrs->{_content});
			my $has_children = grep ref($_) eq 'HASH', values %$attrs;
			my $has_attr = grep {$_ ne '_content' and !ref($attrs->{$_})} keys %$attrs;

			my $rule = do {
				if ($repeated) {
					if ($has_content) {
						if ($has_attr or $has_children) {
							'as array'
						} else {
							'content array'
						}
					} else {
						if ($has_attr or $has_children) {
							'as array no content'
						} else {
							'content array'
						}
					}
				} else {
					if ($has_content) {
						if ($has_attr or $has_children) {
							'as is'
						} else {
							'content'
						}
					} else {
						if ($has_attr or $has_children) {
							'no content'
						} else {
							'content'
						}
					}
				}
			};

			if (not exists $rules{$tag}) {
				$rules{$tag} = $rule
			} elsif($rules{$tag} ne $rule) {
				# we've already seen the tag and it had different type
				if ($rules{$tag} eq 'raw extended array') {
				} elsif ($rule eq 'raw extended array') {
					$rules{$tag} = 'raw extended array';
				} elsif ($rules{$tag} eq 'raw extended' and $rule =~ /array/
					or $rule eq 'raw extended' and $rules{$tag} =~ /array/) {
					$rules{$tag} = 'raw extended array'
				} elsif ($rules{$tag} eq 'as array' or $rule eq 'as array') {
					$rules{$tag} = 'as array'
				} elsif ($rules{$tag} eq 'content array' and $rule eq 'content'
					or $rule eq 'content array' and $rules{$tag} eq 'content') {
					$rules{$tag} = 'content array'
				} elsif ($rules{$tag} eq 'content array' and $rule eq 'as array no content'
					or $rule eq 'content array' and $rules{$tag} eq 'as array no content') {
					$rules{$tag} = 'as array'
				} elsif ($rules{$tag} eq 'content array' and $rule eq 'as is'
					or $rule eq 'content array' and $rules{$tag} eq 'as is') {
					$rules{$tag} = 'as array'
				} elsif ($rules{$tag} eq 'content array' and $rule eq 'no content'
					or $rule eq 'content array' and $rules{$tag} eq 'no content') {
					$rules{$tag} = 'as array'
				} elsif ($rules{$tag} eq 'as array no content' and $rule eq 'as is'
					or $rule eq 'as array no content' and $rules{$tag} eq 'as is') {
					$rules{$tag} = 'as array'
				} elsif ($rules{$tag} eq 'as array no content' and $rule eq 'content'
					or $rule eq 'as array no content' and $rules{$tag} eq 'content') {
					$rules{$tag} = 'as array'
				} elsif ($rules{$tag} eq 'as array no content' and $rule eq 'no content'
					or $rule eq 'as array no content' and $rules{$tag} eq 'no content') {
					$rules{$tag} = 'as array no content'
				} elsif ($rules{$tag} eq 'as is' and ($rule eq 'no content' or $rule eq 'content')
					or $rule eq 'as is' and ($rules{$tag} eq 'no content' or $rules{$tag} eq 'content')) {
					$rules{$tag} = 'as is'
				} elsif ($rules{$tag} eq 'content' and $rule eq 'no content'
					or $rule eq 'content' and $rules{$tag} eq 'no content') {
					$rules{$tag} = 'as is'
				} else {
					die "Unexpected combination of rules: old=$rules{$tag}, new=$rule for tag $tag\n";
				}
			}

			if ($has_content and $has_children) { # the tag contains both text content and subtags!, need to use the raw extended rules
				foreach my $child (grep ref($attrs->{$_}) eq 'HASH', keys %$attrs) {
					next if $rules{$child} =~ /^raw extended/;
					if ($rules{$child} =~ /array/) {
						$rules{$child} = 'raw extended array'
					} else {
						$rules{$child} = 'raw extended'
					}
				}
			}
			return $tag => {};
		}
	},
	stripspaces => 7,
);

$parser->parse(\*DATA);

print Dumper(\%rules);

__DATA__
<root>
	<rep>x</rep>
	<rep>y</rep>
	<rep>z</rep>
	<norep>sdfsdf</norep>
	<attr a="45" b="88">contents</attr>
	<attrrep a="45" b="88">contents</attrrep>
	<attrrep a="45" b="88">contents</attrrep>
	<attrrep a="45" b="88">contents</attrrep>
	<parent>
		<attrrep a="45" b="88">contents</attrrep>
	</parent>
	<parentCnt>
		x = <attrrepX a="45" b="88">contents</attrrepX>
	</parentCnt>
	<parentRep id="1">
		<sattrrep a="45" b="88">contents</sattrrep>
	</parentRep>
	<parentRep id="2">
		<sattrrep a="45" b="88">contents</sattrrep>
		<sattrrep a="45" b="88">contents</sattrrep>
	</parentRep>
	<parentRep id="3">
		<sattrrep a="45" b="88">contents</sattrrep>
	</parentRep>
</root>