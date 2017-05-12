use strict;
use warnings;
no warnings 'uninitialized';

use XML::DTDParser;

my $enable_extended = 1;

my $DTD = ParseDTDFile($ARGV[0]);
print Dumper($DTD);

my $has_mixed = 0;
foreach my $tag (values %$DTD) {
	$tag->{is_mixed} = (($tag->{content} and $tag->{children}) ? 1 : 0)
	 and $has_mixed = 1;
}

my %settings;
foreach my $tagname (keys %$DTD) {
	my $tag = $DTD->{$tagname};

	my $repeated = ($tag->{option} =~ /^[+*]$/ ? 1 : 0);
	my $has_content = $tag->{content};

	my $in_mixed = grep {$DTD->{$_}{is_mixed}} @{$tag->{parent}};

	if ($in_mixed) {
		if ($enable_extended) {
			if ($repeated) {
				$settings{$tagname} = "raw extended array"
			} else {
				$settings{$tagname} = "raw extended"
			}
		} else {
			$settings{$tagname} = "raw"
		}
	} else {
		if (exists $DTD->{attributes} or exists $tag->{children}) {
			my @ids ;
			if (exists $DTD->{attributes}) {
				@ids = grep {$DTD->{attributes}{$_}[0] eq 'ID' and $DTD->{attributes}{$_}[0] eq '#REQUIRED'} keys %{$DTD->{attributes}};
			}
			if (scalar(@ids) == 1) {
				if ($has_content) {
					$settings{$tagname} = "by $ids[0]"
				} else {
					$settings{$tagname} = "no content by $ids[0]"
				}
			} else {
				if ($has_content) {
					if ($repeated) {
						$settings{$tagname} = "as array"
					} else {
						$settings{$tagname} = "as is"
					}
				} else {
					if ($repeated) {
						$settings{$tagname} = "as array no content"
					} else {
						$settings{$tagname} = "no content"
					}
				}
			}
		} elsif ($repeated) {
			$settings{$tagname} = "content array"
		} else {
			$settings{$tagname} = "content array"
		}
	}
}

use Data::Dumper;
print Dumper(\%settings);

my %compressed;
{
	my %tmp;
	while (my ($tag, $option) = each %settings) {
		push @{$tmp{$option}}, $tag;
	}

	while (my ($option, $tags) = each %tmp) {
		$compressed{join ',', @$tags} = $option
	}
}

my %result = (
	rules => \%compressed,
);
if ($has_mixed) {
	$result{stripspaces} = 0;
} else {
	$result{stripspaces} = 7;
}

print Dumper(\%result);
