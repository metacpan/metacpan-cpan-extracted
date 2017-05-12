# $Id: PYX.pm,v 1.9 2000/06/21 17:05:51 matt Exp $

package XML::PYX;

use strict;
use vars qw($VERSION);

$VERSION = '0.07';

$XML::PYX::Lame = 0;

sub encode {
	my $text = shift;
	$text =~ s/\n/\\n/g;
	return $text;
}

sub parse {
	my $output = shift;
	my $ioref;
	my $arg = shift @_;
	
	if (ref($arg) and UNIVERSAL::isa($arg, 'IO::Handler')) {
		$ioref = $arg;
	} else {
		eval {
			$ioref = *{$arg}{IO};
		};
	}
	if (!defined($ioref)) {
		die "Can't get filehandle!\n";
	}
	my $xml;
	# may have already done $ioref in parse, so rewind
	seek($ioref,0,0);
	{
		local $/;
		$xml = <$ioref>;
	}
	my $res;
	my @stack;
	while($xml =~ m/\G([^<]*)(<([\?!\/]?)([\w\-]+))?/gc) {
		my ($data, $type, $tag) = ($1, $3, $4);
#		warn "$data $type $tag\n";
		if (length $data) {
			$res .= $output->("-" . encode($data) . "\n");
		}
		
		last unless $type || $tag;
		
		if ($type eq '?') {
			if ($xml =~ m/\G\s+(.*?)\?>/gcs) {
				# processing instruction
				my $data = $1;
				$res .= $output->("?$tag " . encode($data) . "\n");
			}
			else {
				die "Invalid psuedo XML: No end to processing instruction\n";
			}
		}
		elsif ($type eq '!') {
			if ($tag eq '--') {
				# comment
				if ($xml =~ m/\G(.*?)-->/gcs) {
					# pyx doesn't support comments!
				}
				else {
					die "Invalid psuedo XML: No end to comment\n";
				}
			}
			else {
				die "Invalid tag <!$tag\n";
			}
		}
		elsif ($type eq '/') {
			# close element
			if ($tag eq $stack[0]) {
				shift @stack;
				if ($xml =~ m/\G\s*>/gc) {
					$res .= $output->(")$tag\n");
				}
				else {
					die "Invalid psuedo XML: Bad close tag\n";
				}
			}
			else {
				die "Invalid psuedo XML: Close tag mismatch\n";
			}
		}
		else {
			# start element
			unshift @stack, $tag;
			$res .= $output->("($tag\n");
			while($xml =~ m/\G(\s*(\w+)\s*=\s*(["'])(.*?)\3|>)/gcs) {
				last if $1 eq '>';
				my ($key, $val) = ($2, $4);
				$res .= $output->("A$key " . encode($val) . "\n");
			}
		}
	}
	return $res;
}

{
	package XML::PYX::Parser;
	use vars qw/@ISA/;
	
	use XML::Parser;

	@ISA = 'XML::Parser';

	sub new {
		my ($class, %args) = (@_, 'Style' => 'PYX', '_output' => sub { shift; });
		if ($args{Validating}) {
			require XML::Checker::Parser;
			@ISA = 'XML::Checker::Parser';
		}
		$class->SUPER::new(%args);
	}
	
	sub parse {
		my $self = shift;
		if ($XML::PYX::Lame) {
			return XML::PYX::parse($self->{_output}, @_);
		}
		return $self->SUPER::parse(@_);
	}
}

{
	package XML::PYX::Parser::ToCSF;
	use vars qw/@ISA/;
	
	use XML::Parser;
	
	@ISA = 'XML::Parser';
	
	sub new {
		my ($class, %args) = (@_, 'Style' => 'PYX', '_output' => sub { print shift; undef; });
		if ($args{Validating}) {
			require XML::Checker::Parser;
			@ISA = 'XML::Checker::Parser';
		}
		$class->SUPER::new(%args);
	}

	sub parse {
		my $self = shift;
		if ($XML::PYX::Lame) {
			return XML::PYX::parse($self->{_output}, @_);
		}
		return $self->SUPER::parse(@_);
	}
}

{
	package XML::Parser::PYX;

	use vars qw/$_PYX/;

	$XML::Parser::Built_In_Styles{PYX} = 1;

	sub Final {
		return $_PYX;
	}
	
	sub Init {
		undef $_PYX;
	}

	sub Char {
		my ($e, $t) = @_;
		$_PYX .= $e->{_output}->("-" . XML::PYX::encode($t) . "\n");
	}

	sub Start {
		my ($e, $tag, @attr) = @_;
		$_PYX .= $e->{_output}->("($tag\n");

		while(@attr) {
			my ($key, $val) = (shift(@attr), shift(@attr));
			$_PYX .= $e->{_output}->("A$key " . XML::PYX::encode($val) . "\n");
		}
		
	}

	sub End {
		my ($e, $tag) = @_;
		$_PYX .= $e->{_output}->(")$tag\n");
	}

	sub Proc {
		my ($e, $target, $data) = @_;
		$_PYX .= $e->{_output}->("?$target " . XML::PYX::encode($data) . "\n");
	}
}

1;
__END__

=head1 NAME

XML::PYX - XML to PYX generator

=head1 SYNOPSIS

  use XML::PYX;
  my $parser = XML::PYX::Parser->new;
  my $string = $parser->parsefile($filename);

=head1 DESCRIPTION

After reading about PYX on XML.com, I thought it was a pretty cool idea,
so I built this, to generate PYX from XML using perl. See
http://www.xml.com/pub/2000/03/15/feature/index.html for an excellent
introduction.

The package contains 2 usable packages, and 3 utilities that 
are probably currently more use than the module:

	pyx - a XML to PYX converter using XML::Parser
	pyxv - a Validating XML to PYX converter using XML::Checker::Parser
	pyxw - a PYX to XML converter
	pyxhtml - an HTML to PYX converter using HTML::TreeBuilder

All these utilities can be pipelined together, so you can have:

	pyx test.xml | grep -v "^-" | pyxw > new.xml

Which should remove all text from an XML file (leaving only tags).

The 2 packages are XML::PYX::Parser and XML::PYX::Parser::ToCSF. The
former is a direct subclass of XML::Parser that simply returns a PYX
string on a call to parse or parsefile. The latter stands for B<To
Currently Selected Filehandle>. Instead of returning a string, it sends
output directly to the currently selected filehandle. This is much better
for pipelined utilities for obvious reasons.

There's a special variable: $XML::PYX::Lame. Set it to 1 to use a "Lame"
parser that simply uses regexps. This is useful, for example, if you are
changing the input to invalid XML for some reason. You can then use
$XML::PYX::Lame = 1 to enable the non-xml parser. It does check for some
things, like balanced tags, but otherwise it's pretty lame :)

Lame mode is enabled for pyx and pyxw with the B<-l> option.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=cut
