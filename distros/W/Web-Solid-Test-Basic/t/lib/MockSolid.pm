=pod

=encoding utf-8

=head1 NAME

MockSolid - Very minimal mock implementation to test the Solid tests

=head1 DESCRIPTION

This is a very minimal L<Web::Simple> Web server to allow some minimal
test scripts to run against an actual server, to test that the test
scripts themselves run.


=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is Copyright (c) 2019 by Inrupt Inc.

This is free software, licensed under:

  The MIT (X11) License


=cut

use strict;
use warnings;
use Plack::Request;

package MockSolid;
use Web::Simple;
use Plack::Middleware::CrossOrigin;
use parent qw( Plack::Component );

sub dispatch_request {
  'HEAD'=> sub {
	 [ 200,
		[ 'Content-type', 'text/turtle',
		  'Link', '<.acl>; rel="acl", <.meta>; rel="describedBy", <http://www.w3.org/ns/ldp#Resource>; rel="type"'
		],
		[ '' ]
	  ]
	 },
  'GET + /**'=> sub {
	 Plack::Middleware::CrossOrigin->new(origins => 'https://app.example');
  },
	 'GET + /public/**'=> sub {
    [ 200, [ 'Content-type', 'text/turtle' ], [ '</public/verypublic/foobar.ttl#dahut> a <http://example.org/Cryptid> .' ] ]
  },
  'GET + /public/**/'=> sub {
    [ 200, [ 'Content-type', 'text/turtle' ], [ '</public/verypublic/foobar.ttl#dahut> a <http://example.org/Cryptid> .' ] ]
  },
  'PUT + /**' => sub {
    [ 201, [ 'Content-type', 'text/turtle' ], [ '' ] ]
  },
  'POST + /public/' => sub {
    [ 201, [ 'Content-type', 'text/turtle',
				 'Location', '/public/sluggish/'
			  ], [ '' ] ]
  },
  'DELETE + /public/sluggish/' => sub {
    [ 204, [ '' ], [ '' ] ]
  },
  '' => sub {
    [ 405, [ 'Content-type', 'text/plain' ], [ 'Method not allowed' ] ]
  }
}


1;

