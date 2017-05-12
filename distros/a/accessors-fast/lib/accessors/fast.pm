# Copyright (c) 2009 Mons Anderson <mons@cpan.org>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package accessors::fast;

=head1 NAME

accessors::fast - Compiletime accessors using Class::Accessor::Fast

=cut

our $VERSION = '0.03';

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

	package My::Simple::Package;
	use accessors::fast qw(field1 field2);
	
	# constructor is private, redefine only init;
	sub init {
		my $self = shift;
		my %args = @_;
		$self->field1($args{arg1});
	}
	
	package main;
	my $o = My::Simple::Package->new( arg1 => 'some value' );
	print $o->field1; # some value
	
	for ($o->field_list) {
		printf "object have field %s with value %s\n", $_, $o->$_;
	}

=head1 DESCRIPTION

This module was created as an alternative to C<use fields>, and uses L<Class::Accessor::Fast> as a base

Creates accessors at compiletime

Have own default C<new> method: it creates object as a blessed hash, then locks keys to defined field list, and invoke C<init>.
So, recommended usage inside packages, is access by hash keys (it's 3 times faster then accessor).
Since keys are locked, you will not suffer from autovivification. Public interface recommended to be documented as accessors.

Uses L<Class::C3>

=head1 METHODS

All methods inherited from L<Class::Accessors::Fast>. Own methods defined below

=head2 new( ARGS )

Creates blessed hash, locks it keys to current fields of this package, and invoke C<init> method with C<ARGS>

=head2 init( ARGS )

Recommended to redefine in subclasses. Will be invoked by inherited C<new>

=head2 field_list

Since this module keeps information about object fields, it can return it.

	for ($o->field_list) {
		printf "%s: %s\n",$_,$o->$_;
	}

=head1 FEATURES

This module uses L<constant::def>, so it behaviour could be affected by L<constant::abs>

=head2 TIE [ = 0 ]

Use tied hash, instead of L<Hash::Util>C<::lock_keys>. Much more slower, but could help during development.

Could be enabled by

	# your main program/main.pl
	use constant::abs 'accessors::fast::TIE' => 1;

=head2 CONFESS [ = 0 ]

use Carp::confess instead of croak on error conditions

Could be enabled by

	# your main program/main.pl
	use constant::abs 'accessors::fast::CONFESS' => 1;

=head2 warnings

This module uses L<warnings::register>. So, warnings from it could be disabled by

	no warnings 'accessors::fast';

=cut

use 5.008008;
use strict;
use warnings;
use warnings::register;
use constant::def {
    DEBUG   => 0,
    CONFESS => 0,
    TIE     => 0,
};
our $ME;

use base ();
BEGIN {
	$ME = __PACKAGE__;
	!TIE and eval q{ use Class::Accessor::Fast::XS; 1 }
	     and do{ base->import('Class::Accessor::Fast::XS'); 1 }
	or
	eval { require Class::Accessor::Fast; 1 }
	     and do{ base->import('Class::Accessor::Fast'); 1 }
	or die "accessors::fast can't find neither Class::Accessor::Fast::XS nor Class::Accessor::Fast. ".
	       "Please install one.\n";
	TIE and require accessors::fast::tie;
}

use Hash::Util ();
use Carp       ();
use Class::C3  ();

our %CLASS;
our @ADD_FIELDS;

sub mk_accessors {
	my $pkg = shift;
	$pkg = ref $pkg if ref $pkg;
	my %uniq;
	$CLASS{$pkg}{fields} = [ grep !$uniq{$_}++, @{ $CLASS{$pkg}{list} || [] }, @_ ];
	$pkg->next::method(@_);
}

sub field_list {
	my $self = shift;
	my $pkg = ref $self || $self;
	my %uniq;
	$CLASS{$pkg}{isa} ||= do{ no strict 'refs'; \@{$pkg.'::ISA'} };
	#warn "field_list for $self [ @{ $CLASS{$pkg}{fields} || [] } ] +from[ @{ $CLASS{$pkg}{isa} || [] } ]";
	grep !$uniq{$_}++,
		map ( $_ ne $pkg && $_->can('field_list') ? $_->field_list : (), @{ $CLASS{$pkg}{isa} || [] } ),
		@{ $CLASS{$pkg}{fields} || [] },
	;
}

sub new {
	my $pkg = shift;
	my %h;
	TIE and tie %h, 'accessors::fast::tie', $pkg, [ $pkg->field_list,@ADD_FIELDS ];
	my $self = bless \%h,$pkg;
	&Hash::Util::lock_keys($self,$pkg->field_list,@ADD_FIELDS);
	$self->init(@_);
	return $self;
}

sub init {
	my $self = shift;
	@_ or return;
	my $args;
	{
		my $orig = \@_;
		my $sw = $SIG{__WARN__};
		local $SIG{__WARN__} = sub {
			local $_ = shift;
			local *__ANON__ = 'init:SIG:WARN';
			return unless warnings::enabled( $ME );
			if(m{Odd number of elements}s) {
				@_ = ("Wrong init params for $self: [ ".join(', ', map { defined() ? length() ? $_ : "''" : 'undef' } @$orig)." ]. Pass a single hash ref");
				local $SIG{__WARN__} = $sw if $sw;
				Carp::carp(@_);
				return;
			}
			goto &$sw if $sw;
			CORE::warn $_;
		};
		$args = ( @_ == 1 && ref $_[0] ) ? shift : +{ @_ };
	}
	#warn "$self\->init (@{[ %$args ]})";
	#warn "$self\->init $args";
	my %chk = map { $_ => 1 } $self->field_list;
	#warn "$self have fields @{[ $self->field_list ]}";
	for (keys %$args) {
		if ($chk{$_}){
			$self->{$_} = $args->{$_};
		}
		elsif(warnings::enabled( $ME )){
			my ($file,$line) = (caller(1))[1,2];
			warn "class `".(ref $self)."' have no field `$_' but instance attempted ".
			     "to be initialized with value '$args->{$_}' at $file line $line.\n";
		}
	}
	return;
}

sub import {
	no strict 'refs';
	( my $me = shift ) eq $ME or return; # Only me can define class isa.
	my $pkg = caller;
	#warn "declare $pkg as $me at @{[ (caller(0))[1,2] ]}";
	push @{$pkg.'::ISA'}, $me unless $pkg->isa($me);
	$CLASS{$pkg}{isa} = \@{$pkg.'::ISA'};
	$pkg->mk_accessors(@_);
}

1;
__END__

=head1 BUGS

None known

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Mons Anderson, <mons@cpan.org>

=cut
