###########################################################################
### Trinket::Directory::FilterParser::LDAP
###
### Foo
###
### $Id: LDAP.pm,v 1.1.1.1 2001/02/15 18:47:50 deus_x Exp $
###
### TODO:
###
###########################################################################

package Trinket::Directory::FilterParser::LDAP;

use strict;
use vars qw($VERSION @ISA @EXPORT $DESCRIPTION $AUTOLOAD);
no warnings qw( uninitialized );
use Carp qw( confess );

# {{{ Begin POD

=head1 NAME

Trinket::Directory::FilterParser::LDAP - Handle RFC1960 search filters

=head1 ABSTRACT

Accept an LDAP-like search filter to find objects.

=head1 SYNOPSIS

 my @objs = $serializer->Search
   ('(&(parent=1)(objectclass=Iaido::Object::Folder))');

 my @objs = $serializer->Search
   (qq^
       (&
         (path~=/hivemind/*)
         (objectclass=Iaido::Object::Hivemind::Task)
         (| (parent=2378)(parent=2124)(parent=2308)(parent=3217) )
         (| (author=1949)(author=4158) )
         (& (created>=883976400)(created<=947307600) )
         (closed=0)
        )
     ^);

=head1 DESCRIPTION

The parse_filter() method accepts a filter string, based on and
mostly compatible with RFC1960 (http://www.ietf.org/rfc/rfc1960.txt),
the string representation format of Lightweight Directory Access Protocol
(LDAP) search filters.  (TODO: Detail what features, if any, of the spec
are not supported)

=cut

# }}}

# {{{ METADATA

BEGIN
  {
    $VERSION      = "0.0";
    @ISA          = qw( Trinket::Directory::FilterParser );
    $DESCRIPTION  = 'LDAP (RFC1960) search filter parser';
  }

# }}}

use Trinket::Directory::FilterParser;

# {{{ EXPORTS

=head1 EXPORTS

TODO

=cut

# }}}

# {{{ METHODS

=head1 METHODS

=over 4

=cut

# }}}

# {{{ init(): Object initializer

sub init {
    no strict 'refs';
    my ($self, $props) = @_;
}

# }}}

### To give credit where credit is due:  LDAP search filter processing was
### borrowed via cut and paste from Graham Barr's Net::LDAP::Filter module

### Regular expressions to recognize LDAP attributes, operators, and
### search values
my($Attr)  = qw{  [-;.:\d\w]*[-;\d\w] };
my($Op)    = qw{  ~=|<=|>=|<|>|=      };
my($Value) = qw{  (?:\\.|[^\\()]+)*   };

### Define a mapping between LDAP filter operators to search filter
### LoL node names
# my %Op =
# 	qw(
# 		 &   FILTER_AND
# 		 |   FILTER_OR
# 		 !   FILTER_NOT
# 		 =   FILTER_EQ
# 		 ~=  FILTER_APPROX
# 		 >   FILTER_GT
# 		 >=  FILTER_GE
# 		 <   FILTER_LT
# 		 <=  FILTER_LE
# 		);
my %Op =
	qw(
     &   AND
     |   OR
     !   NOT
     =   EQ
     ~=  APPROX
     >   GT
     >=  GE
     <   LT
     <=  LE
    );

### Reverse the LDAP op to node name mapping.
my %Rop = reverse %Op;

### Define a mapping of search filter LoL node names to compilation methods
my %node_methods =
	(
	 'FILTER_AND'    => 'sql_and_seq',
	 'FILTER_OR'     => 'sql_or_seq',
	 'FILTER_NOT'    => 'sql_not_seq',
	 'FILTER_EQ'     => 'sql_leaf',
	 'FILTER_APPROX' => 'sql_leaf',
	 'FILTER_GT'     => 'sql_leaf',
	 'FILTER_GE'     => 'sql_leaf',
	 'FILTER_LT'     => 'sql_leaf',
	 'FILTER_LE'     => 'sql_leaf',
	);

### Define a mapping of search filter LoL leaf node names to SQL operators.
my %leaf_sql_ops =
	(
	 'FILTER_EQ'     => '=',
	 'FILTER_APPROX' => ' LIKE ',
	 'FILTER_GT'     => '>',
	 'FILTER_GE'     => '>=',
	 'FILTER_LT'     => '<',
	 'FILTER_LE'     => '<=',
	);

# {{{ parse: Parse a search filter into an LoL

sub parse {
	my ($self, $filter) = @_;
	
	my @stack = ();   # stack
	my $cur = [];
	
	# Algorithm depends on /^\(/;
	$filter =~ s/^\s*//;		
	$filter = "(" . $filter . ")" unless $filter =~ /^\(/;
	
	while (length($filter)) {
		# Process the start of  (& (...)(...))			
		if ($filter =~ s/^\(\s*([&|!])\s*//) {
			my $n = [];                   # new list to hold filter elements
			push(@$cur, $Op{$1}, $n);
			push(@stack,$cur);    # push current list on the stack
			$cur = $n;
			next;
		}
		
		# Process the end of  (& (...)(...))			
		if ($filter =~ s/^\)\s*//o) {
			$cur = pop @stack;
			last unless @stack;
			next;
		}
		
		# present is a special case (attr=*)
		#if ($filter =~ s/^\(\s*($Attr)=\*\)\s*//o)
		#	{ push(@$cur, FILTER_PRESENT => $1); next; }
		
		# process (attr op string)
		if ($filter =~ s/^\(\s*($Attr)\s*($Op)($Value)\)\s*//o)
		  { push(@$cur, encode($1,$2,$3)); next; }

		# If we get here then there is an error in the filter string
		# so exit loop with data in $filter
		last;
	}
	
	if (length $filter) {
		# If we have anything left in the filter, then there is a problem
		confess("Bad filter, error before " . substr($filter,0,20));
		return undef;
	}

	return $cur;
}

# }}}
# {{{ encode: Encode a leaf filter node into the LoL

sub encode {
	my($attr,$op,$val) = @_;
	return ($Op{$op} =>	[ STRING => $attr, STRING => unescape($val) ]);
}

# }}}
# {{{ escape: Escape 'illegal' characters in the filter

sub escape {
	$_[0] =~ s/([\\\(\)\*\0])/sprintf("\\%02x",ord($1))/sge;
	$_[0];
}

# }}}
# {{{ unescape: Unescape 'illegal' characters in the filter

sub unescape {
	$_[0] =~ s/\\([\da-fA-F]{2}|.)/length($1) == 1 ? $1 : chr(hex($1))/soxeg;
	$_[0];
}

# }}}

# {{{ DESTROY

sub DESTROY
  {
    ## no-op to pacify warnings
  }

# }}}

# {{{ End POD

=back

=head1 AUTHOR

Maintained by Leslie Michael Orchard <F<deus_x@pobox.com>>

=head1 COPYRIGHT

Copyright (c) 2000, Leslie Michael Orchard.  All Rights Reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

# }}}

1;
__END__

