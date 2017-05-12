package WWW::BookBot::Chinese::Agriculture::Cast;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw(WWW::BookBot::Chinese);
our $VERSION='1.02';

sub default_settings {
	my $self = shift->SUPER::default_settings;
	$self->{text_paragraph_type}='brbr_or_brandspace';
	$self->{book_has_chapters}=0;
	$self->{get_trunk_size}=2500;
	$self->{get_trunk_fresh_size}=250;
	$self;
}
sub msg_init {
	my $self = shift;
	my $msg=$self->SUPER::msg_init;
	$msg->{CatalogURL}='http://www.cast.net.cn/yaowen/yaowen.asp?page=$pargs->{pageno}';
	$msg->{CatalogInfo}='==>科技要闻第$pargs->{pageno}页：';
}

sub get_alias {
	'agr_cast';
}
sub argv_default {
	qw(pageno=i);
}
sub argv_process {
	my ($self, $pargs)=@_;
	if( defined($pargs->{pageno}) ){
		$self->go_catalog($pargs);
	}else{
		$self->argv_process_all($pargs);
	}
}
sub argv_process_all {
	my ($self, $pargs)=@_;
	for($pargs->{pageno}=1; $pargs->{pageno}<=$self->{catalog_max_pages}; $pargs->{pageno}++) {
		last if $self->go_catalog($pargs)==0;
	}
}
sub getpattern_catalog_get_bookargs_data {
	<<'DATA';
＋</span><a href="#" onClick="MM_openBrWindow\('yao-text.asp\?id=(\d+)[^\)]+\)">([^<>]*)</a>[^<>\(]*\([^\)]+\)</TD>[^<>]*<TD>[^<>]*<font color=gray>([^<>]*)</font></TD>
DATA
}
sub catalog_get_bookargs {
	my $self = shift;
	my @a=@_;
	my $pargs=$a[0];
	$pargs->{id}=$a[1];
	$pargs->{url}='http://www.cast.net.cn/yaowen/yao-text.asp?id='.$pargs->{id};
	$pargs->{title}=$self->parse_titleen($a[2]);
	$pargs->{date}=$self->parse_titleen($a[3]);
	'OK';
}
sub getpattern_catalog_get_next_data {
	<<'DATA';
>下一页<
DATA
}
sub getpattern_chapter_head_data {
	<<'DATA';
align="left"></div>
DATA
}
sub getpattern_chapter_end_data {
	<<'DATA';
<br></TD>
DATA
}
sub result_time {
	my ($self, $pargs) = @_;
	if($pargs->{date}=~/^(\d+)年(\d+)月(\d+)日$/) {
		return $self->string2time("$1-$2-$3");
	}else{
		return $pargs->{last_modified};
	}
}

1;
__END__

=head1 NAME

WWW::BookBot::Chinese::Agriculture::Cast - Bot to fetch from http://www.cast.net.cn

=head1 SYNOPSIS

  use WWW::BookBot::Chinese::Agriculture::Cast;
  my $bot=WWW::BookBot::Chinese::Agriculture::Cast->new({work_dir=>'/output'});
  $bot->go_catalog({pageno=>0});

  bookbot --bot=agr_cast
  bookbot --bot=agr_cast --pageno=1

=head1 ABSTRACT

Bot to fetch from http://www.cast.net.cn

=head1 DESCRIPTION

Bot to fetch from http://www.cast.net.cn

=head2 pageno

  pageno=1	first page
  pageno=2	second page
  ...
  if no pageno is set in bookbot command line, all pages will be fetched.

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
