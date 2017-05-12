package Ubic::Service::PSGI;
{
  $Ubic::Service::PSGI::VERSION = '1.18';
}

use strict;
use warnings;

use base qw(Ubic::Service::Plack);

# ABSTRACT: deprecated module, see Ubic::Service::Plack instead


sub new {
    my $class = shift;
    warn "Ubic::Service::PSGI is deprecated, use Ubic::Service::Plack instead";
    $class->SUPER::new(@_);
}



sub defaults {
    return (
        env => 'deployment',
    );
}

1;

__END__

=pod

=head1 NAME

Ubic::Service::PSGI - deprecated module, see Ubic::Service::Plack instead

=head1 VERSION

version 1.18

=head1 DESCRIPTION

This package got renamed into L<Ubic::Service::Plack> and will be removed soon.

=for Pod::Coverage defaults

=head1 AUTHORS

=over 4

=item *

Yury Zavarin <yury.zavarin@gmail.com>

=item *

Vyacheslav Matjukhin <mmcleric@yandex-team.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
