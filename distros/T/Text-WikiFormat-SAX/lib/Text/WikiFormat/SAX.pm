# $Id: SAX.pm,v 1.5 2003/01/04 00:27:25 matt Exp $

package Text::WikiFormat::SAX;

$VERSION = '0.03';
use XML::SAX::Base;
@ISA = qw(XML::SAX::Base);

use strict;
use XML::SAX::DocumentLocator;

sub _parse_bytestream {
    my ($self, $fh) = @_;
    my $parser = Wiki::SAX::Parser->new();
    $parser->set_parent($self);
    local $/;
    my $text = <$fh>;
    $parser->parse($text);
}

sub _parse_characterstream {
    my ($self, $fh) = @_;
    die "parse_characterstream not supported";
}

sub _parse_string {
    my ($self, $str) = @_;
    my $parser = Wiki::SAX::Parser->new();
    $parser->set_parent($self);
    $parser->parse($str);
}

sub _parse_systemid {
    my ($self, $sysid) = @_;
    my $parser = Wiki::SAX::Parser->new();
    $parser->set_parent($self);
    open(FILE, $sysid) || die "Can't open $sysid: $!";
    local $/;
    my $text = <FILE>;
    $parser->parse($text);
}

package Wiki::SAX::Parser;

use strict;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub set_parent {
    my $self = shift;
    $self->{parent} = shift;
}

sub parent {
    my $self = shift;
    return $self->{parent};
}

sub parse {
    my $self = shift;
    
    my $sysid = $self->parent->{ParserOptions}->{Source}{SystemId};
    $self->parent->set_document_locator(
         XML::SAX::DocumentLocator->new(
            sub { "" },
            sub { $sysid },
            sub { $self->{line_number} },
            sub { 0 },
        ),
    );
    $self->parent->start_document({});
    $self->parent->start_element(_element('wiki'));
    $self->parent->characters({Data => "\n"});
    $self->parent->comment({Data => " Text::WikiFormat::SAX v$Text::WikiFormat::SAX::VERSION "});
    $self->parent->characters({Data => "\n"});
    
    $self->parse_wiki(shift);
    
    $self->parent->end_element(_element('wiki', 1));
    $self->parent->end_document({});
}

sub start_list {
    my $self = shift;
    my $type = shift;
    $self->parent->start_element(_element("${type}list"));
    $self->parent->characters({Data => "\n"});
    $self->{in_list} = $type;
}

sub end_list {
    my $self = shift;
    $self->parent->end_element(_element("$self->{in_list}list"));
    $self->parent->characters({Data => "\n"});
    $self->{in_list} = '';
}

use vars qw($indent);
$indent = qr/^(?:\t+|\s{4,})/;

sub parse_wiki {
    my $self = shift;
    my ($text) = @_;
    foreach my $line (split(/\n/, $text)) {
	if ($line =~ /$indent(.*)$/) {
	    my $match = $1;
	    if ($match =~ /([\dA-Za-z]+)\.\s*(.*)$/) {
		# ordered list
		my $value = $1;
		my $data = $2;
		if ($self->{in_list} ne 'ordered') {
		    if ($self->{in_list}) {
			$self->end_list();
		    }
		    $self->start_list('ordered');
		}
		my $el = _element('listitem');
		_add_attrib($el, value => $value);
		$self->parent->start_element($el);
		$self->format_line($data);
		$self->parent->end_element(_element('listitem', 1));
		$self->parent->characters({Data => "\n"});
	    }
	    elsif ($match =~ /\*\s*(.*)$/) {
		# bulleted list
		my $data = $1;
		if ($self->{in_list} ne 'itemized') {
		    if ($self->{in_list}) {
			$self->end_list();
		    }
		    $self->start_list('itemized');
		}
		$self->parent->start_element(_element('listitem'));
		$self->format_line($data);
		$self->parent->end_element(_element('listitem', 1));
		$self->parent->characters({Data => "\n"});
	    }
	    else {
		# code
		if ($self->{in_list}) {
		    $self->end_list();
		}
		
		$self->parent->start_element(_element('code'));
		$self->format_line($match);
		$self->parent->end_element(_element('code', 1));
		$self->parent->characters({Data => "\n"});
	    }
	}
	else {
	    if ($self->{in_list}) {
		$self->end_list();
	    }
	    $self->format_line($line);
	}
    }
}

sub format_line {
    my $self = shift;
    my ($text) = @_;
    
    my $strong = sub {
	$self->parent->start_element(_element('strong'));
	$self->parent->characters({Data => $_[0]});
	$self->parent->end_element(_element('strong',1));
	return '';
    };
    my $emphasized = sub {
	$self->parent->start_element(_element('em'));
	$self->parent->characters({Data => $_[0]});
	$self->parent->end_element(_element('em',1));
	return '';
    };
    my $line = sub {
	$self->parent->start_element(_element('hr'));
	$self->parent->end_element(_element('hr',1));
	$self->parent->characters({Data => "\n"});
	return '';
    };
    my $link = sub {
	$self->make_link($_[0]);
	return '';
    };
    my $data = sub {
	$self->parent->characters({Data => $_[0]});
	return '';
    };
    
    $self->_format_line($text, $strong, $emphasized, $line, $link, $data);
    $self->parent->start_element(_element('br'));
    $self->parent->end_element(_element('br',1));
    $self->parent->characters({Data => "\n"});
}

sub _format_line {
    my ($self, $text, $strong, $emphasized, $line, $link, $data) = @_;
    
    if ($text =~ s/^-{4,}//) {
	$line->();
    }
    
    if ($text =~ s/^(.*?)('')/$2/) {
	$self->_format_line($1, $strong, $emphasized, $line, $link, $data);
	if ($text =~ s/^'''(.*?)'''//) {
	    $strong->($1);
	}
	elsif ($text =~ s/^''(.*?)''//) {
	    $emphasized->($1);
	}
	else {
            $text =~ s/^(.*)$//;
            $data->($1);
	}
    }
    elsif ($text =~ s/^(.*?)\[([^\]]+)\]//) {
	$self->_format_line($1, $strong, $emphasized, $line, $link, $data);
	$link->($2);
    }
    elsif ($text =~ s|^(.*?)(?<!["/>=])\b([A-Za-z]+(?:[A-Z]\w+)+)||) {
	$data->($1);
	$link->($2);
    }
    else {
	$text =~ s/^(.*)$//;
	$data->($1);
    }

    if (length($text)) {
	# warn("re-parsing $text\n");
	return $self->_format_line($text, $strong, $emphasized, $line, $link, $data);
    }
    
    return undef;
}

sub make_link {
    my ($self, $link) = @_;

    my $title;
    ($link, $title) = split(/\|/, $link, 2);
    $title ||= $link;

    my $el = _element('link');
    _add_attrib($el, href => $link);
    $self->parent->start_element($el);
    $self->parent->characters({Data => $title});
    $self->parent->end_element(_element('link'));
}

sub _element {
    my ($name, $end) = @_;
    return { 
        Name => $name,
        LocalName => $name,
        $end ? () : (Attributes => {}),
        NamespaceURI => '',
        Prefix => '',
    };
}

sub _add_attrib {
    my ($el, $name, $value) = @_;
    
    $el->{Attributes}{"{}$name"} =
      {
	  Name => $name,
	    LocalName => $name,
	    Prefix => "",
	    NamespaceURI => "",
	    Value => $value,
      };
}



1;
__END__
  
=head1 NAME

Text::WikiFormat::SAX - a SAX parser for Wiki text

=head1 SYNOPSIS

  use Text::WikiFormat::SAX;
  use XML::SAX::Writer;
  
  my $output = '';
  
  my $parser = Text::WikiFormat::SAX->new(
       Handler => XML::SAX::Writer->new(
         Output => \$output
       )
     );
  $parser->parse_string($wiki_text);
  print $output;

=head1 DESCRIPTION

This module implements a SAX parser for WikiWiki text. The code is
based on Text::WikiFormat, and so only supports the formatting that
module supports.

=cut
