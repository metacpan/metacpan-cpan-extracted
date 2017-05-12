package WWW::Freshmeat::User;

use strict;
use warnings;
use WWW::Freshmeat ();
use Carp;

our $VERSION = '0.22';

sub init_html {
    croak "removed";
    my $self = shift;
    my $html = shift;
    require HTML::TreeBuilder::XPath;
    $self->{_html}=HTML::TreeBuilder::XPath->new_from_content($html);
}

sub _html_tree {
    my $self = shift;
    if (!$self->{_html}) {
      my $id=$self->{id};
      my $url = "http://freshmeat.net/~$id/";
      $self->{www_freshmeat}->agent('User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; ru; rv:1.8.1.19) Gecko/20081201 Firefox/2.0.0.19');
      my $response = $self->{www_freshmeat}->get($url);
      my $html = $response->content();
      if ($response->is_success) {
        if ($html=~m#<p>\s*Invalid user ID\s*</p>#s) {
          return;
        }
        $self->init_html($html);
      } else {
        die "Could not GET $url (".$response->status_line.", $html)";
      }
    }
    return $self->{_html};
}

sub new {
    croak "removed";
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;
    $self->{www_freshmeat} = shift;
    $self->{id} = shift;
    return $self;
}


sub projects {
    my $self = shift;
    my $tree=$self->_html_tree();
    my $xpath=q{/html/body/div[1]/table/tr/td[2]/table/tr[1]/td[2]/p/ul[1]/li/a};
    my $nodes=$tree->findnodes($xpath);
    my @list;
    while (my $node=$nodes->shift) {
      if ($node->attr('href') =~m#/projects/($WWW::Freshmeat::Project::project_re)/#) {
        push @list,$1;
      } else {
        die;
      }
    }
    return @list;
}

1

# (c) Alexandr Ciornii, 2009
