package WWW::FMyLife;

use Moose;
use XML::Simple;
use LWP::UserAgent;
use WWW::FMyLife::Item;

our $VERSION = '0.15';

has 'username' => ( is => 'rw', isa => 'Str' );
has 'password' => ( is => 'rw', isa => 'Str' );

has 'language' => ( is => 'rw', isa => 'Str', default => 'en'       );
has 'token'    => ( is => 'rw', isa => 'Str', default => q{}        );
has 'key'      => ( is => 'rw', isa => 'Str', default => 'readonly' );

# XXX: is there a point to this? is this wannabe caching?
has 'pages'    => ( is => 'rw', isa => 'Int' );

has 'api_url'  => (
    is      => 'rw',
    isa     => 'Str',
    default => 'http://api.betacie.com',
);

has 'module_error' => (
    is      => 'rw',
    isa     => 'Str',
    clearer => 'clear_module_error',
);

has 'fml_errors'   => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    clearer => 'clear_fml_errors',
);

has 'error'        => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'agent'    => (
    is      => 'rw',
    isa     => 'Object',
    default => sub { LWP::UserAgent->new(); },
);

# Credentials sub: sets username and password as an array
sub credentials {
    my ( $self, $user, $pass ) = @_;
    $self->username ( $user );
    $self->password ( $pass );

    return;
}

sub top {
    my ( $self, $opts ) = @_;
    my @items = $self->_parse_options( $opts, 'top' );
    return @items;
}

sub top_day {
    my ( $self, $opts ) = @_;
    my @items = $self->_parse_options( $opts, 'top_day' );
    return @items;
}

sub top_week {
    my ( $self, $opts ) = @_;
    my @items = $self->_parse_options( $opts, 'top_week' );
    return @items;
}

sub top_month {
    my ( $self, $opts ) = @_;
    my @items = $self->_parse_options( $opts, 'top_month' );
    return @items;
}

sub flop {
    my ( $self, $opts ) = @_;
    my @items = $self->_parse_options( $opts, 'flop' );
    return @items;
}

sub flop_day {
    my ( $self, $opts ) = @_;
    my @items = $self->_parse_options( $opts, 'flop_day' );
    return @items;
}

sub flop_week {
    my ( $self, $opts ) = @_;
    my @items = $self->_parse_options( $opts, 'flop_week' );
    return @items;
}

sub flop_month {
    my ( $self, $opts ) = @_;
    my @items = $self->_parse_options( $opts, 'flop_month' );
    return @items;
}

sub last {
    my ( $self, $opts ) = @_;
    my $type = 'last';

    if ( ref $opts eq 'HASH' && $opts->{'category'} ) {
        $type = $opts->{'category'};
    }

    my @items = $self->_parse_options( $opts, $type );
    return @items;
}

sub get_id {
    my ( $self, $id, $opts ) = @_;
    $opts->{'page'} = '/nocomment';
    my @items = $self->_parse_options( $opts, $id  );
    return @items;
}

sub random {
    my $self = shift;
    my $xml  = $self->_fetch_data('/view/random');
    my $item = $self->_parse_item_as_object($xml);
    return $item;
}

sub _parse_options {
    my ( $self, $opts, $add_url ) = @_;
    my ( $as,   $page );

    if ( ref $opts eq 'HASH' ) {
        $as   = $opts->{'as'};
        $page = $opts->{'page'};
    } else {
        $page = $opts;
    }

    $as   ||= 'object';
    $page ||= q{};

    my %types = (
        object => sub { return $self->_parse_items_as_object(@_) },
        text   => sub { return $self->_parse_items_as_text  (@_) },
        data   => sub { return $self->_parse_items_as_data  (@_) },
    );

    my $xml = $self->_fetch_data("/view/$add_url/$page");

    $xml || return;

    if ( my $id = $xml->{'items'}{'item'}{'id'} ) {
        $xml->{'items'}{'item'} = { $id => $xml{'items'}{'item'} };
        $xml->{'pages'}         = 1;
    }

    $self->pages( $xml->{'pages'} );

    my @items = $types{$as}->($xml);

    return @items;
}

sub _fetch_data {
    my ( $self, $add_to_url ) = @_;

    my $res = $self->agent->post(
        $self->api_url . $add_to_url, {
            key      => $self->key,
            language => $self->language,
        },
    );

    $self->error(0);
    $self->clear_fml_errors;
    $self->clear_module_error;

    if ( ! $res->is_success ) {
        $self->error(1);
        $self->module_error( $res->status_line );
        return;
    }

    my $xml = XMLin( $res->decoded_content );

    if ( my $raw_errors = $xml->{'errors'}->{'error'} ) {
        my $array_errors =
            ref $raw_errors eq 'ARRAY' ? $raw_errors : [ $raw_errors ];

        $self->error(1);
        $self->fml_errors($array_errors);
        return;
    }

    return $xml;
}

sub _parse_item_as_object {
    # this parses a single item
    my ( $self, $xml ) = @_;

    my %item_data = %{ $xml->{'items'}{'item'} };
    my $item      = WWW::FMyLife::Item->new();

    foreach my $attr ( keys %item_data ) {
        $item->$attr( $item_data{$attr} );
    }

    return $item;
}

sub _parse_items_as_object {
    # this parses multiple items
    my ( $self, $xml ) = @_;
    my @items;

    while ( my ( $id, $item_data ) = each %{ $xml->{'items'}{'item'} } ) {
        my $item = WWW::FMyLife::Item->new(
            id => $id,
        );

        foreach my $attr ( keys %{$item_data} ) {
            $item->$attr( $item_data->{$attr} );
        }

        push @items, $item;
    }

    return @items;
}

sub _parse_items_as_text {
    my ( $self, $xml ) = @_;
    my @items = map { $_->{'text'} } values %{ $xml->{'items'}{'item'} };
    return @items;
}

sub _parse_items_as_data {
    my ( $self, $xml ) = @_;
    my $itemsref       = $xml->{'items'}{'item'};
    my @items          = map +{ $_ => $itemsref->{$_} }, keys %{$itemsref};
    return @items;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WWW::FMyLife - Obtain FMyLife.com anecdotes via API

=head1 VERSION

Version 0.15

=head1 SYNOPSIS

THIS MODULE IS STILL UNDER INITIAL DEVELOPMENT! BE WARNED!

    use WWW::FMyLife;

    my $fml = WWW::FMyLife->new();
    print map { "Items: $_\n" } $fml->last( { as => text' } );

=head1 DESCRIPTION

This module fetches FMyLife.com (FML) anecdotes, comments, votes and more via API, comfortably and in an extensible manner.

    my @items = $fml->top_daily();
    foreach my $item (@items) {
        my $item_id      = $item->id;
        my $item_content = $item->content;
        print "[$item_id] $item_content\n";
    }

    print $fml->random()->text, "\n";
    ...

=head1 EXPORT

This module exports nothing.

=head1 SUBROUTINES/METHODS

=head2 last()

Fetches the last quotes. Can accept a hashref that indicates the formatting:

    # returns an array of WWW::FMyLife::Item objects
    $fml->last();

    # or more explicitly
    $fml->last( { as => 'object' } ); # same as above
    $fml->last( { as => 'text'   } ); # returns an array of text anecdotes
    $fml->last( { as => 'data'   } ); # returns an array of hashes of anecdotes

You can also specify which page you want:

    # return 1st page
    my @last = fml->last();

    # return 5th page
    my @last = $fml->last(5);

    # same
    my @last = $fml->last( { page => 5 } );

And options can be mixed:

    my @not_so_last = $fml->last( { as => 'text', page => 50 } );

=head2 random

This method gets a single random quote as an object.

=head2 top

This method works the same as the last() method, only it fetches the top quotes.

This method, as for its variations, can format as an object, text or data.

=head2 top_day

This method works the same as the last() method, only it fetches the top quotes.

This specific variant fetches the top anecdotes from the last day.

=head2 top_week

This method works the same as the last() method, only it fetches the top quotes.

This specific variant fetches the top anecdotes from the last week.

=head2 top_month

This method works the same as the last() method, only it fetches the top quotes.

This specific variant fetches the top anecdotes from the last month.

=head2 flop

Fetches the flop quotes.

This method, as for its variations, can format as an object, text or data.

=head2 flop_day

Fetches the flop quotes of the day.

=head2 flop_week

Fetches the flop quotes of the week.

=head2 flop_month

Fetches the flop quotes of the month.

=head2 credentials( $username, $password ) (NOT YET FULLY IMPLEMENTED)

WARNING: THIS HAS NOT YET BEEN IMPLEMENTED.

THE TESTS HAVE BEEN DISABLED FOR NOW, PLEASE WAIT FOR A MORE ADVANCED VERSION.

Sets credentials for members.

    $fml->credentials( 'foo', 'bar' );

    # same thing
    $fml->username('foo');
    $fml->password('bar');

=head1 AUTHOR

Sawyer X (XSAWYERX), C<< <xsawyerx at cpan.org> >>

Tamir Lousky (TLOUSKY), C<< <tlousky at cpan.org> >>

=head1 DEPENDENCIES

L<Moose>

L<XML::Simple>

L<LWP::UserAgent>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-www-fmylife at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-FMyLife>.

You can also use the Issues Tracker on Github @ L<http://github.com/xsawyerx/www-fmylife/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::FMyLife

You can also look for information at:

=over 4

=item * Our Github!

L<http://github.com/xsawyerx/www-fmylife/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-FMyLife>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-FMyLife>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-FMyLife>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-FMyLife/>

=item * FML (FMyLife)

L<http://www.fmylife.com>

=back

=head1 SEE ALSO

=over 4

=item * L<WWW::VieDeMerde>

Apparently supports more options right now. Mainly for French version but seems to support English as well.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sawyer X, Tamir Lousky.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

