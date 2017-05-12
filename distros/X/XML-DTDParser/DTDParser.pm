package XML::DTDParser;
require Exporter;
use FileHandle;
use strict;
use File::Spec;
use Cwd;
our @ISA = qw(Exporter);

our @EXPORT = qw(ParseDTD FindDTDRoot ParseDTDFile);
our @EXPORT_OK = @EXPORT;

our $VERSION = '2.01';

my $namechar = '[#\x41-\x5A\x61-\x7A\xC0-\xD6\xD8-\xF6\xF8-\xFF0-9\xB7._:-]';
my $name = '[\x41-\x5A\x61-\x7A\xC0-\xD6\xD8-\xF6\xF8-\xFF_:]' . $namechar . '*';
my $nameX = $name . '[.?+*]*';

my $nmtoken = $namechar . '+';

my $AttType = '(?:CDATA\b|IDREFS?\b|ID\b|ENTITY\b|ENTITIES\b|NMTOKENS?\b|\([^\)]*\)|NOTATION\s+\([^\)]*\))';
my $DefaultDecl = q{(?:#REQUIRED|#IMPLIED|(:?#FIXED ?)?(?:".*?"|'.*?'))};
my $AttDef = '('.$name.') ('.$AttType.')(?: ('.$DefaultDecl.'))?';


sub ParseDTDFile {
	my $file = shift;
	open my $IN, "< $file"
		or die "Cannot open the $file : $!\n";
	my $xml = do {local $/; <$IN>};
	close $IN;
	my ($vol,$dir,$filename) = File::Spec->splitpath( $file);
	if ($filename eq $file) {
		return ParseDTD($xml);
	} else {
		# in case there are any includes, they should be relative to the DTD file, not to current dir
		my $cwd = cwd();
		chdir(File::Spec->catdir($vol,$dir));
		my $DTD = ParseDTD($xml);
		chdir($cwd);
		return $DTD;
	}
}

sub ParseDTD {
	my $xml = shift;
	my (%elements, %definitions);

	$xml =~ s/\s\s*/ /gs;

	while ($xml =~ s{<!ENTITY\s+(?:(%)\s*)?($name)\s+SYSTEM\s*"(.*?)"\s*>}{}io) {
		my ($percent, $entity, $include) = ($1,$2,$3);
		$percent = '&' unless $percent;
		my $definition;
		{
			# the $include may be a URL, use LWP::Simple to fetch it if it is.
			my $IN;
			open $IN, "<$include" or die "Cannot open include file $include : $!\n";
			$definition = do {local $/; <$IN>};
			close $IN;
		}
		$definition =~ s/\s\s*/ /gs;
		$xml =~ s{\Q$percent$entity;\E}{$definition}g;
	}

	my (%elementinfo, %attribinfo);
	while ($xml =~ s{<!--#info\s+(.*?)-->}{}s) {
		my $info = $1;$info =~ s/\s+$//s;
		my %info;
		while ($info =~ s{^([\w-]+)\s*=\s*((?:'[^']*')+|(?:"[^"]*")+|[^\s'"]\S*)\s*}{}s) {
			my ($name, $value) = ($1, $2);
			if ($value =~ /^'/) {
				($value = substr $value, 1, length($value)-2) =~ s/''/'/g;
			} elsif ($value =~ /^"/) {
				($value = substr $value, 1, length($value)-2) =~ s/""/"/g;
			}
			$info{$name} = $value;
		}
		die "Malformed <!--#info ...--> section!\n\t<!--#info $info -->\n"
			if ($info ne '');
		die "The <!--#info $info --> section doesn't contain the 'element' parameter!\n"
			unless exists $info{'element'};
		my $element = $info{'element'};
		delete $info{'element'};
		if (exists $info{'attribute'}) {
			my $attribute = $info{'attribute'};
			delete $info{'attribute'};
			$attribinfo{$element}->{$attribute} = \%info;
		} else {
			$elementinfo{$element} = \%info;
		}
	}

	$xml =~ s{<!--.*?-->}{}gs;
	$xml =~ s{<\?.*?\?>}{}gs;

	while ($xml =~ s{<!ENTITY\s+(?:(%)\s*)?($name)\s*"(.*?)"\s*>}{}io) {
		my ($percent, $entity, $definition) = ($1,$2,$3);
		$percent = '&' unless $percent;
		$definitions{"$percent$entity"} = $definition;
	}

	{
		my $replacements = 0;
		1 while $replacements++ < 1000 and $xml =~ s{([&%]$name);}{(exists $definitions{$1} ? $definitions{$1} : "$1\x01;")}geo;
		die <<'*END*' if $xml =~ m{([&%]$name);}o;
Recursive <!ENTITY ...> definitions or too many entities! Only up to 1000 entity replacements allowed.
(An entity is something like &foo; or %foo;. They are defined by <!ENTITY ...> tag.)
*END*
	}
	undef %definitions;
	$xml =~ tr/\x01//d;

	while ($xml =~ s{<!ELEMENT\s+($name)\s*(\(.*?\))([?*+]?)\s*>}{}io) {
		my ($element, $children, $option) = ($1,$2,$3);
		$elements{$element}->{childrenSTR} = $children . $option;
		$children =~ s/\s//g;
		if ($children eq '(#PCDATA)') {
			$children = '#PCDATA';
		} elsif ($children =~ s/^\((#PCDATA(?:\|$name)+)\)$/$1/o and $option eq '*') {
			$children =~ s/\|/*,/g;
			$children .= '*';
		} else {
			$children = simplify_children( $children, $option);
		}

		die "<!ELEMENT $element (...)> is not valid!\n"
			unless $children =~ m{^#?$nameX(?:,$nameX)*$}o;


		$elements{$element}->{childrenARR} = [];
		foreach my $child (split ',', $children) {
			$child =~ s/([?*+])$//
				and $option = $1
				or $option = '!';
			if (exists $elements{$element}->{children}->{$child}) {
				$elements{$element}->{children}->{$child} = _merge_options( $elements{$element}->{children}->{$child}, $option);
				$elements{$element}->{childrenX}->{$child} = _merge_counts( $elements{$element}->{childrenX}->{$child}, _char2count($option))
					unless $child eq '#PCDATA';
			} else {
				$elements{$element}->{children}->{$child} = $option;
				$elements{$element}->{childrenX}->{$child} = _char2count($option)
					unless $child eq '#PCDATA';
			}
			push @{$elements{$element}->{childrenARR}}, $child
				unless $child eq '#PCDATA';
		}
		delete $elements{$element}->{childrenARR}
			if @{$elements{$element}->{childrenARR}} == 0
	}

	while ($xml =~ s{<!ELEMENT\s+($name)\s*(EMPTY|ANY)\s*>}{}io) {
		my ($element, $param) = ($1,$2);
		if (uc $param eq 'ANY') {
			$elements{$element}->{any} = 1;
		} else {
			$elements{$element} = {};
		}
	}
#=for comment
	while ($xml =~ s{<!ATTLIST(?:\s+($name)\s+(.*?))?\s*>}{}io) {
		my ($element, $attributes) = ($1,$2);
		die "<!ELEMENT $element ...> referenced by an <!ATTLIST ...> not found!\n"
			unless exists $elements{$element};
		while ($attributes =~ s/^\s*$AttDef//io) {
			my ($name,$type,$option,$default) = ($1,$2,$3);
			if ($option =~ /^#FIXED\s+["'](.*)["']$/i){
				$option = '#FIXED';
				$default = $1;
			} elsif ($option =~ /^["'](.*)["']$/i){
				$option = '';
				$default = $1;
			}
			$elements{$element}->{attributes}->{$name} = [$type,$option,$default,undef];
			if ($type =~ /^(?:NOTATION\s*)?\(\s*(.*?)\)$/) {
				$elements{$element}->{attributes}->{$name}->[3] = parse_enum($1);
			}
		}
	}
#=cut
#$xml = '';

	$xml =~ s/\s\s*/ /g;

	die "UNPARSED DATA:\n$xml\n\n"
		if $xml =~ /\S/;

	foreach my $element (keys %elements) {
		foreach my $child (keys %{$elements{$element}->{children}}) {
			if ($child eq '#PCDATA') {
				delete $elements{$element}->{children}->{'#PCDATA'};
				$elements{$element}->{content} = 1;
			} else {
				die "Element $child referenced by $element was not found!\n"
					unless exists $elements{$child};
				if (exists $elements{$child}->{parent}) {
					push @{$elements{$child}->{parent}}, $element;
				} else {
					$elements{$child}->{parent} = [$element];
				}
				$elements{$child}->{option} = $elements{$element}->{children}->{$child};
			}
		}
		if (scalar(keys %{$elements{$element}->{children}}) == 0) {
			delete $elements{$element}->{children};
		}
		if (exists $elementinfo{$element}) {
			foreach my $info (keys %{$elementinfo{$element}}) {
				$elements{$element}->{$info} = $elementinfo{$element}->{$info};
			}
		}
		if (exists $attribinfo{$element}) {
			foreach my $attribute (keys %{$attribinfo{$element}}) {
				$elements{$element}->{'attributes'}->{$attribute}->[4] = $attribinfo{$element}->{$attribute};
			}
		}
	}

	return \%elements;
}

sub flatten_children {
	my ( $children, $option ) = @_;

	if ($children =~ /\|/) {
		$children =~ s{[|,]}{?,}g;
		$children .= '?'
	}

	if ($option) {
		$children =~ s/,/$option,/g;
		$children .= $option;
	}

	return $children;
}

sub simplify_children {
	my ( $children, $option ) = @_;

	1 while $children =~ s{\(($nameX(?:[,|]$nameX)*)\)([?*+]*)}{flatten_children($1, $2)}geo;

	if ($option) {
		$children =~ s/,/$option,/g;
		$children .= $option;
	}

	foreach ($children) {
		s{\?\?}{?}g;
		s{\?\+}{*}g;
		s{\?\*}{*}g;
		s{\+\?}{*}g;
		s{\+\+}{+}g;
		s{\+\*}{*}g;
		s{\*\?}{*}g;
		s{\*\+}{*}g;
		s{\*\*}{*}g;
	}

	return $children;
}

sub parse_enum {
	my $enum = shift;
	$enum =~ tr/\x20\x09\x0D\x0A//d; # get rid of whitespace
	return [split /\|/, $enum];
}

my %merge_options = (
	'!!' => '+',
	'!*' => '+' ,
	'!+' => '+',
	'!?' => '+',
	'**' => '*',
	'*+' => '+',
	'*?' => '*',
	'++' => '+',
	'+?' => '+',
	'??' => '?',
);
sub _merge_options {
	my ($o1, $o2) = sort @_;
	return $merge_options{$o1.$o2};
}

my %char2count = (
	'!' => '1',
	'?' => '0..1',
	'+' => '1..',
	'*' => '0..',
);
sub _char2count{
	return $char2count{$_[0]}
}

sub _merge_counts {
	my ($c1, $c2) = @_;
	if ($c1 =~ /^\d+$/) {
		if ($c2 =~ /^\d+$/) {
			return $c1+$c2
		} elsif ($c2 =~ /^(\d+)..(\d+)$/) {
			return ($c1+$1) . ".." . ($c1+$2);
		} elsif ($c2 =~ /^(\d+)..$/) {
			return ($c1+$1) . "..";
		}
	} elsif ($c1 =~ /^(\d+)..(\d+)$/) {
		my ($c1l,$c1u) = ($1,$2);
		if ($c2 =~ /^\d+$/) {
			return ($c1l+$c2) . ".." . ($c1u+$c2);
		} elsif ($c2 =~ /^(\d+)..(\d+)$/) {
			return ($c1l+$1) . ".." . ($c1u+$2);
		} elsif ($c2 =~ /^(\d+)..$/) {
			return ($c1l+$1) . "..";
		}
	} elsif ($c1 =~ /^(\d+)..$/) {
		$c1=$1;
		if ($c2 =~ /^\d+$/) {
			return ($c1+$c2) . "..";
		} elsif ($c2 =~ /^(\d+)..(\d+)$/) {
			return ($c1+$1) . "..";
		} elsif ($c2 =~ /^(\d+)..$/) {
			return ($c1+$1) . "..";
		}
	}
}

sub FindDTDRoot {
	my $elements = shift;
	my @roots;
	foreach my $element (keys %$elements) {
		if (!exists $elements->{$element}->{parent}) {
			push @roots, $element;
			$elements->{$element}->{option} = '!';
		}
	}
	return @roots;
}

=head1 NAME

XML::DTDParser - quick and dirty DTD parser

Version 2.01

=head1 SYNOPSIS

  use XML::DTDParser qw(ParseDTD ParseDTDFile);

  $DTD = ParseDTD $DTDtext;
 #or
  $DTD = ParseDTDFile( $dtdfile)

=head1 DESCRIPTION

This module parses a DTD file and creates a data structure containing info about
all tags, their allowed parameters, children, parents, optionality etc. etc. etc.

Since I'm too lazy to document the structure, parse a DTD you need and print
the result to a file using Data::Dumper. The datastructure should be selfevident.

Note: The module should be able to parse just about anything, but it intentionaly looses some information.
Eg. if the DTD specifies that a tag should contain either CHILD1 or CHILD2 you only get that
CHILD1 and CHILD2 are optional. That is is the DTD contains
	<!ELEMENT FOO (BAR|BAZ)>
the result will be the same is if it contained
	<!ELEMENT FOO (BAR?,BAZ?)>

You get the original unparsed parameter list as well so if you need this
information you may parse it yourself.

Since version 1.6 this module supports my "extensions" to DTDs.
If the DTD contains a comment in form

	<!--#info element=XXX foo=bar greeting="Hello World!" person='d''Artagnan'-->

and there is an element XXX in the DTD, the resulting hash for the XXX will contain

	'foo' => 'bar',
	'person' => 'd\'Artagnan',
	'greeting => 'Hello World!'

If the DTD contains

	<!--#info element=XXX attribute=YYY break=no-->

the

	$DTD->{XXX}->{attributes}->{YYY}->[4]

will be set to

	{ break => 'no' }

I use this parser to import the DTD into the database so that I could map some fields
to certain tags for output and I want to be able to specify the mapping inside the file:

	<!--#info element=TagName map_to="FieldName"-->

=head2 EXPORT

By default the module exports all (both) it's functions. If you only want one, or none
use

	use XML::DTDParser qw(ParseDTD);
	or
	use XML::DTDParser qw();

=over 4

=item ParseDTD

	$DTD = ParseDTD $DTDtext;

Parses the $DTDtext and creates a data structure. If the $DTDtext contains some
<!ENTITY ... SYSTEM "..."> declarations those are read and parsed as needed.
The paths are relative to current directory.

The module currently doesn't support URLs here yet.

=item ParseDTDFile

	$DTD = ParseDTDFile $DTDfile;

Parses the contents of $DTDfile and creates a data structure. If the $DTDfile contains some
<!ENTITY ... SYSTEM "..."> declarations those are read and parsed as needed.
The paths are relative to the $DTDfile.

The module currently doesn't support URLs here yet.

=item FindDTDRoot

	$DTD = ParseDTD $DTDtext;
	@roots = FindDTDRoot $DTD;

Returns all tags that have no parent. There could be several such tags defined by the DTD.
Especialy if it used some common includes.

=back

=head1 AUTHOR

Jenda@Krynicky.cz
http://Jenda.Krynicky.cz

=head1 COPYRIGHT

Copyright (c) 2002 Jan Krynicky <Jenda@Krynicky.cz>. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

