package WebService::GialloZafferano::Recipe;
use Mojo::Base -base;
use WebService::GialloZafferano::Ingredient;
use Mojo::UserAgent;
use Encode;

=encoding utf-8

=head1 NAME

WebService::GialloZafferano::Recipe - Represent a recipe of GialloZafferano.it website

=head1 SYNOPSIS

  my $Recipe = WebService::GialloZafferano::Recipe->new();

=head1 DESCRIPTION

WebService::GialloZafferano::Recipe represent a Recipe of the site GialloZafferano.it .

=head1 ATTRIBUTES

=over

=item title

  $Recipe->title() #gets the title of the recipe
  $Recipe->title("Spaghetti allo Scoglio") #sets the title of the recipe

returns undef on error

=item url

  $Recipe->url() #gets the of the recipe
  $Recipe->url("http://...") #sets the url

returns undef on error

=back 

=head1 METHODS

=over

=item text

	$Recipe->text() #gets the text of the recipe

returns undef on error

=item ingredients

	$Recipe->ingredients() #gets the ingredients of the recipe

It returns an array of L<WebService::GialloZafferano::Ingredients>.
returns undef on error

=back 

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014 mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WebService::GialloZafferano>, L<WebService::GialloZafferano::Ingredient>

=cut

has 'title';
has 'url';
has '_ingredients';
has '_text';
has 'ua' => sub { Mojo::UserAgent->new };

sub text {
    my $self = shift;
    return $self->{'_text'} if exists $self->{'_text'};
    my $url = shift || $self->url;

    # Form POST with exception handling
    my $tx = $self->ua->max_redirects(2)->get($url);
    if ( my $res = $tx->success ) {
    	$self->_text(encode_utf8($res->dom->find("div.steps")->first->text));
        return $self->_text;
    }
    else {
        my ( $err, $code ) = $tx->error;
        say $code ? "$code response: $err" : "Connection error: $err";
        return undef;
    }
}

sub ingredients {
    my $self = shift;
    return $self->{'_ingredients'} if exists $self->{'_ingredients'};
    my $url = shift || $self->url;
    # Form POST with exception handling
    my $tx = $self->ua->max_redirects(2)->get( $url );
    if ( my $res = $tx->success ) {
        my %Ingredients = $res->dom->find("dd.ingredient")->map(
            sub {
                $_->find('em')->text =>
                    WebService::GialloZafferano::Ingredient->new(
                    name     => $_->find('em')->first->text,
                    quantity => $_->find('span')->first->text
                    );
            }
        )->each;
        $self->_ingredients(values %Ingredients);
        return
            values %Ingredients
            ;    #returns uniques WebService::GialloZafferano::Ingredient
    }
    else {
        my ( $err, $code ) = $tx->error;
        say $code ? "$code response: $err" : "Connection error: $err";
        return undef;
    }
}
1;
