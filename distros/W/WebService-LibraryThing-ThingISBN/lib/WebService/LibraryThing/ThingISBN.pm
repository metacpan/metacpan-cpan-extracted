package WebService::LibraryThing::ThingISBN;

use Business::ISBN;
use Carp qw( carp );
use HTTP::Request;
use LWP::UserAgent;
use base qw( Exporter );
use warnings;
use strict;

our @EXPORT_OK = qw( thing_isbn_list );

=head1 NAME

WebService::LibraryThing::ThingISBN - Get ISBNs for all editions of a book

=head1 VERSION

Version 0.503

=cut

our $VERSION = '0.503';

=head1 SYNOPSIS

This is a Perl interface to the LibraryThing social cataloging
website's thingISBN web service, which "takes an ISBN and returns a
list of ISBNs from the same 'work' (ie., other editions and
translations)." The web service is freely available for noncommercial
use, per the terms at L<http://www.librarything.com/api>.

    use WebService::LibraryThing::ThingISBN qw( thing_isbn_list );
    my @alternate_isbns = thing_isbn_list( isbn => '0060987049' );

=head1 EXPORT

Exports nothing by default. C<thing_isbn_list> can be optionally exported:

    use WebService::LibraryThing::ThingISBN qw( thing_isbn_list );

=head1 FUNCTIONS

=head2 C<thing_isbn_list>

This function takes a single ISBN as an argument, and queries
LibraryThing's thingISBN web service to get a list of ISBNs
corresponding to other editions of the same book, based on
LibraryThing's work definitions.

ISBNs can be either strings (hyphenated or unhyphenated; ISBN-10 or
ISBN-13) or Business::ISBN objects.

C<thing_isbn_list> returns a list of unhyphenated ISBN strings. If
there's an error, it returns an empty list.

Per LibraryThing's API terms of use, requests are limited to run no
more than once per second. (Users hitting the service over 1000 times
a day are required to notify LibraryThing.)

=head1 AUTHOR

Anirvan Chatterjee, C<< <anirvan at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-librarything-thingisbn at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-LibraryThing-ThingISBN>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

Bug reports about the underlying thingISBN API should be sent to
LibraryThing. Contact them at L<http://www.librarything.com/contact>.

=head1 SUPPORT

The thingISBN API is documented at:

=over 4

=item * LibraryThing APIs
                                                                               
L<http://www.librarything.com/api>

=item * "Introducing thingISBN"

L<http://www.librarything.com/thingology/2006/06/introducing-thingisbn_14.php>

=back

You can find documentation for this module with the perldoc command.

    perldoc WebService::LibraryThing::ThingISBN

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-LibraryThing-ThingISBN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-LibraryThing-ThingISBN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-LibraryThing-ThingISBN>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-LibraryThing-ThingISBN/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to LibraryThing for making thingISBN available.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Anirvan Chatterjee.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

Use of the LibraryThing thingISBN API is governed by the terms of use
listed at L<http://www.librarything.com/api>.

=cut

sub thing_isbn_list {
    my $isbn = shift;
    my @isbns = _thing_isbn_all( isbn => $isbn );
    return @isbns;
}

sub _thing_isbn_all {

    my ( $input_type, $input_value ) = @_;

    my %valid_input_types = ( isbn => 1, lccn => 1, oclc => 1 );
    unless ( $input_type and $valid_input_types{$input_type} ) {
        my $input_type_printable
            = ( defined $input_type ? $input_type : '[undef]' );
        carp
            qq{Expected input type "isbn", "lccn", or "oclc", got "$input_type_printable"};
        return ();
    }

    my $input_value_clean = $input_value;
    if ( $input_type eq 'isbn' ) {
        $input_value_clean = _clean_isbn_input($input_value_clean);
    } elsif ( $input_type eq 'lccn' ) {
        $input_value_clean = _clean_lccn_input($input_value_clean);
    } elsif ( $input_type eq 'oclc' ) {
        $input_value_clean = _clean_oclc_input($input_value_clean);
    }

    unless ( defined $input_value_clean and length $input_value_clean ) {
        return ();
    }

    return
        _internal_lookup( type  => $input_type,
                          value => $input_value_clean );
}

# internal functions

my $next_lookup_ok_time = 0;
my $have_time_hi_res;

# http://www.librarything.com/api
# http://www.librarything.com/thingology/2008/02/thingisbn-adds-lccns-oclc-numbers.php

sub _internal_lookup {
    my %args = @_;

    unless ( defined $have_time_hi_res ) {
        $have_time_hi_res = eval q{ use Time::HiRes; 1} || 0;
    }

    my $type  = $args{type};
    my $value = $args{value};
    my $ua    = $args{ua} ||= _default_ua();

    my $arg;
    if ( $type eq 'isbn' ) {
        $arg = $value;
    } elsif ( $type eq 'lccn' ) {
        $arg = "lccn$value";
    } elsif ( $type eq 'oclc' ) {
        $arg = "ocm$value";
    }

    my $request = HTTP::Request->new(
           GET => "http://www.librarything.com/api/thingISBN/$arg&allids=1" );

    if ( _get_time() < $next_lookup_ok_time ) {
        _sleep_until_time($next_lookup_ok_time);
    }

    my $result = $ua->request($request);

    $next_lookup_ok_time = _get_time() + 1;

    if ( $result->is_success ) {
        my @isbns = $result->content =~ m|<isbn>(.*?)</isbn>|ig;
        shift @isbns;    # remove argument from list
        return @isbns;
    } else {
        return ();
    }
}

sub _clean_isbn_input {
    my $isbn_input = shift;

    my $isbn;
    if ( !defined $isbn_input ) {
        return;
    } elsif (
        ref $isbn_input
        and eval {
            $isbn_input->isa('Business::ISBN');
        }
        ) {
        return $isbn_input->as_string( [] );
    } elsif ( !length $isbn_input ) {
        return;
    } else {
        my $isbn_object = Business::ISBN->new($isbn_input);
        if ($isbn_object) {
            return $isbn_object->as_string( [] );
        }
    }
    return;
}

sub _clean_lccn_input {
    my $lccn_input = shift;

    my $lccn;
    if ( !defined $lccn_input ) {
        return;
    } elsif ( !length $lccn_input ) {
        return;
    } else {
        $lccn = $lccn_input;
        $lccn =~ s/\s+//g;
        if ( $lccn !~ m/\d/ ) {
            return;
        } else {
            return $lccn;
        }
    }
}

sub _clean_oclc_input {
    my $oclc_input = shift;

    my $oclc;
    if ( !defined $oclc_input ) {
        return;
    } elsif ( !length $oclc_input ) {
        return;
    } else {
        $oclc = $oclc_input;
        $oclc =~ s/\s+//g;
        $oclc =~ s/^ocm//;
        if ( $oclc !~ m/\d/ ) {
            return;
        } else {
            return $oclc;
        }
    }
}

my $_default_ua;

sub _default_ua {
    unless ($_default_ua) {
        $_default_ua = new LWP::UserAgent;

        # set ua agent string
        my $lwp_agent = $_default_ua->agent();
        $_default_ua->agent(
                 "WebService::LibraryThing::ThingISBN/$VERSION ($lwp_agent)");
    }
    return $_default_ua;
}

sub _get_time {
    unless ( defined $have_time_hi_res ) {
        $have_time_hi_res = eval q{ use Time::HiRes; 1} || 0;
    }
    if ($have_time_hi_res) {
        return Time::HiRes::time();
    } else {
        return time;
    }
}

sub _sleep_until_time {
    my $time_to_sleep_until = shift;
    if ( _get_time >= $time_to_sleep_until ) {
        return;
    } else {
        unless ( defined $have_time_hi_res ) {
            $have_time_hi_res = eval q{ use Time::HiRes; 1} || 0;
        }
        my $seconds_to_sleep = $time_to_sleep_until - _get_time;
        if ($have_time_hi_res) {
            Time::HiRes::sleep($seconds_to_sleep);
        } else {
            sleep $seconds_to_sleep;
        }
    }
    return;
}

1;    # End of WebService::LibraryThing::ThingISBN

# Local Variables:
# mode: perltidy
# End:
