##pullword

 pullword - The perl agent for Pullword(a online Chinese segmentation System) api! .

 梁博在线分词pullword的perl客户端，支持直接结果以及一个分词词频的hash。
 


##INSTALLATION 安装

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install
 Or you can sample using cpan tool (用perl包管理工具安装):
   
       cpanm pullword

## SYNOPSIS 使用方法
 
    use pullword;
 
    my $value='关关雎鸠，在河之洲。窈窕淑女，君子好逑。
    参差荇菜，左右流之。窈窕淑女，寤寐求之。
    求之不得，寤寐思服。悠哉悠哉，辗转反侧。
    参差荇菜，左右采之。窈窕淑女，琴瑟友之。
    参差荇菜，左右芼之。窈窕淑女，钟鼓乐之。';
    
    my $threshold=0.5;
    my $debug=1;
    
    # 直接输出分词返回结果（文本格式）。
    print PWget($value,$threshold,$debug);
 
    # 以分词分布频度的hash的结果。

    my $fchash=PWhash($value);    
    print "$_ $fchash->{$_} \n" for(sort{$fchash->{$b}<=>$fchash->{$a}} keys %{$fchash});

## Result 结果展示

### 直接分词结果(Mojo::webqq 在线分词)

      桔子  11:29:02  
     
     分词 参差荇菜，左右流之。窈窕淑女，寤寐求之
     Washington  11:29:02
     
     参差:0.403159
     参差荇菜:1
     荇菜:0.046988
     左右:1
     窈窕:0.400039
     窈窕淑女:0.908464
     淑女:0.460456
     女，:0.572975
     寤寐:0.828164
     寤寐求之:0.970102
     (源于Mojo-Webqq桔子分词机器人插件)


### 频度hash结果   

     窈窕淑女 4
     淑女 4
     窈窕 4
     女， 4
     参差荇菜 3
     荇菜 3
     参差 3
     左右 3
     寤寐 2
     悠哉 2
     不得 1
     乐之 1
     辗转 1
     求之不得 1
     关关 1
     好逑 1
     寤寐求之 1
     思服 1
     悠哉悠哉 1
     琴瑟 1
     辗转反侧 1
     关关雎鸠 1
     君子好逑 1
     钟鼓 1
     反侧 1
     关雎 1
     君子 1
     君 1
     雎鸠 1
     在河之洲 1
     鼓乐 1
     关雎鸠 1

##SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc pullword

You can also look for information at:

### RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=pullword
### AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/pullword

### CPAN Ratings
        http://cpanratings.perl.org/d/pullword

### Search CPAN
        http://search.cpan.org/dist/pullword/
###Git repo

[github] (https://github.com/bollwarm/pullword.git)

[oschina] (https://git.oschina.net/ijz/pullword.git)

##LICENSE AND COPYRIGHT

Copyright (C) 2016 ORANGE

This program is released under the following license: Perl

