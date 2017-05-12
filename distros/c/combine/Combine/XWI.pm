# $Id: XWI.pm 226 2006-12-13 15:06:48Z anders $

# Copyright (c) 1996-1998 LUB NetLab, 2002-2006 Anders Ardö
# 
# See the file LICENCE included in the distribution.

package Combine::XWI;

use strict;
use HTML::Entities;

sub new { 
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    $self->url_reset;
    $self->heading_reset;
    $self->link_reset;
    $self->meta_reset;
    $self->robot_reset;
    $self->topic_reset;
    return $self;
} 

sub DESTROY {
#  print "an XWI object is destroyed" if Combine::Config::GetLoglev() > 2;
}

sub AUTOLOAD {
    my ($self, $value) = @_;
    my $name = $Combine::XWI::AUTOLOAD;
    $name =~ s/.*://;
    if ($value) { 
	$self->{$name} = $value;
	return undef;
    }
    else {
	return $self->{$name};
    }
}

sub url_remove {
    my ($self,$url) = @_;
    my ($i,$next);
    my $index = 1;
    my $count = $self->{'url_count'};
    while ( $index <= $count and $self->{"url_$index"} ne $url ) {
      $index++;
    }
    return undef if $index > $count;
    for ($i=$index; $i<$count; $i++) {
       $next = $i + 1;
       $self->{"url_$i"} = $self->{"url_$next"};
    }
    $self->{'url_count'}--;
}

sub url_reset { 
    my ($self) = @_; 
    $self->{'url_point'} = 1;
    $self->{'url_count'} = 0;
}

sub url_rewind {
    my ($self) = @_;
    $self->{'url_point'} = 1;
}

sub url_add {
    my ($self, $url) = @_;
    $self->{'url_count'}++;
    my $point = $self->{'url_count'};
    $self->{"url_$point"} = $url;
    return $self->{'url_count'};
}

sub url_get {
    my ($self) = @_;
    my $point = $self->{'url_point'};
    return undef unless $point <= $self->{'url_count'};
    $self->{'url_point'}++;
    return $self->{"url_$point"};
}

sub meta_reset {
    my ($self) = @_;
    $self->{'meta_point'} = 1;
    $self->{'meta_count'} = 0;
}

sub meta_rewind {
    my ($self) = @_;
    $self->{'meta_point'} = 1;
}

sub meta_add {
    my ($self, $meta_name, $meta_content) = @_;
    $self->{'meta_count'}++;
    my $point = $self->{'meta_count'};
    $self->{"meta_" . $point . "_name"} = $meta_name;
    $self->{"meta_" . $point . "_content" } = 
	HTML::Entities::decode_entities($meta_content);
# special for robots meta-tag
    if ( $meta_name eq "robots" ) {
       $self->{metarobots} = $meta_content;
    }
    return $self->{'meta_count'};
}

sub meta_get {
    my ($self) = @_;
    my $point = $self->{'meta_point'};
    return undef unless $point <= $self->{'meta_count'};
    $self->{'meta_point'}++;
    my $meta_name = $self->{"meta_" . $point . "_name"};
    my $meta_content = $self->{"meta_" . $point . "_content"};
    return($meta_name, $meta_content);
}

sub robot_reset {
    my ($self) = @_;
    $self->{'robot_point'} = 1;
    $self->{'robot_count'} = 0;
}

sub robot_rewind {
    my ($self) = @_;
    $self->{'robot_point'} = 1;
}

sub robot_add {
    my ($self, $robot_name, $robot_content) = @_;
    $self->{'robot_count'}++;
    my $point = $self->{'robot_count'};
    $self->{"robot_" . $point . "_name"} = $robot_name;
    $self->{"robot_" . $point . "_content" } = $robot_content;
    return $self->{'robot_count'};
}

sub robot_get {
    my ($self) = @_;
    my $point = $self->{'robot_point'};
    return undef unless $point <= $self->{'robot_count'};
    $self->{'robot_point'}++;
    my $robot_name = $self->{"robot_" . $point . "_name"};
    my $robot_content = $self->{"robot_" . $point . "_content"};
    return($robot_name, $robot_content);
}


sub topic_reset {
    my ($self) = @_;
    $self->{'topic_point'} = 1;
    $self->{'topic_count'} = 0;
}

sub topic_rewind {
    my ($self) = @_;
    $self->{'topic_point'} = 1;
}

sub topic_add {
    my ($self, $topic_cls, $topic_absscore, $topic_relscore, $terms, $algorithm) = @_;
    $self->{'topic_count'}++;
    my $point = $self->{'topic_count'};
    $self->{"topic_" . $point . "_cls"} = $topic_cls;
    $self->{"topic_" . $point . "_absscore" } = $topic_absscore;
    $self->{"topic_" . $point . "_relscore" } = $topic_relscore;
    $self->{"topic_" . $point . "_terms" } = $terms;
    $self->{"topic_" . $point . "_algorithm" } = $algorithm;
    return $self->{'topic_count'};
}

sub topic_get {
    my ($self) = @_;
    my $point = $self->{'topic_point'};
    return undef unless $point <= $self->{'topic_count'};
    $self->{'topic_point'}++;
    my $topic_cls = $self->{"topic_" . $point . "_cls"};
    my $topic_absscore = $self->{"topic_" . $point . "_absscore"};
    my $topic_relscore = $self->{"topic_" . $point . "_relscore"};
    my $terms = $self->{"topic_" . $point . "_terms"};
    my $algorithm = $self->{"topic_" . $point . "_algorithm"};
    return($topic_cls, $topic_absscore, $topic_relscore, $terms, $algorithm);
}

sub xmeta_reset {
    my ($self) = @_;
    $self->{'xmeta_point'} = 1;
    $self->{'xmeta_count'} = 0;
}

sub xmeta_rewind {
    my ($self) = @_;
    $self->{'xmeta_point'} = 1;
}

sub xmeta_add {
    my ($self, $meta_name, $meta_content, $meta_scheme,
	$meta_lang, $meta_group) = @_;
    $self->{'xmeta_count'}++;
    my $point = $self->{'xmeta_count'};
    $self->{"xmeta_" . $point . "_name"} = $meta_name;
    $self->{"xmeta_" . $point . "_content" } = $meta_content;
    $self->{"xmeta_" . $point . "_scheme" } = $meta_scheme;
    $self->{"xmeta_" . $point . "_lang" } = $meta_lang;
    $self->{"xmeta_" . $point . "_group" } = $meta_group;
    return $self->{'xmeta_count'};
}

sub xmeta_get {
    my ($self) = @_;
    my $point = $self->{'xmeta_point'};
    return undef unless $point <= $self->{'xmeta_count'};
    $self->{'xmeta_point'}++;
    my $meta_name = $self->{"meta_" . $point . "_name"};
    my $meta_content = $self->{"meta_" . $point . "_content"};
    my $meta_scheme = $self->{"xmeta_" . $point . "_scheme" };
    my $meta_lang = $self->{"xmeta_" . $point . "_lang" };
    my $meta_group = $self->{"xmeta_" . $point . "_group" };

    return ($meta_name, $meta_content, $meta_scheme,$meta_lang, $meta_group);
}


sub heading_reset { 
    my ($self) = @_; 
    $self->{'heading_point'} = 1;
    $self->{'heading_count'} = 0;
}

sub heading_rewind {
    my ($self) = @_;
    $self->{'heading_point'} = 1;
}

sub heading_add {
    my ($self, $heading) = @_;
    $self->{'heading_count'}++;
    my $point = $self->{'heading_count'};
    $self->{"heading_$point"} = HTML::Entities::decode_entities($heading);
    return $self->{'heading_count'};
}

sub heading_get {
    my ($self) = @_;
    my $point = $self->{'heading_point'};
    return undef unless $point <= $self->{'heading_count'};
    $self->{'heading_point'}++;
    return $self->{"heading_$point"};
}

sub link_reset { 
    my ($self) = @_; 
    $self->{'link_point'} = 1;
    $self->{'link_count'} = 0;
}

sub link_rewind {
    my ($self) = @_;
    $self->{'link_point'} = 1;
}

sub link_add {
    my ($self, $link_urlstr, $link_netlocid, $link_urlid, $link_text, $link_type) = @_;
    $self->{'link_count'}++;
    my $point = $self->{'link_count'};
    $self->{"link_" . $point . "_text"} = 
	HTML::Entities::decode_entities($link_text);
    $self->{"link_" . $point . "_urlstr" } = $link_urlstr;
    $self->{"link_" . $point . "_netlocid" } = $link_netlocid;
    $self->{"link_" . $point . "_urlid" } = $link_urlid;
    $self->{"link_" . $point . "_type" } = $link_type;
    return $self->{'link_count'};
}

sub link_get {
    my ($self) = @_;
    my $point = $self->{'link_point'};
    return undef unless $point <= $self->{'link_count'};
    $self->{'link_point'}++;
    my $link_text = $self->{"link_" . $point . "_text"};
    my $link_urlstr  = $self->{"link_" . $point . "_urlstr"};
    my $link_netlocid  = $self->{"link_" . $point . "_netlocid"};
    my $link_urlid  = $self->{"link_" . $point . "_urlid"};
    my $link_type  = $self->{"link_" . $point . "_type"};
    return($link_urlstr, $link_netlocid, $link_urlid, $link_text, $link_type);
}

1;

__END__

=head1 NAME

XWI.pm - class for internal representation of a document record

=head1 SYNOPSIS

 use Combine::XWI;
 $xwi = new Combine::XWI;

 #single value record variables
 $xwi->server($server);

 my $server = $xwi->server();

 #original content
 $xwi->content(\$html);

 my $text = ${$xwi->content()};

 #multiple value record variables
 $xwi->meta_add($name1,$value1);
 $xwi->meta_add($name2,$value2);

 $xwi->meta_rewind;
 my ($name,$content);
 while (1) {
  ($name,$content) = $xwi->meta_get;
  last unless $name;
 } 


=head1 DESCRIPTION

Provides methods for storing and retrieving structured records
representing crawled documents.

=head1 METHODS

=head2 new()

=head2 XXX($val)

Saves $val using AUTOLOAD. Can later be retrieved, eg

    $xwi->MyVar('My value');
    $t = $xwi->MyVar;

will set $t to 'My value'

=head2 *_reset()

Forget all values.

=head2 *_rewind()

*_get will start with the first value.

=head2 *_add

stores values into the datastructure

=head2 *_get

retrieves values from the datastructure

=head2 meta_reset() / meta_rewind() / meta_add() / meta_get()

Stores the content of Meta-tags

Takes/Returns 2 parameters: Name, Content

 $xwi->meta_add($name1,$value1);
 $xwi->meta_add($name2,$value2);

 $xwi->meta_rewind;
 my ($name,$content);
 while (1) {
  ($name,$content) = $xwi->meta_get;
  last unless $name;
 } 

=head2 xmeta_reset() / xmeta_rewind() / xmeta_add() / xmeta_get()

Extended information from Meta-tags. Not used.

=head2 url_remove() / url_reset() / url_rewind() / url_add() / url_get()

Stores all URLs (ie if multiple URLs for the same page) for this record

Takes/Returns 1 parameter: URL

=head2 heading_reset() / heading_rewind() / heading_add() / heading_get()

Stores headings from HTML documents

Takes/Returns 1 parameter: Heading text

=head2 link_reset() / link_rewind() / link_add() / link_get()

Stores links from documents

Takes/Returns 5 parameters: URL, netlocid, urlid, Anchor text, Link type

=head2 robot_reset() / robot_rewind() / robot_add() / robot_get()

Stores calculated information, like genre, language, etc

Takes/Returns 2 parameters Name, Value. Both are strings with max length Name: 15, Value: 20

=head2 topic_reset() / topic_rewind() / topic_add() / topic_get()

Stores result of topic classification.

Takes/Returns 5 parameters: Class, Absolute score, Normalized score, Terms, Algorithm id

Class, Terms, and Algorithm id are strings with max
lengths Class: 50, and Algorithm id: 25

Absolute score, and Normalized score are integers

Normalized score and Terms are optional and may be replaced with 0, and '' respectively

=head1 SEE ALSO

Combine focused crawler main site L<http://combine.it.lth.se/>

=head1 AUTHOR

Yong Cao <tsao@munin.ub2.lu.se> v0.05 1997-03-13

Anders Ardö, E<lt>anders.ardo@it.lth.seE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005,2006 Anders Ardö

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

See the file LICENCE included in the distribution at
 L<http://combine.it.lth.se/>

=cut
