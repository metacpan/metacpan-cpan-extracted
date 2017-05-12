package WWW::TamperData;

use warnings;
use strict;
use Carp;
use XML::Simple;
use HTTP::Request;
use LWP::UserAgent;

=head1 NAME

WWW::TamperData - Replay tamper data XML files

=head1 VERSION

Version 0.09

=cut

# Globals
our $VERSION = '0.09';
our $AUTHOR = 'Eldar Marcussen - http://www.justanotherhacker.com';
our $_tamperagent;
our $_tamperxml;

=head1 SYNOPSIS

    use WWW::TamperData;

    my $foo = WWW::TamperData->new(transcript => "myfile.xml");
    my %data = $foo->replay();

=head1 DESCRIPTION
Tamperdata is a firefox extension that lets you intercept or inspect browser requests and the server responses. WWW::TamperData can replay
requests exported to an XML file from Tamperdata.

=head1 SUBROUTINES/METHODS

=head2 new

Initializes the new object, it takes some options;

=over 4

=item WWW::TamperData->new(%options);

    KEY               DEFAULT                 USE
    ---------------   -----------------       --------------------------------------------------
    transcript        undef                   Filename to read tamperdata xml from
    timeout           60                      LWP connection timeout
    requestfilter     undef                   Name of function to call before making the request
    responsefilter    undef                   Name of function to call after making the request

=back

=cut

sub new {
    my ($class, %options) = @_;
    my $self = {};

    if ($options{'transcript'}) {
            $self->{'transcript'} = $options{'transcript'};
            $_tamperxml = XMLin($self->{'transcript'});
    }
    
    $self->{'timeout'}    = $options{'timeout'} ? $options{'timeout'} : 60;

    if ($options{'requestfilter'}) {
        $self->{requestfilter}{module} = caller;
        $self->{requestfilter}{function} = $options{'requestfilter'};
    }
    
    if ($options{'responsefilter'}) {
        $self->{responsefilter}{module} = caller;
        $self->{responsefilter}{function} = $options{'responsefilter'};
    }

    $_tamperagent = LWP::UserAgent->new;
    $_tamperagent->timeout($self->{'timeout'});
    return bless $self, $class;
}

=head2 replay

This function will replay all the requests provided in the xml file in sequential order.

=cut

#TODO: Add delay between requests
sub replay {
    my $self = shift;
    if (ref($_tamperxml->{tdRequest}) eq 'ARRAY') {
        for my $x (0..scalar $_tamperxml->{tdRequest}) {
        $self->_make_request($_tamperxml->{tdRequest}->[$x]);

        }
    } else {
        $self->_make_request($_tamperxml->{tdRequest});
    }
    return 1;
}

=head2 requestfilter

Callback function that allows inspection/tampering of the uri and parameters before the request is performed.

=cut

sub requestfilter {
    my ($self, $callback) = @_;
    $self->{requestfilter}{module} = caller;
    $self->{requestfilter}{function} = $callback;
    return 1;
}

=head2 responsefilter

Callback function that allows inspection of the response object.

=cut

sub responsefilter {
    my ($self, $callback) = @_;
    $self->{responsefilter}{module} = caller;
    $self->{responsefilter}{function} = $callback;
    return 1;
}

# Internal functions

sub _make_request {
    my ($self, $uriobj) = @_;
    # TODO: Make this _process_request_filter() & support multiple filters
    if ($self->{requestfilter}) {
	my $rqfclass = $self->{requestfilter}{module};
        my $rqfmethod = $self->{requestfilter}{function};
        eval { $rqfclass->$rqfmethod($uriobj); };
        carp "Request filter errors:\n $@" if ($@);
    }
    $uriobj->{uri} =~ s/%([0-9A-F][0-9A-F])/pack("c",hex($1))/gei;
    my $request = HTTP::Request->new($uriobj->{tdRequestMethod} => "$uriobj->{uri}");
    my $request_headers = $uriobj->{tdRequestHeaders}{tdRequestHeader};
    foreach my $header (keys %{$request_headers} ) {
        $request_headers->{$header}{content} =~ s/%([0-9A-F][0-9A-F])/pack("c",hex($1))/gei;
        $request->push_header($header => $request_headers->{$header}{content});
    }
    my $response = $_tamperagent->request($request);
    # TODO: Make this into _process_response_filter() & support multiple filters
    if ($self->{responsefilter}) {
        my $rpfclass = $self->{responsefilter}{module};
        my $rpfmethod = $self->{responsefilter}{function};
        eval { $rpfclass->$rpfmethod($uriobj, $response); };
        carp "Response filter errors:\n $@\n" if ($@);
    }
    if (!$response->is_success) {
        croak $response->status_line;
    }
    return $response;
}

sub _process_request_filter {
}

sub _process_response_filter {
}



=head1 AUTHOR

Eldar Marcussen, C<< <japh at justanotherhacker.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-www-tamperdata at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-TamperData>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::TamperData


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-TamperData>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-TamperData>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-TamperData>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-TamperData>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2009 Eldar Marcussen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::TamperData
