# Copyright 2009 by Prasad Balan
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
package X12::Parser::Cf;
use strict;
require Exporter;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
# This allows declaration    use X12::Parser::Cf ':all';
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
use X12::Parser::Tree;

sub new {
	my $self = { _LINES => undef, };
	return bless $self;
}

sub load {
	my $self   = shift;
	my %params = @_;

	#open the config file and read it into array
	open( FILE, $params{file} )
	  || die "error: cannot open cf file $params{file}\n";
	@{ $self->{_LINES} } = <FILE>;
	chomp( @{ $self->{_LINES} } );
	close(FILE);

	#create the root tree object
	my $root = X12::Parser::Tree->new();
	$root->set_name("X12");
	my $pos = $self->_get_loop_pos("LOOPS");

	#parse the LOOPS section of the config file
	for ( my $i = $pos ; $i < scalar @{ $self->{_LINES} } ; $i++ ) {
		if ( $self->{_LINES}->[$i] !~ /^[a-zA-Z0-9#]/ ) {
			last;
		}
		else {
			$self->_parse_loop( $root, $self->{_LINES}->[$i] );
		}
	}
	return $root;
}

#get the position of a loop section e.g. [2300]
sub _get_loop_pos {
	my ( $self, $loop ) = @_;
	for ( my $i = 0 ; $i < @{ $self->{_LINES} } ; $i++ ) {
		if ( $self->{_LINES}->[$i] =~ /^\[$loop\]/ ) {
			return $i + 1;
		}
	}
	return undef;
}

sub _parse_loop {
	my ( $self, $node, $loop ) = @_;
	my $pos   = $self->_get_loop_pos($loop);
	my $end   = undef;
	my $child = X12::Parser::Tree->new();
	$child->set_name($loop);
	if ( $self->{_LINES}->[$pos] =~ /^segment=/ ) {
		$end = substr $self->{_LINES}->[$pos], 8;
	}
	$child->set_loop_start_parm( split( /:/, $end ) );
	$child->set_parent($node);
	$node->add_child($child);
	for ( my $i = $pos ; $i < scalar( @{ $self->{_LINES} } ) ; $i++ ) {
		if ( $self->{_LINES}->[$i] =~ /^segment=/ ) {
			next;
		}
		if ( $self->{_LINES}->[$i] =~ /^loop=/ ) {
			$end = substr $self->{_LINES}->[$i], 5;
			$self->_parse_loop( $child, $end );
		}
		if ( $self->{_LINES}->[$i] !~ /^[a-zA-Z0-9#]/ ) {
			last;
		}
	}
}
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

X12::Parser::Cf - Perl module for reading X12 configuration files.

=head1 SYNOPSIS

    use X12::Parser::Cf;

    # Create a X12::Parser::Cf object
    my $cf = new X12::Parser::Cf;

    # Read/load a cf file
    $cf->load ( file => '837_004010X098.cf' );

=head1 DESCRIPTION

X12::Parser::Cf module is created to read the configuration files that 
are created for parsing X12 transaction files. This module is used in
the L<X12::Parser> module and is not designed for independent usage.

Note that this module does not do syntax checking of the configuration 
file. The user should ensure that he has got the cf file correct.

Read the L<X12::Parser::Readme> man page for details.

The sample cf files provided with this package are good to the best of
the authors knowledge. However the user should ensure the validity of
these files. The user may use them as is at his own risk.


=head1 AUTHOR

Prasad Balan, I<prasad@cpan.org>

=head1 SEE ALSO

L<X12::Parser>, L<X12::Parser::Readme>, L<X12::Parser::Tree> 

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Prasad Balan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
