package Text::Summary::MediaWiki;
use strict;

use Carp;
use HTML::Entities;

our $VERSION = '0.02';

my %TMP_WHITELIST = (
  IPA => 1,
  'Lang-ru' => 1,
  'Nihongo' => 1, # not sure about this one

);

sub new {
  my($class, %opt) = @_;

  return bless {
    url => $opt{url} || croak("No URL provided"),
    get => $opt{get} || croak("No get callback provided"),
    redirect_limit => $opt{redirect_limit} || 5,
    approx_length => $opt{approx_length} || 200,
    template_whitelist => {%TMP_WHITELIST, $opt{template_whitelist}},
  }, $class;
}

sub get {
   my($self, $name, $redirects) = @_;

   return "Too many redirects" if defined @$redirects &&
     @$redirects > $self->{redirect_limit};

   $name = _name($name);

   my $text = $self->{get}->($self->{url} . $name);

   return "" unless $text =~ /\w/;

   return $self->format($text, $name, $redirects);
}

sub _name {
   my $name = ucfirst shift;
   $name =~ s/ /_/g;
   return $name;
}

sub format {
   my($self, $text, $title, $redirects) = @_;

   # handle redirects
   if($text =~ /^#REDIRECT[ :]*\[\[(.*?)(?:#.*?)?\]\]/i) {
      push @$redirects, $title;
      return $self->get($1, $redirects);
   }

   # Remove comments and templates (maybe should handle templates..?)
   $text =~ s/{{.*?}}//sg;
   $text =~ s/<!--.*?-->//sg;
   # Don't want references..
   $text =~ s/<ref>.*?<\/ref>//sg;

   my($line, $maybe) = ("", 0);
   for(split /\n/, $text) {
      s/\r//g;
      next if /^\s*$/;

      if(/^\s*(?:[-_#!\t}{:|<=\[]|\W*$)/
        && (!/^\s*\[\[/ || /\[\[Image:/i)) {
        if($maybe == 1 && /[#!{}|]/) { $maybe = 0; }
        next;
      }

      next if /^\s*\*/ and not $line; # lists in templates, etc.
      next if /^\s*\w+\s*=/; # info boxes..

      if($maybe < 1 && /^(?:the\s+)?'/i) { # '''Thing'' is ....
        $line = "" if $maybe == 0;
        $maybe = 2;
      }

      if($maybe == 1) {
        $maybe++;
      } elsif($maybe == 0) {
        $line = "" if $line;
        $maybe = 1;
      }

      s/\t/ /g;

      if(/\*/ || $maybe == 3) {
        $maybe = 3;
        $line =~ s/,$//, last unless /^\*/;
        if(/^\s*\*+\s*\[\[.*?\]\]\s*-(\s*.*?)\.?\s*$/) {
           $line .= "$1,";
        }else{
           /^\s*\*+\s*(.*?)\.?$/;
           my $st = $1;
           $line .= ($st =~ /[;:,.]$/ ? " $st" : " $st,");
        }
        next;
      }else{
        $line =~ s/\.$/. / if $line;
        $line .= $_;
      }

      next if length($line) < $self->{approx_length};
      last;
   }

   if(defined $line) {
      $line =~ s/'''//g;
      $line =~ s/''//g;
      $line =~ s/{{([^|]+)|(.*?)}}/
        exists $self->{template_whitelist}->{_name($1)} ? _tl_fixup($2) : ""/ge;
      $line =~ s/\[\[(.*?)\]\]/_wp_link($1)/ge;
      $line =~ s/\[[^ ]+ (.*?)\]/$1/g;
      $line =~ s/<[^>]+>//g;
      $line =~ s/\{\{(.*?)\}\}//g;
      $line = decode_entities($line);
   }

   if(length($line) > 350) {
      $line = substr($line, 0, 380);
      $line =~ s/ +/ /g;
      if(not($line =~ s/^(.{330}[^\.]+\.).*/$1/)) {
         $line =~ s/^(.{345,}\w+)\W.*/$1/;
      }
      $line =~ s/(?:\.)?\s*$//;
      $line .= "...";
   }

   # fixup places where we've stripped templates
   $line =~ s/\s*,\s*\)/)/g;
   $line =~ s/\(\s*,\s*/(/g;
   $line =~ s/\(\s*\)//g;

   # get rid of extra spacing
   $line =~ s/ +/ /g;
   $line =~ s/(^ | $)//g;

   return $line, "$self->{url}$title" if wantarray;
   return $line;
}

sub _tl_fixup {
  my $name = shift;
  $name =~ s/|/ /g;
  return $name;
}

sub _wp_link {
  my $link = shift;
  my $x = index($link, '|');
  return substr($link, $x + 1) if $x != -1;
  return $link
}

1;
__END__

=head1 NAME

Text::Summary::MediaWiki - Produce a short summary from MediaWiki markup

=head1 SYNOPSIS

    use Text::Summary::MediaWiki;

    my $s = Text::Summary::MediaWiki->new(
      url => "http://en.wikipedia.org/wiki/", # Trailing / is required
      get => sub {
        my($url) = @_;
        # return markup of page at URL
      });

    print $s->get("Perl");

=head1 DESCRIPTION

Produces short summaries from MediaWiki markup. This has been mostly tested
with Wikipedia but this should work for any wiki using MediaWiki markup.

Note that making requests to Wikipedia for each page is considered rather rude,
if you need a high query volume use a local database dump (I use
L<Parse::MediaWikiDump>).

=head1 METHODS

=head2 new

The C<new> method takes a parameter hash containing the following:

=over 4

=item * url

Required, the URL used to identify the instance of MediaWiki to produce summaries for. This should be the base
path to the instance.

=item * get

Required, a callback to fetch the actual text, this is required so the code can get additional pages if
redirected.

=item * redirect_limit

Optional, a limit for redirection, default 5.

=item * approx_length

Optional, approximate length of summary to produce (in characters), default 200.

=back

=head2 get

Given the name of an article fetches it and generates a summary.

If called in array context returns the summary and the URL it can be found at.

=head2 format

Generates a summary from text in MediaWiki format.

=head1 AUTHOR

David Leadbeater C<<dgl at dgl.cx>>

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Leadbeater, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
