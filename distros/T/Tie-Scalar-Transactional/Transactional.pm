# ----------------------------------------------------------------------------#
# Tie::Scalar::Transactional                                                  #
#                                                                             #
# Copyright (c) 2002-03 Arun Kumar U <u_arunkumar@yahoo.com>.                 #
# All rights reserved.                                                        #
#                                                                             #
# This program is free software; you can redistribute it and/or               #
# modify it under the same terms as Perl itself.                              #
# ----------------------------------------------------------------------------#

package Tie::Scalar::Transactional;

use strict;
use Carp;

use Exporter;
use vars qw($VERSION @EXPORT_OK @ISA %EXPORT_TAGS);

$VERSION = '0.01';

@EXPORT_OK   = qw( commit rollback );
%EXPORT_TAGS = ( commit => \@EXPORT_OK, rollback => \@EXPORT_OK );

@ISA = qw(Exporter);

sub new
{
	my $class = $_[0];
	my $var   = $_[1];

	if (!defined($var)) { croak('Usage: ' . __PACKAGE__ . '->new($var)'); }
	elsif (ref($var)) { 
		my $message = "References are not allowed\n";
		croak("$message\nUsage: " . __PACKAGE__ . '->new($var)'); 
	}

	my $self = tie $_[1], $class, $_[1];
	return $self;
}

sub TIESCALAR
{
	my ($proto, $var) = @_;
	my ($self, $class);

	$self = {};
	$class = ref($proto) || $proto;
	bless $self, $class;

	$self->_initialize($var);
	return $self;
}

sub _initialize
{
	my ($self, $value) = @_;

	$self->{'_committedValue'} = $value;
	$self->{'_currentValue'}   = $value;
}

sub FETCH
{
	my ($self) = @_;
	return $self->{'_currentValue'};
}

sub STORE
{
	my ($self, $value) = @_;
	$self->{'_currentValue'} = $value;
}

sub DESTROY
{
	## Nothing to be done (atleast in this version !!)
}

sub commit
{
	my $self;

	if (@_ == 1) { 
		if (UNIVERSAL::isa($_[0], __PACKAGE__)) { $self = $_[0]; }
		else {
			$self = tied($_[0]) if (!ref($_[0]));
		}
  }
	elsif (@_ == 2) { $self = tied($_[1]); }
	else {
		my $package = __PACKAGE__;
		croak(<<"USAGE");
Usage: $package->commit(\$var);
       tied(\$var)->commit();
       commit(\$a);  # (if explicitely imported)
USAGE
	}

	$self->{'_committedValue'} = $self->{'_currentValue'};
	return 1;
}

sub rollback
{
	my $self;

	if (@_ == 1) { 
		if (UNIVERSAL::isa($_[0], __PACKAGE__)) { $self = $_[0]; }
		else {
			$self = tied($_[0]) if (!ref($_[0]));
		}
  }
	elsif (@_ == 2) { $self = tied($_[1]); }
	else {
		my $package = __PACKAGE__;
		croak(<<"USAGE");
Usage: $package->rollback(\$var);
       tied(\$var)->rollback();
			 rollback(\$a);  # (if explicitely imported)
USAGE
	}

	$self->{'_currentValue'} = $self->{'_committedValue'};
	return 1;
}

1;

__END__

=head1 NAME

Tie::Scalar::Transactional - Implementation of Transactional Scalars

=head1 SYNOPSIS

    use Tie::Scalar::Transactional;

    my $foo = 10;
    new Tie::Scalar::Transactional($foo);

    $foo = $baz * 10;
    #... Transactions here ...#

    if ($error) {
      Tie::Scalar::Transactional->rollback($foo);  ## or
      tied($foo)->rollback();                      
    }
    else {
      Tie::Scalar::Transactional->commit($foo);  ## or
      tied($foo)->commit();                      
    }

    ### ----------------------------------------- ###
    ### Or use the following Procedural Interface ###
    ### ----------------------------------------- ###

    use Tie::Scalar::Transactional qw(:commit);
    tie my $bar, 'Tie::Scalar::Transactional', 10;

    $bar = $baz * 10;
    #... Transactions here ...#

    if ($error) { rollback $bar; }
    else        { commit $bar; }

=head1 DESCRIPTION

This module implements scalars with transactional capabilities. The functionality is similar to the ones found in most Relation Database Management Systems (RDBMS). 

A transaction begins under any one of the following conditions: 

=over 4

=item *
A new transactional variable is created 

=item *
When an existing scalar is converted into a transactional scalar

=item *
When an existing transaction is committed, a new one begins automatically.

=back

All the changes/updates to the scalar after the transaction has begun can be rolled back, if neccessary. Once committed a change cannot be rolledback.

=head1 INVOCATION

The module can be invoked in two ways:

=over 4

=item *
use Tie::Scalar::Transactional;

=item *
use Tie::Scalar::Transactional qw(:commit);

=back

If you are strong believer (like me) in the fact that an Object Oriented module should never export methods, then you should use the first method. 

On the other hand if you are constantly annoyed by the line noise created by the C<commit()> / C<rollback()> calls, when using a pure OO interface. And would prefer the less terse procedural interface, then the 2nd method is for you. This will import the C<commit()> and C<rollback()> methods the current package's namespace.

=head1 CREATING A TRANSACTIONAL SCALAR

There are two modes in which you can create a Transactional scalar i.e.

=over 4

=item *
Call the module's constructor with the scalar as the first argument

=item *
Call the builtin C<tie()> function and pass the Scalar and Class name as arguments

=back

The two modes are illustrated below:

    my $foo = 10;
    new Tie::Scalar::Transactional($foo);
              (or)
    tie my $foo, 'Tie::Scalar::Transactional', 10;

=head1 METHODS

=over 4

=item commit()

The C<commit()> method, sets the state of the scalar to the last update/change done to the scalar since the start of the transaction. The subsequent C<rollback()> method call (if any) will revert back the scalar to this state.

The C<commit()> method can be invoked in one of the following ways:

    Tie::Scalar::Transactional->commit($foo);  ## or
    tied($foo)->commit();                      ## or
    commit $foo;  ## When you have 'use T::S::T qw(:commit)'

=item rollback()

The C<rollback()> method, reverts back the state of the scalar to what it was at the beginning of the transaction. The calling conventions are similar to the C<commit()> method, as discussed above.

=back

=head1 LIMITATIONS

Since this is a pure Perl module, it may not be fully optimized in terms of performance. Also the module *might not* be thread safe [But who cares ;) ... ]

=head1 KNOWN BUGS

May be lot of them :-), but hopefully none.
Bug reports, fixes, suggestions or feature requests are most welcome.

=head1 INSPIRATION

This modules was inspired by "Perl6 RFC 161: Everything in Perl becomes an Object", that talks about the possibility of implementing transaction support in Perl scalars.  

=head1 COPYRIGHT

Copyright (c) 2002-03 Arun Kumar U <u_arunkumar@yahoo.com>
All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Arun Kumar U <u_arunkumar@yahoo.com>, <uarun@cpan.org>

=head1 SEE ALSO

perl(1), perltie(1)

=cut
