=encoding utf-8

=head1 NAME

Yandex::Metrika - It's module to get access to Yandex.Metrika API via OAuth

=head1 SYNOPSIS

    use Yandex::Metrika;

    my $metrika = Yandex::Metrika->new( token => '*******************************', counter => 1234567 );

    $metrika->set_per_page( 20 ); # optional, default 100
    $metrika->set_pretty( 1 ); # optional, default 1

    $metrika->user_vars({ date1 => '20150501', date2 => '20150501', table_mode => 'tree', group => 'all' });

    # if answer contains {links}->{next} you can load next page by

    $metrika->user_vars({ next => 1});
    
    # show next link

    say $metrika->next_url;


=head1 DESCRIPTION

Yandex::Metrika is using Yandex::OAuth::Client as base class to get access.
API methods are mapped to object methods.
See api docs for parameters and response formats at https://tech.yandex.ru/metrika/doc/ref/stat/api-stat-method-docpage/

Looking for contributors for this and other Yandex.APIs

=cut

package Yandex::Metrika;
use 5.008001;
use utf8;
use Modern::Perl;

use Class::MOP;
use Moo;

extends 'Yandex::OAuth::Client';

has '+endpoint' => (
    is      => 'ro',
    default => 'https://api-metrika.yandex.ru/',
);

has 'counter' => (
    is       => 'rw',
    required => 1,
);

has 'per_page' => (
    is      => 'rw',
    default => 100,
    writer  => 'set_per_page',
);

has 'pretty' => (
    is      => 'rw',
    default => 1,
    writer  => 'set_pretty',
);

our $VERSION = "0.01";

BEGIN {
    my $metrika = Class::MOP::Class->initialize(__PACKAGE__);

    my @methods = qw/
        traffic conversion sources sites search_engines phrases social_networks
        marketing direct_summary direct_platforms_all direct_platform_types
        direct_regions tags geo interest demography_age demography_gender
        demography_structure deepness_time deepness_depth hourly popular entrance
        exit titles url_param share_services share_titles links downloads user_vars
        ecommerce browsers os display_all display_groups mobile_devices mobile_phones
        flash silverlight java cookies javascript load load_minutely_24
        load_minutely_all robots_all robot_types /;

    foreach my $method ( @methods ) {
        $metrika->add_method( $method => sub {
            my ( $self, $params ) = @_;

            return $self->get_stat(['stat', $method], $params);
        } );
    }


    $metrika->get_all_methods();
}

=head1 METHODS

=over

=item B<traffic()>

=item B<conversion()>

=item B<sites()>

=item B<search_engines()>

=item B<phrases()>

=item B<social_networks()>

=item B<marketing()>

=item B<direct_summary()>

=item B<direct_platforms_all()>

=item B<direct_platform_types()>

=item B<direct_regions()>

=item B<tags()>

=item B<geo()>

=item B<interest()>

=item B<demography_age()>

=item B<demography_gender()>

=item B<demography_structure()>

=item B<deepness_time()>

=item B<deepness_depth()>

=item B<hourly()>

=item B<popular()>

=item B<entrance()>

=item B<exit()>

=item B<titles()>

=item B<url_param()>

=item B<share_services()>

=item B<share_titles()>

=item B<links()>

=item B<downloads()>

=item B<user_vars()>

=item B<ecommerce()>

=item B<browsers()>

=item B<os()>

=item B<display_all()>

=item B<display_groups()>

=item B<mobile_devices()>

=item B<mobile_phones()>

=item B<flash()>

=item B<silverlight()>

=item B<java()>

=item B<cookies()>

=item B<javascript()>

=item B<load()>

=item B<load_minutely_24()>

=item B<load_minutely_all()>

=item B<robots_all()>

=item B<robot_types()>


=cut

sub get_stat {
    my ( $self, $resources, $params ) = @_;

    if ( $params->{next} ) {
        return $self->get( $self->next_url . '&per_page=' . $self->per_page ); 
    }
    else {
        return $self->get($resources, 
        { 
            id          => $self->counter, 
            pretty      => $self->pretty,
            date1       => $params->{date1}      || undef,
            date2       => $params->{date2}      || undef,
            goal_id     => $params->{goal_id}    || undef,
            per_page    => $self->per_page,
            table_mode  => $params->{table_mode} || 'plain',
            group       => $params->{group}      || undef,
            top_n       => $params->{top_n}      || undef,
            row_ids     => $params->{row_ids}    || undef,
            lang        => $params->{lang}       || undef,
            sort        => $params->{sort}       || 'clicks',
        } );
    }
}

1;
__END__

=back

=head1 LICENSE

Copyright (C) Andrey Kuzmin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Andrey Kuzmin E<lt>chipsoid@cpan.orgE<gt>

=cut

