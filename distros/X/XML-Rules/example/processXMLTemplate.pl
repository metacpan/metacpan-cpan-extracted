use strict;
use XML::Rules;

my $parser = XML::Rules->new( rules => [ _default => 'raw extended array']);


my %plugins;
%plugins = (
	'_parser' => $parser,
	set => sub {
		die "The <set> plugin requires a name attribute!\n" unless exists($_[0]->{name});

		my $content = $_[0]->{_content};
		$plugins{$_[0]->{name}} = sub {$content};
		return;
	},
	print => sub {
		print $parser->ToXML( '', process($_[0]->{_content}));
		return;
	},
	select => sub {
		die "The <select> plugin requires a switch attribute!\n" unless exists($_[0]->{switch});

		my $switch = $_[0]->{switch};
		if (exists $_[0]->{':' . $switch}) { # exists a subtag with that name
			return process($_[0]->{':' . $switch}[0]{_content})
		} elsif (exists $_[0]->{':case'}) { # maybe there is a <case id="that name">
			foreach my $case (@{$_[0]->{':case'}}) {
				return process($case->{_content}) if $case->{id} eq $switch;
			}
			return;
		} else {
			return; # the case was not found
		}
	},
);

my $data = $parser->parse( \*DATA);
$data = $data->{_content};

use Data::Dumper;
#print Dumper($data);
#print Dumper(process($data));
my $result = $parser->ToXML(@{(process($data))->[0]});

print "\n-----------------------------\n\n$result";

sub process {
	my ($what) = @_;
	if (! ref $what) {
		return $what
	} elsif (ref($what) eq 'ARRAY') {
		return [ map {
			if (!ref $_) {
				$_
			} elsif (ref($_) eq 'ARRAY' and @$_ == 2) {
				processAttr($_->[1]);
				if (exists $plugins{$_->[0]}) {
					$plugins{$_->[0]}->($_->[1])
				} else {
					$_->[1]{_content} = process($_->[1]{_content});
					[ $_->[0] => $_->[1]]
				}
			}
		} @$what]
	} else {
		die "process() only accepts strings and array refs.\n";
	}
}

sub processAttr {
	my ($attrs) = @_;
	foreach my $attr (keys %$attrs) {
		next if $attr =~ /^:/;
		next unless $attrs->{$attr} =~ /\{/;
#print "$attrs->{$attr} -> ";
		$attrs->{$attr} =~ tr/{}/<>/;
		my $data = $parser->parse( '<root>' . $attrs->{$attr} . '</root>');
		$data = $data->{_content}[0][1]{_content};
#print "(" . Dumper($data) . ")";
		$attrs->{$attr} = $parser->ToXML('', process($data));
#print "$attrs->{$attr}\n";
	}
}


__END__
<html>
 <set name="foo">blah blah</set>
 <set name="bar">two</set>
 <set name="x">3</set>
 <h1>I say <foo/>, you know.</h1>
<print>This is printed always!</print>
 <p>
 <select switch="{bar/}">
   <one>This is one.</one>
   <two>This is the other.</two>
   <three>And this is yet another.</three>
   <print>This is NOT printed!</print>
 </select>
 </p>

 <p>
 <select switch="{x/}0">
   <case id="10">This is ten.</case>
   <case id="20">This is twenty.</case>
   <case id="30">This is thirty.</case>
   <case id="41">This is fourty one.<print>This is not printed neither!</print></case>
 </select>
 </p>
</html>