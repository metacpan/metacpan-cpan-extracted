package WebService::Zaqar::Middleware::DateHeader;

# ABSTRACT: middleware for adding a Date header to all requests

use Moose;
extends 'Net::HTTP::Spore::Middleware';

use HTTP::Date;

sub call {
    my ($self, $req) = @_;
    $req->header('Date' => HTTP::Date::time2str);
}

1;
