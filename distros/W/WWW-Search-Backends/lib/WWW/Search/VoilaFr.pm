# VoilaFr.pm
# by Mikou 03/21/2000 v1.0
# mikou@spip.viewline.net

=head1 NAME

WWW::Search::VoilaFr - class for searching voila.fr

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('VoilaFr');

=head1 DESCRIPTION

This class is a specialization of WWW::Search for voila.fr.
A french search engine.
All searchs are based on and ONLY on gui_query function.

This class exports no public interface; all interaction should be done
through WWW::Search objects.

=head1 USAGE EXAMPLE

  use WWW::Search;

  my $oSearch = new WWW::Search('VoilaFr');
  $oSearch->maximum_to_retrieve(100);

  #$oSearch ->{_debug}=1;

  my $sQuery = WWW::Search::escape_query("bretagne");
  $oSearch->gui_query($sQuery);

  while (my $oResult = $oSearch->next_result())
  {
        print $oResult->url,"\t",$oResult->title,"\n";
  }


=head1 AUTHOR

C<WWW::Search::VoilaFr> is written by Mikou,
mikou@spip.viewline.net

=cut




#####################################################################

package WWW::Search::VoilaFr;

use strict;
use warnings;

use base 'WWW::Search';

#use strict vars;
use Carp ();
use HTML::Parse qw(parse_html);
use WWW::Search(qw( generic_option strip_tags unescape_query ));
use WWW::SearchResult;

our
$VERSION = do { my @r = ( q$Revision: 1.4 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my($debug) = 0;
my ($engine) = "voila.fr";

sub gui_query
{
  #http://search.voila.fr/voila?dd=&kw=myword1+myword2&dt=*
  my ($self, $sQuery, $rh) = @_;
  $self->{'search_base_url'} ||= 'http://search.voila.fr';
  $self->{_options} = {
                       'search_url' => $self->{'search_base_url'} .'/voila',
                      };
  return $self->native_query($sQuery, $rh);
} # gui_query          



#private
sub native_setup_search
{
	my($self, $native_query, $native_options_ref) = @_; 
	print STDERR " *   ${engine}::native_setup_search()\n" unless $debug==0;

	$self->user_agent('zemikou'); 
	if (!defined($self->{_options})) 
	{
	     $self->{_options} = 
		{
            	'search_url' => 'http://search.voila.fr'.'/voila',
		#'_debug'=> '1'
        	} 
	}

	$self->{_base_url} = $self->{_next_url} = $self->{_options}{'search_url'} .
	"?dd=&kw=" . $native_query .
	"&dt=*" . $options; 
	print STDERR $self->{_base_url} . "\n" if ($self->{_debug}); 
}



# private
sub native_retrieve_some
{
 	my ($self) = @_;      
 
	my($hits_found) = 0;

 	#fast exit if already done
	return undef if (!defined($self->{_next_url}));    

print STDERR "WWW::Search::${engine}::native_retrieve_some: fetching " . $self->{_next_url} . "\n" if ($self->{_debug});

	my($response) = $self->http_request('GET', $self->{_next_url});
	$self->{response} = $response;

print STDERR "WWW::Search::${engine} GET  $self->{_next_url} return ",$response->code,"\n"  if ($self->{_debug});
  	if (!$response->is_success) 
	{
       	 	return undef;
   	};

	$self->{_next_url} = undef; 

	my $ht_tree = parse_html($response->content);
	my $base = $response->base;
	my($linkpair);
	my ($hit)=0;
	foreach $linkpair (@{$ht_tree->extract_links('a')})
	{                                 
		my($link,$elem) = @$linkpair;           
       		my $MyAsHTML=$elem->as_HTML();

		if ($hit != 0)
		{	
			my $title;
			$title=strip_tags($elem->as_text());
			$hit->add_url($link);
			$hit->title($title);
			push(@{$self->{cache}}, $hit);	
			print STDERR "Adding ",$hit->url,"\t",$title,"\n" unless $debug==0;
			$hit=0;
			$hits_found++;

		}

        	print "link=$link\n" unless $debug==0;

        	#Next Button ???
        	if ($MyAsHTML =~ m/src=\"\/Icons\/Search\/suite.gif\"/ )
        	{
                	print STDERR "Next page is=",$link,"\n" unless $debug==0;
			$self->{_next_url} = $link;
			goto fini;
        	}

        	#http://www.voila.fr/cgi_view?file=www.bretagne-online.tm.fr/telegram/index.html&words=bretagne#marker
		#signale une url dans l'element suivant
        	if ($link =~ m/http\:\/\/www\.voila\.fr\/cgi_view\?file\=/ )
        	{
                	#my $MyRealLink=$link;
                	#remove the start of url
                	#$MyRealLink =~ s/http\:\/\/www\.voila\.fr\/cgi_view\?file\=//;
                	#remove end of url until &
                	#print $MyRealLink,"\n" unless $debug==0;
                	#my $car="";
                	#while ($car ne "&")
                	#{
                       	#	$car = chop($MyRealLink);
                	#}
			#$MyRealLink="http://".$MyRealLink;

			$hit = new WWW::SearchResult;
			#$hit->add_url($MyRealLink);
			#on va recuperer le titre
			#$hit->title("mon titre qu'il est bidon");
        	}
    	}
fini:    
	return $hits_found;
}

__END__

