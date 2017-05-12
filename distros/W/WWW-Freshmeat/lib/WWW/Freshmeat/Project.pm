package WWW::Freshmeat::Project;

use 5.008;
use strict;
use warnings;
use WWW::Freshmeat::Project::URL;
use Carp;


our $VERSION = '0.22';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self=bless shift, $class;
    $self->{www_freshmeat} = shift || die;
    return $self;
}

my %new_api_map=('www_freshmeat'=>'www_freshmeat','desc_short'=>'oneliner',
 'desc_full'=>'description','projectname_full'=>'name','projectname_short'=>'permalink');
foreach my $field ( qw(url_homepage projectname_full desc_short desc_full license www_freshmeat projectname_short) ) {
    no strict 'refs';
    my $xml_field=$new_api_map{$field};
    if ($xml_field) {
      *$field = sub {
          my $self = shift;
          my $value = $self->{$xml_field};
          if ( ref($value) && ref($value) eq 'HASH' && !(keys %$value) ) {
              return undef;
          }
          else {
              return $value;
          }
      }
    } else {
      *$field = sub {
        croak "'$field' method was removed";
      }
    }
}

sub name        { $_[0]->{name} } 
sub description { $_[0]->desc_full(@_) || $_[0]->desc_short(@_) } 

sub url_project_page {
  my $self = shift;
  return 'http://freshmeat.net/projects/'.$self->{'permalink'};
}

sub languages {
  my $self = shift;
  my $lang = $self->{'programming-language-list'};
  return (split /,\s*/,$lang);
}

sub tags {
  my $self = shift;
  my $tags = $self->{'tag-list'};
  return (split /,\s*/,$tags);
}

sub trove_id { 
  croak "method was removed";
  #$_[0]{descriminators}{trove_id}
}

sub version { 
  my $self=shift;
  return '' unless exists $self->{'recent-releases'}{'recent-release'};
  my @versions=@{$self->{'recent-releases'}{'recent-release'}};
  return $versions[0]->{'version'};
}

sub release_date {
  croak "'release_date' is temporarily removed";
  my $dt=$_[0]{latest_release}{latest_release_date};
  if (ref($dt) eq 'HASH') {
    return '';
  } else {
    if ($dt eq '1970-01-01 00:00:00') {
      return '';
    } else {
      return $dt;
    }
  }
}

sub date_add {
  my $dt=$_[0]{'created-at'}{'content'};
  if (ref($dt)) { # eq 'HASH'
    die ref($dt);
    return '';
  } else {
    if ($dt eq '1970-01-01 00:00:00' or $dt eq '1970-01-01T00:00:00Z') {
      die;
    } else {
      $dt=~s/T/ /g;$dt=~s/Z$//g; #get rid ot T and Z in '2009-01-22T14:58:27Z'
      die if $dt=~/[a-zA-Z]/;
      return $dt;
    }
  }
}

sub date_updated {
  my $dt=$_[0]{'updated-at'}{'content'};
  if (ref($dt)) { # eq 'HASH'
    die ref($dt);
    return '';
  } else {
    if ($dt eq '1970-01-01 00:00:00' or $dt eq '1970-01-01T00:00:00Z') {
      die;
    } else {
      $dt=~s/T/ /g;$dt=~s/Z$//g; #get rid ot T and Z in '2009-01-22T14:58:27Z'
      die if $dt=~/[a-zA-Z]/;
      return $dt;
    }
  }
}

sub maintainers {
  croak "removed";
  my $authors=$_[0]{authors}{author};
  if (ref($authors) eq 'HASH') {
    if (keys %$authors>0) {
      return ($authors->{author_name});
      #$authors=[$authors];
    } else {
      return ();
    }
  } elsif (ref($authors) eq 'SCALAR') {
    die;
    #$authors=[$authors];
  }
  return map { $_->{author_name} } @$authors;
}

sub url {
    croak "removed";
    my $self = shift;
    return $self->{url} if $self->{url};
    my $freshmeat_url = $self->{url_project_page};

    my $url = $self->url_homepage() or return;

    $self->{url} = $self->www_freshmeat()->redir_url($url);
    return $self->{url};
}

sub init_html {
    croak "removed";
    my $self = shift;
    my $html = shift;
    #require HTML::TreeBuilder::XPath;
    $self->{_html}=HTML::TreeBuilder::XPath->new_from_content($html);
}

sub _html_tree {
    croak "removed";
    my $self = shift;
    if (!$self->{_html}) {
      my $id=$self->projectname_short();
      my $url = "http://freshmeat.net/projects/$id/";
      $self->www_freshmeat()->agent('User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; ru; rv:1.8.1.19) Gecko/20081201 Firefox/2.0.0.19');
      my $response = $self->www_freshmeat()->get($url);
      my $html = $response->content();
      if ($response->is_success) {
        $self->init_html($html);
      } else {
        die "Could not GET $url (".$response->status_line.", $html)";
      }
    }
    return $self->{_html};
}

sub branches {
    croak "removed";

=for cmt    
    my $self = shift;
    my $tree=$self->_html_tree();
    my $nodes=$tree->findnodes(q{//table/tr/th/b[text()='Branch']/../../following-sibling::tr/td[1]/a});
    my %list;
    while (my $node=$nodes->shift) {
      if ($node->attr('href') =~m#/branches/(\d+)/#) {
        $list{$1}=$node->as_text();
      } else {
        die;
      }
    }
    return %list;
=cut
}

our $project_re=qr/[a-z0-9_\-\.!]+/;
sub url_list {
    croak "removed";

=for cmt
    my $self = shift;
    my $real=(@_>0?1:0);
    my $tree=$self->_html_tree();
    my $nodes=$tree->findnodes(q{/html/body/div/table/tr/td/table/tr/td/p/a[@href=~/\/redir/]}); #/
    my %list;
    while (my $node=$nodes->shift) {
      if ($node->attr('href') =~m#/redir/$project_re/\d+/(url_\w+)/#) {
        my $type=$1;
        my $text=$node->as_text();
        if ($text=~/\Q[..]\E/) {
          if ($real) {
            $list{$type}=$self->www_freshmeat()->redir_url('http://freshmeat.net'.$node->attr('href'));
          } else {
            $list{$type}=$node->attr('href');
          }
        } else {
          $list{$type}=$text;
        }
      } else {
        die "bad link:".$node->attr('href');
      }
    }
    return %list;
=cut

}

sub url_list1 {
    my $self = shift;
    die unless $self->isa('WWW::Freshmeat::Project');
    my $url_xml=$self->{'approved-urls'}{'approved-url'};
    die unless $url_xml;
    my @urls;
    my %dedupe;
    foreach my $a_url (@$url_xml) {
      die unless $a_url->{type} eq 'Url';
      my $concatenated=$a_url->{permalink}.$a_url->{label};
      next if $dedupe{$concatenated};
      $dedupe{$concatenated}=1;
      #my $a_url1=$a_url->{'content'};
      my $url=WWW::Freshmeat::Project::URL->new(
       (map {$_=>$a_url->{$_}} qw/label redirector host/),
       www_freshmeat=>$self->{www_freshmeat},
      );
      push @urls,$url;
      #if (1) {
      #} else {
      #  die "bad link:";
      #}
    }
    return @urls;
    #return %list;
}

my %detect_url_types=('website'=>'url_homepage',
'homepage'=>'url_homepage',
'home'=>'url_homepage',
lc 'Download'=>'url_download',
'bug tracker'=>'url_bugtracker',
lc 'GitHub source repo' => 'url_cvs',
lc 'Repository' => 'url_cvs',
'cpan' => 'url_mirror',
lc 'Mirror site' => 'url_mirror',
);
#url_changelog
#url_download
#url_cvs
#url_mirror
sub detect_link_types {
    my $self = shift;
    my $urls = shift;
    my %type_set;
    foreach my $url (@$urls) {
      my $type=$detect_url_types{lc $url->{label}} || '';
      #$type_set{$type} ||= [];
      if (exists $type_set{$type}) {
        if (ref $type_set{$type} eq 'ARRAY') {
          push @{$type_set{$type}},$url;
        } else {
          $type_set{$type}=[$type_set{$type},$url];
        }
      } else {
        $type_set{$type}=$url;
      }
      #if ($type) {
      #} else 
    }
    return \%type_set;
}

my %popularity_conv=('Record hits'=>'record_hits','URL hits'=>'url_hits','Subscribers'=>'subscribers');
sub popularity {
    croak "removed";
    my $self = shift;
    my $tree=$self->_html_tree();
    my $nodes=$tree->findnodes(q{/html/body/div[1]/table/tr/td[2]/table/tr[3]/td[3]/table[2]/tr/td/small});
    my %list;
    if (my $node=$nodes->shift) {
      my $text=$node->as_text();
      $text=~s/à/ /g;
      my @list=grep {$_} split /<br(?: \/)?>|\s{4}/,$text;
      foreach my $s (@list) {
        $s=~s/^(?:^&nbsp;|\s)+//s;
        $s=~s/\s+$//s;
        #print "F:$s\n";
        if ($s=~/(\w[\w\s]+\w):\s+([\d,]+)/ and exists $popularity_conv{$1}) {
          my $type=$popularity_conv{$1};
          my $num=$2;
          $num=~s/,//g;
          $list{$type}=$num;
        } else {
          die "Cannot find popularity record: '$s'";
        }
        
      }
    } else {
      die "Cannot find popularity data";
    }
    return %list;
}

sub real_author {
    croak "removed";

    my $self = shift;
    my $tree=$self->_html_tree();
    my $nodes=$tree->findnodes(q{/html/body/div[1]/table/tr/td[2]/table/tr[3]/td[1]/p[2]/b/..});
    my %list;
    if (my $node=$nodes->shift) {
      my $text=$node->as_text;
      $text=~s/^Author:\s+//s;
      $text=~s/\s+\Q[contact developer]\E\s*$//s;
      $text=~s/\s+<[^<>]+>\s*$//s;
      return $text;
    }
}


=head2 WWW::Freshmeat::Project methods

The C<WWW::Freshmeat::Project> object provides some of the fields from the
freshmeat.net entry through the following methods

=over 4

=item B<url_project_page>

URL of project page on Freshmeat 

=item B<url_homepage>

deprecated

=item B<projectname_full>

=item B<desc_short>

=item B<desc_full>

=item B<license>

=item B<trove_id>

Removed.

=item B<projectname_short>

=item B<www_freshmeat>

=back

Additionally, it provides the following "higher-level" methods:

=over 4

=item B<name>

=item B<description>

Return either C<projectname_full> (respectively C<desc_full>) or
C<projectname_short> (respectively C<desc_short>) if the former is empty.

=item B<version>

Returns the version of the latest release.

=item B<url>

Removed.

C<url_homepage> returns a freshmeat.net URL that redirects to the actual
project's home page. This url() method tries to follow the redirection and
returns the actual homepage URL if it can be found, or the URL to the
freshmeat.net entry for the project.

=item B<branches>

Removed.

List of branches for project. Returns hash in form of (branch id => branch name).

=item B<popularity>

Removed.

Freshmeat popularity data for project. Returns hash with keys
record_hits, url_hits, subscribers

=item B<url_list>

Removed.

=item B<url_list1>

Returns list of URLs for project. Each URL is a WWW::Freshmeat::Project::URL object.

=item B<real_author>

Removed.

Returns name of author (not maintainer).

=item B<release_date>

Removed.

Returns date of latest release.

=item B<maintainers>

Removed.

Returns list of names of maintainers.

=back

1;
