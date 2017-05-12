#!/usr/bin/env perl -w

## workaround for PkgVersion
## no critic
package WebService::PagerDuty::Base;
{
  $WebService::PagerDuty::Base::VERSION = '1.20131219.1627';
}
## use critic
use strict;
use warnings;
use Class::Accessor;

use base qw/ Class::Accessor /;

__PACKAGE__->mk_ro_accessors(qw/ _defaults _init_args /);

sub new {
    my $self = shift;
    my $args = {@_};    # copy
    $args->{_defaults} = {} unless exists $args->{_defaults};
    my $init = {%$args};    # copy
    delete $init->{_defaults};
    $self->SUPER::new( { _init_args => $init, %$args } );
}

sub get {
    my $self  = shift;
    my $field = shift;

    my $defaults  = $self->{_defaults};
    my $init_args = $self->{_init_args};

    if ( !exists( $init_args->{$field} ) && exists( $defaults->{$field} ) ) {
        $init_args->{$field} = 'lazy_build';
        $self->{$field}      = $defaults->{$field}->($self);
    }
    else {
        $self->SUPER::get( $field, @_ );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PagerDuty::Base

=head1 VERSION

version 1.20131219.1627

=head1 SYNOPSIS

Internal module, do not use it directly

=head1 DESCRIPTION

WebService::PagerDuty - is a client library for http://PagerDuty.com

For detailed description of B<%extra_params> (including which of them are
required or optional), see PagerDuty site:

=over 4

=item L<Events API|http://www.pagerduty.com/docs/integration-api/integration-api-documentation>

=item L<Incidents API|http://www.pagerduty.com/docs/rest-api/incidents>

=item L<Schedules API|http://www.pagerduty.com/docs/rest-api/schedules>

=back

Also, you could explore tests in t/ directory of distribution archive.

=head1 NAME

WebService::PagerDuty::Base - base class for all WebService::PagerDuty hierarchy

=head1 SEE ALSO

L<http://PagerDuty.com>, L<http://oDesk.com>

=head1 AUTHOR

Oleg Kostyuk (cubuanic), C<< <cub@cpan.org> >>

=head1 LICENSE

Same as Perl.

=head1 COPYRIGHT

Copyright by oDesk Inc., 2012

All development sponsored by oDesk.

=head1 NO WARRANTY

This software is provided "as-is," without any express or implied warranty.
In no event shall the author or sponsor be held liable for any damages
arising from the use of the software.

=for Pod::Coverage     new
    get

=head1 AUTHOR

Oleg Kostyuk <cub@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Odesk Inc..

This is free software, licensed under:

  The (three-clause) BSD License

=cut
