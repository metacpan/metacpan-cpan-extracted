package WWW::Mechanize::Script::Plugin;

use strict;
use warnings;

# ABSTRACT: plugin base class for check plugins

our $VERSION = '0.100';

use 5.014;


sub new
{
    my ($class) = @_;

    my $self = bless( {}, $class );

    return $self;
}


sub get_check_value
{
    my ( $self, $check, $value_name ) = @_;

    $value_name or return;

    return $check->{check}->{$value_name};
}


sub get_check_value_as_bool
{
    my ( $self, $check, $value_name ) = @_;

    $value_name or return;

    my $val = $check->{check}->{$value_name};

    defined($val) or return;
    ref($val) and return $val;
    if ( _STRING($val) )
    {
        $val =~ m/(?:true|on|yes)/i and return 1;
    }

    return 0;
}


sub can_check
{
    my ( $self, $check ) = @_;
    my $ok = 0;

    my @value_names = $self->check_value_names();
    foreach my $value_name (@value_names)
    {
        my $cv = $self->get_check_value( $check, $value_name );
        $cv and $ok = 1 and last;
    }

    return $ok;

}


sub check_value_names { ... }


sub check_response { ... }

1;

__END__

=pod

=head1 NAME

WWW::Mechanize::Script::Plugin - plugin base class for check plugins

=head1 VERSION

version 0.101

=head1 METHODS

=head2 new()

Instantiates new WWW::Mechanize::Script::Plugin. This is an abstract class.

=head2 get_check_value(\%check,$value_name)

Retrieves the value for I<$value_name> from the hash I<%check>.

=head2 get_check_value_as_bool(\%check,$value_name)

Retrieves the value for I<$value_name> from the hash I<%check> and returns
true when it can be interpreted as a boolean value with true content
(any object is always returned as it is, (?:(?i)true|on|yes) evaluates to
I<true>, anything else to I<false>).

=head2 can_check(\%check)

Proves whether this instance can check anything on the current run test.
Looks if any of the required L</check_value_names> are specified in the
check parameters of the current test.

=head2 check_value_names()

Returns list of check values which are used to check the response.

Each I<value> has a I<value>C<_code> counterpart which is used to modify
the return value of L</check_response> when the check upon that value
fails.

=head2 check_response(\%check,$mech)

Checks the response based on test specifications. See individual plugins
for specific test information.

Returns the accumulated code for each failing check along with optional
messages containing details about each failure.

  # no error
  return (0);
  # some error
  return ($code,@messages);
  # some error but no details
  return ($code);

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Script or by email
to bug-www-mechanize-script@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Jens Rehsack <rehsack@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
