package WWW::BookBot::Chinese::Novel::DragonSky;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw(WWW::BookBot::Chinese);
our $VERSION='1.02';

sub default_settings {
	my $self = shift->SUPER::default_settings;
	$self->{text_paragraph_type}='br';
	$self->{book_has_chapters}=0;
	$self;
}
sub msg_init {
	my $self = shift;
	my $msg=$self->SUPER::msg_init;
	$msg->{CatalogURL}='http://www.dragonsky.net/readbook/booklist.asp?sort=$pargs->{cat}';
	$msg->{CatalogInfo}='==>$pargs->{cat}：';
}

sub get_alias {
	'dragonsky';
}
sub argv_default {
	qw(cat=s);
}
sub argv_process {
	my ($self, $pargs)=@_;
	$pargs->{cat}='军事' if $pargs->{cat} eq '';
	$self->go_catalog($pargs);
}
sub argv_process_all {
	my ($self, $pargs)=@_;
	foreach (qw(武侠 玄幻 科幻 文艺 历史 军事 侦探 评论)) {
		my %args=%$pargs;
		$args{cat}=$_;
		$self->go_catalog(\%args);
	}
}
sub getpattern_catalog_get_bookargs_data {
	<<'DATA';
<tr><td width=230 align=left><a href=/bookhtml/([^/]*)/default\.html target=\_blank>([^<]*)</a></td><td width=150 align=left>([^<]*)</td><td width=150 align=left>([^<]*)</td><td width=70 align=left>(.*?)</td></tr>
DATA
}
sub catalog_get_bookargs {
	my $self = shift;
	my @a=@_;
	my $pargs=$a[0];
	$pargs->{id}=$a[1];
	$pargs->{url}="http://www.dragonsky.net/zip/zip".$pargs->{id}.".html";
	$pargs->{title}=$self->parse_titleen($a[2]);
	$pargs->{author}=$self->parse_titleen($a[3]);
	$pargs->{date}=$self->parse_titleen($a[4]);
	$pargs->{status}=$self->parse_titleen($a[5]);
	'OK';
}
sub getpattern_chapter_head_data {
	<<'DATA';
<b>龙的天空</b></font></a></p></blockquote>
DATA
}
sub getpattern_chapter_end_data {
	<<'DATA';
<hr>Copyright
DATA
}
sub parse_paragraph_begin {
	$_[1]=~s/<\/font><\/a><\/td>/<br>/sg;							#paragraph after TOC
	$_[1]=~s/<a name=[^<>]*><\/a>/<br> \$BOOKBOTRETURN\$<br>/sg;	#reserved return
}
sub book_finish {
	my ($self, $pargs)=@_;
	$self->result_add($pargs->{filename}, "\n\n　　($pargs->{status} : 更新于$pargs->{date})");
}
sub result_filestem {
	my ($self, $pargs) = @_;
	my $year=3;
	my $month=1;
	if($pargs->{date}=~/^\d\d\d(\d)年(\d+)月/) {
		$year=$1;
		$month=$2;
	}
	my $status='u';
	$status='t' if $pargs->{status} eq '暂停';
	$status='l' if $pargs->{status} eq '连载中';
	$status='w' if $pargs->{status} eq '已完成';
	return $self->string_limit($pargs->{author},4).
		$year.
		sprintf("%x",$month).
		$status.
		$pargs->{title};
}

1;
__END__

=head1 NAME

WWW::BookBot::Chinese::Novel::DragonSky - Bot to fetch from http://www.dragonsky.net

=head1 SYNOPSIS

  use WWW::BookBot::Chinese::Novel::DragonSky;
  my $bot=WWW::BookBot::Chinese::Novel::DragonSky->new({work_dir=>'/output'});
  $bot->go_catalog({cat=>'军事'});

  bookbot --bot=dragonsky 军事
  bookbot --bot=dragonsky all

=head1 ABSTRACT

Bot to fetch from http://www.dragonsky.net

=head1 DESCRIPTION

Bot to fetch from http://www.dragonsky.net

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
