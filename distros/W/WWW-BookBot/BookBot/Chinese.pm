package WWW::BookBot::Chinese;

use 5.008;
use strict;
use warnings;
no warnings qw(uninitialized);
use base qw(WWW::BookBot);
use vars qw($VERSION);
$VERSION = '0.12';

#-------------------------------------------------------------
# Default settings
#	$class->default_settings						=> \%settings
#-------------------------------------------------------------
sub default_settings {
	my $self = shift->SUPER::default_settings;
	$self->{get_language}='zh-cn';
	$self->{language_decode}='gbk';
	$self->{language_encode}='gbk';
	$self;
}

#-------------------------------------------------------------
# Redefined functions
#	$bot->decode_entity($content_dein_deout)			=> N/A
#	$bot->trandict_init								=> $bot->{translate_dict}
#	$bot->msg_init									=> $bot->{messages}
#-------------------------------------------------------------
sub decode_entity {
	#chinese novels sometimes add \x{FF1B} after unkown unicode string
	$_[1]=~s/(?:&\#(\d{1,5});?\x{FF1B}?)/chr($1)/esg;
	$_[1]=~s/(?:&\#[xX]([0-9a-fA-F]{1,5});?\x{FF1B}?)/chr(hex($1))/esg;
	$_[1]=~s/(&([0-9a-zA-Z]{1,9});?)/$WWW::BookBot::entity2char{$2} or $1/esg;
	#normalize middle dot
	$_[1]=~s/\x{2022}/\x{00B7}/sg;
}
sub trandict_init {
	shift->{translate_dict} = {
		'log'		=> "日志",
		'result'	=> "结果",
		'DB'		=> "数据",
		'debug'		=> "调试",
	}
}
sub msg_init {
	my $skip_info="\n".'$pargs->{levelspace}  url=$pargs->{url}'."\n";
	shift->{messages} = {
		TestMsg			=> '测试: $pargs->{TestInfo} $pargs->{TestNum}',
		BookStart		=> '$pargs->{levelspace} [$pargs->{bpos_limit}/$pargs->{book_num}] $pargs->{title_limit} ',
		BookBinaryOK	=> '$pargs->{data_len_KB} $pargs->{write_file}'."\n",
		BookChapterErr	=> ' - 无法分析'.$skip_info,
		BookChapterMany	=> '[$pargs->{chapter_num_limit}章]',
		BookChapterOne	=> '[单章节]',
		BookChapterOK	=> '$pargs->{data_len_KB}'."\n",
		BookTOCFinish	=> '$pargs->{TOC_len_KB}'."\n",
		CatalogInfo		=> '取书目: ',
		CatalogResultErr=> ' 0套书'."\n",
		CatalogResultOK	=> ' $pargs->{book_num}套书'."\n",
		CatalogURL		=> '$pargs->{url}',
		CatalogURLEmpty	=> '[失败] 索引的URL为空'."\n",
		DBBookErr		=> "\t".' \$bot->go_book({$pargs->{allargs}});'."\t#错误\n",
		DBBookOK		=> "\t".'#\$bot->go_book({$pargs->{allargs}});'."\n",
		DBCatalogErr	=> ' \$bot->go_catalog({$pargs->{allargs}});'."\t#错误\n",
		DBCatalogOK		=> '#\$bot->go_catalog({$pargs->{allargs}});'."\n",
		DBHead			=> <<'DATA',
#!$pargs->{perlcmd}
##======================================
## 自动生成的数据文件，用于$pargs->{classname}
##    生成时间: $pargs->{createtime}
##======================================

use $pargs->{classname};
my \$bot = new $pargs->{classname};

DATA
		FailClearDB		=> '无法清除数据文件$pargs->{filename}: $pargs->{errmsg}',
		FailClose	 	=> '无法关闭$self->{translate_dict}->{$pargs->{filetype}}文件$pargs->{filename}: $pargs->{errmsg}',
		FailMkDir		=> '建目录$pargs->{dir}失败: $pargs->{errmsg}',
		FailOpen	 	=> '无法打开$self->{translate_dict}->{$pargs->{filetype}}文件$pargs->{filename}: $pargs->{errmsg}',
		FailWrite	 	=> '无法写入$self->{translate_dict}->{$pargs->{filetype}}文件$pargs->{filename}: $pargs->{errmsg}',
		GetFail404		=> <<'DATA',
[$pargs->{code},失败] 找不到文件
        $pargs->{url_real}
DATA
		GetFail404Detail=> <<'DATA',
[$pargs->{code},失败] 找不到文件
>>>>请求
$pargs->{req_content}<<<<响应
$pargs->{status_line}

DATA
		GetFailRetries	=> <<'DATA',
[$pargs->{code},失败] 重试太多，放弃
        $pargs->{url_real}
DATA
		GetFailRetriesDetail	=> <<'DATA',
[$pargs->{code},失败] 重试太多，放弃
>>>>请求
$pargs->{req_content}<<<<响应
$pargs->{status_line}
$pargs->{res_content}

DATA
		GetURLSuccess	=> '$pargs->{len_KB} ',
		GetURLRetry		=> '[$pargs->{code},重试] ',
		GetWait			=> '等待..',
		SkipMaxLevel	=> '[跳过]层数>$self->{book_max_levels}'.$skip_info,
		SkipMedia		=> '[跳过]媒体文件'.$skip_info,
		SkipTitleEmpty	=> '[跳过]标题为空'.$skip_info,
		SkipUrlEmpty	=> '[跳过]地址为空'."\n",
		SkipVisited		=> '[跳过]已访问过'."\n",
		SkipZip			=> '[跳过]压缩文件'.$skip_info,
	};
}

#-------------------------------------------------------------
# patterns
#-------------------------------------------------------------
sub getpattern_space2_data {
	<<'DATA';
[　]
DATA
}
sub getpattern_line_head_data {
	'　　';
}
sub getpattern_parentheses_data {
	shift->SUPER::getpattern_parentheses_data().<<'DATA';
〃 〃
‘ ’
“ ”
〔 〕
〈 〉
《 》
「 」
『 』
〖 〗
【 】
′ ′
″ ″
＂ ＂
＇ ＇
（ ）
＜ ＞
［ ］
｀ ｀
｀ ＇
｛ ｝
︵ ︶
︹ ︺
︿ ﹀
︽ ︾
﹁ ﹂
﹃ ﹄
︻ ︼
︷ ︸
ˋ ˊ
‵ ‵
〝 〞
﹙ ﹚
﹛ ﹜
﹝ ﹞
﹤ ﹥
DATA
}
sub getpattern_mark_dash_data {
	<<'DATA';
[#-&\*\+\-=@_~ˉ—～‖…×÷∷⊙≡≈∽∞＄¤￠‰§＃％＆＊＋－＝＠＿｜–―‥∣￤‐ー─-♂〇〓※︱-︴﹉-﹏﹡﹢﹣﹦﹩﹪﹫]
DATA
}
sub getpattern_mark_wordsplit_data {
	<<'DATA';
[\.\,\?\!\:\;∶、。·！，．：；？︰﹐﹑﹒﹔﹕﹖﹗]
DATA
}
sub getpattern_word_finish_data {
	<<'DATA';
(?:全[文书]|)[完终]
DATA
}
sub getpattern_remove_line_by_end_data {
	<<'DATA';
(case)
[报网社讯]
[连重排整出提推扫校较编书世视文科在讨小工转][学幻论作]?(?:[载贴排版理品供出入校较描正对者屋库城路界苑线区组室]|海洋|望远镜|桃花源|-K12)(?:完成|)
请(?:申请授权|保留站台信息)[。．﹒\.！﹗]?
制作
[OoＯｏ][CcＣｃ][RrＲｒ]
采编中心
亦凡公益图书馆
龙的天空
失落的星辰
书香门第
旧雨楼
一剑小天下
竹露荷风
扬剑轩居士
幻想时代
冒险者天堂
信息中心
cnread[\.。．·﹒]net
ezla[\.。．·﹒]com?[\.。．·﹒]tw
thebook[\.。．·﹒]yeah[\.。．·﹒]net
y(?:esho[\.。．·﹒]com/wenxue|uzispy[\.。．·﹒]yeah[\.。．·﹒]net)
www[\.。．·﹒](?:v-war|oldrain)[\.。．·﹒](?:net|com)
DATA
}
sub getpattern_remove_line_by_end_special_data {
	<<'DATA';
报网社讯
DATA
}

1;
__END__

=head1 NAME

WWW::BookBot::Chinese - Virtual class of bots to process chinese e-texts.

=head1 SYNOPSIS

  use WWW::BookBot::Chinese::Novel::DragonSky;
  my $bot=WWW::BookBot::Chinese::Novel::DragonSky->new({work_dir=>'/output'});
  $bot->go_catalog({});

  use WWW::BookBot::Chinese::Novel::ShuKu;
  my $bot=WWW::BookBot::Chinese::Novel::ShuKu->new({});
  $bot->go_catalog({desc=>'NewNovel', cat1=>0, cat2=>1, pageno=>0});

=head1 ABSTRACT

Virtual class of bots to process chinese e-texts.

=head1 DESCRIPTION

Virtual class of bots to process chinese e-texts.

to be added.

=head2 EXPORT

None by default.

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-BookBot

=head1 AUTHOR

Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

=head1 SEE ALSO

L<WWW::BookBot>

=cut
