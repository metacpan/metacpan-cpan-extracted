#===============================================================================
#
#  DESCRIPTION:  convert pod6 to atom
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================

=head1 NAME

WriteAt::To::Atom - Atom renderer

=head1 SYNOPSIS

        new WriteAt::To::Atom:: 
            lang=>'en', 
            baseurl=>'http://example.com',
            as_entry => 'CHAPTER',

=cut

package WriteAt::To::Atom;
use strict;
use warnings;
use Perl6::Pod::Utl;
use WriteAt::To;
use DateTime::Format::W3CDTF;

use Perl6::Pod::To::XHTML;
use base ( 'Perl6::Pod::To::XHTML', 'WriteAt::To' );
use utf8;
our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self =
      $class->SUPER::new( baseurl => 'http://example.com', lang => 'en', as_entry=>'CHAPTER', @_ );
    return $self;
}

sub get_published {
    my $self = shift;
    my $node = shift || return;
    return $node->get_attr->{published}

      #    unless
}

=head2 get_time_stamp_from_string <str>

Get time stamp from strnigs like this:

        2012-11-27T09:39:19Z
        2012-11-27 09:39:19
        2012-11-27 09:39
        2012-11-27 09
        2012-11-27

return unixtimestamp

=cut

sub get_time_stamp_from_string {
    my $self = shift;
    my $str  = shift;

    #if w3cdtf time
    if ( $str =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|.\d{2}:\d{2})/ ) {
        my $dt = DateTime::Format::W3CDTF->new();
        return $dt->parse_datetime($str)->epoch();
    }
    elsif ( $str =~
        /^(\d{4})-(\d{2})-(\d{2})(?:.(\d{2})(?::(\d{2})(?::(\d{2}))?)?)?/ )
    {
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4 || 0,
            minute     => $5 || 0,
            second     => $6 || 0,
            nanosecond => 500000000,
        );
        return $dt->epoch;
    }
    die "Bad srting $str";
}

=head2 unixtime_to_string timestamp

Return 

=cut

sub unixtime_to_string {
    my $self = shift;
    my $time = shift || return;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday ) = gmtime($time);
    $year += 1900;
    return sprintf( "%04d-%02d-%02dT%02d:%02d:%02dZ",
        $year, $mon + 1, $mday, $hour, $min, $sec );
}

sub start_write {
    my $self         = shift;
    my %tags         = @_;
    my $w            = $self->writer;
    my $title        = &WriteAt::get_text( @{ $tags{TITLE} } );
    my $base_url     = $self->{baseurl};
    my $author       = &WriteAt::get_text( @{ $tags{AUTHOR} } );
    my $atomid       = "tag:$base_url, 2012:1";
    my $updated_time = $self->unixtime_to_string( time() );
    $w->raw(<<TXT);
<?xml version="1.0" encoding="utf-8"?>
  <feed xmlns="http://www.w3.org/2005/Atom">
  <title>$title</title>
  <id>$atomid</id>
  <link rel="alternate" href="$base_url" type="text/html"/>
  <link rel="self" href="$base_url/Atom.xml" type="application/atom+xml"/>
  <updated>$updated_time</updated>
  <author>
    <name>$author</name>
    <uri>$base_url</uri>
  </author>
TXT
  # add category if tag exists
  if ( my $desc_node = $tags{DESCRIPTION}->[0] ) {
    if ( my $tags = $desc_node->get_attr()->{tag} ) {
        # save TAGS as ref to array 
        $self->{TAGS} = ref($tags) ? $tags : [$tags];
        #fill categoty tags
        foreach my $tag ( @{$self->{TAGS}} ) {
            $w->raw("<category>$tag</category>\n")
            
        }
    }
  }
}

sub write {
    my $self = shift;
    my $tree = shift;
    my $res ;
    if ($self->{as_entry} eq 'CHAPTER')  {
           $res  =  &WriteAt::make_levels( "CHAPTER", 0, $tree ) ;
    } else {
      #headN
        $self->{as_entry} =~ /(\d+)$/ || die "use in as_entry: head1, head2 ...";
        $res  =  &WriteAt::make_levels( "head", $1, $tree ) ;
    }
    my $w    = $self->writer;

    #first setup published attr for items
    # if default_published
    my $current_time =
        $self->{set_date}
      ? $self->get_time_stamp_from_string( $self->{set_date} )
      : time();
    my @items_to_publish = ();
    my $order            = 0;
    foreach my $entry (@$res) {
        $entry->{order} = ++$order;    #for sort in later
        my $published = $entry->{node}->get_attr->{published};
        #set default publushed = current time
        my $published_time =
            $published
          ? $self->get_time_stamp_from_string($published)
          : $current_time;

        #save publish timesamp for sorting later
        $entry->{pub_time} = $published_time;
        push @items_to_publish, $entry;
    }

    #sort entries
    @items_to_publish =
      sort { $b->{pub_time} <=> $a->{pub_time} || $b->{order} <=> $a->{order} }
      @items_to_publish;
    foreach my $entry (@items_to_publish) {

        # check if need filter by published
        my $published = $entry->{node}->get_attr->{published};
        my $updated   = $entry->{node}->get_attr->{updated} || $published || $self->unixtime_to_string($current_time);
        $published ||= $updated;
        my $title    = &WriteAt::get_text( $entry->{node} );
        my $title_en = &WriteAt::rus2lat($title);

        #strip spaces
        $title_en =~ s/\s+/-/g;
        my $filename = $title_en . ".htm";
        my $url      = $self->{baseurl} . "/" . $filename;
        my $id       = $self->{baseurl} . ";" . $title_en;
        $w->raw(
            qq%<entry xmlns="http://www.w3.org/2005/Atom">
                <title>$title</title>
                 <id>$id</id>
                 <link rel="alternate" href="$url" title="$title" type="text/html"/>
                <published>$published</published>
                <updated>$updated</updated>
                %
        );
        if ( my $tags = $entry->{node}->get_attr->{tag} ) {
            # save TAGS as ref to array 
            my $local_tags = ref($tags) ? $tags : [$tags];
            #union tags fill categoty tags
            foreach my $tag (  @{ $self->{TAGS}|| [] }, @{$local_tags} ) {
                $w->raw("<category>$tag</category>\n")
            }
        }

        my $out = '';
        open( my $fd, ">", \$out );
        my $renderer = new Perl6::Pod::To::XHTML::
          writer  => new Perl6::Pod::Writer( out => $fd, escape => 'xml' ),
          out_put => \$out,
          doctype => 'xhtml',
          header  => 0;

        foreach my $BLOCK_NAME ( keys %{ $self->context->use } ) {
            $renderer->context->use->{$BLOCK_NAME} =
              $self->context->use->{$BLOCK_NAME};
        }

        foreach my $n ( $entry->{childs} ) {
            $renderer->visit($n);
        }
        close $fd;
        my $safe_text = &Perl6::Pod::Writer::_html_escape($out);
        $w->raw('<content type="html">');
        $w->raw($safe_text);
        $w->raw(
            '</content>
        </entry>'
        );

    }

}

sub end_write {
    my $self = shift;
    $self->SUPER::end_write();
    $self->w->raw('</feed>');
}

sub page_template {
    my $self = shift;
    my %keys = @_;
    my $page = <<TXT;
<html>
<head>
<title>{{title}}</title>
</head>
<body>
   {{content}} 
</body>
</html>
TXT
    $page =~ s/\{\{ \s* (\S+) \s* \}\}/ $keys{$1} || ""/gex;
    return $page;
}

1;

