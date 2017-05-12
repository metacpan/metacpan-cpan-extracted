package WML::Card::7110;

use strict;
use vars qw($VERSION @ISA);

@ISA = qw(WML::Card);

$VERSION = '0.01';


sub link_list{
	my $self = shift;
	my ($name, $listtitle, $offset,$pager,$data, $align)  = @_;
	$align = defined $align ? $align : 'center';
	$self->{'_body'}.= "<p align=\"$align\">";
	#$self->{'_body'}.=  sprintf "%s:<br/>", $self->_format_text($listtitle)  if defined $listtitle;
	my $total = scalar @{$data};
	my $i;
	for ($i= ($offset * $pager); 
				($i < ($offset * $pager + $pager) && ($i < scalar @{$data}));
				$i++) {
			my $opt = $self->_format_text($data->[$i][$0]);
			$self->{'_body'}.= "<a href=\"$data->[$i][1]\">$opt</a><br/>\n";
	}
	$offset++;
	if ($i < $total){
		$ENV{'QUERY_STRING'} =~ s/([&]o=\d[&]?)//;
		$ENV{'QUERY_STRING'} =~ s/\///;
		my $href = $ENV{'SCRIPT_NAME'};
                $href .= length $ENV{'QUERY_STRING'}> 0 ? "?$ENV{'QUERY_STRING'}&amp;o=$offset" :"?o=$offset";
		 my $next =$self->_format_text($self->{'_next'});
		$self->{'_body'}.= << "EOF" ;
<a href=\"$href\">$next</a>
EOF
	}

	$self->{'_body'}.= << 'EOF';
</p>
EOF
};


sub table{
	my $self = shift;
	my ($data,  $title, $offset, $pager, @headers) = @_;
	my $texto;
	my $i;
	my $total = scalar @{$data};
	
	$self->{'_body'}.= "<p align='center'>$title</p>";
	$self->{'_body'}.= "<p align='center'>";

	#Header
	if (scalar @headers) {
			my $texto = sprintf ("%s    %s<br/>",
								$self->_format_text($headers[0]), 
								$self->_format_text($headers[1]) ); 
			$self->{'_body'}.= $texto;
	}
#Datos
	for ($i=($offset * $pager); (($i < ($offset * $pager + $pager)) && ($i < $total));$i++) {
			my $texto = sprintf  ("%s  ->  %s <br/>",
							$self->_format_text($data->[$i][0]), 
							$self->_format_text($data->[$i][1]) ); 
			$self->{'_body'}.= $texto;
	}
	$self->{'_body'}.= '</p>';
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
1;
