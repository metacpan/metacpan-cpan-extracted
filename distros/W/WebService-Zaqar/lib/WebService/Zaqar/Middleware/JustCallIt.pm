package WebService::Zaqar::Middleware::JustCallIt;

# ABSTRACT: middleware to follow hrefs provided by the user

use URI;

use Moose;
extends 'Net::HTTP::Spore::Middleware';

sub call {
    my ($self, $request) = @_;
    my %method_params = @{$request->env->{'spore.params'} || []};
    if (my $explicit_url = $method_params{__url__}) {
        $explicit_url = URI->new($explicit_url);
        $request->env->{PATH_INFO} = $explicit_url->rel($request->_uri_base)->path;
        $request->env->{'spore.params'} = [ $explicit_url->query_form ];
    }
}

1;
