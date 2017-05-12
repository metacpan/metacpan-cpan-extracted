package WebService::GialloZafferano;

use strict;
use 5.008_005;
use Mojo::UserAgent;
use Encode;
use Mojo::Base -base;
use Mojo::DOM;
use feature 'say';
use List::Util qw( min );
use WebService::GialloZafferano::Recipe;
use WebService::GialloZafferano::Ingredient;

our $VERSION = '0.02';

=encoding utf-8

=head1 NAME

WebService::GialloZafferano - Perl interface to GialloZafferano.it website to find cooking recipes

=head1 SYNOPSIS

  my $Cook = WebService::GialloZafferano->new();
  my @recipes = $Cook->search("Spaghetti"); # It returns a list of WebService::GialloZafferano::Recipe 
  my $spaghetti_recipe= $recipes[0]->text; #i wanna knew more about that recipe
  my @Ingredients = $recipes[0]->ingredients(); # i'm not happy, wanna know the ingredients of the next one 
  # @Ingredients is a list of WebService::GialloZafferano::Ingredient

=head1 DESCRIPTION

WebService::GialloZafferano is a Perl interface to the site GialloZafferano.it, it allows to query the cooking recipes and get the ingredients

=head1 METHODS

=over

=item search

Takes input terms and process the GialloZafferano.it research.
It returns a list of L<WebService::GialloZafferano::Recipe>.

returns undef on error

=back 

=head1 ATTRIBUTES

=over

=item ua

Returns the L<Mojo::UserAgent> instance

=back 

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WebService::GialloZafferano::Recipe>, L<WebService::GialloZafferano::Ingredient>

=cut

has 'ua' => sub { Mojo::UserAgent->new };

sub search {
    my $self = shift;
    my $term = shift;

    # Form POST with exception handling
    my $tx = $self->ua->max_redirects(2)->post(
        'http://www.giallozafferano.it/ricerca-ricette/' => form => {
            'q'     => $term,
            'fakeq' => $term
        }
    );
    if ( my $res = $tx->success ) {
        my %ric = $res->dom->find('a[href]')->grep(
            sub {
                $_->attr("title")
                    and $_->attr('href')
                    =~ /ricette\.giallozafferano\.it\/.*\.html$/;
            }
            )->map(
            sub {
                $_->attr("title") => WebService::GialloZafferano::Recipe->new(
                    ua    => $self->ua,
                    title => $_->{'title'},
                    url   => $_->{'href'}
                );
            }
            )->each;
        my @ricette = values %ric;
        return
            @ricette
            ;    #returns an array of WebService::GialloZafferano::Recipe objs
    }
    else {
        my ( $err, $code ) = $tx->error;
        say $code ? "$code response: $err" : "Connection error: $err";
        return undef;
    }
}

1;
__END__
