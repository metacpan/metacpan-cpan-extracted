package WWW::BookBot::Chinese::Periodical::WanFang;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw(WWW::BookBot::Chinese);
our $VERSION='1.02';
our $mag_name='';
our $has_catalog=0;
our $key_valid='';

use File::Spec::Functions;

sub default_settings {
	my $self = shift->SUPER::default_settings;
	$self->{text_paragraph_type}='br_or_p';
	$self->{book_has_chapters}=0;
	$self->{screen_limit_title}=35;
	$self->{screen_limit_trunk}=10;
	$self->{get_trunk_size}=2500;
	$self->{get_trunk_fresh_size}=250;
	$self->{get_lasturl}='http://periodicals.wanfangdata.com.cn/qikan/index.jsp';
	$self;
}
sub msg_init {
	my $self = shift;
	my $msg=$self->SUPER::msg_init;
	$msg->{CatalogURL}='http://periodicals.wanfangdata.com.cn/qikan/periodical/$pargs->{name}/$pargs->{name_4}$pargs->{year}/$pargs->{year_2}$pargs->{month_2}/$pargs->{year_2}$pargs->{month_2}ml.htm';
	$msg->{CatalogInfo}='==>万方资源-$pargs->{desc}-[$pargs->{year_2}$pargs->{month_2}]：';
}
sub go_login {
	my $self = shift;
	print "登录：";

	$self->{get_lasturl}='http://periodicals.wanfangdata.com.cn/qikan/index.jsp';
	my $res=$self->get_url_request('http://periodicals.wanfangdata.com.cn/qikan/servlet/Login_Check', {
		method=>'bookbot',
		form=>[user=>'bookbot', pass=>'book9bot', 'Submit.x'=>'56', 'Submit.y'=>'15'],
	});

	my $result=($res->is_success and ($res->request->uri->as_string eq 'http://periodicals.wanfangdata.com.cn/qikan/index.jsp'))
		? '成功' : '失败';
	print "$result\n";
}

sub get_alias {
	'wanfang';
}
sub argv_default {
	qw(desc=s name=s year=i month=i year_from=i year_to=i month_to=i key_valid=s);
}
sub argv_process {
	my ($self, $pargs)=@_;
	if(not(defined($pargs->{desc}))) {
		$pargs->{desc}='农业工程学报';
		$pargs->{name}='nygcxb';
		$pargs->{year}=2003;
		$pargs->{month}=1;
	}

	$pargs->{key_valid}='' if not(defined($pargs->{key_valid}));
	$pargs->{key_valid}=~s,/,\n,sg;
	$key_valid=$self->parse_patterns($pargs->{key_valid});

	if(not(defined($pargs->{month}))) {
		$self->argv_process_all($pargs);
	}else{
		$self->go_catalog($pargs);
	}
}
sub argv_process_all {
	my ($self, $pargs)=@_;

	$pargs->{year_from}=2001 if not(defined($pargs->{year_from}));
	$pargs->{year_to}=2100 if not(defined($pargs->{year_to}));
	$pargs->{month_to}=24 if not(defined($pargs->{month_to}));

	if(not(defined($pargs->{desc}))) {
		$pargs->{desc}='农业工程学报';
		$pargs->{name}='nygcxb';
	}

	$pargs->{key_valid}='' if not(defined($pargs->{key_valid}));
	$pargs->{key_valid}=~s,/,\n,sg;
	$key_valid=$self->parse_patterns($pargs->{key_valid});

	if(defined($pargs->{year}))	{
		for($pargs->{month}=1; $pargs->{month}<=$pargs->{month_to}; $pargs->{month}++) {
			$self->go_catalog($pargs);
			return unless $has_catalog;
		}
	}else{
		for($pargs->{year}=$pargs->{year_from}; $pargs->{year}<=$pargs->{year_to}; $pargs->{year}++) {
			for($pargs->{month}=1; $pargs->{month}<=$pargs->{month_to}; $pargs->{month}++) {
				$self->go_catalog($pargs);
				return if not($has_catalog) and $pargs->{month}==1;
				last unless $has_catalog;
			}
		}
	}
}
sub go_catalog {
	my ($self, $pargs)=@_;
	$pargs={} if not(ref($pargs));
	$mag_name=$pargs->{desc};
	$pargs->{name_4}=substr($pargs->{name}, 0, 4);
	$pargs->{year_2}=substr($pargs->{year}, 2, 2);
	$pargs->{month_2}=sprintf("%02d", $pargs->{month});
	$has_catalog=0;
	$self->SUPER::go_catalog($pargs);
}
sub getpattern_catalog_get_bookargs_data {
	<<'DATA';
\n    (?:<p>|)([^<>]*)<br>\n[^<>\n]*<a href="(/qikan/servlet/one_digest\?path=/periodical/[a-zA-Z]+/[a-zA-Z]+(\d+)/\d\d(\d\d)/\d\d\d\d(\d+)\.htm)">
DATA
}
sub catalog_get_bookargs {
	my $self = shift;
	my @a=@_;
	my $pargs=$a[0];
	$has_catalog=1;
	$pargs->{title}=$self->parse_titleen($a[1]);
	$pargs->{url}=$2;
	$pargs->{date}="$a[3]-$a[4]-01";
	$pargs->{seq}=$a[5];
	'Skip' if $key_valid ne '' and not($a[1]=~/$key_valid/os);
}
sub getpattern_chapter_head_data {
	<<'DATA';
<td colspan="3"><hr>
DATA
}
sub book_finish {
	my ($self, $pargs)=@_;
	my $url=$pargs->{url};
	$url=~s,/one_digest,/one_article,sg;
	$url=~s,(/\d\d\d\d)(/\d+\.)htm$,$1pdf$2pdf,sg;
	$self->result_add($pargs->{filename}, "\n\n　　PDF全文：$url");
}
sub result_filestem {
	my ($self, $pargs) = @_;
	my $date=substr($pargs->{date}, 0, 7);
	$date=~s/-//sg;
	$pargs->{ext_save}='txt';
	return $mag_name.
		$date.
		$pargs->{seq}.
		$pargs->{title};
}
sub result_time {
	my ($self, $pargs) = @_;
	return $self->string2time($pargs->{date});
}

1;
__END__

=head1 NAME

WWW::BookBot::Chinese::Periodical::WanFang - Bot to fetch from http://periodicals.wanfangdata.com.cn

=head1 SYNOPSIS

  use WWW::BookBot::Chinese::Periodical::WanFang;
  my $bot=WWW::BookBot::Chinese::Periodical::WanFang->new({work_dir=>'/output'});
  $bot->go_catalog({});

  bookbot --bot=wanfang --desc=农业工程学报 --name=nygcxb --year=2003 --month=1
  bookbot --bot=wanfang 农业工程学报 nygcxb
  bookbot --bot=wanfang --key_valid=温室/设施 农业工程学报 nygcxb

=head1 ABSTRACT

Bot to fetch from http://periodicals.wanfangdata.com.cn

=head1 DESCRIPTION

Bot to fetch from http://periodicals.wanfangdata.com.cn

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
