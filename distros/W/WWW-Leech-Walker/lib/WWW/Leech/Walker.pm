package WWW::Leech::Walker;
use strict;
use LWP;
use URI::URL;
use WWW::Leech::Parser;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.05';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

sub new{
	my $class = shift;
	my $this = shift;

	$this->{'url'} = url $this->{'url'};
	$this->{'state'} ||= {};
	
	$this->{'_stop_flag'} = undef;

	$this = bless $this, __PACKAGE__;

	$this->{'parser'} = new WWW::Leech::Parser($this->{'parser'});

	if(!$this->{'raw_preprocessor'}){
		$this->{'raw_preprocessor'} = sub {
			return shift();
		}
	}
	if(!$this->{'error_handler'}){
		$this->{'error_handler'} = sub {
			my $this = shift;
			my $item = shift;
			my $err = shift;
			die $err;
		}
	}
	
	return $this;
}

sub leech{
	my $this = shift;
	$this->{'_stop_flag'} = undef;

	my $current_url = $this->{'url'} or die("No url provided");

	while(1){

		$this->log("Getting links list: $current_url ");

		# get and parse link list
		my $data = $this->_get($current_url, $this->{'post_data'});

		my $parse_result = $this->{'parser'}->parseList($data);

		my $links = [map { url($_, $this->{'url'})->abs } @{$parse_result->{'links'}}];
		my $links_text = $parse_result->{'links_text'};

		$this->log("Links list length: ".scalar(@$links));

		if(scalar(@$links) == 0){
			$this->log("No items links found, check your XPath: ".$this->{'parser'}->{'item:link'});

			$this->stop();
			return;
		}

		# filtering if required
		if( $this->{'filter'} ){
			$this->log("Filtering links");
			$links = $this->{'filter'}->($links, $this, $links_text);
			$this->log("Filtered links list length: ".scalar(@$links));

			return if($this->{'_stop_flag'});
		}

		# get and parse individual items
		my $i = 0;
		my $llength = scalar(@$links);
		foreach(@$links){

			$i++;

			# some log
			my $ll = length($llength);
		
			$this->log("\tGetting item (".sprintf("%0${ll}d",$i)."/$llength): $_ ");

			my $str = $this->_get($_);

			my $item = {'_url' => $_->as_string };

			# try to parse content
			eval{
				$item = $this->{'parser'}->parse($str);
			};

			if($@){
				$this->{'error_handler'}->($item,$this,$@);
			} else {
				$this->{'processor'}->($item,$this);
			}


			return if($this->{'_stop_flag'});
		}

		if($parse_result->{'next_page'}){

			my $pnurl;

			if($this->{'next_page_link_post_process'}){
				$pnurl = $this->{'next_page_link_post_process'}->($parse_result->{'next_page'}, $this, $current_url);
			}

			if($pnurl){
				$current_url = url($pnurl)->abs;
			} else {
				$current_url = url($parse_result->{'next_page'}, $this->{'url'})->abs;
			}

			return if($this->{'_stop_flag'});			

		} else {
			$this->stop("No next page link found");
			return;
		}
	}

	
}

sub getCurrentDOM{
	my $this = shift;
	return $this->{'parser'}->{'current_dom'};
}

sub log{
	my $this = shift;
	my $message = shift;

	if($this->{'logger'}){
		$this->{'logger'}->($message,$this);
	}
}

sub stop{
	my $this = shift;
	my $reason = shift;

	$this->{'_stop_flag'} = 1;
	$this->log("\tWalker stopped.");
	if($reason){
		$this->log("\tReason: $reason.");
	}
}

sub _get{
	my $this = shift;
	my $url = shift;
	my $post_data = shift;

	my $req;

	if( $post_data ){
		$req = new HTTP::Request('POST',$url);
		$req->content_type('application/x-www-form-urlencoded');
		$req->content( $post_data );

	} else {
		$req = new HTTP::Request('GET',$url);
	}


	my $res = $this->{'ua'}->request($req)->decoded_content();
	$res = $this->{'raw_preprocessor'}->($res);

	return $res;
	
}


1;


__END__
=head1 NAME

WWW::Leech::Walker - small web content grabbing framework

=head1 SYNOPSIS

  use WWW::Leech::Walker;

  my $walker = new WWW::Leech::Walker({
  	ua => new LWP::UserAgent(),
  	url => 'http://example.tdl',

  	parser => $www_leech_parser_params,

  	state => {},

  	logger => sub {print shift()},

  	raw_preprocessor => sub{
  		my $html = shift();
  		my $walker_obj = shift;
  		return $html;
  	},

  	filter => sub{
		my $urls = shift;
		my $walker_obj = shift;

		# ... filter urls

		return $urls
  	},

  	processor => sub {
		my $data = shift;
		my $walker_obj = shift;

		# ... process grabbed data

  	},

  	error_handler => sub {
		my $item = shift;
		my $walker_obj = shift;
		my $error_text = shift;

		# ... handle error

  	}
  });

  $walker->leech();


=head1 DESCRIPTION

WWW::Leech::Walker walks through a given website parsing content and generating structured data.
Declarative interface makes Walker some sort of a framework.

This module is designed to extract data from sites with particular structure: an index page (or any other provided as a root page) contains links to individual pages representing items that should be grabbed. Index page may also contain 'paging' links (e.g. http://exmple.tdl/?page=2) which lead to the page with similar structure. The closest example is a products category page with links to individual products and links to 'sub-pages'.

All required parameters are set as constructor arguments. Other methods are used to start/stop the grabbing process and launch logger (see below).


=head1 DETAILS

=over 4

=item new($params)

$params must be a hashref providing all data required. 

=over 4

=item ua

LWP compatible user-agent object.

=item url

Starting url.

=item post_data

Url-encoded post data. By default Walker will fetch items list using GET method. POST method is used if post_data is set. Requests fetching individual items pages are still using GET method.

=item parser

Parameters for L<WWW::Leech::Parser>

=item state

Optional user-filled value. Walker does not use it directly. State is passed to user callbacks instead.
Defaults to empty hashref.

=item logger

Optional logging callback. Whenever something happens walker runs this subroutine passing message.


=item filter

Optional urls filtering callback. When walker gets a list of items-pages urls it passes that list to the filter subroutine. Walker itself is passed as a second argument and an arrayref with links text as third. Walker expects it to return filtered list. Empty list is okay.

=item processor

This callback is launched after the individual item is parsed and converted to a hashref. This hashref is passed to the processor to be saved, or processed in some other way.

=item raw_preprocessor

This optional callback is launched after any page was retrieved but before parsing started. Walker expects it to return scalar.

=item error_handler

Walker dies with an error message if something goes wrong while parsing. Providing this optional callback allows caller to handle such errors. Skip page with broken html for example.

=item next_page_link_post_process

This optional callback allows user to alter next page url. Usually these urls look like 'http://example.tld/list?page=2' and no changes needed there. But sometimes such links are javascript calls like 'javascript:gotoPageNumber(2)'. The source url is passed as is before walker absolutizes it. Walker passes current page url as a third agument - this may be usefull for links like 'javascript:gotoNextPage()'

Walker expects this callback to return a fixed url.

=back

=item leech()

Starts the process.


=item stop()

Stops the process completely. By default walker keeps working untill there are links. Some sites may contain zillions of pages, while only first million is required. This method allows to stop at some point. See L</CALLBACKS> section below.

If walker is restarted with B<leech()> method it will run as if it was newly created (still the 'state' is saved). 


=item log($message)

Runs the 'logger' callback with $message argument.

=item getCurrentDOM()

Returns DOM currently beeing processed.

=back


=head1 CALLBACKS

Walker passes callback specific data as a first argument, itself as a second and some additional data as third if any.

When grabbing large sites the grabbing process should be stopped at some point (if you don't need all the data of course). This example shows how to do it using B<state> propery and B<stop()> method:

  #....
  state => {total_links_amount => 0},
  filter => sub{
    my $links = shift;
    my $walker = shift;

    if($walker->{'state'}->{'total_links_amount'} > 1_000_000 ){
    	$walker->log("Million of items grabbed. Enough.");
    	$walker->stop();

    	return [];
    }

    $walker->{'state'}->{'total_links_amount'} += scalar(@$links);

    return $links;
  }
  #....





=head1 AUTHOR

    Dmitry Selverstov
    CPAN ID: JAREDSPB
    jaredspb@cpan.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=cut
