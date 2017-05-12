package WWW::SFDC::Apex::ExecuteAnonymousResult;
# ABSTRACT: Container for the result of an executeAnonymous call

use strict;
use warnings;

our $VERSION = '0.37'; # VERSION

use overload
  bool => sub {
    return $_[0]->success;
  };

use Log::Log4perl ':easy';
use Moo;

has '_result',
    is => 'ro',
    required => 1;

has '_headers',
    is => 'ro';


has 'success',
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return $self->_result->{success} eq 'true';
    };


has 'failureMessage',
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return $self->_result->{compiled} eq 'true'
            ? $self->_result->{exceptionMessage}
            : $self->_result->{compileProblem};
    };


has 'log',
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return $self->_headers ? $self->_headers->{debugLog} : "";
    };

sub BUILD {
    my $self = shift;
    FATAL $self->failureMessage unless $self->success;
}

1;

__END__

=pod

=head1 NAME

WWW::SFDC::Apex::ExecuteAnonymousResult - Container for the result of an executeAnonymous call

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This module acts as a container for the result of an executeAnonymous request.
It's overloaded so that used as a boolean, it acts as the success value of the
call.

=head1 ATTRIBUTES

=head2 success

Whether or not the apex code executed successfully

=head2 failureMessage

If the code failed to compile, the compilation error; if the code failed to
execute, the exception message. This will be undefined if the code succeeded.

=head2 log

The debug log for the code. This will be undefined if the code failed to
compile, and an empty string if no logs were requested.

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/sophos/WWW-SFDC/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::SFDC::Apex::ExecuteAnonymousResult

You can also look for information at L<https://github.com/sophos/WWW-SFDC>

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
