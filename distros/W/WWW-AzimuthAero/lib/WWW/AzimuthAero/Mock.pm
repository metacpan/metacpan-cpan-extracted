package WWW::AzimuthAero::Mock;
$WWW::AzimuthAero::Mock::VERSION = '0.31';

# ABSTRACT: additional subroutines for unit testing


use DateTime;
use Mojo::UserAgent::Mockable;
use feature 'say';


sub mock_data {
    return {
        get => {

    # uncomment when check for new DOM and change date next after testing
    # from => 'ROV', to => 'MOW', date => DateTime->now->add(weeks=>2)->dmy('.')
            from => 'ROV',
            to   => 'MOW',
            date => '23.06.2019'
        }
    };
}

sub filename {
    return 't/ua_mock.json';
}


sub generate {
    my $self      = shift;
    my $mock_data = $self->mock_data->{get};

    my $ua = Mojo::UserAgent::Mockable->new(
        mode           => 'record',
        file           => $self->filename,
        ignore_headers => 1
    );
    $ua->get('https://booking.azimuth.aero/');
    my $url =
        'https://booking.azimuth.aero/!/'
      . $mock_data->{from} . '/'
      . $mock_data->{to} . '/'
      . $mock_data->{date}
      . '/1-0-0/';
    $ua->get($url)->res->dom;
    $ua->save;
    say 'please manually check prices at ' . $url
      . ' and fix 01-AzimuthAero.t if needed';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::AzimuthAero::Mock - additional subroutines for unit testing

=head1 VERSION

version 0.31

=head1 SYNOPSIS

    perl -Ilib -e "use WWW::AzimuthAero::Mock; WWW::AzimuthAero::Mock->generate()"

=head1 DESCRIPTION

    Some helpers to generate mocks

=head2 mock_data

Return data that is used for mock at unit tests

=head2 generate

Generate json mock data

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
