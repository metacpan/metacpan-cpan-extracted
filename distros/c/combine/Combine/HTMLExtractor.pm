package Combine::HTMLExtractor;

use strict;

use HTML::TokeParser 2; # use HTML::TokeParser::Simple 2;
use URI 1;
use Carp qw( croak );

use vars qw( $VERSION );
$VERSION = '0.121';

## The html tags which might have URLs
# the master list of tagolas and required attributes (to constitute a link)
use vars qw( %TAGS );
%TAGS = (
              a => [qw( href )],
         applet => [qw( archive code codebase src )],
           area => [qw( href )],
           base => [qw( href )],
        bgsound => [qw( src )],
     blockquote => [qw( cite )],
           body => [qw( background )],
            del => [qw( cite )],
            div => [qw( src )], # IE likes it, but don't know where it's documented
          embed => [qw( pluginspage pluginurl src )],
           form => [qw( action )],
          frame => [qw( src longdesc  )],
         iframe => [qw( src )],
         ilayer => [qw( background src )],
            img => [qw( dynsrc longdesc lowsrc src usemap )],
          input => [qw( dynsrc lowsrc src )],
            ins => [qw( cite )],
        isindex => [qw( action )], # real oddball
          layer => [qw( src )],
           link => [qw( src href )],
         object => [qw( archive classid code codebase data usemap )],
              q => [qw( cite )],
         script => [qw( src  )], # HTML::Tagset has 'for' ~ it's WRONG!
          sound => [qw( src )],
          table => [qw( background )],
             td => [qw( background )],
             th => [qw( background )],
             tr => [qw( background )],
  ## the exotic cases
           meta => undef,
     '!doctype' => [qw( url )], # is really a process instruction
);

## tags which contain <.*?> STUFF TO GET </\w+>
use vars qw( @TAGS_IN_NEED );
@TAGS_IN_NEED = qw(
    a
    blockquote
    del
    ins
    q
);

use vars qw( @VALID_URL_ATTRIBUTES );
@VALID_URL_ATTRIBUTES = qw(
        action
        archive
        background
        cite
        classid
        code
        codebase
        data
        dynsrc
        href
        longdesc
        lowsrc
        pluginspage
        pluginurl
        src
        usemap
);

use vars qw( %SECTIONTAGS );
%SECTIONTAGS = (
		'div' => 1,
		'p' => 1,
		'table' => 1,
		'ol' => 1,
		'ul' => 1,
		'dir' => 1,
		'menu' => 1,
		'h1' => 1,
		'h2' => 1,
		'h3' => 1,
		'h4' => 1,
		'h5' => 1,
		'h6' => 1
		);

sub new {
    my($class, $cb, $base, $strip) = @_;
    my $self = bless {}, $class;


    $self->{_cb} = $cb if defined $cb;
    $self->{_base} = URI->new($base) if defined $base;
    $self->strip( $strip || 0 );

    return $self;
}

sub strip {
    my( $self, $on ) = @_;
    return $self->{_strip} unless defined $on;
    return $self->{_strip} = $on ? 1 : 0;
}

## $p= HTML::TokeParser::Simple->new($filename || FILEHANDLE ||\$filecontents);

sub parse {
    my( $this, $hmmm ) = @_;
    my $tp = new HTML::TokeParser( $hmmm );#    my $tp = new HTML::TokeParser::Simple( $hmmm );

    unless($tp) {
        croak qq[ Couldn't create a HTML::TokeParser object: $!];#        croak qq[ Couldn't create a HTML::TokeParser::Simple object: $!];
    }

    $this->{_tp} = $tp;

    $this->_parsola();
    return();
}

sub _parsola {
    my $self = shift;

## a stack of links for keeping track of TEXT
## which is all of "<a href>text</a>"
    my @TEXT = ();
    $self->{_LINKS} = [];
    my $tottext=''; #All visible text
    my $inHeading=0; my $headtext=''; #All headings
#  ["S",  $tag, $attr, $attrseq, $text]
#  ["E",  $tag, $text]
#  ["T",  $text, $is_data]
#  ["C",  $text]
#  ["D",  $text]
#  ["PI", $token0, $text]

    while (my $T = $self->{_tp}->get_token() ) {
        my $NL; #NewLink
        my $Tag = $T->[1]; #        my $Tag = $T->return_tag;
        my $got_TAGS_IN_NEED=0;
#	Adump($T); #Debug

## Start tag?
        if( $T->[0] eq 'S' ) { #        if($T->is_start_tag) {
	    if ( $Tag =~ /^h\d$/ ) { $inHeading=1; }
	    if (exists $SECTIONTAGS{$Tag}) { $tottext .= "\n\n";}
            next unless exists $TAGS{$Tag};

## Do we have a tag for which we want to capture text?
            $got_TAGS_IN_NEED = 0;
            $got_TAGS_IN_NEED = grep { /^\Q$Tag\E$/i } @TAGS_IN_NEED;

## then check to see if we got things besides META :)
            if(defined $TAGS{ $Tag }) {

                for my $Btag(@{$TAGS{$Tag}}) {
## and we check if they do have one with a value
                    if(exists $T->[2]->{ $Btag }) { #                    if(exists $T->return_attr()->{ $Btag }) {

                        $NL = $T->[2]; #Save all attributes incl ALT in IMG # $NL = $T->return_attr();
## TAGS_IN_NEED are tags in deed (start capturing the <a>STUFF</a>)
                        if($got_TAGS_IN_NEED) {
                            push @TEXT, $NL;
                            $NL->{_TEXT} = "";
                        }
                    }
                }
		if ($Tag eq 'img') {
		    #extract ALT-text
		    if (exists $T->[2]->{alt}) {
			$tottext .= '[' . $T->[2]->{alt} . '] ';
		    } ##else { $tottext .= '[IMG]'; }
		}
            }elsif($Tag eq 'meta') {
                $NL = $T->[2]; #                $NL = $T->return_attr();

                if(defined $$NL{content} and length $$NL{content} and (
                    defined $$NL{'http-equiv'} &&  $$NL{'http-equiv'} =~ /refresh/i
                    or
                    defined $$NL{'name'} &&  $$NL{'name'} =~ /refresh/i
                    ) ) {

                    my( $timeout, $url ) = split m{;\s*?URL=}, $$NL{content},2;
                    my $base = $self->{_base};
                    $$NL{url} = URI->new_abs( $url, $base ) if $base;
                    $$NL{url} = $url unless exists $$NL{url};
                    $$NL{timeout} = $timeout if $timeout;
                }
            }

            ## In case we got nested tags
            if(@TEXT) {
                $TEXT[-1]->{_TEXT} .= $T->[-1]; #                $TEXT[-1]->{_TEXT} .= $T->as_is;
#		my $t=$T->[-1]; print " Nested: $t\n"; #debug
            }

## Text?
        }elsif($T->[0] eq 'T') { #        }elsif($T->is_text) {
            $TEXT[-1]->{_TEXT} .= $T->[-2] if @TEXT; #            $TEXT[-1]->{_TEXT} .= $T->as_is if @TEXT;
	    $tottext .=  $T->[-2] . ' '; #	    $tottext .=  $T->as_is;
	    if ( $inHeading ) { $headtext .= $T->[-2]; } #	    if ( $h ne '' ) { $headtext .= $T->as_is . '; '; }
## Declaration?
        }elsif($T->[0] eq 'D') { #        }elsif($T->is_declaration) {
## We look at declarations, to get anly custom .dtd's (tis linky)
            my $text = $T->[-1]; #            my $text = $T->as_is;
            if( $text =~ m{ SYSTEM \s \" ( [^\"]* ) \" > $ }ix ) {
                $NL = { raw => $text, url => $1, tag => '!doctype' };
            }
## End tag?
        }elsif($T->[0] eq 'E'){ #        }elsif($T->is_end_tag){
	    if ( $Tag =~ /^h\d$/ ) { $inHeading=0; $headtext .= '; '; }
	    if (exists $SECTIONTAGS{$Tag}) { $tottext .= "\n\n";}
## these be ignored (maybe not in between <a...></a> tags
## unless we're stacking (bug #5723)
            if(@TEXT and exists $TAGS{$Tag}) {
                $TEXT[-1]->{_TEXT} .= $T->[-1]; #                $TEXT[-1]->{_TEXT} .= $T->as_is;
                my $pop = pop @TEXT;
                $TEXT[-1]->{_TEXT} .= $pop->{_TEXT} if @TEXT;
                $pop->{_TEXT} = _stripHTML( \$pop->{_TEXT} ) if $self->strip;
#		my $t = $pop->{_TEXT}; print " I endtag stripHTML: $t\n";
                $self->{_cb}->($self, $pop) if exists $self->{_cb};
            }
        }

        if(defined $NL) {
            $$NL{tag} = $Tag;

            my $base = $self->{_base};

            for my $at( @VALID_URL_ATTRIBUTES ) {
                if( exists $$NL{$at} ) {
                    $$NL{$at} = URI->new_abs( $$NL{$at}, $base) if $base;
                }
            }

            if(exists $self->{_cb}) {
                $self->{_cb}->($self, $NL ) if not $got_TAGS_IN_NEED or not @TEXT; #bug#5470
            } else {
                push @{$self->{_LINKS}}, $NL;
#		my $t=$$NL{_TEXT}.';'.$$NL{tag}; print " PushNL: $t\n";
#		foreach $t (keys(%{$NL})) { print " K=$t; V=$$NL{$t}\n";  }
            }
        }
    }## endof while (my $token = $p->get_token)

    undef $self->{_tp};
#    $headtext =~ s/; $//;
    my $NL = { tag=>'headings', _TEXT => $headtext };
    push @{$self->{_LINKS}}, $NL;
    $tottext=~ s/\s*\n\s*\n[\s\n]+/\n\n/g;
    $tottext=~ s/[\x20\t]+/ /g;
    $NL = { tag=>'text', _TEXT => $tottext };
    push @{$self->{_LINKS}}, $NL;
    return();
}

sub links {
    my $self = shift;
    ## just like HTML::LinkExtor's
    return $self->{_LINKS};
}


sub _stripHTML {
    my $HtmlRef = shift;
    my $tp = new HTML::TokeParser( $HtmlRef ); #    my $tp = new HTML::TokeParser::Simple( $HtmlRef );
    my $t = $tp->get_token(); # MUST BE A START TAG (@TAGS_IN_NEED)
                              # otherwise it ain't come from LinkExtractor
    if($t->[0] eq 'S') { #    if($t->is_start_tag) {
        return $tp->get_trimmed_text( '/'.$t->[1] ); #        return $tp->get_trimmed_text( '/'.$t->return_tag );
    } else {
        require Data::Dumper;
        local $Data::Dumper::Indent=1;
        die " IMPOSSIBLE!!!! ",
            Data::Dumper::Dumper(
                '$HtmlRef',$HtmlRef,
                '$t', $t,
            );
    }
}

sub Adump {
    my ($a) = @_;
    my @aref = @{$a};
    print 'Dump: ', $aref[0], ',', $aref[1];
    if ($aref[0] eq 'S') { print ',', $aref[4]; }
    elsif ($aref[0] eq 'E') { print ',', $aref[2]; }
#    elsif (($aref[0] eq 'T') && $aref[2]) { print ',TRUE'; }
#    elsif (($aref[0] eq 'T') && !$aref[2]) { print ',FALSE'; }
#    elsif ($aref[0] eq 'C') { }
#    elsif ($aref[0] eq 'D') { }
    elsif ($aref[0] eq 'PI') { print ',', $aref[2]; }
    print "\n";
    return;
}

1;

__END__


=head1 NAME

HTMLExtractor

=head1 DESCRIPTION

Adopted from HTML::LinkExtractor - Extract links from an HTML document
by D.H (PodMaster)

=head1 AUTHOR
Anders Ardo

D.H (PodMaster)

=head1 LICENSE

Copyright (c) 2003 by D.H. (PodMaster).
All rights reserved.

This module is free software;
you can redistribute it and/or modify it under
the same terms as Perl itself.
The LICENSE file contains the full text of the license.

=cut

