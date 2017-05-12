package WWW::BookBot::Chinese::Novel::ShuKu;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw(WWW::BookBot::Chinese);
our $VERSION='1.02';

sub default_settings {
	my $self = shift->SUPER::default_settings;
	$self->{text_paragraph_type}='crandspace';
	$self->{get_delay_second}=2;
	$self->{get_delay_second_rand}=2;
	$self;
}
sub msg_init {
	my $self = shift;
	my $msg=$self->SUPER::msg_init;
	$msg->{CatalogURL}='http://www.shuku.net:8082/dblx/html/$pargs->{cat1}/$pargs->{cat2}-2-$pargs->{pageno}.html';
	$msg->{CatalogInfo}='==>$pargs->{desc}第$pargs->{pageno}页：';
}

sub get_alias {
	'shuku';
}
sub argv_default {
	qw(desc=s cat1=i cat2=i pageno=i);
}
sub argv_process {
	my ($self, $pargs)=@_;
	$pargs->{cat1}=0 if not(defined($pargs->{cat1}));
	$pargs->{cat2}=1 if not(defined($pargs->{cat2}));
	$pargs->{desc}='畅销' if not(defined($pargs->{desc}));
	if( defined($pargs->{pageno}) ){
		$self->go_catalog($pargs);
	}else{
		for($pargs->{pageno}=0; $pargs->{pageno}<$self->{catalog_max_pages}; $pargs->{pageno}++) {
			last if $self->go_catalog($pargs)==0;
		}
	}
}
sub get_url_verify {
	$_[1]=~s/net:8080/net:8082/g;
}
sub getpattern_catalog_get_bookargs_data {
	<<'DATA';
<a href="http://www\.shuku\.net/cgi-bin/dblx/\.libs/lt-displaybook\?ID=([^<>]*?)&URL=([^<>]*?)">([^<>]*?)</a>
DATA
}
sub catalog_get_bookargs {
	my $self = shift;
	my @a=@_;
	my $pargs=$a[0];
	$pargs->{id}=$a[1];
	$pargs->{url}=$a[2];
	$pargs->{title}=$self->parse_titleen($a[3]);
	return 'Skip' if $pargs->{title}=~/作品集$/;
	'OK';
}
sub getpattern_TOC_exists_data {
	<<'DATA';
<h(?:\d|r width="\d+%")
DATA
}
sub getpattern_TOC_head_data {
	<<'DATA';
(?=<h\d)
DATA
}
sub getpattern_TOC_end_data {
	<<'DATA';
(?:>发表评论</a>|</table>|亦凡公益图书馆)
DATA
}
sub getpattern_chapter_head_data {
	<<'DATA';
(?=<pre)
DATA
}
sub getpattern_chapter_end_data {
	<<'DATA';
(?:</pre>|亦凡公益图书馆)
DATA
}
sub parse_paragraph_begin {
	$_[1]=~s/<td height=\"20\" colspan=\"2\">(.*?)<\/td>/\$BOOKBOTRETURN\$$1/sg;	#reserved paragraph
}
sub parse_paragraph_end {
	$_[1]=~s/\n?\$BOOKBOTRETURN\$//sg;			#reserved paragraph
}

1;
__END__

=head1 NAME

WWW::BookBot::Chinese::Novel::ShuKu - Bot to fetch from http://www.shuku.net

=head1 SYNOPSIS

  use WWW::BookBot::Chinese::Novel::ShuKu;
  my $bot=WWW::BookBot::Chinese::Novel::ShuKu->new({work_dir=>'/output'});
  $bot->go_catalog({desc=>'畅销', cat1=>0, cat2=>1, pageno=>0});

  bookbot --bot=shuku 畅销 0 1 0
  bookbot --bot=shuku --desc=畅销 --cat1=0 --cat2=1 --pageno=0

  bookbot --bot=shuku 畅销 0 1
  bookbot --bot=shuku --desc=畅销 --cat1=0 --cat2=1

=head1 ABSTRACT

Bot to fetch from http://www.shuku.net

=head1 DESCRIPTION

Bot to fetch from http://www.shuku.net

=head2 desc

  Description infomation for what to fetch.

=head2 cat1

  畅销书籍 http://www.shuku.net/dblx/html/0/1-2-0.html
  cat1 -> http://www.shuku.net/dblx/html/[0]/1-2-0.html

=head2 cat2

  畅销书籍 http://www.shuku.net/dblx/html/0/1-2-0.html
  cat2 -> http://www.shuku.net/dblx/html/0/[1]-2-0.html

=head2 pageno

  pageno=0	first page
  pageno=1	second page
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
