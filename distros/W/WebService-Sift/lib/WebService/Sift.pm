package WebService::Sift;

use Modern::Perl;
use Mouse;

# ABSTRACT: WebService::Sift - an interface to siftscience.com's Events, Score and Label APIs using Web::API

our $VERSION = '0.2'; # VERSION

with 'Web::API';


has 'commands' => (
    is      => 'rw',
    default => sub {
        {
            # events
            create_order => {
                path               => 'events',
                default_attributes => { '$type' => '$create_order' },
                mandatory          => ['$type'],
            },
            transaction => {
                path               => 'events',
                default_attributes => { '$type' => '$transaction' },
                mandatory          => [ '$type', '$user_id' ],
            },
            create_account => {
                path               => 'events',
                default_attributes => { '$type' => '$create_account' },
                mandatory          => [ '$type', '$user_id' ],
            },
            update_account => {
                path               => 'events',
                default_attributes => { '$type' => '$update_account' },
                mandatory          => [ '$type', '$user_id' ],
            },
            add_item => {
                path               => 'events',
                default_attributes => { '$type' => '$add_item_to_cart' },
                mandatory          => ['$type'],
            },
            remove_item => {
                path               => 'events',
                default_attributes => { '$type' => '$remove_item_to_cart' },
                mandatory          => ['$type'],
            },
            submit_review => {
                path               => 'events',
                default_attributes => { '$type' => '$submit_review' },
                mandatory          => ['$type'],
            },
            send_message => {
                path               => 'events',
                default_attributes => { '$type' => '$send_message' },
                mandatory          => ['$type'],
            },
            login => {
                path               => 'events',
                default_attributes => { '$type' => '$login' },
                mandatory =>
                    [ '$type', '$user_id', '$session_id', '$login_status' ],
            },
            logout => {
                path               => 'events',
                default_attributes => { '$type' => '$logout' },
                mandatory          => [ '$type', '$user_id' ],
            },
            link_session_to_user => {
                path               => 'events',
                default_attributes => { '$type' => '$link_session_to_user' },
                mandatory          => [ '$type', '$user_id', '$session_id' ],
            },
            custom => {
                path      => 'events',
                mandatory => ['$type'],
            },

            # score
            score => {
                path      => 'score/:user_id',
                method    => 'GET',
                mandatory => ['api_key'],
            },

            # labels
            label => {
                path      => 'users/:$user_id/labels',
                mandatory => ['$is_bad']
            },
        };
    },
);


sub commands {
    my ($self) = @_;
    return $self->commands;
}


sub BUILD {
    my ($self) = @_;

    $self->user_agent(__PACKAGE__ . ' ' . $WebService::Sift::VERSION);
    $self->default_method('POST');
    $self->content_type('application/json');
    $self->base_url('https://api.siftscience.com/v203');
    $self->auth_type('hash_key');
    $self->api_key_field('$api_key');

    return $self;
}


1;    # End of WebService::Sift

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Sift - WebService::Sift - an interface to siftscience.com's Events, Score and Label APIs using Web::API

=head1 VERSION

version 0.2

=head1 SYNOPSIS

Please refer to the API documentation at L<https://siftscience.com/resources/references/events-api.html>

    use WebService::Sift;
    
    my $ws = WebService::Sift->new(api_key => 'XXX', debug => 1);
    
    # send a transaction event
    my $response = $ws->transaction(
        '$user_id'       => 'some@email.user',
        '$currency_code' => 'USD',
        '$amount'        => 500000,   # $50
    );
    
    # get score for a user_id
    # unfortunately due to some weird variable naming decisions at SiftScience
    # the api_key has to be passed in here as well
    $response = $ws->score(user_id => 'some@email.user', api_key => 'XXX');
    
    # label a user_id as fraud
    $ws->label('$user_id' => 'some@email.user', '$is_bad' => 'true');

=head1 SUBROUTINES/METHODS

=head2 create_order

=head2 transaction

=head2 create_account

=head2 update_account

=head2 add_item

=head2 remove_item

=head2 submit_review

=head2 send_message

=head2 login

=head2 logout

=head2 link_session_to_user

=head2 custom

=head2 score

=head2 label

=head1 INTERNALS

=head2 BUILD

basic configuration for the client API happens usually in the BUILD method when using Web::API

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/nupfel/WebService::Sift/issues>.
Pull requests welcome.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Sift

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/nupfel/WebService::Sift>

=item * MetaCPAN

L<https://metacpan.org/module/WebService::Sift>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService::Sift>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService::Sift>

=back

=head1 AUTHOR

Tobias Kirschstein <lev@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Tobias Kirschstein.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
