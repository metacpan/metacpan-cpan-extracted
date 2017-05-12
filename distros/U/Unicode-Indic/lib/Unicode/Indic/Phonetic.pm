#  Used to translate roman key board strokes to Unicode.

package Unicode::Indic::Phonetic;
use strict;
our $VERSION = 0.01;

sub new {
  my $proto = shift;
  my $class = ref($proto)||$proto;
  my $self = {
    @_
  };
}

sub translate{
  my $self = shift;
  my $map  = $self ->{Map};
  my $text = shift;
  my $prev = '';
  my $boc  = 1;
  my $out;
  my $flag = '';
  my $halant = $map->{virama}; 
  foreach my $ch (split (//, $text),' '){
    if ($flag ne ''){
      $flag = ''  if ($flag eq '<' && $ch eq '>');
      $flag = ''  if ($flag eq '&' && $ch eq ';');
      if ($flag eq '#' && $ch eq '#'){
        $flag = '';
	$out .= '\e';
        next;
      }
      if ($flag ne ''){
	$out .= $ch unless $ch eq '#';
	$out .= '\e' if $ch eq '#';
	next;
      }
    }
    if (!$prev){
      $prev = $ch;
      next;
    }
    $out .= $halant if (!$boc && $prev !~ /[aeiouAEIOUMHR]/);
    if (exists $map->{$prev.$ch}){
      if ($boc && $ch =~ /[aieouAEIOUMHR]/){
        $out .= $map->{'_'.$prev.$ch};
      }else{
        $out .= $map->{$prev.$ch};
      }
      $prev ='';
      $boc =  ($ch =~ /[aieouAEIOUMHR]/);
    }elsif (exists $map->{$prev}){
      if ($boc && $prev =~ /[aieouAEIOUR]/){
        $out .= $map->{'_'.$prev};
      }else{
        $out .= $map->{$prev} if $map->{$prev}; 
      }
      $boc = ($prev =~ /[aieouAEIOUMHR]/);
      $prev = $ch;
    }else{
      $out .= $prev unless $prev eq '#';
      $out .= '\e' if $prev eq '#';
      $boc = 1;
      if ((($prev eq '&') || ($prev eq '<'))|| ($prev eq '#')){
       $flag = $prev;
       $out .= $ch;
       $prev = '';
       }else{
        $prev = $ch;
      }
    }
   }
  return $out;
}

sub romanise{
  my $self = shift;
  my $map  = $self ->{Map};
  $self->{RMap} = $self->rmap() unless exists $self->{RMap};
  my $rmap = $self ->{RMap};
  my $base = ord($map->{base});
  my $text = shift;
  my $prev = 'a';
  my $out;
  my $halant = $map->{virama}; 
  foreach my $ch (split (//, $text),' '){
    if (ord($ch) >= $base){
      my $ch1 .= $rmap->[ord($ch) - $base];
      if ($ch eq $halant){
      $prev = 'a';
      next;
      }
      $out .= 'a' if "$prev.$ch1" !~ /[aeiouAEIOUMHR]/; 
      $out .= $ch1;
      $prev = $ch1;
    }else{
      $out .= 'a' if $prev !~ /[aeiouAEIOUMHR]/;
      $out .= '#' if $ch eq '\e';
      $out .= $ch;
      $prev = 'a';
    }
   }
  return $out;
}

sub rmap{
  my $self = shift;
  my $Map = $self->{Map};
  my $base = ord($Map->{base});
  my $RMap = [];
  foreach my $key (sort keys %{$Map}){
      my $v = ord($Map->{$key}) - $base;
      next if $v < 0 or length $key > 3;
      #print $v, ": ", $key,"\n";
      $key =~ s/^_//;
      $RMap->[$v] = $key;
  }
  return $RMap;
}
1;

__END__

=head1 NAME

	Unicode::Indic::Phonetic  -For Phonetic translation of Indian languages.
	
=head1 SYNOPSIS

	use Unicode::Indic::Phonetic;

=head1  DESCRIPTION

	This is the base class for Perl modules for Indian languages.
	For ex., The top few lines of Unicode::Indic::Telugu module has text:
	
	package Unicode::Indic::Telugu;
	use strict;
	use Unicode::Indic::Phonetic;
	our @ISA = qw (Unicode::Indic::Phonetic);
	use constant U => 0x0c00;
	
=head1 DIAGNOSTICS

	None!
	
=head1  AUTHOR

	Syamala Tadigadapa
	
=head1  COPYRIGHT

	Copyright (c) 2003, Syamala Tadigadapa. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
     (see http://www.perl.com/perl/misc/Artistic.html)
