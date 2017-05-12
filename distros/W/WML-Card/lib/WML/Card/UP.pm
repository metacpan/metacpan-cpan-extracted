package WML::Card::UP;

use strict;
use HTML::Entities;
use vars qw($VERSION @ISA);

@ISA = qw(WML::Card);

$VERSION = '0.01';

sub _format_text {
	my $self = shift;
	my $str = shift;
	$str =~ tr|ÁÂÀÅÃÄÇÉÊÈËÍÎÌÏÑÓÔÒØÕÖÚÛÙÜÝáâàåãäçéêèëíîìïñóôòøõöúûùüýÿ|AAAAAACEEEEIIIINOOOOOOUUUUYaaaaaaceeeeiiiinoooooouuuuyy|;
	$str=$self->SUPER::_format_text($str);
	$str;
}

sub print{
	my  $self = shift;
	$self->{'_id'} =~s/\s/_/gs;
        $self->{'_title'} = $self->_format_text($self->{'_title'});
        print << "EOF";
<card id="$self->{'_id'}">
$self->{'_do'}
<p>$self->{'_title'}</p>
$self->{'_body'}
</card>
EOF
}

sub img{
        my  $self = shift;
	return;
}


1;
