package HTML::TkText;
use base qw(HTML::Parser);

use Data::Dumper;

my %empty;
my %autoclose;

sub autoclose
{           
 while (@_)
  {
   $autoclose{shift(@_)} = 1;
  }
}
       
sub emptytags
{           
 while (@_)
  {
   $empty{shift(@_)} = 1;
  }
}

autoclose qw(p li html);
emptytags qw(br hr img);

sub new
{
 my $class = shift;
 my $obj = $class->SUPER::new;
 $obj->{'TAGS'} = [];
 while (@_)
  {
   my ($key,$val) = splice(@_,0,2);
   $obj->{$key} = $val;
  }
 return $obj;
}

sub inside
{   
 my $self = shift;
 my $re   = '^('.join('|',@_).')$';
 $re = qr/$re/;
 my $tags = $self->{'TAGS'};
 my $i = @$tags;
 while ($i-- > 0)
  {
   return $1 if $tags->[$i] =~ $re;
  }
 return 0;
}
       
sub start
{
 my ($self,$tag, $attr, $attrseq, $origtext) = @_;
 if ($tag =~ /^(\w+)=/)
  {
   warn "Treating '<$tag>' as '<$1>'";
   $tag = $1; 
  }
 if ($autoclose{$tag} && $self->inside($tag))
  {
   warn "Autoclose <$tag>";
   $self->end($tag) 
  }
 my $method = "start_$tag"; 
 $self->$method($tag,$attr,$attrseq,$origtext) if $self->can($method);
 if ($empty{$tag})
  {
   print "<$tag />\n";         
   my $method = "end_$tag"; 
   $self->$method($tag,$origtext) if $self->can($method);
  }
 else
  {
   print "<$tag>\n";         
   push(@{$self->{'TAGS'}},$tag);
  }
} 

sub end
{
 my ($self,$tag,$origtext) = @_;
 my @list = @{$self->{'TAGS'}};
 my @popped;
 while (@list)
  {
   my $top = pop(@list);
   if ($top eq $tag)
    {
     while (@popped)
      {
       my $inner = shift(@popped);
       warn "<$inner> closed by <$tag>";
       $self->end($inner);
      }
     $self->{'TAGS'} = \@list; 
     my $method = "end_$tag"; 
     $self->$method($tag,$origtext) if $self->can($method);
     print "</$tag>\n";
     return;
    }
   else
    {
     push(@popped,$top);
    }
  }
 warn "No $tag in ".join(',',@{$self->{'TAGS'}}); 
}    

sub text
{
 my ($self,$text) = @_;
 print $text;
 $text =~ s/\s+/ /g;
 my $t = $self->{Widget};
 if ($t)
  {
   $t->insert('end',$text,$self->{'TAGS'});
  }
}

sub force_parent
{
 my ($self,$tag,@parents) = @_;
 unless ($self->inside(@parents))
  {
   warn "<$tag> not in <".join('> or <',@parents).">";
   $self->start($parents[0]);
  }
}      

sub start_title
{
 my ($self,$tag, $attr, $attrseq, $origtext) = @_;
 $self->force_parent($tag,'head');
}

sub start_head
{
 my ($self,$tag, $attr, $attrseq, $origtext) = @_;
 $self->force_parent($tag,'html');
}

sub start_body
{
 my ($self,$tag, $attr, $attrseq, $origtext) = @_;
 $self->end('head') if $self->inside('head');
 $self->force_parent($tag,'html');
}

sub start_td 
{
 my ($self, $tag, $attr, $attrseq, $origtext) = @_;
 $self->force_parent($tag,'tr');
}

*start_th = \&start_td;

sub start_tr 
{
 my ($self,$tag, $attr, $attrseq, $origtext) = @_;
 $self->force_parent($tag,'table');
}

sub start_li
{
 my ($self,$tag, $attr, $attrseq, $origtext) = @_;
 $self->force_parent($tag,qw(ul ol));
}        

sub eof
{
 my $self = shift;
 $self->SUPER::eof;
 while (@{$self->{'TAGS'}})
  {
   my $tag = $self->{'TAGS'}[-1];
   warn "<$tag> closed by eof";
   $self->end($tag); 
  }
}

1;
__END__
