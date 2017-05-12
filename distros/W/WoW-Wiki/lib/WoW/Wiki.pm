package WoW::Wiki;

use 5.008006;
use strict;
use warnings;

#
# Module dependencies
#
use Carp;
use XML::Parser;
use XML::SimpleObject;
use LWP::UserAgent; 
use URI::Escape;
use HTTP::Response;
use Storable qw(store retrieve freeze thaw dclone);

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration	use WoW::Wiki ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(parse) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(parse);

our $VERSION = '0.01';


# OO Methods
sub new 
{
	my $this  = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
	$self->{AGENT} = new LWP::UserAgent;
	$self->{AGENT}->agent("Wiki Scraper/0.1");
    return $self;
}

=cut
	This public method takes 1 parameter
	the title page to parse, it returns a list of hashes representing
	each part of the API
=cut
sub parse
{
	my $self = shift;
	my $title = shift;
	my $results = $self->_get_wikidata($title);
	my $titleType = $self->_get_markup_type($results);
	if($titleType eq 'HANDLER')
	{
		return [_handler_parse($title,$results)];
	}
	elsif($titleType eq 'EVENT')
	{
		return _event_parse($results);
	}
	elsif($titleType eq 'METHOD')
	{
		return _method_parse($title,$results);
	}
	elsif($titleType eq 'API')
	{
		return _api_parse($title,$results);
	}
	elsif($titleType eq 'UI')
	{
		return _ui_parse($title,$results);
	}
	
}


=head3 PRIVATE METHODS
=cut

=cut
	Get the wiki markup for a given title
=cut
sub _get_wikidata
{
	my $self = shift;
	my $page = shift;
 	my $req = new HTTP::Request POST => 'http://www.wowwiki.com/Special:Export';
  	$req->content_type('application/x-www-form-urlencoded');
  	$req->content('action=submit&curonly=1&pages='.uri_escape($page));
 	my $res = $self->{AGENT}->request($req);
  	# Check the outcome of the response
  	if ($res->is_success) 
	{
		my $wikiMarkup = "";
		eval{
			my $xmlobj = new XML::SimpleObject(XML => $res->content, ErrorContext => 2);
			my $markup = $xmlobj->child("mediawiki")->child("page")->child("revision")->child("text");
			$wikiMarkup = $markup->value;
		};
		if($@) 
		{ 
			croak "Bad Title Page!"; 
		}
		return $wikiMarkup;
  	} 
	else 
	{
      croak "Unable to pull data from wow wiki! "..$res->content;
  	}	
}

=cut
	Determine the type of markup this is
=cut
sub _get_markup_type
{
	# Markup tags
	# Handler: {{widgethandler}}
	# Events : {{evt|EVENT|Categories}} comma seperator for cats
	# Methods: {{widgetmethod}}
	# API Raw: {{wowapi}}
	# UIXML  : {{framexmlfunc|XML_FILE_LOCATION}}
	my $self = shift;
	my $input = shift;
	if($input =~ /\{\{widgethandler/)
	{
		return "HANDLER";
	}
	elsif($input =~ /\{\{evt/)
	{
		return "EVENT";
	}
	elsif($input =~ /\{\{widgetmethod/)
	{
		return "METHOD";
	}
	elsif($input =~ /\{\{wowapi/)
	{
		return "API";
	}
	elsif($input =~ /\{\{framexmlfunc/)
	{
		return "UI";
	}
	return "UNKNOWN";
}
=cut
	trim whitespace
=cut
sub _trim
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;	
}
sub _fix_hrefs
{
	my $string = shift;
	$string =~ s/\[\[(.+\s?.+)\|+?(.*)\]\]/$2/;
	$string =~ s/\[\[(\w+)\]\]/$1/;
	return $string;
}	
sub _fix_quotes
{
	my $string = shift;
	$string =~ s/(["])/\\$1/g;
	return $string;
}
sub _fix_case
{
	my $line = shift;
	my $nline = lc($line);
	$nline =~ s/\b(\w)/\U$1/g;
	return $nline;
}
=cut
	Handle an Event Page
=cut
sub _event_parse
{
	my $input = shift;
	my @lines = split(/\n/,$input);
	my $lastEvent = "";
	my @events = [];
	my %event;
	foreach my $line (@lines)
	{
		# Skip blank lines
		if(length($line) <= 1)
		{
			next;
		}
		# look for the starting "Event" Line
		if($line =~ /evt\|/)
		{
			if(keys(%event))
			{
				my $d = dclone(\%event);
				push(@events,$d);
				undef %event;
			}
			# remove the braces
			$line =~ s/{|}//g;
			# split the line up
			my($evtL,$event,$cat) = split(/\|/,$line);
			$lastEvent = $event;
			$event =~ s/_/ /g;
			$event{'NAME'} = _fix_case($event);
			$event{'TYPE'} = 'EVENT';
			$event{'CATEGORIES'} = $cat;
		}
		elsif($line =~ /^\w/ && length($lastEvent) > 1)
		{
			chomp($line);
			$event{'DESC'} .= _fix_quotes(_fix_hrefs(_trim($line))) . "\\n";
		}
		elsif($line =~ /^:/ && length($lastEvent) > 1)
		{
			chomp($line);
			$line =~ s/://;
			$event{'DESC'} .= _fix_quotes(_fix_hrefs(_trim($line))) . "\\n";
		}
		elsif($line =~ /^\;/ && length($lastEvent) > 1)
		{
			chomp($line);
			$line =~ s/\;//;
			$event{'ARGS'} .= _fix_quotes(_fix_hrefs(_trim($line))) . "\\n";
		}
	}
	return \@events;
}

=cut
	parser for Widget Handlers
=cut
sub _handler_parse
{
	my $title = shift;
	my $input = shift;
	$title =~ s/UIHANDLER_//;
	my %handler;
	$handler{'NAME'} = $title;
	$handler{'TYPE'} = 'HANDLER';
	my @lines = split(/\n/,$input);
	my $state = "";
	foreach my $sitem (@lines)
	{
		if($sitem =~ /^== Description/)
		{
			$state = "DESC";
			next;
		}
		if($sitem =~ /^== Arguments/)
		{
			$state = "ARGS";
			next;
		}
		if($sitem =~ /^== \w+/)
		{
			$state = "";
			next;
		}
		unless(length($sitem) > 1 || length($state) < 1)
		{
			next;
		}
		if(length($state) > 1)
		{
			if($state eq 'ARGS')
			{
				if($sitem =~ /^; ar/)
				{
					$sitem =~ s/\;//;
				}
				$handler{$state} .= _trim($sitem);
			}
			else
			{
				$handler{$state} .= _trim($sitem);
			}
		}
	}
	return \%handler;
}

sub _method_parse
{
	croak "Method parsing not implemented yet!";
}
sub _api_parse
{
	croak "API type parsing not implemented yet!";
}
sub _ui_parse
{
	croak "UI frameXML parsing not implemented yet!";
}


1;
__END__
=head1 NAME

WoW::Wiki - Perl extension to parse WoW wikki markup

=head1 SYNOPSIS

  use WoW::Wiki;
  my $data = $parser->parse('UIHANDLER_OnClick');
  .. throb your data here
  
=head1 DESCRIPTION

This module is designed to pull the markup for a given heading section on wow wiki
and generate perl hashes of the data for further processing each has will have a NAME and TYPE tag
supported types right now EVENT and HANDLER

=head2 EXPORT

parse

=head1 SEE ALSO

http://www.wowwiki.com

=head1 AUTHOR

Sal  Scotto, E<lt>sal.scotto@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Sal  Scotto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
