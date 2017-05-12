package WWW::FreshBooks::API;
use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.1.0');

use base qw/Class::Accessor::Children::Fast/;
__PACKAGE__->mk_accessors( qw/svc_url auth_token method m_api m_func r_args ua xs response results item_class item_fields/ );
__PACKAGE__->mk_child_accessors(
				Response => [qw(http ref content as_string status)],
				Results  => [qw(page per_page pages total fields items iterator)],
			);

use Iterator::Simple qw(iter);
use LWP::UserAgent;
use XML::Simple;

sub new {
	my $class = shift;
    my $args  = shift;
	
	if ((!exists $args->{'svc_url'}) || (!exists $args->{'auth_token'})) {
		warn "Undefined svc_url or auth_token.";
		return;
	}

    $class = ref($class) || $class;
    my $self = bless {}, $class;

    $self->init($args);
    return $self;
}

sub init {
    my $self = shift;
    my $args = shift;

    $self->svc_url($args->{'svc_url'});
    $self->auth_token($args->{'auth_token'});
    $self->ua(LWP::UserAgent->new(agent => $self->_agent, timeout => 30));
    $self->xs(XML::Simple->new(RootName => ''));

	return $self;
}

sub call {
    my $self   = shift;
    my $method = shift;
    my $args   = shift;

    $self->r_args($args);
	$self->_parse_method($method);

    my $req = HTTP::Request->new(POST => $self->svc_url);
    $req->authorization_basic($self->auth_token, "X");
    $req->content($self->_rxml);

	print STDERR Data::Dumper->Dump([$req]);
    my $resp = $self->ua->request($req);
    if ($resp->code != 200) {
		return(0,$resp);
	}

    my $ref = $self->xs->xml_in($resp->content, KeyAttr => []);
	my $response = WWW::FreshBooks::API::Response->new({
		http	=> $resp,
		ref		=> $ref,
		status	=> $ref->{'status'},
		content => $resp->content,
		as_string => $resp->as_string,
	});
	$self->response($response);

	my $robj;
	my $ritems;
	my $item_class;
	unless (($self->m_func eq "list") || (!exists $ref->{$self->m_api})) {
		$self->_mk_item_class($ref->{$self->m_api});
		$ritems = [ $ref->{$self->m_api} ];
		$robj = {};
	}

	unless (defined $item_class) {
		foreach my $k(keys %{$ref}) {
			my $v = $ref->{$k};
			if ((ref $v eq "HASH") && (exists $v->{$self->m_api})) {
				$robj = $v;

				$self->_mk_item_class($v->{$self->m_api});
				$ritems = $v->{$self->m_api};
			}
		}
	}
	$item_class = $self->item_class;

	my $items;
	my $fmap = $self->item_fields;
	my $fields = $fmap->{$item_class};
	foreach my $i(@{$ritems}) {
		my $item = $item_class->new($i);
		push(@{$items}, $item);
	}

	$robj->{'items'} = $items;
	$robj->{'fields'} = $fields;
	$robj->{'iterator'} = iter($items);
	my $results = WWW::FreshBooks::API::Results->new($robj);
	$self->results($results);

    return (wantarray) ? ($ref,$resp) : $self->results;
}

sub _mk_item_class {
	my $self = shift;
	my $tmpl = shift;

	$tmpl = $$tmpl[0] if ref($tmpl) eq "ARRAY";
	my $fields = [keys %{$tmpl}];
	my $item_name = ucfirst($self->m_api);
	__PACKAGE__->mk_child_accessors($item_name => $fields);
	my $class = __PACKAGE__ . "::" . $item_name;

	$self->item_class($class);
	my $item_fields = $self->item_fields;
	$item_fields->{$class} = $fields;
	$self->item_fields($item_fields);

	return $self;
}

sub _parse_method {
	my $self = shift;
	my $method = shift;

    $self->method($method);
	my ($api, $func) = split(/\./, $method);
	$self->m_api($api);
	$self->m_func($func);

	return $self;
}

sub _rxml {
    my $self = shift;

    my $w = $self->_xwrap();
    my $x = $self->xs->xml_out($self->r_args, RootName => $self->_root_name);
    my $fnr = {
		'__M__' => $self->method,
        '__X__' => $x,
	};

    foreach my $f(keys %{$fnr}) {
		$w =~ s/$f/$fnr->{$f}/g;
	}
    return $w;
}

sub _root_name {
	my $self = shift;
	my $root_name = (($self->m_func eq "create") || ($self->m_func eq "update")) ? $self->m_api : "";
	return $root_name;
}

sub _xwrap {
        return qq{<?xml version="1.0" encoding="UTF-8"?>
<request method="__M__">
__X__
</request>};
}

sub _agent { __PACKAGE__ . "/" . $VERSION }

1; 

__END__

=head1 NAME

WWW::FreshBooks::API - Perl Interface to the Freshbooks 2.1 API!

=head1 VERSION

Version 0.1.0

=cut

#our $VERSION = '0.01';


=head1 SYNOPSIS

    use WWW::FreshBooks::API;

    my $fb = WWW::FreshBooks::API->new({
		svc_url => "https://sample.freshbooks.com/api/xml-in",
		auth_token => "yourfreshbooksapiauthenticationtoken",
	});

	# old n' busted - though still works for backward compatibility
	# ---------------------------------------------------------------
	    # $ref is a hash reference created from the xml response.
	    # $resp is an HTTP::Response object containg the response.
    my ($ref,$resp) = $fb->call('client.list', {
		$arg1 => 'val1',
		$arg2 => 'val2',
	});

    # Verifies that the request was completed successfully.
    # Displays the client_id of the first client in the list.
    if ($ref) {
        $ref->{'client'}[0]->{'client_id'};
    }

    # Displays the response content as a string
    $resp->as_string;
	# ---------------------------------------------------------------


	# new hotness - better data handling, easier access to response data, etc.
	# ----------------------------------------------------------------
		# result and response data now accessed via class accessors.
	$fb->call("client.list", {foo => "bar", biz => "baz"});
	my $response = $fb->response;
	unless ($response->status eq "ok") {
		return;
	}

	my $results = $fb->results;
	$results->total;		# Total number of result items
	$results->items;		# array of results as result item classes
	$results->item_fields;	# hash of result item field names keyed by class - used to create item class accessors
	$results->item_class;	# name of the class created from the result items
	$results->iterator; 	# iterator for list of result items

	my $items = $results->iterator;
	my $fields = $results->item_fields->{$results->item_class};
	while (my $item = $items->next()) {
		$item->client_id;
		$item->organization;

		# or something like ..

		map { print $_ . " --> " . $item->$_ . "\n" } @{$fields};
	}
	# -----------------------------------------------------------------

=head1 DESCRIPTION

The long awaited update to the original perl freshbooks api interface adds some much needed data handling
improvements, on-the-fly response item class creation, and a simple result item iterator for improved 
handling of result lists.  Stubs of the original implementation exist for backwards compatibility, and 
access to new features are possible without changing old code.

The result item classes are built on the fly using the data contained within the response.  This is meant
to keep class accessors up to date in the absence of a provided service description and without having to
maintain your own.  Example of how this works:

	# your "client.list" request returns:
	 <?xml version="1.0" encoding="utf-8"?>  
	 <response status="ok">  
	   <clients page="1" per_page="15" pages="3" total="42">  
	     <client>  
	       <client_id>13</client_id>  
	       <organization>ABC Corp</organization>  
	       <username>janedoe</username>  
	       <first_name>Jane</first_name>  
	       <last_name>Doe</last_name>  
	       <email>janedoe@freshbooks.com</email>  
	     </client>  
	     ...  
	   </clients>  
	 </response>

	# on the fly we create WWW::FreshBooks::API::Client with accessors available via:
	my $item = $results->iterator->next();
	$item->client_id;		# 13
	$item->organization; 	# ABC Corp
	$item->username;		# janedoe
	....

=head1 WARNING

Please note that "item" refers to each object returned in the list of results.  This is
not to be confused with a Freshbooks line item.  I realize that this is a bit semantically 
unsound, but I have to point the finger at the FB kats for this one.  I mean "item" is pretty 
vague for a top level api, no?  My vocab-fu is not strong ... plus, by the time I noticed
the collision, I was married to the item reference.

=head1 FUNCTIONS

=over 4

=item C<new>

=item C<init>

=item C<call>

=back

=head1 RESPONSE CLASS ACCESSORS

=over 4

=item C<$response->http>

=item C<$response->ref>

=item C<$response->content>

=item C<$response->as_string>

=item C<$response->status>

=back

=head1 RESULT CLASS ACCSSORS

=over 4

=item C<$results->page>

=item C<$results->per_page>

=item C<$results->pages>

=item C<$results->total>

=item C<$results->fields> 

=item C<$results->items>

=item C<$results->iterator>

=back

=head1 DEPENDENCIES

L<Class::Accessor::Children>
L<Iterator::Simple>
L<LWP::UserAgent>
L<XML::Simple>

=head1 AUTHOR

Anthony Decena, C<< <anthony at mindelusions.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-freshbooks-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-FreshBooks-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::FreshBooks::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-FreshBooks-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-FreshBooks-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-FreshBooks-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-FreshBooks-API/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Anthony Decena, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

