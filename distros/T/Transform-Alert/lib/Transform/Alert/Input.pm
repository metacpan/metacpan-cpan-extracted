package Transform::Alert::Input;

our $VERSION = '1.00'; # VERSION
# ABSTRACT: Base role for Transform::Alert input types

use sanity;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(HashRef Object);

requires qw(open opened get eof close);

has group => (
   is       => 'rwp',
   isa      => Object,
   weak_ref => 1,
   handles  => [ 'log' ],
);
has connopts => (
   is       => 'ro',
   isa      => HashRef,
   required => 1,
);

42;

__END__

=pod

=encoding utf-8

=head1 NAME

Transform::Alert::Input - Base role for Transform::Alert input types

=head1 DESCRIPTION

This is the role used for all input types.

=head1 PROVIDES

=head2 group

The L<InputGrp object|Transform::Alert::InputGrp> that constructed it.

=head2 connopts

Hash ref of the connection options (from configuration).

=head1 REQUIRES

All IE<sol>O types require the following methods below.  Unless specified, all of the methods should report a true value on success or undef on
error.  The methods are responsible for their own error logging.

=head2 open

Called on every new interval, if C<<< opened >>> returns false.  Most types would open up the connection here and run through any "pre-getE<sol>send" setup.
Though, in the case of UDP, this isn't always necessary.

=head2 opened

Must return a true value if the connection is currently open and valid, or false otherwise.

=head2 get

Called on each messageE<sol>alert that is to be parsed through the templates and sent to the outputs.  This is called on a loop, so the IE<sol>O cycle
will happen on a per-alert basis.

This must return a list of:

    (\$text, $hash)

or undef on error.  The C<<< $text >>> is used for Template validation, while the C<<< $hash >>> is stored in the OutputE<sol>Munger variables as C<<< p >>>.  See
L<Transform::Alert::Input::POP3/OUTPUTS> for an example.

=head2 eof

Must return a true value if there are no more alerts available to process, or false otherwise.

=head2 close

Called after the interval loop has been completed.  This should close the connection and run through any cleanup.

This method should double-check all IE<sol>O cleanup with the C<<< opened >>> method to ensure that close doesn't fail.  This is important if the loop
detects that the C<<< opened >>> method is false, since it will try a C<<< close >>> before trying to re-open.

=head1 PERSISTENT CONNECTIONS

Persistent connections can be done by defining C<<< close >>> in such a way that it still keeps the connection online, and making sure C<<< opened >>> can
handle the state.  Take special care to check that the connection is indeed valid and the module can handle re-opens properly.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Transform-Alert/wiki>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Transform::Alert/>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
