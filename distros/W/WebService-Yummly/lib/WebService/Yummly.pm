package WebService::Yummly;

# ABSTRACT: get search and get a recipe from Yummly

use strict;
use warnings;

use URL::Encode;
use WebService::Simple;
use Data::Dumper;

our $VERSION = '1.3';


sub new {
    my ($class, $APP_ID, $APP_KEY, $id) = @_ ;
    my $obj = bless {}, $class ;

    my $string = "" ;
    if (defined $id) {
      $string = "recipe/$id" ;
    }

    # Simple use case
    $obj->{wss} = WebService::Simple->new
      (
       base_url => "http://api.yummly.com/v1/api/" . $string,
       response_parser => 'JSON',
       param    =>
       {
        _app_id  => $APP_ID,
        _app_key => $APP_KEY,
       }
      );
    return $obj ;
}

sub search {
  my ($self, $search) = @_;

  my $wss = $self->{wss};
  my $ret = $wss->
    get( "recipes", { q => $search } ) ;
  my $json = $ret->parse_response;
  return $json;
}


sub get_recipe {
  my $self = shift;
  my $wss = $self->{wss};
  my $ret = $wss->get() ;
  my $json = $ret->parse_response;
  return $json;
}

1;

=pod

=head1 NAME

WebService::Yummly - Simple interface to the search and recipe interface to Yummly

=head1 SYNOPSIS

  use WebService::Yummly;

  # use your ID/key here
  my $APP_ID = "2f6cfcff";
  my $APP_KEY = "a3cec319936cdf2fb03f4b0f5dfdaf4e";
  my $y = WebService::Yummly->new($APP_ID, $APP_KEY);
  my $recipes = $y->search("lamb shank");

  my $r = WebService::Yummly->new($APP_ID, $APP_KEY, "Sunday-Supper_-Curried-Lamb-Shanks-Serious-Eats-42000");
  ok($r,"new yummly");

  my $recipe = $r->get_recipe ;

=head1 DESCRIPTION

  Search and retrieve recipe from Yummly

=head1 FUNCTIONS

=head2 new

  my $y = WebService::Yummly->new($APP_ID, $APP_KEY);

Create a new Yummly object passing in credentials.

=head2 search

  $recipes = $y->search("lamb shank") ;

Return a JSON structure containing matching recipes.

=head2 get_recipe

  my $r = WebService::Yummly->new($APP_ID, $APP_KEY, "Sunday-Supper_-Curried-Lamb-Shanks-Serious-Eats-42000");
  my $recipe = $r->get_recipe ;

Return a JSON data structure with recipe information.

=head1 DIAGNOSTICS

=head1 SUPPORT

=head2 BUGS

Please report any bugs by email to C<bug-webservice-yummly at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=WebService-Yummly>.
You will be automatically notified of any progress on the request by the system.

=head2 SOURCE CODE

This is open source software. The code repository is available for public
review and contribution under the terms of the license.

L<https://github.com/davehodg/Webservice-Yummly/>

    git clone https://github.com/davehodg/Webservice-Yummly

=head1 AUTHOR

Dave Hodgkinson C<davehodg@cpan.org>

=head1 COPYRIGHT

Copyright 2014 by Dave Hodgkinson

This library is under the Artistic License.

