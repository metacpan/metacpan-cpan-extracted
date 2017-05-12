=head1 CLASS
Name:	POP::POX_parser
Desc:	Class implementing a parser for POX files
	(Persistent Object {eXoskeleton,eXchange,XML})
	POX is a markup language conforming to the XML specification which
	describes class structure for persistent classes.  A POX_parser parser
	turns a POX instance into a perl data structure.
=cut
package POP::POX_parser;

$VERSION = do{my(@r)=q$Revision: 1.6 $=~/d+/g;sprintf '%d.'.'%02d'x$#r,@r};

use XML::Parser;
use POP::Environment qw/$POP_POXLIB/;
use Carp;

use vars qw/$in_isa $VERSION/;

=head2 CONSTRUCTOR
Name:	POP::POX_parser::new
Desc:	Takes no arguments, returns a new parser object, which embeds an
	XML::Parser.
=cut
sub new {
  my $this = bless {}, shift;
  $this->{'parser'} = XML::Parser->new();
  $this->{'parser'}->setHandlers(
	Start	=> sub { $this->start(@_) },
	End	=> sub { $this->end(@_) },
	Char	=> sub { $this->char(@_) },
	Proc	=> sub { $this->proc(@_) }
  );
  return $this;
}

=head2 METHOD
Name:	POP::POX_parser::parse
Desc:	When given a filename as an argument, parses it and returns the data
	structure generated from it.  If there are any problems, it will die,
	so you might want to wrap it in an eval {}.
=cut
sub parse {
  my $this = shift;
  $this->{'parser'}->parsefile(@_);
  $this->{'class'}{'version'} = $this->{'version'};
  delete $this->{'version'};
  return $this->{'class'};
}

=head2 METHOD
Name:	POP::POX_parser::start
Desc:	Used as the callback for element start tags.
=cut
sub start {
  my($this, $parser, $elem, %attrib) = @_;
  $attrib{'inherited'} = $in_isa;
  # Allow any case on the tag:
  $elem = lc($elem);
  if ($elem eq 'class') {
    push(@{$this->{'parents'}}, $this->{'class'} = \%attrib) unless $in_isa;
    $attrib{'dbname'} = $attrib{'abbr'} || lc($attrib{'name'}) unless $in_isa;
    if ($attrib{'isa'}) {
      # We have to recursively parse any classes we inherit from.
      # We use $POP_POXLIB} to help us find the POX file which contains each
      # class we derive from.
      foreach (split /\s*,\s*/, $attrib{'isa'}) {
	my $pox_file;
	unless ($pox_file = pox_find($_)) {
	  croak "Could not find POX for [$_] (POP_POXLIB=[$POP_POXLIB])";
	}
	# dynamic scoping, babeee!
	local $in_isa = $_;
	$this->{'parser'}->parsefile($pox_file);
      }
    }
  } elsif ($elem eq 'attribute') {
    push(@{$this->{'parents'}},
          $this->{'class'}{'attributes'}{$attrib{'name'}} = \%attrib);
    $attrib{'dbname'} = $attrib{'abbr'} || lc($attrib{'name'});
    if ($attrib{'hash'}) {
      $this->{'class'}{'hash_attributes'}{$attrib{'name'}} = \%attrib;
    } elsif ($attrib{'list'}) {
      $this->{'class'}{'list_attributes'}{$attrib{'name'}} = \%attrib;
    } else {
      $this->{'class'}{'scalar_attributes'}{$attrib{'name'}} = \%attrib;
    }
  } elsif ($elem eq 'participant') {
    unless ($this->{'parents'}[-1]{'type'} eq 'link') {
      croak "Can't define participant in a non-link class\n";
    }
    push(@{$this->{'parents'}},
	$this->{'class'}{'participants'}{$attrib{'name'}} = \%attrib);
	$attrib{'dbname'} = $attrib{'abbr'} || lc($attrib{'name'});
  } elsif ($elem eq 'method') {
    push(@{$this->{'parents'}},
       $this->{'class'}{'methods'}{$attrib{'name'}} = \%attrib);
  } elsif ($elem eq 'constructor') {
    push(@{$this->{'parents'}},
       $this->{'class'}{'constructors'}{$attrib{'name'}} = \%attrib);
  } elsif ($elem eq 'class-method') {
    push(@{$this->{'parents'}},
       $this->{'class'}{'class-methods'}{$attrib{'name'}} = \%attrib);
  } elsif ($elem eq 'param') {
    push(@{$this->{'parents'}},
       $this->{'parents'}[-1]{'params'}{$attrib{'name'}} = \%attrib);
  } elsif ($elem eq 'em') {
    $this->{'parents'}[-1]{'comments'} .= "<em>";
  } else {
    croak "Unknown element [$elem]\n";
  }
}

=head2 METHOD
Name:	POP::POX_parser::end
Desc:	Used as the callback for element end tags.
=cut
sub end {
  my($this, $parser, $elem) = @_;
  return if $in_isa && $elem eq 'class';
  if ($elem eq 'em') {
    $this->{'parents'}[-1]{'comments'} .= "</em>";
  } else {
    pop(@{$this->{'parents'}});
  }
}

=head2 METHOD
Name:	POP::POX_parser::char
Desc:	Used as the callback for character data. Adds to the comments key of
	the current parent element.
=cut
sub char {
  my($this, $parser, $data) = @_;
  # Ignore class-level comments if we're parsing a base class
  return if ($in_isa && $this->{'parents'}[-1] == $this->{'class'});
  $this->{'parents'}[-1]{'comments'} .= $data;
}

=head2 METHOD
Name:	POP::POX_parser::proc
Desc:	Used as the callback for processing instructions; currently only
	understands <?version ... ?>
=cut
sub proc {
  my($this, $parser, $target, $data) = @_;
  return if $in_isa;
  if ($target eq 'version') {
    # This pattern is split onto two lines so RCS doesn't muck with it.
    $data =~ /\$
	Revision:\ ([\d.]+)/x;
    $this->{'version'} = $1;
  }
}
     
=head2 METHOD
Name:	POP::POX_parser::pox_find
Desc:	Searches through $POP_POXLIB paths to find .pox file matching given
	class.
=cut
sub pox_find {
  my $class = shift;
  $class =~ s,::,/,g;
  foreach my $dir (split /:/, $POP_POXLIB) {
    if (-e "$dir/$class.pox") {
      return "$dir/$class.pox";
    }
  }
  return;
}

$VERSION = $VERSION;
