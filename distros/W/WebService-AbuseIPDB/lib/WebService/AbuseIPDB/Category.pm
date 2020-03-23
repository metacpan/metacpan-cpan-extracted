package WebService::AbuseIPDB::Category;
#
#===============================================================================
#
#         FILE: Category.pm
#
#  DESCRIPTION: Category class
#
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 16/08/19 17:02:49
#===============================================================================

use strict;
use warnings;

use Carp;
use Scalar::Util 'blessed';
use WebService::AbuseIPDB;

our $VERSION = $WebService::AbuseIPDB::VERSION;

my %by_id = (
	1 	=> 'DNS Compromise',
	2 	=> 'DNS Poisoning',
	3 	=> 'Fraud Orders',
	4 	=> 'DDoS Attack',
	5 	=> 'FTP Brute-Force',
	6 	=> 'Ping of Death',
	7 	=> 'Phishing',
	8 	=> 'Fraud VoIP',
	9 	=> 'Open Proxy',
	10 	=> 'Web Spam',
	11 	=> 'Email Spam',
	12 	=> 'Blog Spam',
	13 	=> 'VPN IP',
	14 	=> 'Port Scan',
	15 	=> 'Hacking',
	16 	=> 'SQL Injection',
	17 	=> 'Spoofing',
	18 	=> 'Brute-Force',
	19 	=> 'Bad Web Bot',
	20 	=> 'Exploited Host',
	21 	=> 'Web App Attack',
	22 	=> 'SSH',
	23 	=> 'IoT Targeted',
);

my %by_name;
$by_name{$by_id{$_}} = $_ for keys %by_id;

sub new {
	my ($class, $cat) = @_;
	my $self;
	unless (defined $cat) {
		carp "'new' requires an argument";
		return;
	}
	if ($by_id{$cat}) {
		$self = { id => $cat, name => $by_id{$cat} };
	} elsif ($by_name{$cat}) {
		$self = { id => $by_name{$cat}, name => $cat };
	} elsif (blessed ($cat) && $cat->isa ($class)) {
		return $cat;
	} else {
		carp "'$cat' is not a valid category identifier";
		return;
	}
	bless ($self, $class);
	return $self;
}

# Accessors

sub id   { return shift->{id}   };
sub name { return shift->{name} };

1;

__END__

=pod

=encoding utf8

=head1 NAME

WebService::AbuseIPDB::Category - Category names and numbers for
WebService::AbuseIPDB

=head1 SYNOPSIS

	use WebService::AbuseIPDB::Category;

	my $cat = WebService::AbuseIPDB::Category->new (18);
	print $cat->name;

	$cat = WebService::AbuseIPDB::Category->new ('Web App Attack');
	print $cat->id;

=head1 DESCRIPTION

This class stores a list of category IDs and names for use with
L<WebService::AbuseIPDB>.

=head2 METHODS

=head2 new

	my $catobj = WebService::AbuseIPDB::Category->new ($category)

The constructor takes one argument which is the category to be
instantiated. This should be either the number of the category or the
name of the category. If called with an existing category object it will
return that same object as a no-op. If you would prefer a copy of the
object then call it with the name or number instead. eg.

	my $catcopy = WebService::AbuseIPDB::Category->new ($catobj->id)

=head2 id

	my $id = $catobj->id;
	printf "%i\n", $id;

A method for returning the numerical ID of the category.

=head2 name

	my $name = $catobj->name;
	printf "%s\n", $name;

A method for returning the name of the category.

=head1 AUTHOR

Pete Houston, C<< <cpan at openstrike.co.uk> >>

=head1 SEE ALSO

L<WebService::AbuseIPDB>, L<https://www.abuseipdb.com/categories>

=head1 LICENCE AND COPYRIGHT

Copyright © 2020 Pete Houston

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=cut
