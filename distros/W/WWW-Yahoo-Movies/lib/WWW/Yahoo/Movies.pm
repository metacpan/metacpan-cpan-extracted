package WWW::Yahoo::Movies;

use strict;
use warnings;

use vars qw($VERSION $AUTOLOAD %FIELDS);

use fields qw(
	id
	title
	cover
	year
	mpaa_rating
	distributor
	release_date
	runtime
	genres
	plot_summary
	people
	matched
	error
	error_msg
	_proxy
	_timeout
	_user_agent
	_page
	_parser
	_search
	_server_url
	_search_uri
	_movie_uri
);

BEGIN {
	$VERSION = '0.05';
}	

use LWP::Simple qw(get $ua);
use HTML::TokeParser;
use Carp;

use Data::Dumper;

{
	my $_class_def = {
		error		=> 0,
		error_msg	=> '',
		mpaa_rating	=> [],
		_timeout	=> 10,
		_user_agent	=> 'Mozilla/5.0',
		_server_url	=> 'http://movies.yahoo.com',
		_movie_uri	=> '/shop?d=hv&cf=info&id=',
		_search_uri	=> '/mv/search?type=feature&p=',
	};

	sub _class_def { $_class_def }
	sub _get_default_val {
		my $self = shift;
		my $attr = shift;

		return $_class_def->{$attr};
	}
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
	my %params = @_;
	
	for my $prop(keys %FIELDS) {
		my $attr = $prop;
		$attr =~ s/^_//;
		$self->{$prop} = exists $params{$attr} ? $params{$attr} 
											: $self->_get_default_val($prop);	
	}
	
	if($self->proxy) { $ua->proxy(['http'], $self->proxy) }
	else { $ua->env_proxy }

	$ua->agent($self->user_agent);
	$ua->timeout($self->timeout);		
	
	$self->_get_page();
	return if $self->error;

	$self->parse_page();
}

sub _get_page {
	my $self = shift;

	croak "Wrong paramter!" if $self->id !~ /^\d+$/ && $self->_search;
	
	my $url = $self->_server_url.($self->id =~ /^\d+$/ && length($self->id) > 4 ? $self->_movie_uri : $self->_search_uri).$self->id;

	$self->{_page} = get($url) || die "Cannot connect to the Yahoo: $!!";
	
	unless($self->id =~ /^\d+$/ && length($self->id) > 4) {
		$self->_process_page();									
		$self->_search(1);
	}	
}

sub _process_page {
	my $self = shift;

	if($self->_page =~ /no\s+matches\s+were\s+found/i) {
		$self->error_msg("Nothing found!");
		$self->error(1);
		return;
	}

	my $parser = $self->_parser;
	
	my($tag, $text);
	while($tag = $parser->get_tag('b')) {
		$text = $parser->get_text();
		last if $text =~ /top\s+matching\s+movie\s+titles/i;
	}

	$parser->get_tag('table');
	
	while($tag = $parser->get_tag) {
		
		if($tag->[0] eq 'a' && $tag->[1]{href} =~ m#/(\d+)/info#) {
			$text = $parser->get_trimmed_text('a', 'br');
			my $id = $1;
			$self->matched($id, $text);
		}
	
		last if $tag->[0] eq '/table';
	}

	if($self->matched) {
		$self->id($self->matched->[0]{id});
		$self->_get_page();
	} else {
		$self->error_msg("Nothing matched!");
		$self->error(1);
		return;
	}
}

sub matched {
	my $self = shift;
	if(@_) {
		my($id, $title) = @_;
		push @{ $self->{matched} }, {id => $id, title => $title};
	}

	return $self->{matched};
}

sub proxy {
	my $self = shift;
	if(@_) { $self->{_proxy} = shift }
	return $self->{_proxy};
}

sub timeout {
	my $self = shift;
	if(@_) { $self->{_timeout} = shift }
	return $self->{_timeout}
}

sub user_agent {
	my $self = shift;
	if(@_) { $self->{_user_agent} = shift }
	return $self->{_user_agent}
}

sub parse_page {
	my $self = shift;

	$self->_parse_title();
	$self->_parse_details();
	$self->_parse_cover();
	$self->_parse_trailer();
	$self->_parse_plot();
	$self->_parse_people();
}

sub cover_file {
	my $self = shift;
	if($self->cover) {
		my($file_name) = $self->cover =~ /(?:.+)\/(.+)$/;
		return $file_name;
	}	
}

sub mpaa_rating {
	my $self = shift;
	
	if($_[0] && ref($_[0]) eq 'ARRAY') { $self->{mpaa_rating} = shift }
	
	return wantarray ? @{ $self->{mpaa_rating} } : $self->{mpaa_rating}[0];
}

sub directors {
	my $self = shift;

	return $self->{'people'}->{'directors'} if $self->{'people'};
}

sub producers {
	my $self = shift;

	return $self->{'people'}->{'producers'} if $self->{'people'};
}

sub cast {
	my $self = shift;

	return $self->{'people'}->{'cast'} if $self->{'people'};
}

sub _parser {
	my $self = shift;	
	$self->{_parser} = new HTML::TokeParser(\$self->_page());
	return $self->{_parser};
}

sub _parse_title {
	my $self = shift;

	($self->{title}, $self->{year}) = 
			$self->_page =~ m#<h1><strong>(.+)\s+\((\d+)\)</strong></h1>#mi;
}

sub _parse_details {
	my $self = shift;
	my $p = $self->_parser();
	while($p->get_tag('b')) {
		my $t;	
		my $caption = $p->get_text;
		
		SWITCH: for($caption) {
			/^Genres/ && do {
				$t = $p->get_trimmed_text('/tr');
				$self->genres([split m#/#, $t]);
				last SWITCH; };
			/^Running Time/ && do {
				$t = $p->get_trimmed_text('/tr');				
				$self->runtime($self->_parse_runtime($t));
				last SWITCH; };
			/^Release Date/ && do {
				$t = $p->get_trimmed_text('b');
				my($mon, $day, $year) = $t =~ /(.+?)\s+(\d+)(?:th|sd|st)?,\s+(\d+)\s?(?:[.(])?/;
				my $date = "$day $mon $year";
				$self->release_date($date);
				last SWITCH; };
			/^MPAA Rating/ && do {
				$t = $p->get_trimmed_text('/tr');
				my($code, $descr) = $t =~ /(.+?)\s+(.+)/;
				$self->mpaa_rating([$code, $descr]); 
				last SWITCH; };
			/^Distributor/ && do {
				$t = $p->get_trimmed_text('/tr');
				my($distr) = $t =~ /(.*)\./;
				$self->distributor($distr);
				last SWITCH; };				
		};
	}	
}

sub _parse_cover {
	my $self = shift;
	my $p = $self->_parser();
	
	while(my $tag = $p->get_tag('img')) {
		if($tag->[1]{alt} && $tag->[1]{alt} =~ /^$self->{title}/i) {
			$self->{cover} = $tag->[1]{src};
			last;
		}
	}
}

sub _parse_trailer {
	my $self = shift;
	my $p = $self->_parser();

	while(my $tag = $p->get_tag('a')) {
		if($tag->[1]{href} =~ /videoWin/i) {
			$self->{trailer} = $tag->[1]{href};
			last;
		}
	}
}

sub _parse_plot {
	my $self = shift;
	my $p = $self->_parser();

	while(my $tag = $p->get_token()) {
		if($tag->[0] eq 'C') {
			last if $tag->[1] =~ /another vertical spacer/;
		}	
	}

	$p->get_tag('font');
	$self->{plot_summary} = $p->get_trimmed_text('font', 'table');
}

sub _parse_runtime {
	my($self, $time_str) = @_;
	my $time = '';	
	
	if($time_str) {
		my($hours, $min) = 
				$time_str =~ m#(\d{0,2})(?:\s+hr\w?\.?)(?:\s+?)(\d{1,2})\s+min\.?#;
		$time = $hours*60 + $min;
	}

	return $time;
}

sub _parse_people {
	my($self) = @_;
    
	my $p = $self->_parser();
		
	my $key;
    while(my $tag = $p->get_token()) {
        last if $tag->[0] eq 'C' && $tag->[1] =~ /cast and credits/;
    }

	while(my $tag = $p->get_token) {
		
		if($tag->[1] eq 'font') {
			my $text = $p->get_text();

			if($text eq 'Starring:') { $key = 'cast' } 
			elsif($text eq 'Directed by:') { $key = 'directors' } 
			elsif($text eq 'Produced by:') { $key = 'producers' }
		}	

		if($tag->[0] eq 'S' && $tag->[1] eq 'a') {
            if($tag->[2]{href} =~ /movie\/contributor\/(\d+)/ && $key) {
				push @{ $self->{'people'}->{$key} }, [$1, $p->get_text];			
			}	
		}
	}
}

sub AUTOLOAD {
	my $self = shift;
	my($class, $attr) = $AUTOLOAD =~ /(.*)::(.*)/; 
	my($pack, $file, $line) = caller;
	if(exists $FIELDS{$attr}) {
		$self->{$attr} = shift() if @_;
		return $self->{$attr};
	} else {	
		carp "Method [$attr] not found in the class [$class]!\n Called from $pack at line $line";
	}	
}

sub DESTROY {
	my $self = shift;
}

1;
__END__

=head1 NAME

WWW::Yahoo::Movies - Perl extension to get Yahoo! Movies
information.

=head1 SYNOPSIS

  use WWW::Yahoo::Movies;
  
  my $movie = new WWW::Yahoo::Movies();

  print "TITLE: ".$movie->title." - ".$movie->year."\n";

=head1 DESCRIPTION

WWW::Yahoo::Movies is Perl interface to the Yahoo! Movies 
(http://movies.yahoo.com/). Sometimes IMDB doesn't have full information
about movie (plot summary, cover etc). In that case it's good idea
to have another place to get movie info.

Also, there are many Perl extensions for Yahoo! in the CPAN. Hope 
WWW::Yahoo::Movies will be useful as well!

=head2 CONSTRUCTOR

=over 4

=item new()

You should pass movie title or Yahoo! movie ID. In case movie ID it'll
retrieve the movie information directly. If movie title was passed as 
constructor parameter it'll make a search, store matched results and 
return the first matched movie info:

	my $movie = new WWW::Yahoo::Movies(id => 1808444810);

or

	my $movie = new WWW::Yahoo::Movies(id => 'Troy');
	

=back

=head2 PUBLIC OBJECT METHODS

=over 4

=item id()

Yahoo! movie ID:

	my $id = $ym->id();

=item title()

Yahoo! movie title:

	my $title $ym->title();

=item cover()

A link on Yahoo! movie cover:
	
	use LWP::Simple qw(get);
	
	my $cover_img = get($ym->cover);

	 print "Content-type: image/jpeg\n\n";
	 print $cover_img;

=item year()

Year of release of Yahoo! movie:

	my $year = $ym->year();

=item mpaa_rating()

MPAA rating of Yahoo! movie. In scalar context it returns MPAA code, in array context
it returns array contained MPAA code and description.

	my $mpaa_code = $ym->mpaa_rating();

or

	my($mpaa_code, $mpaa_descr) = $ym->mpaa_rating();

For more information about MPAA rating please visit that page 
http://www.mpaa.org/movieratings/

=item distributor()

Company name which distributes Yahoo! movie:

	my $distr_name = $ym->distributor();

=item release_date()

Release date of Yahoo! movie:

	my $date = $ym->release_date();

=item runtime()

Returns a duration of Yahoo! movie in minutes:

	my $runtime = $ym->runtime();

=item genres()

Genres of Yahoo! movie:

	my @genres = @{ $self->genres };

Note: that method returns a reference on array with genres.	

=item plot_summary()

A short description of Yahoo! movie:

	my $plot = $ym->plot_summary();

=item matched()

List of mathed Yahoo! movies in case of search by movie's title. It returns
an array reference with hashes in the form of id => title:

	map { print "ID: $_->{id}; title: $_->{title}\n" } @{ $ym->matched();

=item people()

Return a hash with following keys - director, producer and cast, which correspond on array
with Yahoo Person ID and person full name:

	my $people = $ymovie->people();

	for(keys %$people) {
		print "Category $_ \n";
		for(@{$person->{$_}}) {
			print "$_->[0]: $_->[2] ...\n";
		}
	}

=item cast()

Return a list of movie cast like pair: Yahoo Person ID, person name:
	
	my $cast = $ymovie->cast;

	for(@$cast) {
		print "$_->[0]: $_->[1]\n";
	}

=item producers()

Return a list of movie producers like pair: Yahoo Person ID, person name:
	
	my $producers = $ymovie->producers;

	for(@$producer) {
		print "$_->[0]: $_->[1]\n";
	}

=item directors()

Return a list of movie directors like pair: Yahoo Person ID, person name:
	
	my $directors = $ymovie->directors;

	for(@$directors) {
		print "$_->[0]: $_->[1]\n";
	}


=back

=head2 ERROR METHODS

=over 4

=item error()

Indicates if some error happened during retrieving of movie information:

	if($ym->error) {
		print "[ERROR] [".$ym->error."] ".ym->error_msg."!\n";
		exit(0);
	}

=item error_msg()

Contains an error description:

	print "ERROR: ".$ym->error_msg."!\n";	

=back

=head1 EXAMPLE

	#!/usr/bin/perl -w

	use strict;
	use warnings;

	use WWW::Yahoo::Movies;

	my $title = shift || 'troy';

	my $matched = get_movie_info($title, 1);

	for(@$matched) {
		print "\nGet [$_->{title}] ...\n";
		get_movie_info($_->{id});
	}

	sub get_movie_info {
		my $title = shift;
		my $ret_match = shift || 0;
		
		my $ym = new WWW::Yahoo::Movies(id => $title);

		print "Get info about [$title] ...";

		print "\n\tID: ".$ym->id;
		print "\n\tTITLE: ".$ym->title;
		print "\n\tYEAR: ".$ym->year;
		print "\n\tMPAA: ".$ym->mpaa_rating;
		print "\n\tCOVER: ".$ym->cover_file;
		print "\n\tPLOT: ".substr($ym->plot_summary, 0, 90)." ...";
		print "\n\tDATE: ".$ym->release_date;
		print "\n\tDISTR: ".$ym->distributor;
		print "\n\tGENRES: ".join(", ", @{ $ym->genres }) if $ym->genres;

		return $ym->matched if $ret_match;
	}	

=head1 EXPORT

None by default.

=head1 SEE ALSO

IMDB::Film

=head1 AUTHOR

Michael Stepanov, E<lt>stepanov.michael@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Michael Stepanov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
