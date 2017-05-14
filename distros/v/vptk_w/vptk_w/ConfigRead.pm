=head1 NAME

 ConfigRead -- read vptk_w configuration information

=cut

package vptk_w::ConfigRead;
use Exporter 'import';
@EXPORT = qw(ReadHTML ReadCnfDlgBalloon);

use strict;

# Read-in limited HTML format:
# 1. Text is pre-formatted
# 2. Each line associated with bold_text/regular_text/picture
#
# Return each line encoded in following format:
# <type> <line>
# type = text|bold|gif
sub ReadHTML
{
  my $file_name=shift;
  my @result=();

  open (HTML,$file_name) || return 0;
  my @file=<HTML>;
  close HTML;
  my $body=0;
  my ($line,$type);
  foreach (@file)
  {
    $body=1 if/<body/i;
    $body=0 if/<\/body>/i;
    s/.*<body[^>]+>//i;
    s/<\/body>.*//i;
    if ($body)
    {
      next if /<.?pre>/;
      $type='text';
      if(/<b>.*<\/b>/i)
      {
        $line=$_;
        $line=~s/<.?b>//ig;
        $type ='bold';
      }
      elsif(/<img src=/i)
      {
        ($line) = (/<img src=["']([^'"]+)\.gif['"]/i);  
        $type ='gif';
      }
      else
      {
        $line=$_;
        $line=~s/<[^>]+>//g;
      }
      $line =~ s/\&gt;/>/g;
      $line =~ s/\&lt;/</g;
      push(@result,"$type $line");
    }
  }
  return (@result);
}

sub ReadCnfDlgBalloon
{
  my ($file_name) = @_;
  return unless open(BF,$file_name);
  my $key='';
  my %cnf_dlg_balloon = ();
  while(<BF>)
  {
    chomp;
    next if /^\s*$/;
    if(/^\s*-/)
    {
      ($key,$_) = (/^\s*(-\S+)\s*=>\s*(\S.*)/);
    }
    next unless $key;
    if (defined $cnf_dlg_balloon{$key})
    {
      $cnf_dlg_balloon{$key}.="\n$_";
    }
    else
    {
      $cnf_dlg_balloon{$key}=" $key => $_";
    }
  }
  close BF;
  return (%cnf_dlg_balloon);
}

1;#)
