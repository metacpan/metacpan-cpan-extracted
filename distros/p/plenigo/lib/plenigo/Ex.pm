package plenigo::Ex;

=head1 NAME

 plenigo::Ex - Exception thrown if something went wrong.

=head1 SYNOPSIS

 use plenigo::Ex;

 # Throw an exception

 plenigo::Ex->throw({ code => 100, message => 'Description of the error code.' });

=head1 DESCRIPTION

 plenigo::Ex represents an exception.

=cut

use Moo;
with 'Throwable';

our $VERSION = '3.0000';

has code => (is=>'ro');
has message  => (is=>'ro');

sub e {
    if (ref($_) eq 'plenigo::Ex') {
        return $_;
    } else {
        chomp; return plenigo::Ex->new(message => $_, code=>0);
    }
}

1;
