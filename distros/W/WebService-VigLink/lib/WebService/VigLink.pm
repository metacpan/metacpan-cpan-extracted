package WebService::VigLink;

use strict;
use warnings;

=head1 NAME

WebService::VigLink - Interface to the VigLink web API

=cut

our $VERSION = 0.06;

use Any::URI::Escape;

=head1 METHODS

=over 4

=item new()

 $VigLink = WebService::VigLink->new({ key => $apikey })

See http://www.viglink.com/corp/api for the low level details and where
to obtain an API key.

=cut

sub new {
    my ($class, $args) = @_;
    
    die "You need an api key to access the VigLink API, args "
        unless (defined $args->{key});

    my %self; # old school OO

    $self{key}     = $args->{key};
    $self{format}  = $args->{format} || 'go'; # default to 301

    bless \%self, $class;

    return \%self;
}

=item make_url()

 $api_url = $VigLink->make_url({ out      => $click_destination,
                                 cuid     => $anonymous_user_id,
                                 txt      => $text_of_link,
                                 loc      => $current_webpage,
                                 title    => $current_page_title,
                                 referrer => $referring_page, });

Returns a VigLink href.  Dies on missing args.

=cut


sub make_url {
    my ($self, $args) = @_;

    foreach my $param ( qw( out cuid txt loc title referrer ) ) {
        die "missing param $param" unless defined $args->{$param};
    }

    my $url = sprintf("http://api.viglink.com/api/click?title=%s&key=%s&out=%s&format=%s&cuid=%s&loc=%s&txt=%s&ref=%s",
        uri_escape($args->{'title'}),
        $self->{'key'},
        uri_escape($args->{'out'}),
        $self->{'format'},
        $args->{'cuid'},
        uri_escape($args->{'loc'}),
        uri_escape($args->{'txt'}),
        uri_escape($args->{'referrer'}),);

    return $url;
}

1;


=back

=head1 SYNOPSIS

  use WebService::VigLink;
  $VigLink = WebService::VigLink->new({ key => $api_key });
  $affiliate_url = $VigLink->make_url({ ... });

=head1 DESCRIPTION

Simple encapsulation of the VigLink API.

=head1 AUTHOR

"Fred Moyer", E<lt>fred@slwifi.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Silver Lining Networks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
