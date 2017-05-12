#!/usr/bin/perl -w

use strict;

=head1 NAME

atompost.pl - post Atom entries to an Atom editing endpoint

=head1 SYNOPSIS

    cat atomfeed.xml | atom2linkTL.pl | atompost.pl \
    'http://www.typepad.com/t/atom/lists/list_id=150635' user password

=head1 DESCRIPTION

C<atompost.pl> is an example script for XML::Atom::Filter that posts entries
in processed feeds to an Atom editing endpoint. The invocation syntax is:

=over 4

C<atompost.pl> I<endpoint> I<username> I<password>

=back

Note when using Movable Type to use your Atom authentication token for the
I<password> parameter.

=head1 AUTHOR

Mark Paschal, C<< <markpasc@markpasc.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-atom-filter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Atom-Filter>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Mark Paschal, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package AtomPost;
use XML::Atom::Filter;
use base qw( XML::Atom::Filter );

use XML::Atom::Client;
use Storable;

my ($PostURI, $api, $seen);

sub pre {
	$PostURI = shift @ARGV;
	$api = XML::Atom::Client->new;
	$api->username(shift @ARGV);
	$api->password(shift @ARGV);

	$seen = retrieve('posted_uris') if -e 'posted_uris';
}

sub entry {
	my ($class, $e) = @_;
	my $id = join "\n", $e->id, $PostURI;
	return if $seen->{$id};
	$seen->{$id} = $api->createEntry($PostURI, $e)
		or die $api->errstr;
}

sub post { store $seen, 'posted_uris'; }

package main;
AtomPost->filter;
