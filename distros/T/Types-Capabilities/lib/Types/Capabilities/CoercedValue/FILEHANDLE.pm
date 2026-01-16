use 5.010001;
use strict;
use warnings;

package Types::Capabilities::CoercedValue::FILEHANDLE;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003000';

our $INPUT_RECORD_SEPARATOR = "\n";
our $AUTO_SEEK              = !!1;
our $AUTO_CHOMP             = !!1;
our $PATHTINY_FH_OPTIONS    = { locked => 1 };
our $PATHTINY_FH_BINMODE    = ':utf8';

use Types::Common qw( assert_FileHandle assert_CodeRef assert_Str assert_HashRef assert_Bool );
use Types::Path::Tiny qw( is_File );

sub new {
	my ( $class, $fh ) = @_;

	assert_HashRef( $PATHTINY_FH_OPTIONS );
	assert_Str( $PATHTINY_FH_BINMODE );

	if ( is_File $fh ) {
		if ( $Path::Tiny::VERSION >= 0.066 ) {
			$fh = $fh->filehandle( { %$PATHTINY_FH_OPTIONS }, '<', $PATHTINY_FH_BINMODE );
		}
		else {
			my $filename = $fh->stringify;
			undef $fh;
			open $fh, '<', $filename;
			binmode( $fh, $PATHTINY_FH_BINMODE );
		}
	}

	assert_FileHandle( $fh );

	my $new = bless {
		fh         => $fh,
		auto_seek  => assert_Bool( $AUTO_SEEK ),
		auto_chomp => assert_Bool( $AUTO_CHOMP ),
		input_rs   => defined( $INPUT_RECORD_SEPARATOR ) ? assert_Str( $INPUT_RECORD_SEPARATOR ) : undef,
	}, $class;
	Internals::SvREADONLY( $new, 1 );
	Internals::SvREADONLY( $new->{auto_seek},  1 );
	Internals::SvREADONLY( $new->{auto_chomp}, 1 );
	Internals::SvREADONLY( $new->{input_rs},   1 );

	return $new;
}

sub count {
	my ( $self ) = @_;

	my $fh = $self->{fh};
	seek( $fh, 0, 0 ) if $self->{auto_seek};
	local $/ = $self->{input_rs};

	my $r =()= <$fh>;

	return $r;
}

sub each {
	my ( $self, $coderef ) = @_;
	assert_CodeRef( $coderef );

	my $fh = $self->{fh};
	seek( $fh, 0, 0 ) if $self->{auto_seek};
	local $/ = $self->{input_rs};

	while ( <$fh> ) {
		chomp if $self->{auto_chomp};
		$coderef->( $_ );
	}

	return $self;
}

sub grep {
	my ( $self, $coderef ) = @_;
	assert_CodeRef( $coderef );

	# No need to gather results
	return $self->each( $coderef ) if !defined wantarray;

	my $fh = $self->{fh};
	seek( $fh, 0, 0 ) if $self->{auto_seek};
	local $/ = $self->{input_rs};

	my @r;
	while ( <$fh> ) {
		chomp if $self->{auto_chomp};
		push @r, $_ if $coderef->( $_ );
	}

	return @r if wantarray;

	require Types::Capabilities::CoercedValue::ARRAYREF;
	return Types::Capabilities::CoercedValue::ARRAYREF->new( \@r );
}

sub join {
	my ( $self, $sep ) = @_;
	$sep = '' if !defined $sep;

	my $fh = $self->{fh};
	seek( $fh, 0, 0 ) if $self->{auto_seek};
	local $/ = $self->{input_rs};

	my @r = <$fh>;
	chomp @r if $self->{auto_chomp};

	return join( $sep, @r );
}

sub map {
	my ( $self, $coderef ) = @_;
	assert_CodeRef( $coderef );

	# No need to gather results
	return $self->each( $coderef ) if !defined wantarray;

	my $fh = $self->{fh};
	seek( $fh, 0, 0 ) if $self->{auto_seek};
	local $/ = $self->{input_rs};

	my @r;
	while ( <$fh> ) {
		chomp if $self->{auto_chomp};
		push @r, $coderef->( $_ );
	}

	return @r if wantarray;

	require Types::Capabilities::CoercedValue::ARRAYREF;
	return Types::Capabilities::CoercedValue::ARRAYREF->new( \@r );
}

sub reverse {
	my ( $self ) = @_;

	my $fh = $self->{fh};
	seek( $fh, 0, 0 ) if $self->{auto_seek};
	local $/ = $self->{input_rs};

	my @r = do {
		my @tmp = <$fh>;
		chomp @tmp if $self->{auto_chomp};
		reverse( @tmp );
	};

	return @r if wantarray;

	require Types::Capabilities::CoercedValue::ARRAYREF;
	return Types::Capabilities::CoercedValue::ARRAYREF->new( \@r );
}

sub sort {
	my $self = shift;

	my $fh = $self->{fh};
	seek( $fh, 0, 0 ) if $self->{auto_seek};
	local $/ = $self->{input_rs};

	my @r = <$fh>;
	chomp @r if $self->{auto_chomp};

	require Types::Capabilities::CoercedValue::ARRAYREF;
	return Types::Capabilities::CoercedValue::ARRAYREF->new( \@r )->sort( @_ );
}

no Types::Common;
no Types::Path::Tiny;

__PACKAGE__
__END__
