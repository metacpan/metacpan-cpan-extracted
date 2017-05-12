package WML::Card;

use strict;
use Data::Dumper;
use vars qw($VERSION);

$VERSION = '0.02';

my $pt = [
	{ 'ua' => '7110', 'ot' => 'WML::Card::7110' },
	{ 'ua' => '7160', 'ot' => 'WML::Card::7110' },
	{ 'ua' => 'wapsilon', 'ot' => 'WML::Card::7110' },
	{ 'ua' => 'motorola', 'ot' => 'WML::Card::UP' },
	{ 'ua' => 'up', 'ot' => 'WML::Card::UP' },
	{ 'ua' => 'wapman', 'ot' => 'WML::Card::Palm' },
	{ 'ua' => 'ezwapbrowser', 'ot' => 'WML::Card::Palm' },
	{ 'ua' => 'nokia-wap-toolkit', 'ot' => 'WML::Card' },
];


sub guess {
	shift;
	my $id = shift;
	my $title =shift;
	my $ua = shift || $ENV{'HTTP_USER_AGENT'};
	my $ot = 'WML::Card';
	for my $p (@$pt) {
		if ($ua =~ /$p->{'ua'}/i) {
			$ot = $p->{'ot'};
			last;
		}
	}
	eval "require $ot";
	
	# if ($@) { ...
	# } else { ...
	# }

	my $ob = new $ot($id, $title);
	return $ob;
}

sub new {
	my $cl = shift;
	my ($_id, $_title) = @_;
	my $hr = {
		'_id' => $_id,
		'_title' => $_title,
		'_do'=> undef,
		'_body'=> undef,
		'_next'=> 'Ver más',
	 };
	return bless $hr, $cl;
}


sub buttons{
	my $self =shift;
	my ($label, $type, $task, $href) = @_;
	$self->{'_do'} .= << "EOF";
<do type="$type" label="$label">
EOF

	$self->{'_do'} .= $task eq 'prev' ?  '<prev/>' : "<go href=\"$href\"/>";
	$self->{'_do'} .= '</do>';
}

sub table{
	my $self = shift;
	my ($data,  $title, $offset, $pager, @headers) = @_;
	my $texto;
	my $i;
	my $total = scalar @{$data};
	
	$self->{'_body'}.= "<p align='center'>$title";
	$self->{'_body'}.= "<table  columns='3'>";
	
	#Header
	if (scalar @headers) {
			$self->{'_body'}.= '<tr><td>&nbsp;</td>';
			for ($i=0; $i < 2; $i++) {
				$self->{'_body'}.= '<td>';
				$texto = $self->_format_text($headers[$i]);
				$self->{'_body'}.= "$texto</td>";
			}
			$self->{'_body'}.= '</tr>';
	}

	#Datos
	for ($i=($offset * $pager); (($i < ($offset * $pager + $pager)) && ($i < $total));$i++) {
			$self->{'_body'}.= "<tr><td>&nbsp;</td>";
			for (my $j; $j < 2 ; $j++) {
				$self->{'_body'}.= "<td>";
				$texto = $self->_format_text($data->[$i][$j]);
				$self->{'_body'}.= "$texto</td>";
			}
			$self->{'_body'}.= '</tr>';
	}
	$self->{'_body'}.= "</table></p>";
	$offset++;
	
	if ($i < $total){
			my $next =$self->_format_text($self->{'_next'});
			$ENV{'QUERY_STRING'} =~ s/^(o=\d[&]?)//;
		 	my $href = length $ENV{'QUERY_STRING'}> 0 ? "?o=$offset&$ENV{'QUERY_STRING'}" : "?o=$offset";	
			$href =~ s/\&/\&amp;/gs;
			$self->{'_body'}.= << "EOF";
			<p><a href=\"$href\">$next</a></p>
EOF
	}
}

sub link_list{
	my $self = shift;
	my ($name, $listtitle, $offset, $pager, $data, $align)  = @_;
	$align = defined $align ? $align : 'left';
	$self->{'_body'}.= "<p align=\"$align\">";
	$self->{'_body'}.=  sprintf ("%s", $self->_format_text($listtitle))  if defined $listtitle;
	$name = $self->_format_text($name);
	$self->{'_body'}.=  "<select ivalue=\"0\" name=\"$name\">\n";

	my $total = scalar @{$data};
	my $i;
	for ($i= ($offset * $pager); 
				($i < ($offset * $pager + $pager) && ($i < scalar @{$data}));
				$i++) {
			my $opt = $self->_format_text($data->[$i][$0]);
			$self->{'_body'}.= "<option onpick=\"$data->[$i][1]\">$opt</option>\n";
	}
	$offset++;
	if ($i < $total){
		my $next =$self->_format_text($self->{'_next'});
		$ENV{'QUERY_STRING'} =~ s/^(o=\d[&]?)//;
	 	my $href = length $ENV{'QUERY_STRING'}> 0 ? "?o=$offset&$ENV{'QUERY_STRING'}" : "?o=$offset";	
		$href =~ s/\&/\&amp;/gs;
		$self->{'_body'}.= << "EOF";
<option onpick=\"$href\">$next</option>
EOF
	}

	$self->{'_body'}.= << 'EOF';
</select>
</p>
EOF
};


sub value_list{
	my $self = shift;
	my ($name, $listtitle, $offset,$pager,$data)  = @_;
	$self->{'_body'}.=  '<p mode="nowrap">';
	$self->{'_body'}.=  sprintf ("%s", $self->_format_text($listtitle))  if defined $listtitle;
	$name = $self->_format_text($name);
	$self->{'_body'}.=  "<select ivalue=\"0\" name=\"$name\">\n";

	my $total = scalar @{$data};
	for (my $i= ($offset * $pager); 
				($i < ($offset * $pager + $pager) && ($i < $total));
				$i++) {
			my $opt = $self->_format_text($data->[$i][$0]);
			$self->{'_body'}.= "<option value=\"$data->[$i][1]\">$opt</option>\n";
	}
	$self->{'_body'}.= << "EOF";
</select>
</p>
EOF
};

sub print{
	my  $self = shift;
	$self->{'_title'} = $self->_format_text($self->{'_title'});
	print << "EOF";
<card id="$self->{'_id'}" title="$self->{'_title'}">
$self->{'_do'}
$self->{'_body'}
</card>
EOF
};

sub info{	
	my  $self = shift;
	my $content = shift;
	$content = $self->_format_text($content);
	$content =~ s/\n/<br\/>\n/gs;
	$content = "<p>$content</p>";
	$content =~ s/<br\/>\n<\/p>/<\/p>/;
	$self->{'_body'} .= $content;
};

sub img{
	my  $self = shift;
	my ($file, $alt) = @_;
	$self->{'_body'} .= << "EOF";
<p align="left">
<img src="$file" alt = "$alt"/>
</p>
EOF
}

sub input{
	my  $self = shift;
	my ($label, $text, $name, $format, $type, $size, $target, $arg) = @_;
	$target = defined $arg ? "$target?$arg&amp;$name=\$($name)" : "$target?$name=\$($name)";
	$format = " format=\"$size$format\"" if defined $format;
	$size = " size=\"$size\"" if defined $size ;
	$self->{'_body'} .= << "EOF";
<do type="accept" label="$label">
	<go href="$target"/>
</do>
<p align="center" mode="wrap">
$text
<input type="$type" name="$name" title="$name" $format $size/>
<a href="$target">$label</a>
</p>
EOF
}

sub link{
	my  $self = shift;
	my ($target, $text) = @_;
	$self->{'_body'} .= << "EOF";
<p><a href="$target">$text</a></p>
EOF
}


sub br{
	my  $self = shift;
	$self->{'_body'} .= '<br/>';
}

sub _format_text {
	my $self = shift;
    	my $txt = shift;
		$txt =~ s/([^\w\s])/sprintf '&#%03d;', ord($1)/eg;
    	$txt =~ s/\r//g;
    	$txt;
}


1;

=head1 NAME

WML::Card - Perl extension for builiding WML Cards according to the browser being used.

=head1 SYNOPSIS

use WML::Card;

my $options= [
        ['Option 1', 'http://...'],
        ['Option 2', 'http://...'],
];

my $c = WML::Card->guess('index','Wap Site');
$c->link_list('indice', undef,  0, $options,  $options);
$c->print;

=head1 DESCRIPTION

This perl library simplifies the creation of  WML cards on the fly. It produces 
the most suitable wml code for the browser requesting the card. In this way the  
one building the cards does not have to worry about the differences in how  each
wap browser displays the wml code. In combination wht WML::Deck it provides
functionality to build WAP applications.

=head2 Methods

=over 4

=item $card = WML::Card->guess( $id, $title, [$user_agent] );

This class method constructs a new WML::Card object.  The first argument defines 
the WML card's id and the second argument its title. The if the third argument is 
not defined, the value is obtained from $ENV{'HTTP_USER_AGENT'}.


=item $c->buttons($label, $type, $task, $href)


=item $c->table ($data,  $title, $offset, $pager, @headers)

=item $c->link_list($name, $listtitle, $offset, $pager, $data, $align)

=item $c->value_list($name, $listtitle, $offset,$pager,$data)

The variable $data is an array reference like:
my $menu_items= [
        ['Option 1', 'http://...'],
        ['Option 2', 'http://...'],
];

The variable $pager is the number of items wanted to be displayed in each card.

=item $c->print

=item $c->info($content)

=item $c->img($file, $alt)

=item $c->input($label, $text, $name, $format, $type, $size, $target, $arg);

=item $c->link($target, $text); 

=item $c->br

=head1 AUTHOR

Mariana Alvaro			mariana@alvaro.com.ar

Copyright 2000 Mariana Alvaro. All rights reserved.
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

WML::Deck

=cut
