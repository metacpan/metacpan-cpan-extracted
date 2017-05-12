package XML::Validate::Base;

use strict;
use vars qw($VERSION);

$VERSION = sprintf"%d.%03d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;

sub new {
	die "XML::Validate::Base::new must be overridden. (XML::Validate::Base is an abstract class.)";
}

sub validate {
	die "XML::Validate::Base::validate must be overridden. (XML::Validate::Base is an abstract class.)";
}

sub options {
	my $self = shift;
	return $self->{options};
}

sub last_error {
	my $self = shift;
	return $self->{error};
}

sub add_error {
	my $self = shift;
	my ($error) = @_;
	$self->{error} = $error;
}

sub clear_errors {
	my $self = shift;
	$self->{error} = undef;
}

sub set_options {
	my $self = shift;
	my ($supplied_options,$valid_options) = @_;
	foreach my $option (keys %{$supplied_options}) {
		if (!_member($option,keys %{$valid_options})) {
			die "Unknown option: $option\n";
		}
	}
	$self->{options} = {%{$valid_options},%{$supplied_options}};
}

sub _member {
	my ($search,@list) = @_;
	foreach my $item (@list) {
		return 1 if $search eq $item;
	}
	return 0;
}

sub TRACE {}
sub DUMP {}

1;

=head1 NAME

XML::Validate::Base - Abstract base class to be used by XML::Validate modules

=head1 SYNOPSIS

  use XML::Validate::Base;
  
  sub new {
    ... override new ...
  }
  
  sub validate {
    ... override validate ...
  }

=head1 DESCRIPTION

XML::Validate::Base provides a base class with helpful subs for real
XML::Validate modules.

=head1 METHODS

=over

=item new(%options)

Constructs a new validator. This method must be overridden.

=item validate($xml)

Parses and validates $xml. Returns a true value on success, undef on
failure. This method must be overridden.

=item options

An accessor for the options hashref.

=item set_options($supplied_options,$valid_options)

Sets the options for the validator. $supplied_options and $valid_options are
hash refs containing respectively the options supplied to the constructor and
the valid options for validator along with their default values.

If the supplied options hash ref contains an option not listed in valid
options, this sub throws an exception.

=item last_error

Returns the error from the last validate call. This is a hash ref with the
following fields:

=over

=item *

message

=item *

line

=item *

column

=back

Note that the error gets cleared at the beginning of each C<validate> call.

=item add_error($error)

Stores $error for retrieval by last_error. $error should be a hash ref.

=item clear_errors

Clears any errors held by the validator.

=back

=head1 VERSION

$Revision: 1.9 $ on $Date: 2005/09/06 11:05:08 $ by $Author: johna $

=head1 AUTHOR

Colin Robertson E<lt>cpan _at_ bbc _dot_ co _dot_ ukE<gt>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.
See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
