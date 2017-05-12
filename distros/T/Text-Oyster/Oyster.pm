package Text::Oyster;

# $Id: Oyster.pm,v 1.12 2003/06/27 15:38:38 steve Exp $

# Copyright 2000-2001 by Steve McKay. All rights reserved.
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use Carp;
use vars qw( @ISA $VERSION );
# can we convert to use the base pragma yet?
use Parse::Tokens;
@ISA = ('Parse::Tokens');

$VERSION = 0.32;

sub new
{
	my( $class, $params ) = @_;
	my $self = $class->SUPER::new;
	$self->delimiters( ['<?','?>'] );	# default delimiters
	$self->package( 'Safe' );			# default package
	$self->init( $params );
	return $self;
}

sub init
{
	my( $self, $params ) = @_;
	no strict 'refs';
	my $hash;
	for ( keys %$params )
	{
		my $ref = lc $_;
		if( $_ eq 'hash' )
		{
			$hash = $params->{$_};
			next;
		}
		$self->$ref( $params->{$_} );
	}
	$self->hash( $hash ) if( defined $hash );
	use strict;
}

sub hash
{
	my( $self, $val ) = @_;
	if ( $val ){
	#	$self->_uninstall( $self->{'hash'} ) if $self->{'hash'};
	#	$self->cleanup( $self->package() );
		$self->{'hash'} = $val;
		$self->_install( $val );
	}
	return $self->{'hash'};
}

sub package
{
	my( $self, $val ) = @_;
	$self->{'package'} = $val if $val;
	return $self->{'package'};
}

sub inline_errs
{
	my( $self, $val ) = @_;
	$self->{'inline_errs'} = $val if $val;
	return $self->{'inline_errs'};
}

sub autoclean
{
	my( $self, $val ) = @_;
	$self->{'autoclean'} = $val if $val;
	return $self->{'autoclean'};
}

sub file
{
	my( $self, $val ) = @_;
	if( $val )
	{
		$self->{'file'} = $val;
		# always use the text accessor as it handles cache flushing
		$self->text( &_get_file( $self->{'file'} ) );
	}
	return $self->{'file'};
}

sub parsed
{
	my( $self ) = @_;
	return $self->{'parsed'};
}

sub parse
{
	# overide SUPER::parse
	my( $self, $params ) = @_;
	$self->{'parsed'} = undef;
	$self->init( $params );
	return unless $self->text();
	$self->SUPER::parse();
	return $self->{'parsed'};
}

sub token
{
	# overide SUPER::token
	my( $self, $token) = @_;
	my $package = $self->package();
	no strict 'vars';
	$self->{'parsed'} .= eval qq{
		package $package;
		$token->[1];
	};
	if( $@ ){
		carp $@;
		$self->{'parsed'} .= $@ if $self->inline_errs();
	}
	use strict;
}

sub ether
{
	# overide SUPER::ether

	my( $self, $text ) = @_;
	$self->{'parsed'} .= $text;
}

sub cleanup
{
	# clean up the contents of our package
	# called prior to the installation of a new hash

	my( $self, $package ) = @_;

	return if $package eq 'main';
	no strict 'refs', 'vars';
	*stash = *{"${package}::"};
	for( keys %stash )
	{
		*alias = $stash{$_};
		$alias = undef if( defined $alias );
		@alias = () if( defined @alias );
		%alias = () if( defined %alias )
	}
	use strict;
	return 1;
}

sub DESTROY
{
	my( $self ) = @_;
	$self->cleanup( $self->package() ) if $self->autoclean();
	return;
}

sub _install
{
	# install a given hash in a package for later use

	my( $self, $hash ) = @_;
	my $package = $self->package();
	no strict 'refs';
	for( keys %{$hash} )
	{
	# why if defined?
	#	next unless defined $hash->{$_};
		*{$package."::$_"} = \$hash->{$_};
	}
	use strict;
	return 1;
}

sub _uninstall
{
	# clean up the contents of our package
	# called prior to the installation of a new hash

	my( $self, $hash ) = @_;
	my $package = $self->package();
	no strict 'refs';
	for( keys %{$hash} )
	{
		*{$package."::$_"} = undef;
	}
	use strict;
	return 1;
}

sub _get_file
{
	my( $file ) = @_;
	local *IN;
	open IN, $file || return;
   	local $/;
	my $text = <IN>;
	close IN;
	return $text;
}

1;

__END__

=head1 NAME

Text::Oyster - evaluate perl code embedded in text.

=head1 SYNOPSIS

  use Text::Oyster;

  my $o = new Text::Oyster ({
      hash => {
          name => 'Santa Claus',
          num_presents => 9000
      },
      delimiters => [['<?','?>']],
      text => q{
          Me llamo <? $name ?>.
          Tengo <? $num_presents ?> regalos.
      }
  });

  print $o->parse();

=head1 DESCRIPTION

C<Text::Oyster> is a module for evaluating perl embedded in text.

=head1 METHODS

=over 10

=item new()

Initializes an Oyster object. Pass parameter as a hash reference. Optionally pass: delimiters, hash, package, text, file, inline_errs (see descriptions below).

=item hash()

Installs values identified by a given hash reference into a package under which to evaluate perl tokens.

=item text()

Install the text to be parsed as the template.

=item file()

Specify a file containing the text to be parsed as the template.

=item inline_errs()

Specify how to handle error messages generated during the evaluation of perl tokens. a true value = inline, a flase value = ignore.

=item package()

Set the package name under which to evaluate the extracted perl. If used in concert with a hash, the package name must be set prior to installation of a hash.

=item parse()

Runs the parser. Optionally accepts parameters as specified for new();.

=item parsed();

Returns the fully parsed and evaluated text.

=item cleanup();

Cleanup namespace (excludes 'main'). "Cleanup" mean delete all variables contained therein.

=item autoclean();

Should Oyster cleanup at DESTROY?

=back

=head1 CHANGES

=over 10

=item 0.31

Corrected my dorky spanish...ONE MORE TIME!
=item 0.31

Fixed the pod CHANGES.
Corrected my really bad spanish in the demo code to be significantly less bad(er). Thanks Belden Lyman.

=item 0.30

Removed an errant warn statement.
Build distribution using 'make dist'

=item 0.29

Allow assignment of hash elements with undef values.
Uses evaluation package name correctly.

=item 0.27

Added package data cleanup method, optional autocleaning at DESTROY.

=back


=head1 AUTHOR

Steve McKay, steve@colgreen.com

=head1 COPYRIGHT

Copyright 2000-2001 Steve McKay. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

C<Parse::Tokens>, C<Text::Template>, C<Text::SimpleTemplate>

=cut

