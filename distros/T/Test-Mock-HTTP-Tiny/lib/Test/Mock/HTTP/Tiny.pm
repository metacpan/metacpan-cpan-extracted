package Test::Mock::HTTP::Tiny;

use strict;
use warnings;

# ABSTRACT: Record and replay HTTP requests/responses with HTTP::Tiny

our $VERSION = '0.002'; # VERSION

use Data::Dumper;
use HTTP::Tiny;
use Test::Deep::NoTest;
use URI::Escape;


my $captured_data = [];
my $mocked_data   = [];


sub mocked_data {
    return $mocked_data;
}


sub set_mocked_data {
    my ($class, $new_mocked_data) = @_;

    if (ref($new_mocked_data) eq 'ARRAY') {
        # An arrayref of items was provided
        $mocked_data = [ @$new_mocked_data ];
    }
    elsif (ref($new_mocked_data) eq 'HASH') {
        # A single item was provided
        $mocked_data = [ { %$mocked_data } ];
    }
    else {
        # TODO: error
    }
}


sub append_mocked_data {
    my ($class, $new_mocked_data) = @_;

    if (ref($new_mocked_data) eq 'ARRAY') {
        # Multiple items are being appended
        push @$mocked_data, @$new_mocked_data;
    }
    elsif (ref($new_mocked_data) eq 'HASH') {
        # Single item is being appended
        push @$mocked_data, { %$new_mocked_data };
    }
    else {
        # TODO: error
    }
}


sub clear_mocked_data {
    $mocked_data = [];
}


sub captured_data {
    return $captured_data;
}


sub captured_data_dump {
    local $Data::Dumper::Deepcopy = 1;
    return Dumper $captured_data;
}


sub clear_captured_data {
    $captured_data = [];
}

{
    ## no critic
    no strict 'refs';
    no warnings 'redefine';
    my $_HTTP_Tiny__request = \&HTTP::Tiny::_request;
    *{"HTTP::Tiny::_request"} = sub {
        my ($self, $method, $url, $args) = @_;

        my $normalized_args = { %$args };

        if (exists $args->{headers}{'content-type'} &&
            $args->{headers}{'content-type'} eq
                'application/x-www-form-urlencoded')
        {
            # Unescape form data
            $normalized_args->{content} = {};

            for my $param (split(/&/, $args->{content})) {
                my ($name, $value) =
                    map { uri_unescape($_) } split(/=/, $param, 2);
                $normalized_args->{content}{$name} = $value;
            }
        }

        for my $i (0 .. $#{$mocked_data}) {
            my $mock_req = $mocked_data->[$i];

            next if !eq_deeply(
                [ $mock_req->{method}, $mock_req->{url}, $mock_req->{args} ],
                [ $method, $url, $normalized_args ]
            );

            # Found a matching request in mocked data
            $mock_req = { %$mock_req };

            # Remove the request from mocked data so that it's not used again
            splice(@$mocked_data, $i, 1);

            # Return the corresponding response
            return $mock_req->{response};
        }

        # No matching request found -- call the actual HTTP::Tiny request method
        my $response = &$_HTTP_Tiny__request($self, $method, $url, $args);

        # Save the request/response in captured data
        push @$captured_data, {
            method   => $method,
            url      => $url,
            args     => $normalized_args,
            response => $response,
        };
    
        return $response;
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Mock::HTTP::Tiny - Record and replay HTTP requests/responses with HTTP::Tiny

=head1 VERSION

version 0.002

=head1 SYNOPSIS

Capture HTTP data:

    use HTTP::Tiny;
    use Test::Mock::HTTP::Tiny;

    my $http = HTTP::Tiny->new;
    my $resp = $http->get('http://www.cpan.org/');

    print STDERR Test::Mock::HTTP::Tiny->captured_data_dump;

Replay captured data:

    Test::Mock::HTTP::Tiny->set_mocked_data([
        {
            url      => 'http://www.cpan.org/',
            method   => 'GET',
            args     => { ... },
            response => { ... },
        }
    ]);

    $resp = $http->get('http://www.cpan.org/');

=head1 DESCRIPTION

(TBA)

=head1 METHODS

=head2 mocked_data

=head2 set_mocked_data

=head2 append_mocked_data

=head2 clear_mocked_data

=head2 captured_data

=head2 captured_data_dump

=head2 clear_captured_data

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/odyniec/p5-Test-Mock-HTTP-Tiny/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/odyniec/p5-Test-Mock-HTTP-Tiny>

  git clone https://github.com/odyniec/p5-Test-Mock-HTTP-Tiny.git

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
