package XML::Amazon;

use 5.008;

use strict;
use warnings;

use utf8;

use LWP::Simple qw ();
use XML::Simple;
use XML::Amazon::Item;
use XML::Amazon::Collection;
use Data::Dumper qw ();
use URI::Escape qw();
use Digest::SHA qw(hmac_sha256_hex hmac_sha256_base64);
use POSIX qw(strftime);

our $VERSION = '0.13';

sub new{
	my($pkg, %options) = @_;
	die 'No Access Key ID provided!' unless $options{'token'};
	die 'No Secret Access Key provided!' unless $options{'sak'};
	my $locale = $options{'locale'};
	$locale ||= "us";
	die "Invalid locale" unless $locale eq "jp" || $locale eq "uk" || $locale eq "fr" || $locale eq "us" || $locale eq "de"|| $locale eq "ca";
	my $associate = $options{'associate'} || 'webservices-20';

	my $url;

	$url = 'ecs.amazonaws.jp' if $locale eq "jp";
	$url = 'ecs.amazonaws.co.uk' if $locale eq "uk";
	$url = 'ecs.amazonaws.fr' if $locale eq "fr";
	$url = 'ecs.amazonaws.de' if $locale eq "de";
	$url = 'ecs.amazonaws.ca' if $locale eq "ca";
	$url = 'ecs.amazonaws.com' if $locale eq "us";


	my $req = {
		'Service' => 'AWSECommerceService',
		'AWSAccessKeyId' => $options{'token'},
		'AssociateTag' => $associate,
		'Version' => '2009-03-31',
		'Timestamp' => strftime( "%Y-%m-%dT%TZ", gmtime() )
	};

	bless{
		token => $options{'token'},
		sak => $options{'sak'},
		associate => $associate,
		locale => $locale,
		url => $url,
		req => $req,
		data => undef,
		success => '0'
	}, $pkg;
}

sub _get {
	my $self = shift;
	my $type = shift;
	my $query = shift;
	my $field = shift;
	$self->asin($query) if $type eq "asin";
	$self->search($query,$field) if $type eq "search";
}

sub asin{
	my $self = shift;
	my $asin = shift;
	my $url = $self->{url};
	my $ITEM = XML::Amazon::Item->new();

	warn 'Apparently not an appropriate ASIN' if $asin =~ /[^a-zA-Z0-9]/;

	my %params = %{$self->{req}};

	$params{'Operation'} = 'ItemLookup';
	$params{'ResponseGroup'} = 'Images,ItemAttributes';
	$params{'ItemId'} = $asin;
	$params{'Version'} = '2009-03-31';

	my $data = $self->_get_data(\%params);

	my $xs = new XML::Simple(SuppressEmpty => undef, ForceArray => ['Creator', 'Author', 'Artist', 'Director', 'Actor']);
	my $pl = $xs->XMLin($data);
	$self->{data} = $pl;

	if ($pl->{Items}->{Item}->{ASIN}){
	$ITEM->{asin} = $pl->{Items}->{Item}->{ASIN};
	$ITEM->{title} = $pl->{Items}->{Item}->{ItemAttributes}->{Title};
	$ITEM->{type} = $pl->{Items}->{Item}->{ItemAttributes}->{ProductGroup};


	if ($pl->{Items}->{Item}->{ItemAttributes}->{Author}->[0]){
		for (my $i = 0; $pl->{Items}->{Item}->{ItemAttributes}->{Author}->[$i]; $i++){
			$ITEM->{authors}->[$i] = $pl->{Items}->{Item}->{ItemAttributes}->{Author}->[$i];
		}
	}

	if ($pl->{Items}->{Item}->{ItemAttributes}->{Artist}->[0]){
		for (my $i = 0; $pl->{Items}->{Item}->{ItemAttributes}->{Artist}->[$i]; $i++){
			$ITEM->{artists}->[$i] = $pl->{Items}->{Item}->{ItemAttributes}->{Artist}->[$i];
		}
	}
	if ($pl->{Items}->{Item}->{ItemAttributes}->{Actor}->[0]){
		for (my $i = 0; $pl->{Items}->{Item}->{ItemAttributes}->{Actor}->[$i]; $i++){
			$ITEM->{actors}->[$i] = $pl->{Items}->{Item}->{ItemAttributes}->{Actor}->[$i];
		}
	}

	if ($pl->{Items}->{Item}->{ItemAttributes}->{Director}->[0]){
		for (my $i = 0; $pl->{Items}->{Item}->{ItemAttributes}->{Director}->[$i]; $i++){
			$ITEM->{directors}->[$i] = $pl->{Items}->{Item}->{ItemAttributes}->{Director}->[$i];
		}
	}


	if ($pl->{Items}->{Item}->{ItemAttributes}->{Creator}->[0]->{content}){
		for (my $i = 0; $pl->{Items}->{Item}->{ItemAttributes}->{Creator}->[$i]->{content}; $i++){
			$ITEM->{creators}->[$i] = $pl->{Items}->{Item}->{ItemAttributes}->{Creator}->[$i]->{content};
		}
	}


	$ITEM->{price} = $pl->{Items}->{Item}->{ItemAttributes}->{ListPrice}->{FormattedPrice};
	$ITEM->{author} = $ITEM->{authors}->[0];
	$ITEM->{url} = $pl->{Items}->{Item}->{DetailPageURL};
	$ITEM->{publisher} = $pl->{Items}->{Item}->{ItemAttributes}->{Publisher};
	$ITEM->{smallimage} = $pl->{Items}->{Item}->{SmallImage}->{URL};
	$ITEM->{mediumimage} = $pl->{Items}->{Item}->{MediumImage}->{URL};
	$ITEM->{mediumimage} = $ITEM->{smallimage} unless $ITEM->{mediumimage};
	$ITEM->{largeimage} = $pl->{Items}->{Item}->{LargeImage}->{URL};
	$ITEM->{largeimage} = $ITEM->{mediumimage} unless $ITEM->{largeimage};

	$self->{success} = '1';
	return $ITEM;
	}
	else{
	$self->{success} = '0';
	warn 'No item found';
	return '';
	}
}

sub search{
	my($self, %options) = @_;
	my $keywords = $options{'keywords'};
	my $type = $options{'type'} || "Blended";
	my $page = $options{'page'} || 1;

	my %params = %{$self->{req}};

	$params{'Operation'} = 'ItemSearch';
	$params{'SearchIndex'} = $type;
	$params{'ResponseGroup'} = 'Images,ItemAttributes';
	$params{'Keywords'} = $keywords;
	$params{'ItemPage'} = $page;

	my $data = $self->_get_data(\%params);

	my $xs = new XML::Simple(SuppressEmpty => undef, ForceArray => ['Item', 'Creator', 'Author', 'Artist', 'Actor', 'Director']);
	my $pl = $xs->XMLin($data);
	$self->{data} = $pl;

	my $collection = XML::Amazon::Collection->new();
	if ($pl->{Items}->{Item}->[0]->{ASIN}){
		$collection->{total_results} = $pl->{Items}->{TotalResults};
		$collection->{total_pages} = $pl->{Items}->{TotalPages};
		$collection->{current_page} = $pl->{Items}->{Request}->{ItemSearchRequest}->{ItemPage};

		for (my $i = 0; $pl->{Items}->{Item}->[$i]; $i++){

			my $new_item = XML::Amazon::Item->new();

			$new_item->{asin} = $pl->{Items}->{Item}->[$i]->{ASIN};
			$new_item->{title} = $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Title};
			$new_item->{publisher} = $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Publisher};
			$new_item->{url} = $pl->{Items}->{Item}->[$i]->{DetailPageURL};
			$new_item->{type} = $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{ProductGroup};

			if ($pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Author}->[0]){
				for (my $j = 0; $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Author}->[$j]; $j++){
					$new_item->{authors}->[$j] = $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Author}->[$j];
				}
			}

			if ($pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Artist}->[0]){
				for (my $j = 0; $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Artist}->[$j]; $j++){
					$new_item->{artists}->[$j] = $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Artist}->[$j];
				}
			}

			if ($pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Creator}->[0]->{content}){
				for (my $j = 0; $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Creator}->[$j]->{content}; $j++){
					$new_item->{creators}->[$j] = $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Creator}->[$j]->{content};
				}
			}

			if ($pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Director}->[0]){
				for (my $j = 0; $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Director}->[$j]; $j++){
					$new_item->{directors}->[$j] = $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Director}->[$j];
				}
			}


			if ($pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Actor}->[0]){
				for (my $j = 0; $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Actor}->[$j]; $j++){
					$new_item->{actors}->[$j] = $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{Actor}->[$j];
				}
			}



			$new_item->{price} = $pl->{Items}->{Item}->[$i]->{ItemAttributes}->{ListPrice}->{FormattedPrice};
			$new_item->{smallimage} = $pl->{Items}->{Item}->[$i]->{SmallImage}->{URL};
			$new_item->{mediumimage} = $pl->{Items}->{Item}->[$i]->{MediumImage}->{URL};
			$new_item->{mediumimage} = $new_item->{smallimage} unless $new_item->{mediumimage};
			$new_item->{largeimage} = $pl->{Items}->{Item}->[$i]->{LargeImage}->{URL};
			$new_item->{largeimage} = $new_item->{mediumimage} unless $new_item->{largeimage};

			$collection->add_Amazon($new_item);
		}
		$self->{success} = '1';
		return $collection;

	}

	else{
		$self->{success} = '0';
		warn 'No item found';
		return '';
	}
}

sub is_success {
	my $self = shift;
	return $self->{success};

}

sub _get_data {
	my $self = shift;
	my $params = shift;

	my $url = $self->{url};
	my @param;
	foreach my $key (sort { $a cmp $b } keys %{$params}){
		push @param, $key . '=' . URI::Escape::uri_escape(${$params}{$key}, "^A-Za-z0-9\-_.~");
	}

	my $string_to_sign = 'GET' . "\n" . $url . "\n" . '/onca/xml' . "\n" .  join('&', @param);

	my $sign = hmac_sha256_base64($string_to_sign,$self->{sak});

	while (length($sign) % 4) {
		$sign .= '=';
	}

	push @param, 'Signature=' . URI::Escape::uri_escape($sign, "^A-Za-z0-9\-_.~");

	my $data = LWP::Simple::get('http://' . $url . '/onca/xml?' . join('&', @param))
		or warn 'Couldn\'t get the XML';
	return $data;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::Amazon - Perl extension for getting information from Amazon

=head1 VERSION

version 0.13

=head1 SYNOPSIS

	use XML::Amazon;

	my $amazon = XML::Amazon->new(token => AMAZON-ID, sak => Secret Access Key, locale => 'uk');

	my $item = $amazon->asin('0596101058');## ASIN access

	if ($amazon->is_success){
		print $item->title;
	}

	my $items = $amazon->search(keywords => 'Perl');## Search by 'Perl'

	foreach my $item ($items->collection){
	my $title = $item->title;
	utf8::encode($title);
	print $title . "¥n";
	}

=head1 DESCRIPTION

XML::Amazon provides a simple way to get information from Amazon. I<XML::Amazon> can
connect to US, JP, UK, FR, DE and CA.

=head1 USAGE

=head2 XML::Amazon->new(token => AMAZON-ID, associate => ASSOCIATE-ID, sak => Secret Access Key, locale => UK)

Creates a new empty XML::Amazon object. You should specify your Amazon Web Service ID and Secret Access Key
(which can be obteined thorough
http://www.amazon.com/gp/aws/registration/registration-form.html). You can also specify
your locale (defalut: US; you can choose us, uk, jp, fr, de, ca) and your Amazon
associate ID (default: webservices-20, which is Amazon default).

=head2 $XML_Amazon->asin(ASIN)

Returns an XML::Amazon::Item object whose ASIN is as given.

=head2 $XML_Amazon->search(keywords => 'Perl', page => '2', type => 'Books')

Returns an XML::Amazon::Collection object. i<type> can be Blended, Books, Music, DVD, etc.

=head2 $XML_Amazon->is_success

Returns 1 when successful, otherwise 0.

=head2 $XML_Amazon_Collection->total_results, $XML_Amazon_Collection->total_pages, $XML_Amazon_Collection->current_page

Returns as such.

=head2 $XML_Amazon_Collection->collection

Returns a list of XML::Amazon::Item objects.

=head2 $XML_Amazon_Item->title

=head2 $XML_Amazon_Item->made_by

Returns authors when the item is a book, and likewise.

=head2 $XML_Amazon_Item->publisher

=head2 $XML_Amazon_Item->url

=head2 $XML_Amazon_Item->image(size)

Returns the URL of the cover image. I<size> can be s, m, or l.

=head2 $XML_Amazon_Item->price

=head1 SEE ALSO

=head1 AUTHOR

Yusuke Sugiyama, E<lt>ally@blinkingstar.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Yusuke Sugiyama

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shlomi Fish.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Amazon or by email to
bug-test-runvalgrind@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::Amazon

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/XML-Amazon>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-Amazon>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=XML-Amazon>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-Amazon>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-Amazon>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/XML-Amazon>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-Amazon>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-Amazon>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-Amazon>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::Amazon>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-xml-amazon at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=XML-Amazon>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-XML-Amazon>

  git clone https://github.com/shlomif/perl-XML-Amazon.git

=cut
