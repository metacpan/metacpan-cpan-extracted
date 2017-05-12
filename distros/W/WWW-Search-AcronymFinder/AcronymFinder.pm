package WWW::Search::AcronymFinder;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

our @ISA = qw(WWW::Search);
use WWW::Search qw/generic_option/;
require WWW::SearchResult;

my $MAINTAINER = 'xern <xern@cpan.org>';

sub native_setup_search {
    my($self, $native_query, $native_options_ref) = @_;
    $self->{_debug} = $native_options_ref->{'search_debug'};
    $self->{_debug} = 0 if (!defined($self->{_debug}));
    $self->{agent_e_mail} = 'xern@cpan.org';
    $self->user_agent('WWW::Search::AcronymFinder');
    $self->{_next_to_retrieve} = 1;
    $self->{'_num_hits'} = 0;

    if (!defined($self->{_options})) {
        $self->{'search_base_url'} = 'http://www.acronymfinder.com/';
        $self->{_options} = {
	    'search_url' => 'http://www.acronymfinder.com/af-query.asp',
	    'query' => $native_query,
	};
    }

    my $function;
    my %function = (
		    'reverse', 'on',
		    'wildcard', 'wildcard',
		    'prefix', 'off',
		    'exact' , 'exact'
		    );

    if (defined($native_options_ref)){
        foreach (keys %$native_options_ref)
	{
	    $function=
		"String=".$function{$native_options_ref->{function}}
	    if $function{$native_options_ref->{function}};
	}
    }

    my $options=
	join q/&/, grep{$_} "Acronym=".$self->{_options}->{query}, "Find=Find", $function;
    $self->{_next_url} = $self->{_options}{'search_url'}.'?'.$options;
}


sub native_retrieve_some {
    my ($self) = @_;
    return unless $self->{_next_url};
    my($response) = $self->http_request('GET', $self->{_next_url});
    $self->{response} = $response;

    if($self->{_num_hits} && $response->{_content} =~ /returned (\d+) hits/so){
	$self->{_num_hits} = $1;
    }

    while( $response->{_content} =~
	   m,<td valign="top" width="70%" bgcolor="#.+?">(?:<b>)?(.+?)(</b>)?\r\n</td>,mgo){
	push @{$self->{cache}}, $1;
    }

    if( $response->{_content} =~ 
       m,<a HREF="(af-query.asp\?acronym=.+?&amp;String=.+?&amp;page=\d+)"><font.+?><b>Next page,mo){
	$self->{_next_url} = $self->absurl($self->{search_base_url}, $1)->as_string;
	$self->{_next_url} =~ s/&amp;/&/go;
	return 1;
    }

    return 0;
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

WWW::Search::AcronymFinder - Perl interface to AcronymFinder.com

=head1 SYNOPSIS

  use WWW::Search::AcronymFinder;
  $search = new WWW::Search('AcronymFinder');
  $search->native_query(WWW::Search::escape_query($query), { function => 'exact' });
  while (my $result = $search->next_result()) {
    print "$result\n";
  }


=head1 DESCRIPTION

This module is a subclass of L<WWW::Search> and acts as a perl frontend to http://www.acronymfinder.com/.

Acronymfinder.com provides four functions to search acronyms: B<exact>, B<prefix>, B<wildcard>, and B<reverse>. If not specified, C<exact> is assumed.

=head1 AUTHOR

xern <xern@cpan.org>

=head1 SEE ALSO

L<WWW::Search>

L<findacronym.pl> installed with WWW::Search::AcronymFinder

=head1 LICENSE

Released under The Artistic License.

=cut
