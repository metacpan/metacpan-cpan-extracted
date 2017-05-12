package XML::Hash::LX;

use 5.006002;
use strict;
use warnings;
use XML::LibXML ();

our $PARSER = XML::LibXML->new();

sub _croak { require Carp; goto &Carp::croak }
sub import {
	my $me = shift;
	no strict 'refs';
	my %e = ( xml2hash => 1, hash2xml => 1, ':inject' => 0 );
	if (@_) { %e = map { $_=>1 } @_ }
	*{caller().'::xml2hash'} = \&xml2hash if delete $e{xml2hash};
	*{caller().'::hash2xml'} = \&hash2xml if delete $e{hash2xml};
	if ( delete $e{':inject'} ) {
		unless (defined &XML::LibXML::Node::toHash) {
			*XML::LibXML::Node::toHash = \&xml2hash;
		}
	}
	_croak "@{[keys %e]} is not exported by $me" if %e;
}

=head1 NAME

XML::Hash::LX - Convert hash to xml and xml to hash using LibXML

=cut

our $VERSION = '0.0603';

=head1 SYNOPSIS

    use XML::Hash::LX;

    my $hash = xml2hash $xmlstring, attr => '.', text => '~';
    my $hash = xml2hash $xmldoc;
    
    my $xmlstr = hash2html $hash, attr => '+', text => '#text';
    my $xmldoc = hash2html $hash, doc => 1, attr => '+';
    
    # Usage with XML::LibXML

    my $doc = XML::LibXML->new->parse_string($xml);
    my $xp  = XML::LibXML::XPathContext->new($doc);
    $xp->registerNs('rss', 'http://purl.org/rss/1.0/');

    # then process xpath
    for ($xp->findnodes('//rss:item')) {
        # and convert to hash concrete nodes
        my $item = xml2hash($_);
        print Dumper+$item
    }

=head1 DESCRIPTION

This module is a companion for C<XML::LibXML>. It operates with LibXML objects, could return or accept LibXML objects, and may be used for easy data transformations

It is faster in parsing then L<XML::Simple>, L<XML::Hash>, L<XML::Twig> and of course much slower than L<XML::Bare> ;)

It is faster in composing than L<XML::Hash>, but slower than L<XML::Simple>

Parse benchmark:

               Rate   Simple     Hash     Twig Hash::LX     Bare
    Simple   11.3/s       --      -2%     -16%     -44%     -97%
    Hash     11.6/s       2%       --     -14%     -43%     -97%
    Twig     13.5/s      19%      16%       --     -34%     -96%
    Hash::LX 20.3/s      79%      75%      51%       --     -95%
    Bare      370/s    3162%    3088%    2650%    1721%       --

Compose benchmark:

               Rate     Hash Hash::LX   Simple
    Hash     49.2/s       --     -18%     -40%
    Hash::LX 60.1/s      22%       --     -26%
    Simple   81.5/s      66%      36%       --

Benchmark was done on L<http://search.cpan.org/uploads.rdf>

=head1 EXPORT

C<xml2hash> and C<hash2xml> are exported by default

=head2 :inject

Inject toHash method in the namespace of L<XML::LibXML::Node> and allow to call it on any subclass of L<XML::LibXML::Node> directly

By default is disabled

    use XML::Hash::LX ':inject';
    
    my $doc = XML::LibXML->new->parse_string($xml);
    my $hash = $doc->toHash(%opts);

=head1 FUNCTIONS

=head2 xml2hash $xml, [ OPTIONS ]

XML could be L<XML::LibXML::Document>, L<XML::LibXML::DocumentPart> or string

=head2 hash2xml $hash, [ doc => 1, ] [ OPTIONS ]

Id C<doc> option is true, then returned value is L<XML::LibXML::Document>, not string

=head1 OPTIONS

Every option could be passed as arguments to function or set as global variable in C<XML::Hash::LX> namespace

=head2 %XML::Hash::LX::X2H

Options respecting convertations from xml to hash

=over 4

=item order [ = 0 ]

B<Strictly> keep the output order. When enabled, structures become more complex, but xml could be completely reverted

=item attr [ = '-' ]

Attribute prefix

	<node attr="test" />  =>  { node => { -attr => "test" } }

=item text [ = '#text' ]

Key name for storing text

	<node>text<sub /></node>  =>  { node => { sub => '', '#text' => "test" } }

=item join [ = '' ]

Join separator for text nodes, splitted by subnodes

Ignored when C<order> in effect

	# default:
	xml2hash( '<item>Test1<sub />Test2</item>' )
	: { item => { sub => '', '~' => 'Test1Test2' } };
	
	# global
	$XML::Hash::LX::X2H{join} = '+';
	xml2hash( '<item>Test1<sub />Test2</item>' )
	: { item => { sub => '', '~' => 'Test1+Test2' } };
	
	# argument
	xml2hash( '<item>Test1<sub />Test2</item>', join => '+' )
	: { item => { sub => '', '~' => 'Test1+Test2' } };

=item trim [ = 1 ]

Trim leading and trailing whitespace from text nodes

=item cdata [ = undef ]

When defined, CDATA sections will be stored under this key

	# cdata = undef
	<node><![CDATA[ test ]]></node>  =>  { node => 'test' }

	# cdata = '#'
	<node><![CDATA[ test ]]></node>  =>  { node => { '#' => 'test' } }

=item comm [ = undef ]

When defined, comments sections will be stored under this key

When undef, comments will be ignored

	# comm = undef
	<node><!-- comm --><sub/></node>  =>  { node => { sub => '' } }

	# comm = '/'
	<node><!-- comm --><sub/></node>  =>  { node => { sub => '', '/' => 'comm' } }

=back

=head2 $XML::Hash::LX::X2A [ = 0 ]

Global array casing

Ignored when C<X2H{order}> in effect

As option should be passed as

	xml2hash $xml, array => 1;

Effect:

	# $X2A = 0
	<node><sub/></node>  =>  { node => { sub => '' } }

	# $X2A = 1
	<node><sub/></node>  =>  { node => [ { sub => [ '' ] } ] }

=head2 %XML::Hash::LX::X2A

By element array casing

Ignored when C<X2H{order}> in effect

As option should be passed as

	xml2hash $xml, array => [ nodes list ];

Effect:

	# %X2A = ()
	<node><sub/></node>  =>  { node => { sub => '' } }

	# %X2A = ( sub => 1 )
	<node><sub/></node>  =>  { node => { sub => [ '' ] } }

=cut

our $X2A = 0;
our %X2A = ();

our %X2H;
	%X2H = (
	order  => 0,
	attr   => '-',
	text   => '#text',
	join   => '',
	trim   => 1,
	cdata  => undef,
	comm   => undef,
	#cdata  => '#',
	#comm   => '//',
	%X2H,  # also inject previously user-defined options
);

sub _x2h {
	my $doc = shift;
	my $res;
		if ($doc->hasChildNodes or $doc->hasAttributes) {
			if ($X2H{order}) {
				$res = [];
				my $attr = {};
				for ($doc->attributes) {
					#warn " .> ".$_->nodeName.'='.$_->getValue;
					$attr->{ $X2H{attr} . $_->nodeName } = $_->getValue;
				}
				push @$res, $attr if %$attr;
			} else {
				$res = {};
				for ($doc->attributes) {
					#warn " .> ".$_->nodeName.'='.$_->getValue;
					$res->{ $X2H{attr} . $_->nodeName } = $_->getValue;
				}
			}
			for ($doc->childNodes) {
				my $ref = ref $_;
				my $nn;
				if ($ref eq 'XML::LibXML::Text') {
					$nn = $X2H{text}
				}
				elsif ($ref eq 'XML::LibXML::CDATASection') {
					$nn = defined $X2H{cdata} ? $X2H{cdata} : $X2H{text};
				}
				elsif ($ref eq 'XML::LibXML::Comment') {
					$nn = defined $X2H{comm} ? $X2H{comm} : next;
				}
				else {
					$nn = $_->nodeName;
				}
				my $chld = _x2h($_);
				if ($X2H{order}) {
					if ($nn eq $X2H{text}) {
						push @{ $res }, $chld if length $chld;
					} else {
						push @{ $res }, { $nn => $chld };
					}
				} else {
					if (( $X2A or $X2A{$nn} ) and !$res->{$nn}) { $res->{$nn} = [] }
					if (exists $res->{$nn} ) {
						#warn "Append to $res->{$nn}: $nn $chld";
						$res->{$nn} = [ $res->{$nn} ] unless ref $res->{$nn} eq 'ARRAY';
						push @{$res->{$nn}}, $chld if defined $chld;
					} else {
						if ($nn eq $X2H{text}) {
							$res->{$nn} = $chld if length $chld;
						} else {
							$res->{$nn} = $chld;
						}
					}
				}
			}
			if($X2H{order}) {
				#warn "Ordered mode, have res with ".(0+@$res)." children = @$res";
				return $res->[0] if @$res == 1;
			} else {
				if (defined $X2H{join} and exists $res->{ $X2H{text} } and ref $res->{ $X2H{text} }) {
					$res->{ $X2H{text} } = join $X2H{join}, grep length, @{ $res->{ $X2H{text} } };
				}
				delete $res->{ $X2H{text} } if $X2H{trim} and keys %$res > 1 and exists $res->{ $X2H{text} } and !length $res->{ $X2H{text} };
				return $res->{ $X2H{text} } if keys %$res == 1 and exists $res->{ $X2H{text} };
			}
		}
		else {
			$res = $doc->textContent;
			if ($X2H{trim}) {
				$res =~ s{^\s+}{}s;
				$res =~ s{\s+$}{}s;
			}
		}
	$res;
	
}

sub xml2hash($;%) {
	my $doc = shift;
	defined $doc or _croak("Called xml2hash on undef"),return;
	my %opts = @_;
	my $arr = delete $opts{array};
	local $X2A = 1 if defined $arr and !ref $arr;
	local @X2A{@$arr} = (1)x@$arr if defined $arr and ref $arr;
	local @X2H{keys %opts} = values %opts if @_;
	$doc = $PARSER->parse_string($doc) if !ref $doc;
	#use Data::Dumper;
	#warn Dumper \%X2H;
	my $root = $doc->isa('XML::LibXML::Document') ? $doc->documentElement : $doc;
	return {
		scalar $root->nodeName => $X2A || $X2A{$root->nodeName} ? [ _x2h($root) ] : _x2h($root),
	};

}

=head2 %XML::Hash::LX::H2X

Options respecting convertations from hash to xml

=over 4

=item encoding [ = 'utf-8' ]

XML output encoding

=item attr [ = '-' ]

Attribute prefix

	{ node => { -attr => "test", sub => 'test' } }
	<node attr="test"><sub>test</sub></node>

=item text [ = '#text' ]

Key name for storing text

	{ node => { sub => '', '#text' => "test" } }
	<node>text<sub /></node>
	# or 
	<node><sub />text</node>
	# order of keys is not predictable

=item trim [ = 1 ]

Trim leading and trailing whitespace from text nodes

	# trim = 1
	{ node => { sub => [ '    ', 'test' ], '#text' => "test" } }
	<node>test<sub>test</sub></node>

	# trim = 0
	{ node => { sub => [ '    ', 'test' ], '#text' => "test" } }
	<node>test<sub>    test</sub></node>

=item cdata [ = undef ]

When defined, such key elements will be saved as CDATA sections

	# cdata = undef
	{ node => { '#' => 'test' } } => <node><#>test</#></node> # it's bad ;)

	# cdata = '#'
	{ node => { '#' => 'test' } } => <node><![CDATA[test]]></node>

=item comm [ = undef ]

When defined, such key elements will be saved as comment sections

	# comm = undef
	{ node => { '/' => 'test' } } => <node></>test<//></node> # it's very bad! ;)

	# comm = '/'
	{ node => { '/' => 'test' } } => <node><!-- test --></node>

=back

=cut

our %H2X;
	%H2X = (
	%X2H,
	#attr   => '-',
	#text   => '~',
	#trim   => 1,
	# join   => '+', # useless
	%H2X,
);
our $AL = length $H2X{attr};

our $hd = '/';
sub _h2x {
	@_ or return;
	my ($data,$parent) = @_;
	#warn "> $d";
	return unless defined $data;
	if ( !ref $data ) {
		if ($H2X{trim}) {
			$data =~ s/^\s+//s;
			$data =~ s/\s+$//s;
			#return unless length($data);
		}
		return XML::LibXML::Text->new($data)
	};
	my @rv;
	if (ref $data eq 'ARRAY') {
		#warn "Map @$data";
		@rv = map _h2x($_,$parent), @$data;
	}
	elsif (ref $data eq 'HASH') {
		for (keys %$data) {
			#warn "$_ $data->{$_}";
			#next if !defined $data->{$_} or ( !ref $data->{$_} and !length $data->{$_} );
			
			# What may be empty ?
			# - attribute
			# - node
			# - comment
			# Skip empty: text, cdata
			
			my $cdata_or_text;
			
			if ($_ eq $H2X{text}) {
				$cdata_or_text = 'XML::LibXML::Text';
			}
			elsif (defined $H2X{cdata} and $_ eq $H2X{cdata}) {
				$cdata_or_text = 'XML::LibXML::CDATASection';
			}
			
			if (0) {}
			
			elsif($cdata_or_text) {
				push @rv, map {
					defined($_) ? do {
						$H2X{trim} and s/(?:^\s+|\s+$)//sg;
						$H2X{trim} && !length($_) ? () :
						$cdata_or_text->new( $_ )
					} : (),
				} ref $data->{$_} ? @{ $data->{$_} } : $data->{$_};
				
			}
			elsif (defined $H2X{comm} and $_ eq $H2X{comm}) {
				push @rv, map XML::LibXML::Comment->new(defined $_ ? $_ : ''), ref $data->{$_} ? @{ $data->{$_} } : $data->{$_};
			}
			elsif (substr($_,0,$AL) eq $H2X{attr} ) {
				if ($parent) {
					$parent->setAttribute( substr($_,1),defined $data->{$_} ? $data->{$_} : '' );
				} else {
					warn "attribute $_ without parent" 
				}
			}
			elsif ( !defined $data->{$_} or ( !ref $data->{$_} and !length $data->{$_} ) ) {
				push @rv,XML::LibXML::Element->new($_);
			}
			else {
				local $hd = $hd.'/'.$_;
				my $node = XML::LibXML::Element->new($_);
				#warn ("$hd << ".$_->nodeName),
				$node->appendChild($_) for _h2x($data->{$_},$node);
				push @rv,$node;
			}
		}
	}
	elsif (ref $data eq 'SCALAR') { # RAW
		my $node = eval { XML::LibXML->new->parse_string($$data) } or _croak "Malformed raw data on $hd: $@";
		return $node->documentElement;
	}
	elsif (ref $data eq 'REF') { # LibXML Node
		if (ref $$data and eval{ $$data->isa('XML::LibXML::Node') }) {
			return $$data->cloneNode(1);
		}
		elsif ( ref $$data and do { no strict 'refs'; exists ${ ref($$data).'::' }{'(""'} } ) {
			return XML::LibXML::Text->new( "$$data" );
		}
		else {
			_croak ("Bad reference ".ref( $$data ).": <$$data> on $hd");
		}
	}
	elsif ( do { no strict 'refs'; exists ${ ref($data).'::' }{'(""'} } ) { # have string overload
		return XML::LibXML::Text->new( "$data" );
	}
	elsif (ref $data and eval{ $data->isa('XML::LibXML::Node') }) {
		return $data->cloneNode(1);
	}
	else {
		_croak "Bad reference ".ref( $data ).": <$data> on $hd";
	}
	#warn "@rv";
	return wantarray ? @rv : $rv[0];
}

sub hash2xml($;%) {
	#warn "hash2xml(@_) from @{[ (caller)[1,2] ]}";
	my $hash = shift;
	my %opts = @_;
	my $str = delete $opts{doc} ? 0 : 1;
	my $encoding = delete $opts{encoding} || delete $opts{enc} || 'utf-8';
	my $doc = XML::LibXML::Document->new('1.0', $encoding);
	local @H2X{keys %opts} = values %opts if @_;
	local $AL = length $H2X{attr};
	#use Data::Dumper;
	#warn Dumper \%H2X;
	my $root = _h2x($hash);
	$doc->setDocumentElement($root);
	return $str ? $doc->toString : $doc;
}


=head1 BUGS

None known

=head1 SEE ALSO

=over 4

=item * L<XML::Parser::Style::EasyTree>

With default settings should produce the same output as this module. Settings are similar by effect

=back

=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of XML::Hash::LX
