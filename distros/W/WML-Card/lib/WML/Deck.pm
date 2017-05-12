package WML::Deck;

use strict;
use vars qw($VERSION);
use WML::Card;

$VERSION = '0.01';


sub new{
	my $pkg = shift;
	my @card = @_;
	my $self = bless { 
					'_template' => undef,
					'_card' => undef,
					}, $pkg;
	push @{$self->{'_card'}}, @card;
	return $self;
};


sub _contenttype{
	my $self = shift;
	return "Content-type: text/vnd.wap.wml \n\n";
}

sub cache{
	my $self = shift;
	$self->{'cache'} = shift;
}

sub _cache{
	my $self= shift;
	return if !defined $self->{'cache'};
	return  << "EOF";
<head>
<meta http-equiv="Cache-Control" content="max-age=0"/>
</head>
EOF
 }


sub _header{
	my $self = shift;
	return  << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN" "http://www.wapforum.org/DTD/wml_1.1.xml">

<wml>
EOF
}

sub template{
	my $self = shift;
	my ($type, $label , $href, $target) = @_;
	$self->{'_wml'} .= << "EOF";
<template>
<do type="$type" label="$label">
		<go href="$target"/>
</do>
<do type="prev">
		<prev/>
</do>
</template>
EOF
 }

sub _footer{
	my $self = shift;
	return << 'EOF';
</wml>
EOF
 }



sub return_cgi{
	my $self =shift;
	print $self->_contenttype;
	print $self->_header;
	print $self->_cache;
	print $self->{'_template'};
	for (@{$self->{'_card'}}) {
		$_->print;
	}
	print $self->_footer;
}

=head1 NAME

WML::Deck - Perl extension for builiding WML Decks.

=head1 SYNOPSIS

use WML::Card;

use WML::Deck;

my @cards;

my $options= [
        ['Option 1', 'http://...'],
        ['Option 2', 'http://...'],

];

my $c = WML::Card->guess('index','Wap Site');
$c->link_list('indice', undef,  0, $options,  $options);
push @cards, $c;

# Build the deck
my $wml = WML::Deck->new(@cards);
$wml->return_cgi;

=head1 DESCRIPTION

This perl library simplifies the creation of  WML decks on the fly. In combination with 
WML::Card it provides functionality to build WML code for cards and decks.

=head2 Methods

=over 4

=item $wml = WML::Deck->new(@cards);

This class method constructs a new WML::Deck object.  The first argument is an array 
of WML::Card objects.

=item $wml->cache($n);

This class methos specifies the max-age argument for Cache-Control

=item $wml->return_cgi;

This method prints wml code and HTTP headers for the deck.

=head1 AUTHOR

Mariana Alvaro			mariana@alvaro.com.ar

Copyright 2000 Mariana Alvaro. All rights reserved.
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

WML::Card

=cut



1;
