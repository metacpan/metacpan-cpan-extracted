# Copyright 2009 by Prasad Balan
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
package X12::Parser::Tree;
use strict;
require Exporter;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
# This allows declaration    use X12::Parser::Tree ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
	'all' => [
		qw(
		  )
	]
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT    = qw(
);
our $VERSION = '0.80';

# Preloaded methods go here.
#use X12::Parser::Tree;
#This class holds the loop structure of the X12 transaction.
#The class is populated by X12::Parser::Cf and loaded from the *.cf file.
#constructor.
sub new {
	my $self = {
		_PARENT       => undef,
		_CHILDREN     => undef,
		_NAME         => undef,
		_SEG          => undef,
		_SEG_QUAL     => undef,
		_SEG_QUAL_POS => undef,
		_DEPTH        => 0,
	};
	return bless $self;
}

sub set_name {
	my ( $self, $name ) = @_;
	$self->{_NAME} = $name;
}

sub get_name {
	my $self = shift;
	return $self->{_NAME};
}

sub is_root {
	my $self = shift;
	return ( defined $self->{_PARENT} ) ? 0 : 1;
}

sub set_parent {
	my ( $self, $parent ) = @_;
	$self->{_PARENT} = $parent;
}

sub get_parent {
	my $self = shift;
	return $self->{_PARENT};
}

sub has_children {
	my $self = shift;
	return ( defined $self->{_CHILDREN} ) ? 1 : 0;
}

sub get_child {
	my ( $self, $index ) = @_;
	return $self->{_CHILDREN}->[$index];
}

sub get_children {
	my $self = shift;
	return $self->{_CHILDREN};
}

sub get_child_count {
	my $self = shift;
	if ( defined $self->{_CHILDREN} ) {
		return scalar @{ $self->{_CHILDREN} };
	}
	return 0;
}

sub add_child {
	my ( $self, $child ) = @_;
	if ( $self->get_child_count() ) {
		$child->{_DEPTH} = $self->{_DEPTH} + 1;
		push( @{ $self->{_CHILDREN} }, $child );
	}
	else {
		$child->{_DEPTH} = $self->{_DEPTH} + 1;
		my @children;
		$self->{_CHILDREN} = \@children;
		push( @{ $self->{_CHILDREN} }, $child );
	}
}

sub set_loop_start_parm {
	my ( $self, @args ) = @_;
	$self->{_SEG} = $args[0];
	if ( $args[1] eq '' ) { $self->{_SEG_QUAL_POS} = undef; }
	else {
		$self->{_SEG_QUAL_POS} = $args[1];
		my @array = split( /,/, $args[2] );
		$self->{_SEG_QUAL} = \@array;
	}
}

sub is_loop_start {
	my ( $self, $elements ) = @_;
	if ( $self->{_SEG} eq @{$elements}[0] ) {
		if ( defined( $self->{_SEG_QUAL_POS} ) ) {
			return
			  scalar grep { /@{$elements}[$self->{_SEG_QUAL_POS}]/ }
			  @{ $self->{_SEG_QUAL} };
		}
		else {
			return 1;
		}
	}
	return 0;
}

sub get_depth {
	my $self = shift;
	return $self->{_DEPTH};
}

sub print_tree {
	my $self = shift;
	my $node = shift;
	if ( !defined $node ) { $node = $self; }
	my $pad = '  ' x $node->get_depth();
	print $pad . $node->get_name . "\n";
	for ( my $i = 0 ; $i < $node->get_child_count() ; $i++ ) {
		$self->print_tree( $node->get_child($i) );
	}
}
1;
__END__

=head1 NAME

X12::Parser::Tree - Object structure representing the X12 cf file. 

=head1 SYNOPSIS

    use X12::Parser::Tree;

    #create a new Tree object
    my $node = X12::Parser::Tree->new();

    #set the name of the node/loop
    $node->set_name('1000A');

    #set the name of the parameters used to determine start of a loop
    $node->set_loop_start_parm('NM1', '41', 1);

    #create a new Tree object and set it as the child
    my $child_node = X12::Parser::Tree->new();
    $node->add_child($child_node);

=head1 DESCRIPTION

This module represents the cf file as a object structure. This class is 
used by the L<X12::Parser> and L<X12::Parser::Cf>. Unless you plan to modify the
parser or such you would not need to access this class directly. 

=head1 AUTHOR

Prasad Poruporuthan, I<prasad@cpan.org>

=head1 SEE ALSO

L<X12::Parser>, L<X12::Parser::Cf>, L<X12::Parser::Readme>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Prasad Balan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
