package WML::Card::Palm;

use strict;
use vars qw($VERSION @ISA);

@ISA = qw(WML::Card);

$VERSION = '0.01';

sub link_list{
	my $self = shift;
	my ($name, $listtitle, $offset,$pager, $data, $align)  = @_;
	$align = defined $align ? $align : 'left';
	$self->{'_body'}.= "<p align=\"$align\">";
	$self->{'_body'}.=  sprintf "%s:<br/>", $listtitle  if defined $listtitle;
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
		$ENV{'QUERY_STRING'} =~ s/^(o=\d[&]?)//;
		$0 =~ s/\/usr\/www\/wap//;
                my $href = length $ENV{'QUERY_STRING'}> 0 ? "$0?o=$offset&$ENV{'QUERY_STRING'}" : "$0?o=$offset";
		$href =~ s/\&/\&amp;/gs;
 		my $next =$self->_format_text($self->{'_next'});
		$self->{'_body'}.= << "EOF" ;
<a href=\"$href\">$next</a>
EOF
	}

	$self->{'_body'}.= << 'EOF';
</p>
EOF
};

sub input{
        my  $self = shift;
        my ($label, $text, $name, $format, $type, $size, $target, $arg) = @_;
        $target = defined $arg ? "$target?$arg&amp;$name=\$$name" : "$target?$name=\$$name";
        $format = " format = $format" if defined $format;
        $size = " size=$size" if defined $size ;
        $self->{'_body'} .= << "EOF";
<p align="center" mode="wrap">
$text<br/>
<input type="$type" name="$name" title="$name" $format $size/><br/>
<br/>
<anchor title="$label">$label<go href="$target"/>
</anchor>
</p>
EOF
}

1;
