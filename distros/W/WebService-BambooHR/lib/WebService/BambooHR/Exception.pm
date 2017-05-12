package WebService::BambooHR::Exception;
$WebService::BambooHR::Exception::VERSION = '0.07';
use 5.006;
use Moo;
with 'Throwable';

use overload
    q{""}    => 'as_string',
    fallback => 1;

has message     => (is => 'ro');
has method      => (is => 'ro');
has code        => (is => 'ro');
has reason      => (is => 'ro');
has filename    => (is => 'ro');
has line_number => (is => 'ro');

sub as_string
{
    my $self = shift;
    return $self->method.'(): '
           .$self->message.' ('.$self->code.' '.$self->reason.') '
           .'file '.$self->filename.' on line '.$self->line_number."\n";
           ;
}

=head1 NAME

WebService::BambooHR::Exception - represent exception thrown by WebService::BambooHR::UserAgent.

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 REPOSITORY

L<https://github.com/neilbowers/WebService-BambooHR>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
