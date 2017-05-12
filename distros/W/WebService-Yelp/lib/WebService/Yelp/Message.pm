package WebService::Yelp::Message;

use strict;
use warnings;

use base qw/Class::Accessor/;
__PACKAGE__->mk_ro_accessors(qw/version text code/);

=head1 NAME

  WebService::Yelp::Message - Yelp.com API Message Class

=head1 SYNOPSIS

 use strict;
 use WebService::Yelp;

 my $yelp = WebService::Yelp->new({ywsid => 'XXXXXXXXXXXX'});

 my $biz_res = $yelp->search_review_hood({
                                             term => 'cream puffs',
                                             location => 'San Francisco',
                                             };
 my $message = $biz_res->message();

 if($message->code() == 0) {
   # everything is ok, continue with search results processing
 }
 else {
   print "search failed with code:" . $message->code() . ":" . 
     $message->text();
 }


=head1 DESCRIPTION

This class represents the status of a search result. A code of 0 means success,
otherwise something bad happened.

  http://www.yelp.com/developers/documentation/search_api


=head1 METHODS (Read Only)

=head2 code

The response code

=head2 text

The response message.

=head2 version

The API version

=cut 
1;
