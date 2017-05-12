  #!/usr/bin/perl -w

  use strict;
  use XML::TiePYX;
  use Text::Wrap;
  use Getopt::Std;

  my (@sectnums,%opts);

  getopts('c',\%opts);

  die "usage: psect [-c] file\n" unless @ARGV==1;

  tie *XML,'XML::TiePYX',$ARGV[0],Latin=>1 or die "couldn't open $ARGV[0]: $!";
  die "illegal structure" unless get_event() =~ /^\(outline/;
  push @sectnums,0;
  print_sect() while get_event() =~ /^\(sect/;
  die unless /^\)outline/;
  close XML;

  sub print_sect {
    <XML>=~/^Atitle (.*)/ or die "missing title";
    ++$sectnums[-1];
    print ' ' x (4*$#sectnums),join('.',@sectnums)," $1\n";
    print "\n" unless $opts{c};
    push @sectnums,0;
    while (get_event() !~ /^\)sect/) {
      /^\(sect/ and print_sect(),next;
      /^\(para/ and print_para(),next;
      die "illegal structure";
    }
    pop @sectnums;    
  }
  
  sub print_para() {
    die "illegal structure" unless <XML> =~ /^-(.*)/;
    $_=$1;
    s/\\n/ /g;
    s/^\s+//;
    s/\s+$//;
    print wrap((' ' x (4*($#sectnums-1))) x 2,$_),"\n\n" unless $opts{c};
    die "illegal structure" unless <XML> =~ /^\)para/;
  }

  sub get_event {
    $_=<XML>;
    $_=<XML> if /^-(\s|\\n)*$/;
    $_;
  }
