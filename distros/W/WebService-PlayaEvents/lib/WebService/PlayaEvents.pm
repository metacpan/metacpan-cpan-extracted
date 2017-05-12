package WebService::PlayaEvents;

use 5.010;
use Mouse;

# ABSTRACT: WebService::PlayaEvents - an interface to the burning man PlayaEvents API using Web::API

our $VERSION = '0.1'; # VERSION

with 'Web::API';


has 'commands' => (
    is      => 'rw',
    default => sub {
        {
            # events
            list_events =>
                { path => 'event', optional => [ 'start_time', 'end_time' ], },
            get_event => { path => 'event/:id' },

            # camps
            list_camps => { path => 'camp' },
            get_camp   => { path => 'camp/:id' },

            # art installations
            list_art => { path => 'art' },
            get_art  => { path => 'art/:id' },

            # street names
            list_cstreet => { path => 'cstreet' },
            list_tstreet => { path => 'tstreet' }, };
    },
);

has 'year' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 2013 },
);


sub commands {
    my ($self) = @_;
    return $self->commands;
}


sub BUILD {
    my ($self) = @_;

    $self->user_agent(__PACKAGE__ . ' ' . $WebService::PlayaEvents::VERSION);
    $self->content_type('application/json');
    $self->base_url('http://playaevents.burningman.com/api/0.2/' . $self->year);

    return $self;
}


1;    # End of WebService::PlayaEvents

__END__

=pod

=head1 NAME

WebService::PlayaEvents - WebService::PlayaEvents - an interface to the burning man PlayaEvents API using Web::API

=head1 VERSION

version 0.1

=head1 SYNOPSIS

Please refer to the API documentation at L<http://playaevents.burningman.com/api/0.2/docs/>

    use WebService::PlayaEvents;
    
    my $pe = WebService::PlayaEvents->new(
        debug => 1,
        year => 2013,
    );
    
    my $response = $pe->list_events(
        start_time => '2013-09-01 18:00',
        end_time => '2013-09-02 20:00',
    );

=head1 SUBROUTINES/METHODS

=head2 list_events

=head2 get_event

=head2 list_camps

=head2 get_camp

=head2 list_art

=head2 get_art

=head2 list_cstreet

=head2 list_tstreet

=head1 INTERNALS

=head2 BUILD

basic configuration for the client API happens usually in the BUILD method when using Web::API

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/nupfel/WebService-PlayaEvents/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::PlayaEvents

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/nupfel/WebService-PlayaEvents>

=item * MetaCPAN

L<https://metacpan.org/module/WebService::PlayaEvents>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService::PlayaEvents>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService::PlayaEvents>

=back

=head1 AUTHOR

Tobias Kirschstein <lev@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Tobias Kirschstein.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
