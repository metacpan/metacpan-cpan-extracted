#!/usr/bin/env perl

use strict;
use warnings;

package WWW::Pastebin::PhpfiCom::Retrieve;

use lib '../lib';
use base 'WWW::Pastebin::Base::Retrieve';
use HTML::TokeParser::Simple;
use HTML::Entities;

sub _make_uri_and_id {
    my ( $self, $id ) = @_;

    $id =~ s{ ^\s+ | (?:http://)? (?:www\.)? phpfi\.com/(?=\d+) | \s+$ }{}xi;

    return $self->_set_error(
        q|Doesn't look like a correct ID or URI to the paste|
    ) if $id =~ /\D/;

    return ( URI->new("http://www.phpfi.com/$id"), $id );
}

sub _get_was_successful {
    my ( $self, $content ) = @_;

    my $results_ref = $self->_parse( $content );
    return
        unless defined $results_ref;

    my $content_uri = $self->uri->clone;
    $content_uri->query_form( download => 1 );
    my $content_response = $self->ua->get( $content_uri );
    if ( $content_response->is_success ) {
        $results_ref->{content} = $self->content($content_response->content);
        return $self->results( $results_ref );
    }
    else {
        return $self->_set_error(
            'Network error: ' . $content_response->status_line
        );
    }
}

sub _parse {
    my ( $self, $content ) = @_;

    my $parser = HTML::TokeParser::Simple->new( \$content );

    my %data;
    my %nav = (
        content => '',
        map { $_ => 0 }
            qw(get_info  level  get_lang  is_success  get_content  check_404)
    );
    while ( my $t = $parser->get_token ) {
        if ( $t->is_start_tag('td') ) {
            $nav{get_info}++;
            $nav{check_404}++;
            $nav{level} = 1;
        }
        elsif ( $nav{check_404} == 1 and $t->is_end_tag('td') ) {
            $nav{check_404} = 2;
            $nav{level} = 10;
        }
        elsif ( $nav{check_404} and $t->is_start_tag('b') ) {
            return $self->_set_error('This paste does not seem to exist');
        }
        elsif ( $nav{get_info} == 1 and $t->is_text ) {
            my $text = $t->as_is;
            $text =~ s/&nbsp;/ /g;

            @data{ qw(age name hits) } = $text
            =~ /
                created \s+
                ( .+? (?:\s+ago)? ) # stupid timestaps
                (?: \s+ by \s+ (.+?) )? # name might be missing
                ,\s+ (\d+) \s+ hits?
            /xi;

            $data{name} = 'N/A'
                unless defined $data{name};

            @nav{ qw(get_info level) } = (2, 2);
        }
        elsif ( $t->is_start_tag('select')
            and defined $t->get_attr('name')
            and $t->get_attr('name') eq 'lang'
        ) {
            $nav{get_lang}++;
            $nav{level} = 3;
        }
        elsif ( $t->is_start_tag('div')
            and defined $t->get_attr('id')
            and $t->get_attr('id') eq 'content'
        ) {
            @nav{ qw(get_content level) } = (1, 4);
        }
        elsif ( $nav{get_content} and $t->is_end_tag('div') ) {
            @nav{ qw(get_content level) } = (0, 5);
        }
        elsif ( $nav{get_content} and $t->is_text ) {
            $nav{content} .= $t->as_is;
            $nav{level} = 6;
        }
        elsif ( $nav{get_lang} == 1
            and $t->is_start_tag('option')
            and defined $t->get_attr('selected')
            and defined $t->get_attr('value')
        ) {
            $data{lang} = $t->get_attr('value');
            $nav{is_success} = 1;
            last;
        }
    }

    return $self->_set_error('This paste does not seem to exist')
        if $nav{content} =~ /entry \d+ not found/i;

    return $self->_set_error("Parser error! Level == $nav{level}")
        unless $nav{is_success};

    $data{ $_ } = decode_entities( delete $data{ $_ } )
        for grep { $_ ne 'content' } keys %data;

    return \%data;
}

package main;

my $paster = WWW::Pastebin::PhpfiCom::Retrieve->new;

$paster->retrieve('http://phpfi.com/302683')
    or die $paster->error;

print "Paste content is:\n$paster\n";
