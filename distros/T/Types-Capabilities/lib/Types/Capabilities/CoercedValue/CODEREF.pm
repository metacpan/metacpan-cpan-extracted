use 5.010001;
use strict;
use warnings;

package Types::Capabilities::CoercedValue::CODEREF;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003000';

use Types::Common qw( assert_CodeRef );

sub new {
	my ( $class, $cb ) = @_;
	assert_CodeRef( $cb );

	my $new = bless \$cb, $class;
	Internals::SvREADONLY( $new, 1 );

	return $new;
}

sub each {
	my ( $self, $coderef ) = @_;
	assert_CodeRef( $coderef );

	while ( 1 ) {
		last unless my @got = $$self->();
		$coderef->($_) for @got;
	}

	return $self;
}

sub grep {
	my ( $self, $coderef ) = @_;
	assert_CodeRef( $coderef );
	
	if ( wantarray ) {
		my @r;
		while ( 1 ) {
			last unless my @got = $$self->();
			push @r, grep { $coderef->($_) } @got;
		}
		return @r;
	}
	
	my $cb = $$self;
	my @list;
	my $new_cb = sub {
		return shift @list if @list;
		my @got = $$self->() or return;
		push @list, grep { $coderef->($_) } @got;
		return shift @list if @list;
		return;
	};
	return __PACKAGE__->new( $new_cb );
}

sub map {
	my ( $self, $coderef ) = @_;
	assert_CodeRef( $coderef );
	
	if ( wantarray ) {
		my @r;
		while ( 1 ) {
			last unless my @got = $$self->();
			push @r, map { $coderef->($_) } @got;
		}
		return @r;
	}

	my $cb = $$self;
	my @list;
	my $new_cb = sub {
		return shift @list if @list;
		my @got = $$self->() or return;
		push @list, map { $coderef->($_) } @got;
		return shift @list if @list;
		return;
	};
	return __PACKAGE__->new( $new_cb );
}

sub enqueue {
	my ( $self, @items ) = @_;
	$$self->($_) for @items;
	return $self;
}

sub dequeue {
	my ( $self ) = @_;
	return scalar $$self->();
}

sub push {
	my ( $self, @items ) = @_;
	$$self->($_) for @items;
	return $self;
}

sub pop {
	my ( $self ) = @_;
	return scalar $$self->();
}

no Types::Common;

__PACKAGE__
__END__
