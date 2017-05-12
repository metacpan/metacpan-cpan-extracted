package WebService::Bloglines::Blogroll;

use 5.008006;
use strict;
use warnings;

use fields qw(
	user_name
	folder
	url
	uri
	html
	blogroll_hash
	blogroll_html
	page
	http_proxy
	ftp_proxy
);

use vars qw($VERSION %FIELDS $AUTOLOAD);

BEGIN {
	$VERSION = '0.02';
}	

use LWP::Simple qw($ua get);
use Carp;

use Data::Dumper;

{
	my $_def_values = {
		url			=> 'rpc.bloglines.com',
		uri			=> 'blogroll',
		html		=> 1,
		http_proxy	=> $ENV{http_proxy},
		ftp_proxy	=> $ENV{ftp_proxy},
	};

	sub _get_defaults { %$_def_values }
}

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	$self->_init(@_);
	return $self;
}

sub _init {
	my $self = shift;
	my %pars = @_;
	
	my %_defaults = $self->_get_defaults;	
	for(keys %FIELDS) {
		$self->{$_} = exists $pars{$_} ? $pars{$_} : $_defaults{$_};
	}
	
}

sub retrieve_blogroll {
	my $self = shift;
	
	$ua->proxy('http', $self->http_proxy);
	$ua->proxy('ftp', $self->ftp_proxy);

	$self->page(get($self->_get_url));
	$self->_parse_blogroll();
}

sub get_blogroll_as_html {
	my $self = shift;
	
	my $blogroll_hash = $self->blogroll_hash;
	
	my $blogroll_html;
	for(keys %{$blogroll_hash}) {
		$blogroll_html .= "<h2>$_</h2>\n";
		$blogroll_html .= "<ul>\n";
		
		for my $item (@{$blogroll_hash->{$_}}) {
			$blogroll_html .= "<li><a href='$item->{item_url}'>$item->{item_title}</a></li>\n"
														if $item->{item_url} && $item->{item_title};
		}
		
		$blogroll_html .= '</ul>'
	}
	
	$self->blogroll_html($blogroll_html);
}

sub page {
	my $self = shift;
	if(@_) {
		my $page = shift;
		if(!$page) {
			croak "Cannot retireve a blogroll: \n\tproxy url is
			[$ENV{http_proxy}]\n\turl is [".$self->get_url."]";
		} elsif($page =~ /The user name you are using to access this blogroll is incorrect/i) {
			croak "User name [".$self->user_name."] is not correct!";
		}
		
		$self->{page} = $page;
	}
	
	return $self->{page};
}

sub _parse_blogroll {
	my $self = shift;	
	
	my($folder, $item_title, $item_url, %list);
	for(split/\n/, $self->page) {
		if(/blogrollfolder/) {
			($folder) = m#(?:.+)>(.+?)<#;
		} elsif(/blogrollitem/) {
			($item_url, $item_title) = m#href="(.+?)">(.+?)<#;
			push @{ $list{$folder} }, {item_title => $item_title, item_url => $item_url};
		}
	}

	$self->blogroll_hash(\%list);	
}

sub _get_url {
	my $self = shift;	
	
	croak "User name is not specified!" unless $self->user_name;
	
	my $url = 'http://'.$self->url.'/'.$self->uri.'?id='.$self->user_name;
	$url .= '&folder='.$self->folder if $self->folder;
	$url .= '&html='.$self->html;

	return $url;
}

sub get_blogroll_hash {
	my $self = shift;	
	my $folder = shift;

	return $self->{blogroll_hash}{$folder} if $self->{blogroll_hash} && $folder;
	return $self->{blogroll_hash}
}

sub get_list_folders {
	my $self = shift;
	if($self->{blogroll_hash}) {	
		return [ keys %{ $self->{blogroll_hash} } ]
	}
}

sub AUTOLOAD {
	my $self = shift;
	my($class, $attr) = $AUTOLOAD =~ /(.+)::(.+)/;
	
	if(exists $FIELDS{$attr}) {
		$self->{$attr} = shift() if @_;
		return $self->{$attr};
	} else {
		croak "Method [$attr] is not found in the class [$class]!";
	}
}

sub DESTROY {
	my $self = shift;
}

1;
__END__

=head1 NAME

WebService::Bloglines::Blogroll - Perl extension to get a blogroll from
Bloglines.com.

=head1 SYNOPSIS

  use WebService::Bloglines::Blogroll;
  
  my $bloglines = new WebService::Bloglines::Blogroll(user_name => 'some valid name');

  $bloglines->retrieve_blogroll();

  #
  # Get blogroll as hash reference which contains a following data structure:
  # 
  #	{
  # 	folder_name => [ { item_title => 'title', item_url => 'url' }, ... ],
  #		. . .
  #	}				
  my $blogroll_hash = $bloglines->blogroll_hashref;

  #
  # Also, you can retrieve a list of item for specific folder
  #
  my $blogroll_hash = $bloglines->blogroll_hashref('folder_name');

  #
  # Get blogroll as string contained html code where each folder name surrounded
  # by <h2> tags and list of folder's items put into unordered list (<ul>). 
  # You can easy to embed the blogroll into your design using CSS.
  my $blogroll_html = $blog->blogroll_html;

=head1 DESCRIPTION

Bloglines is the most of famous and handy online tool for agregate and read RSS
feeds. WebService::Bloglines::Blogroll is a simple Perl class which can be used
to retrieve your blogroll from Bloglines, process it and display it on your 
personal page.

=head2 CONSTRUCTOR

=over 4

=item new()

To retrieve a blogroll from Bloglines it's necessarily to specify an user name of owner of blogroll:

	new WebService::Bloglines::Blogroll(user_name => 'some_name');

or 
	
	new WebService::Bloglines::Blogroll(user_name => 'some_name', folder => 'some folder');

=back

=head2 OBJECT'S PROPERTIES

=over 4

=item user_name

User name for Bloglines

	new WebService::Bloglines::Blogroll(user_name => 'some_name');

or	

	$bloglines->user_name('some name');

=item folder

A specific folder from Bloglines

	new WebService::Bloglines::Blogroll(user_name => 'some_name', folder => 'some folder');

or	

	$bloglines->user_name('some name');	

=item page

Contains an original page received from Bloglines

=item http_proxy

Contains a proxy http proxy. (By default, it's got from environment)

=back

=head2 OBJECT'S METHODS

=over 4

=item retrieve_blogroll()

Get a blogroll from Bloglines according to specified parametes:

	my $bloglines = new WebService::Bloglines::Blogroll(user_name => 'name1');
	$bloglines->retrieve_blogroll();
	my $list = $bloglines->get_blogroll_hash();

	. . .

	$bloglines->user_name('name2');
	$bloglines->retrieve_blogroll();
	my $list2 = $bloglines->get_blogroll_hash();

=item get_blogroll_as_html()

Returns a blogroll as HTML:

	my $html = $bloglines->get_blogroll_as_html();

=item get_blogroll_hash()

Returns a blogroll as hash:

	my $all_items = $bloglines->get_blogroll_hash();

or for specified folder

	my $folder_items = $bloglines->get_blogroll_hash('some folder');

=item get_list_folders()

Returns a list of all folders in the Bloglines blogroll

	my $folders = $bloglines->get_list_folders();

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

WebService::Bloglines

=head1 AUTHOR

Michael stepanov, <stepanov.michael@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Michael Stepanov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
