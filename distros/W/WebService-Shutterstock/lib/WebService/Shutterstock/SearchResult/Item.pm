package WebService::Shutterstock::SearchResult::Item;
{
  $WebService::Shutterstock::SearchResult::Item::VERSION = '0.006';
}

# ABSTRACT: role representing common attributes for various search result types

use strict;
use warnings;
use Moo::Role;

has web_url     => ( is => 'ro' );
has description => ( is => 'ro' );


1;

__END__

=pod

=head1 NAME

WebService::Shutterstock::SearchResult::Item - role representing common attributes for various search result types

=head1 VERSION

version 0.006

=head1 ATTRIBUTES

=head2 web_url

=head2 description

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Brian Phillips and Shutterstock, Inc. (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
