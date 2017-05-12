package XML::Parser::Lite::Tree;

use 5.006;
use strict;
use warnings;
use XML::Parser::LiteCopy;

our $VERSION = '0.14';

use vars qw( $parser );

sub instance {
	return $parser if $parser;
	$parser = __PACKAGE__->new;
}

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	my %opts = (ref $_[0]) ? ((ref $_[0] eq 'HASH') ? %{$_[0]} : () ) : @_;
	$self->{opts} = \%opts;

	$self->{__parser} = new XML::Parser::LiteCopy
		Handlers => {
			Start	=> sub { $self->_start_tag(@_); },
			Char	=> sub { $self->_do_char(@_); },
			CData	=> sub { $self->_do_cdata(@_); },
			End	=> sub { $self->_end_tag(@_); },
			Comment	=> sub { $self->_do_comment(@_); },
			PI	=> sub { $self->_do_pi(@_); },
			Doctype	=> sub { $self->_do_doctype(@_); },
		};
	$self->{process_ns} = $self->{opts}->{process_ns} || 0;
	$self->{skip_white} = $self->{opts}->{skip_white} || 0;

	return $self;
}

sub parse {
	my ($self, $content) = @_;

	my $root = {
		'type' => 'root',
		'children' => [],
	};

	$self->{tag_stack} = [$root];

	$self->{__parser}->parse($content);

	$self->cleanup($root);

	if ($self->{skip_white}){
		$self->strip_white($root);
	}

	if ($self->{process_ns}){
		$self->{ns_stack} = {};
		$self->mark_namespaces($root);
	}

	return $root;
}

sub _start_tag {
	my $self = shift;
	shift;

	my $new_tag = {
		'type' => 'element',
		'name' => shift,
		'attributes' => {},
		'children' => [],
	};

	while (my $a_name = shift @_){
		my $a_value = shift @_;
		$new_tag->{attributes}->{$a_name} = $a_value;
	}

	push @{$self->{tag_stack}->[-1]->{children}}, $new_tag;
	push @{$self->{tag_stack}}, $new_tag;
	1;
}

sub _do_char {
	my $self = shift;
	shift;

	for my $content(@_){

		my $new_tag = {
			'type' => 'text',
			'content' => $content,
		};

		push @{$self->{tag_stack}->[-1]->{children}}, $new_tag;
	}
	1;
}

sub _do_cdata {
	my $self = shift;
	shift;

	for my $content(@_){

		my $new_tag = {
			'type' => 'cdata',
			'content' => $content,
		};

		push @{$self->{tag_stack}->[-1]->{children}}, $new_tag;
	}
	1;
}

sub _end_tag {
	my $self = shift;

	pop @{$self->{tag_stack}};
	1;
}

sub _do_comment {
	my $self = shift;
	shift;

	for my $content(@_){

		my $new_tag = {
			'type' => 'comment',
			'content' => $content,
		};

		push @{$self->{tag_stack}->[-1]->{children}}, $new_tag;
	}
	1;
}

sub _do_pi {
	my $self = shift;
	shift;

	push @{$self->{tag_stack}->[-1]->{children}}, {
		'type' => 'pi',
		'content' => shift,
	};
	1;
}

sub _do_doctype {
	my $self = shift;
	shift;

	push @{$self->{tag_stack}->[-1]->{children}}, {
		'type' => 'dtd',
		'content' => shift,
	};
	1;
}

sub mark_namespaces {
	my ($self, $obj) = @_;

	my @ns_keys;

	#
	# mark
	#

	if ($obj->{type} eq 'element'){

		#
		# first, add any new NS's to the stack
		#

		my @keys = keys %{$obj->{attributes}};

		for my $k(@keys){

			if ($k =~ /^xmlns:(.*)$/){

				push @{$self->{ns_stack}->{$1}}, $obj->{attributes}->{$k};
				push @ns_keys, $1;
				delete $obj->{attributes}->{$k};
			}

			if ($k eq 'xmlns'){

				push @{$self->{ns_stack}->{__default__}}, $obj->{attributes}->{$k};
				push @ns_keys, '__default__';
				delete $obj->{attributes}->{$k};
			}
		}


		#
		# now - does this tag have a NS?
		#

		if ($obj->{name} =~ /^(.*?):(.*)$/){

			$obj->{local_name} = $2;
			$obj->{ns_key} = $1;
			$obj->{ns} = $self->{ns_stack}->{$1}->[-1];
		}else{
			$obj->{local_name} = $obj->{name};
			$obj->{ns} = $self->{ns_stack}->{__default__}->[-1];
		}


		#
		# finally, add xpath-style namespace nodes
		#

		$obj->{namespaces} = {};

		for my $key (keys %{$self->{ns_stack}}){

			if (scalar @{$self->{ns_stack}->{$key}}){

				my $uri = $self->{ns_stack}->{$key}->[-1];
				$obj->{namespaces}->{$key} = $uri;
			}
		}
	}


	#
	# descend
	#

	if ($obj->{type} eq 'root' || $obj->{type} eq 'element'){

		for my $child (@{$obj->{children}}){

			$self->mark_namespaces($child);
		}
	}


	#
	# pop from stack
	#

	for my $k (@ns_keys){
		pop @{$self->{ns_stack}->{$k}};
	}
}

sub strip_white {
	my ($self, $obj) = @_;

	if ($obj->{type} eq 'root' || $obj->{type} eq 'element'){

		my $new_kids = [];

		for my $child (@{$obj->{children}}){

			if ($child->{type} eq 'text'){

				if ($child->{content} =~ m/\S/){

					push @{$new_kids}, $child;
				}

			}elsif ($child->{type} eq 'element'){

				$self->strip_white($child);
				push @{$new_kids}, $child;
			}else{
				push @{$new_kids}, $child;
			}
		}

		$obj->{children} = $new_kids;
	}
}

sub cleanup {
	my ($self, $obj) = @_;

	#
	# cleanup PIs
	#

	if ($obj->{type} eq 'pi'){

		my ($x, $y) = split /\s+/, $obj->{content}, 2;
		$obj->{target} = $x;
		$obj->{content} = $y;
	}


	#
	# cleanup DTDs
	#

	if ($obj->{type} eq 'dtd'){

		my ($x, $y) = split /\s+/, $obj->{content}, 2;
		$obj->{name} = $x;
		$obj->{content} = $y;
	}


	#
	# recurse
	#
	
	if ($obj->{type} eq 'root' || $obj->{type} eq 'element'){

		for my $child (@{$obj->{children}}){

			$self->cleanup($child);
		}
	}
}


1;
__END__

=head1 NAME

XML::Parser::Lite::Tree - Lightweight XML tree builder

=head1 SYNOPSIS

  use XML::Parser::Lite::Tree;

  my $tree_parser = XML::Parser::Lite::Tree::instance();
  my $tree = $tree_parser->parse($xml_data);

    OR

  my $tree = XML::Parser::Lite::Tree::instance()->parse($xml_data);

=head1 DESCRIPTION

This is a singleton class for parsing XML into a tree structure. How does this
differ from other XML tree generators? By using XML::Parser::Lite, which is a
pure perl XML parser. Using this module you can tree-ify simple XML without
having to compile any C.


For example, the following XML:

  <foo woo="yay"><bar a="b" c="d" />hoopla</foo>


Parses into the following tree:

          'children' => [
                          {
                            'children' => [
                                            {
                                              'children' => [],
                                              'attributes' => {
                                                                'a' => 'b',
                                                                'c' => 'd'
                                                              },
                                              'type' => 'element',
                                              'name' => 'bar'
                                            },
                                            {
                                              'content' => 'hoopla',
                                              'type' => 'text'
                                            }
                                          ],
                            'attributes' => {
                                              'woo' => 'yay'
                                            },
                            'type' => 'element',
                            'name' => 'foo'
                          }
                        ],
          'type' => 'root'
        };


Each node contains a C<type> key, one of C<root>, C<element> and C<text>. C<root> is the 
document root, and only contains an array ref C<children>. C<element> represents a normal
tag, and contains an array ref C<children>, a hash ref C<attributes> and a string C<name>.
C<text> nodes contain only a C<content> string.


=head1 METHODS

=over 4

=item C<instance()>

Returns an instance of the tree parser.

=item C<new( options... )>

Creates a new parser. Valid options include C<process_ns> to process namespaces.

=item C<parse($xml)>

Parses the xml in C<$xml> and returns the tree as a hash ref.

=back


=head1 AUTHOR

Copyright (C) 2004-2008, Cal Henderson, E<lt>cal@iamcal.comE<gt>


=head1 SEE ALSO

L<XML::Parser::Lite>.

=cut
