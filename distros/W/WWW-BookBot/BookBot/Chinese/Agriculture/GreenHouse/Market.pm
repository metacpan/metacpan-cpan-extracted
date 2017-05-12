package WWW::BookBot::Chinese::Agriculture::GreenHouse::Market;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw(WWW::BookBot::Chinese);
our $VERSION='1.02';

sub default_settings {
	my $self = shift->SUPER::default_settings;
	$self->{text_paragraph_type}='cr';
	$self->{book_has_chapters}=0;
	$self->{get_trunk_size}=2500;
	$self->{get_trunk_fresh_size}=250;
	$self;
}
sub msg_init {
	my $self = shift;
	my $msg=$self->SUPER::msg_init;
	$msg->{CatalogURL}='http://www.chinagreenhouse.com/chinagreenhouse/maindoc/sdinfo/subject_sdinfo_main.asp?direction=next';
	$msg->{CatalogInfo}='==>中国温室网市场需求：';
}

sub alias {
	'agr_cngreen_market';
}
sub argv_default {
	qw();
}
sub argv_process {
	my ($self, $pargs)=@_;
	$self->go_catalog($pargs);
}
sub argv_process_all {
	my ($self, $pargs)=@_;
	for($pargs->{pageno}=1; $pargs->{pageno}<=$self->{catalog_max_pages}; $pargs->{pageno}++) {
		last if $self->go_catalog({})==0;
	}
}
sub getpattern_catalog_head_data {
	<<'DATA';
<p align="center"><b><font size="4">供求信息</font></b></p>
DATA
}
sub getpattern_catalog_end_data {
	<<'DATA';
<p><a href="subject_sdinfo_main.asp
DATA
}
sub getpattern_catalog_get_next_data {
	<<'DATA';
>下一页<
DATA
}
sub getpattern_catalog_get_bookargs_data {
	<<'DATA';
<div align="center"><font size="2">(\d+)-(\d+)-(\d+)</font></div>[^<>]*</td>[^<>]*<td><font size="2">[^<>]*<a href="subject_sdinfo_detail.asp\?DemandID=(\d+)"[^<>]*>([^<>]*?)</a></font></td>
DATA
}
sub catalog_get_bookargs {
	my $self = shift;
	my @a=@_;
	my $pargs=$a[0];
	$pargs->{date}="$a[1]-$a[2]-$a[3]";
	$pargs->{id}=$a[4];
	$pargs->{url}='http://www.chinagreenhouse.com/chinagreenhouse/maindoc/sdinfo/subject_sdinfo_detail.asp?DemandID='.$pargs->{id};
	$pargs->{title}=$self->parse_titleen($a[5]);
	'OK';
}
sub getpattern_chapter_head_data {
	<<'DATA';
>具体内容</font></td>[^<>]*<td colspan="3"><font size="2">
DATA
}
sub getpattern_chapter_end_data {
	<<'DATA';
</font></td>
DATA
}
sub result_time {
	my ($self, $pargs) = @_;
	return $self->string2time($pargs->{date});
}

1;
__END__

=head1 NAME

WWW::BookBot::Chinese::Agriculture::GreenHouse::Market - Bot to fetch from http://www.chinagreenhouse.com/

=head1 SYNOPSIS

  use WWW::BookBot::Chinese::Agriculture::GreenHouse::Market;
  my $bot=WWW::BookBot::Chinese::Agriculture::GreenHouse::Market->new({work_dir=>'/output'});
  $bot->go_catalog({});

  bookbot --bot=agr_cngreen_market
  bookbot --bot=agr_cngreen_market all

=head1 ABSTRACT

Bot to fetch from http://www.chinagreenhouse.com/chinagreenhouse/maindoc/sdinfo/subject_sdinfo_main.asp

=head1 DESCRIPTION

Bot to fetch from http://www.chinagreenhouse.com/chinagreenhouse/maindoc/sdinfo/subject_sdinfo_main.asp

=head2 EXPORT

None by default.

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-BookBot

=head1 AUTHOR

Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

=head1 SEE ALSO

L<WWW::BookBot>, L<bookbot>

=cut
