#!/usr/local/bin/perl
#produce semi-accurate dependency chain (tree, i guess) for functions 
#quick hack by kevin greene
# may be distributed under the terms of the artistic license


use File::Basename qw(basename dirname);
use Text::Balanced qw(extract_codeblock extract_bracketed extract_quotelike);
print STDERR "Searching program and modules for all subroutines...\n";


main();

exit;
################3

sub main
{

  my $filename;

  foreach $filename (@ARGV)
  {

    print "processing: " . $filename . "\n";

    process_file($filename,'./');
  
  }
}

########

sub process_file
{
  my $filename = shift;
  my $dir = shift;
  my $basename = basename $filename;
  my $rawbase = $basename;
  $basename =~ s/\..+$//; #remove everything everything after . (no extension)

  open FILE, '<' . $filename;
  return undef unless FILE; #fail on error
  @text = <FILE>;
  close FILE;

  open OUT, '>' . $basename . '_doc.html';

  $text = join '',@text;
  %funcs = extract_all_subnames($text);
  %subs = get_recursive_subs($filename, $text);
  my %uses = get_recursive_uses($filename);
    print STDERR "uses: " . (join ',',sort keys %subs) . "\n";
  #while ($ya = extract_quotelike($text,'(?s).*?"')) {print 'hmmm' . $ya;}

  #($block, $sub) = get_sub($bla);
    ($block,$next,$sub)= extract_bracketed($text,'{}','(?s).*?sub\s+\w+\s*');
  print OUT "<HTML><HEAD><TITLE>$rawbase Doc</TITLE></HEAD><BODY>";
  print OUT "<center><h1>$rawbase</h2></center>";
  print OUT "<h1>Modules</h1><ul>";
  foreach (sort keys %uses)
  {
    print OUT "<li>$_";
  }
  print OUT "</ul>";
  print OUT "<h1>Functions:</h1><ul>";
  foreach (sort keys %funcs)
  {
    print OUT "<li><a href=\"#$_\">$_</a>";
  }
  print OUT "</ul>";


  %variables = extract_vars('',$sub);
  %calls     = extract_calls('',$sub,%subs);
  ($precomments,$blockcomments) = extract_comments($sub,$block);

  print OUT "<hr><h1>Main Script</h1>";
  print OUT "<h2>Variables:</h2> <ul><li>" . (join '<li>',sort keys %variables) . "</ul>\n";
  print OUT "<h2>Calls:</h2><ul><li> " . (join '<li>',sort keys %calls) . "</ul>\n";
  print OUT "<h2>Comments:</h2> \n <pre>$precomments/n</pre>\n";
  print OUT "<h2>Code:</h2> <pre>$sub</pre>\n";

  while ($block)
  {
    $subname       = extract_subname($sub);
    %variables = extract_vars($sub,$block);
    %calls     = extract_calls($sub,$block,%subs);
    ($precomments,$blockcomments) = extract_comments($sub,$block);
  if (0)
  {
    print "=================================================";
    print "Sub: $subname\n";
    print "Vars: " . (join ',',sort keys %variables) . "\n";
    print "Calls: " . (join ',',sort keys %calls) . "\n";
    print "Comments: \nComments-Pre:\n$precomments\nComments-Block:\n$blockcomments\n";
  }
  else
  {
    print OUT "<br><hr><h1>Function: <a name=\"$subname\">$subname</a></h1>\n";
    print OUT "<h2>Variables:</h2> <ul><li>" . (join '<li>',sort keys %variables) . "</ul>\n";
    print OUT "<h2>Calls:</h2><ul><li> " . (join '<li>',sort keys %calls) . "</ul>\n";
    print OUT "<h2>Comments:</h2> \n <pre>$precomments/n/n $blockcomments</pre>\n";
    print OUT "<h2>Code:</h2> <pre>$block</pre>\n";
  }
    #print "BLOCK:\n$block";
    #($block, $sub) = get_sub($bla);
    ($block,$next,$sub)= extract_bracketed($text,'{}','(?s).*?sub\s+\w+\s*');
}
print OUT "</BODY></HTML>";
}

###########
sub get_recursive_subs
{
  my $filename = shift;
  my $text = shift;
print "calling rec_use..";
  my %use = get_recursive_uses($filename);
  my $use,$file,%new,%subs,@file;
  
  foreach $use (keys %use)
  {
    open FILE, "perldoc -m $use|";
    next unless FILE;
    @file = <FILE>;
    $file = join '',@file;
    close FILE;
    %new = extract_all_subnames($file);
    foreach (keys %new)
    {
      $subs{$_}++;
    }
    
  }
  %subs;
}
###########
sub get_recursive_uses
{
  my $file = shift;
  open MODS, "perl -MDevel::Modlist=nocore,stdout,stop,noversion $file|"; #ignore core files
  #return undef unless MODS;
  my @list = <MODS>;
  close MODS;
  #@list = grep chomp $_,grep ($_ =~ s/[\s]+.*$//, @list); #remove version numbers...
  @list = grep chomp $_, @list; #remove version numbers...

  my %use;
  foreach (@list)
  {
#print $_ . "!\n";
    $use{$_}++;
  }

  %use;
}
###########

#only does one level deep right now...
sub OLD_get_recursive_uses
{
  my $text = shift;

  my %use = extract_use($text);
  my $use,%new,$file;

  foreach $use (keys %use)
  {
    open FILE, "perldoc -m $use|";
    next unless FILE;
    @file = <FILE>;
    $file = join '',@file;
    close FILE;
    %new = extract_use($file);
    foreach (keys %new)
    {
      $use{$_}++;
    }
  }

  %use;

}
###########
sub extract_comments
{
  my ($sub, $block) = @_;

  $sub = join "\n", grep /#/, split "\n", $sub;
#  $sub =~ s/(#.*$)/$1/g;
#  $sub =~ s/^$\n//g;
  $block = join "\n", grep /#/, split "\n", $block;
#  $block =~ s/(#.*$)/$1/g;
#  $block =~ s/^$\n//g;
  ($sub,$block);
}
###########
sub extract_vars
{
  my ($sub, $block) = @_;
  my %list;

  while ($block =~ /([\$@%]\w+)/g)
  {
    $list{$1}++;
  }
  %list;
}
###########
sub extract_calls
{
  my ($sub, $block,%subs) = @_;
  my %list;

  #while ($block =~ /[\s(]?([^$@%]\w+)/g)
  while ($block =~ /(\w+)/g)
  {
    $list{$1}++ if exists $subs{$1};
  }
  %list;
}
###########

sub extract_use
{
  my $text = shift;
  my %list;
  while ($text =~ /\n\s*use\s+([\w:.]+)\s*/g)
  {
#print "USE:$1\n";
    $list{$1}++;
  }
  %list;
}
###########

sub extract_subname
{
  my $sub = shift;
  $sub =~ s/.*sub\s+(\w+)\s*/$1/s;
  $sub;
}
###########

sub extract_all_subnames
{
  my $sub = shift;
  my %list;

  while ($sub =~ /\s*sub\s+(\w+)[\s(]*/g)
  {
#print "SUB:$1\n";
    $list{$1}++;
  }
  %list;
}
###########
sub get_sub
{
  my ($text) = @_;
  
  #my $text = $$textref;

  my ($block,$next,$pre)= extract_bracketed($text,'{}','(?s).*?sub\s+\w+\s*');

  $pre =~ s/.*(sub\s+\w+\s*)/$1/s;
  ($block, $pre);

}

