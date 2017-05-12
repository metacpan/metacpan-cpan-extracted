package XML::DTD::Entity;

use XML::DTD::Component;
use XML::DTD::Error;
use URI;
use LWP::Simple;

use 5.008;
use strict;
use warnings;

our @ISA = qw(XML::DTD::Component);

our $VERSION = '0.09';


# Constructor
sub new {
  my $arg = shift;
  my $ent = shift;
  my $val = shift; # Parser called as validating
  my $uri = shift; # The URI the entity was declared in, if known

  my $cls = ref($arg) || $arg;
  my $obj = ref($arg) && $arg;

  my $self;
  if ($obj) {
    # Called as a copy constructor
    $self = { %$obj };
    bless $self, $cls;
  } else {
    # Called as the main constructor
    $self = { };
    $self->{'VALIDATING'} = $val;
    $self->{'URI'} = $uri;

    bless $self, $cls;
    $self->define('entity', $ent, '<!ENTITY', '>');
    $self->_parse($ent);
  }
  return $self;
}


# Return the entity name
sub name {
  my $self = shift;

  return $self->{'NAME'};
}


# Is the object a parameter entity
sub isparam {
  my $self = shift;

  return $self->{'PARAM'};
}


# Is the object an external entity
sub isextern {
  my $self = shift;

  return $self->{'EXTERNAL'};
}


# Return the entity value
sub value {
  my $self = shift;

  return $self->{'ENTITYDEF'};
}


# Return the URI containing the entity
sub uri {
  my $self = shift;

  return $self->{'URI'};
}


# Write an XML representation
sub writexml {
  my $self = shift;
  my $xmlw = shift;

  my $name = $self->{'NAME'};
  my $type = ($self->isparam)?'param':'gen';
  my $tstr = ($self->isparam)?$self->{'WS0'}.'%':undef;
  my $ltws = ($self->isparam)?$self->{'WS1'}:$self->{'WS0'};
  $xmlw->open('entity', {'name' => $name, 'type' => $type, 'tstr' => $tstr,
			 'ltws' => $ltws, 'rtws' => $self->{'WSRT'}});
  if ($self->isextern) {
    $xmlw->open('external', {'ltws'  => $self->{'WS2'}});
    if (defined $self->{'PUBLIC'}) {
      $xmlw->open('public', {'qchar' => $self->{'QCPUB'},
			     'ltws' => $self->{'WSPUB'}});
      $xmlw->pcdata($self->{'PUBLIC'});
      $xmlw->close;
    }
    $xmlw->open('system', {'qchar' => $self->{'QCSYS'},
			   'ltws' => $self->{'WSSYS'}});
    $xmlw->pcdata($self->{'SYSTEM'});
    $xmlw->close;
    $xmlw->close;
  } else {
    $xmlw->open('internal', {'qchar' => $self->{'QUOTECHAR'},
			     'ltws'  => $self->{'WS2'}});
    $xmlw->pcdata($self->value);
    $xmlw->close;
  }
  $xmlw->close;
}


# Parse the entity declaration
sub _parse {
  my $self = shift;
  my $entdcl = shift;

  if ($entdcl =~ /<\!ENTITY(\s+)(%?)(\s*)([\w\.:\-_]+)(\s+)/) {
    # Determine whether the entity is parameter or general
    $self->{'WS0'} = $1;
    if ($2 eq '%') {
      $self->{'PARAM'} = 1;
    } else {
      $self->{'PARAM'} = 0;
    }
    $self->{'WS1'} = _lftoce($3);
    $self->{'NAME'} = $4;
    $self->{'WS2'} = _lftoce($5);
    my $entdef = $';
    # Determine whether the entity is external or internal
    if ($entdef =~ /^(SYSTEM|PUBLIC)(\s+)([\"\'])(.*?)\3(\s*)(?:([\"\'])(.*?)\6)?(\s*)>$/s) {
      $self->{'EXTERNAL'} = 1;
      if ($1 eq 'PUBLIC') {
	$self->{'WSPUB'} = _lftoce($2);
	$self->{'QCPUB'} = $3;
	$self->{'PUBLIC'} = $4;
	$self->{'WSSYS'} = _lftoce($5);
	$self->{'QCSYS'} = $6;
	$self->{'SYSTEM'} = $7;
      } else {
	$self->{'WSSYS'} = _lftoce($2);
	$self->{'QCSYS'} = $3;
	$self->{'SYSTEM'} = $4;
	throw XML::DTD::Error("SYSTEM entity has two identifiers in ".
			      "definition: $entdcl", $self)
	  if (defined $7);
      }
      $self->{'WSRT'} = _lftoce($8);
      # Need to access external entities here
      $self->_getexternal if ($self->{'VALIDATING'} and $self->{'PARAM'});
    } elsif ($entdef =~ /^([\"\'])(.*?)\1(\s*)>$/s) {
      $self->{'EXTERNAL'} = 0;
      $self->{'QUOTECHAR'} = $1; # " -> &quot;   ' -> &apo;
      $self->{'ENTITYDEF'} = $2;
      $self->{'WSRT'} = _lftoce($3);
    } else {
      throw XML::DTD::Error("Error parsing entity definition: $entdcl",
			    $self);
    }
  } else {
    throw XML::DTD::Error("Error parsing entity name and type in definition".
			  ": $entdcl",$self);
  }
}



# Substitute the &#xA; char entity for linefeeds
sub _lftoce {
  my $txt = shift;

  $txt =~ s/\n/\&\#xA;/g;
  return $txt;
}

# Get the content of external parameter entities
sub _getexternal {
  my $self = shift;

  my $absuri = URI->new_abs($self->{'SYSTEM'}, URI->new($self->{'URI'}));
  ##print "Fetch $self->{'NAME'} from ", $absuri->as_string, "\n";
  my $xent = LWP::Simple::get($absuri);
  throw XML::DTD::Error("Error fetching external entity: $absuri")
    if (!defined $xent);
  # Strip the leading textdef if there is one
  $xent =~ s/^<\?.*\?>//s;
  throw XML::DTD::Error("External entity $absuri has no text declaration",
			$self) if (!defined $&);
  $self->{'ENTITYDEF'} = $xent;
}

1;
__END__

=head1 NAME

XML::DTD::Entity - Perl module representing an entity declaration in a DTD

=head1 SYNOPSIS

  use XML::DTD::Entity;

  my $ent = XML::DTD::Entity->new('<!ENTITY a "b">');

=head1 DESCRIPTION

XML::DTD::Entity is a Perl module representing an entity declaration
in a DTD. The following methods are provided.

=over 4

=item B<new>

 my $ent = XML::DTD::Entity->new('<!ENTITY a "b">');

Construct a new XML::DTD::Entity object.

=item B<name>

 print $ent->name;

Return the entity name

=item B<isparam>

 if ($ent->isparam) {
 ...
 }

Determine whether the object represents a parameter entity

=item B<isextern>

 if ($ent->isextern) {
 ...
 }

Determine whether the object represents an external entity

=item B<value>

 print $ent->value;

Return the entity value

=item B<writexml>

 $xo = new XML::Output({'fh' => *STDOUT});
 $ent->writexml($xo);

Write an XML representation of the entity.

=back

=head1 SEE ALSO

L<XML::DTD>, L<XML::DTD::Component>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2010 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the GPL file included in this distribution.

=head1 ACKNOWLEDGMENTS

Peter Lamb E<lt>Peter.Lamb@csiro.auE<gt> added fetching of external
entities and improved entity substitution.

=cut
