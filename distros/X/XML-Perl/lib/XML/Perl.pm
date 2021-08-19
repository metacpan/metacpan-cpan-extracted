package XML::Perl;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(perl2xml xmlformat xml2perlbase perlbase2xml xpath);

our $VERSION = '1.00';

use HTML::Parser;



sub perl2xml($;$$$) {
	my ($d, $i, $s, $nl) = @_;
	$i  = 0    unless defined $i;
	$s  = "\t" unless defined $s;
	$nl = "\n" unless defined $nl;
    if (ref $d eq "HASH") {
		return join "", map { _kv($_, $$d{$_}, $i, $s, $nl) } sort keys %$d;
	} else {
		warn "Must be HASH ref";
		return;
	}
}



sub _kv($$$$$);
sub _kv($$$$$) {
	my ($k, $v, $i, $s, $nl) = @_;
	my $shift = join "", $s x $i;
	if (ref $v eq "HASH") {
		my @attrs = ();
		my %nodes = ();
		my $value;
		while (my ($_k, $_v) = each %$v) {
			if ( $_k =~ /^@/ ) {
				push @attrs, "$'=\"$_v\"";
			} elsif ($_k eq '') {
				$value = $_v;
			} else {
				$nodes{$_k} = $_v;
			}
		}
		my $attrs = @attrs ? (join " ", "", sort @attrs) : "";
		if (keys %nodes) {
			# nodes
			++$i;
			my $foo = join "", map { _kv($_, $nodes{$_}, $i, $s, $nl) } sort keys %nodes;
			return join "", $shift, "<$k$attrs>$nl", $foo, $shift, "</$k>$nl";
		} elsif ($value) {
			# value
			if (ref $value eq "ARRAY") {
				return join "", map { $shift, "<$k$attrs>$nl", _kv($k, $_, $i, $s, $nl), $shift, "</$k>$nl" } @$value;
			} elsif (ref $value eq "HASH") {
				++$i;
				my $foo = join "", map { _kv($_, $$value{$_}, $i, $s, $nl) } sort keys %$value;
				return join "", $shift, "<$k$attrs>$nl", $foo, $shift, "</$k>$nl";
			} else {
				return join "", $shift, "<$k$attrs>", _char2entity($value), "</$k>$nl";
			}
		} else {
			# Only attrs
			return "$shift<$k$attrs/>$nl";
		}
	} elsif (ref $v eq "ARRAY") {
		return join "", map { _kv($k, $_, $i, $s, $nl) } @$v;
	} else {
		return join "", "$shift<$k>", _char2entity($v), "</$k>$nl";
	}
}


sub _char2entity {
	my ($v) = @_;
	foreach ($v) {
		s/&/&amp;/g;
		s/>/&gt;/g;
		s/</&lt;/g;
		s/"/&quot;/g;
		s/'/&apos;/g;
	}
	return $v;
}



# Форматирование XML - делаем отступы.
sub xmlformat($) {
	my ($xml) = @_;
	my $shift = 0;
	my $last = "";
	my $xmlf = sub {
		my ($i, $j, $k) = @_;
		if ($k) { # />
			--$shift;
			return $k
		} else { # <...
			if ($i eq "<") {
				$last = $j;
				return "\n" . ("\t" x $shift++) . "$i$j";
			} elsif ($i eq "</") {
				--$shift;
				if ($last eq $j) {
					return "$i$j";
				} else {
					return "\n" . ("\t" x $shift) . "$i$j";
				}
			} elsif ($i eq "<?") {
				return $i;
			} else {
				warn "Unknon element: $i";
				return $i;
			}
		}
	};

	$xml =~ s/
	(?:
		(?: (<|<\/|<(?!\/))((?:\w+:)?\w+) )
		|
		(\/\s*?>)
	)
	/$xmlf->($1, $2, $3)/xeg if defined $xml;
	return $xml;
}



sub xml2perlbase {
	my ($xml) = @_;

	my $prs = HTML::Parser->new(api_version => 3);
	$prs->xml_mode(1);
	$prs->utf8_mode(1);
	$prs->marked_sections(1);

	my $t = {};
	# {
	# 	name => [
	# 		{ a => b, '' => v },
	# 		{}
	# 	],
	# 	...
	# }
	# v - {} или scalar
	my @p = ($t); # Текущая цепочка из ссылок на элементы в глубину.
	my @n = ();   # --//-- из имен элементов
	$prs->handler(start => sub {
		my ($prs, $tagname, $attr) = @_;
		my $v = {};
		push @{$p[-1]{$tagname}}, { %$attr, '' => $v };
		push @p, $v;
		push @n, $tagname;
	}, "self,tagname,attr");

	$prs->handler(text => sub {
		my ($prs, $text) = @_;
		unless ($text =~ m/^\s*$/s) { # ToDo Возможно специфика HTML::Parser
			$p[-2]{$n[-1]}[-1]{''} = $text if @p > 1;
		}

	}, "self,dtext");


	$prs->handler(end => sub {
		my ($prs, $tagname) = @_;
		@p > 1 or return;
		my $v = $p[-2]{$n[-1]}[-1]{''};
		if (ref $v eq "HASH" and keys %$v == 0 or $v eq "") {
			delete $p[-2]{$n[-1]}[-1]{''};
		}
		pop @p;
		pop @n;
	}, "self,tagname");

	$prs->parse($xml) if defined $xml;
	return $t;
}





sub perlbase2xml {
	my ($t, $i, $s, $nl) = @_;
	$i  = 0    unless defined $i;
	$s  = "\t" unless defined $s;
	$nl = "\n" unless defined $nl;
	_perlbase2xml($t, $i, $s, $nl);
}



sub _perlbase2xml {
	my ($t, $i, $shift, $nl) = @_;
	my @s = ();
	foreach my $n (sort keys %$t) {
		foreach my $e (@{$$t{$n}}) {
			push @s, $shift x $i, join " ",
				"<$n",
				map { "$_=\"$$e{$_}\"" } sort grep { $_ } keys %$e;
			my $v = $$e{''};
			if (ref $v) {
				push @s, ">$nl",
					_perlbase2xml($v, $i + 1, $shift, $nl),
					$shift x $i, "</$n>$nl";
			} elsif (defined $v and $v ne "") {
				push @s, join "", ">", _char2entity($v), "</$n>$nl";
			} else {
				push @s, "/>$nl";
			}
		}
	};
	return join "", @s;
}




sub xpath {
	my ($tree, $path) = @_;
	my @path = split /\//, $path;
	if ($path[0] eq '') {
		# From root
		shift @path;
		_xpath($tree, @path);
	} else {
		_xpath_sub($tree, @path);
	}
}


sub _xpath {
	my ($tree, $path, @path) = @_;
	my ($k, $i) = $path =~ m/^(.+?)(?:\[(\d+)\])?$/;
	if (ref $tree eq "HASH" and $$tree{$k}) {
		my @sub_tree = ();
		if ($i) {
			push @sub_tree, $$tree{$k}[$i - 1];
		} else {
			push @sub_tree, @{$$tree{$k}};
		}
		if (@path) {
			my @r = ();
			my %r = ();
			foreach (map { __xpath($_, @path) } @sub_tree) {
				if (ref $_ eq "HASH") {
					foreach my $k (keys %$_) {
						my $v = $$_{$k};
						push @{$r{$k}}, @$v;
					}
				} else {
					push @r, $_;
				}
			}
			push @r, \%r, if keys %r;
			return @r;
		} else {
			return ({ $k => \@sub_tree });
		}
	} else {
		return;
	}
}


sub __xpath {
	my ($tree, @path) = @_;
	if (@path == 1 and $path[0] =~ m/^\@(.+)$/) {
		return $$tree{$1};
	} elsif (@path) {
		return _xpath($$tree{''}, @path);
	} else {
		return $$tree{''};
	}
}



sub _xpath_sub {
	my ($tree, @path) = @_;
	my @sub_tree = grep { ref $_ } map { $$_{''} } map { @$_ } values %$tree;
	my @r = grep { $_ } map { _xpath($_, @path) } @sub_tree;
	push @r, map { _xpath_sub($_, @path) } @sub_tree;
	return @r;
}



1;

__END__

=head1 NAME

XML::Perl - XML producer from humane perl data, parser to base perl data and simple XPath

=head1 SYNOPSIS

  use XML::Perl;
  print perl2xml($data);
  print xmlformat($xml);
  my $t = xml2perlbase($xml);
  print perlbase2xml($t);
  print xpath($t, $xpath);

=head1 DESCRIPTION

XML::Perl is:

 - XML producer from humane perl data;
 - XML formater;
 - XML parser to base perl data;
 - XML producer from base perl data;
 - Simple XPath.

=head2 perl2xml

XML producer from humane perl data.

 my $xml = perl2xml($data);
 my $xml = perl2xml($data, 0, "\t", "\n");

 Perl (humane data)                    XML
 ----------------------------------------------------------
 {name => value}                      <name>value</name>
 ..........................................................
 {name => { a => b, c => d } }        <name>
                                          <a>b</a>
                                          <c>d</c>
                                      </name>
 ..........................................................
 {name => { '@a' => b, c => d } }     <name a="b">
                                          <c>d</c>
                                      </name>
 ..........................................................
 {name => { '@a' => b, '' => v } }    <name a="b">v</name>
 ..........................................................
 {name => { '@a' => b } }             <name a="b" />
 ..........................................................
 {name => [v1, v2, v2]}               <name>v1</name>
                                      <name>v2</name>
                                      <name>v3</name>
 ..........................................................
 {name => [                           <name a="b">v1</name>
     { '@a' => b, '' => v1 },         <name>v2</name>
     v2,                              <name>v3</name>
     v3,
     ] }
 ..........................................................

=head2 xmlformat

XML formater.

 print xmlformat($xml);

=head2 xml2perlbase

XML parser to base perl data.

 my $t = xml2perlbase($xml);

Base perl data:

 {
 	name => [
 		{ a => b, '' => v },
 		{}
 	],
 	...
 }

where: v - hash or scalar.
Atention, a - is attribute.

=head2 perlbase2xml

XML producer from base perl data.

 my $xml = perlbase2xml($t);
 my $xml = perlbase2xml($t, 0, "\t", "\n");

=head2 xpath

Simple XPath

Examples:

 xpath($t, '/a/b');
 xpath($t, '/a[2]/b');
 xpath($t, '/a/b[2]/@a');
 xpath($t, 'a/b');

=head1 ATTENTION

The xpath function is incompatible between versions 1.x and 0.x.
New xpath returns nodes. Old xpath returns values.
To use old behavior see to_old function from t/4_xpath.t.

=head1 AUTHOR

Nick Kostirya

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Nick Kostirya

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
