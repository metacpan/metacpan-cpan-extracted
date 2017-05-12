#!/usr/bin/perl 
use strict;
use warnings;
use feature 'say';
use Sub::Current;
use YAML::Any qw{LoadFile};
use Data::Dumper; sub D (@) {warn Dumper(@_)};

my $slides = LoadFile(shift @ARGV);

=pod

[YAML]

---
- Tool::Bench :
    (ben hengst) ben.hengst@gmail.com
- Features :
    - work for anything, not just perl
    - easy to play with
    - easy to extend
   
[HBML]

slides{
    slide{
        h3{Tool::Bench}
        (ben hengst) ben.hengst@gmail.com
    }
    slide{
        h3{Features}
        * work for anything, not just perl
        * easy to play with
        * easy to extend
    }
}
=cut
my $indent = '    ';
sub IN(@) {
   my $pad  = join '', map{$indent} 1..shift;
   my $text = shift || '';
   my $trinket = shift || '';
   say $pad, $trinket || '', $text =~ m/\n/ ? qq|code{pre{{{$text\n}}}\n}| : $text ;
};
sub is_array ($) {ref(shift) eq 'ARRAY'};
sub is_hash  ($) {ref(shift) eq 'HASH'};
sub LI(@) {
   my $in = shift;
   my $data = shift;
   for (@$data) {
        is_array $_ ? ROUTINE->( 1+$in => $_)
      : is_hash  $_ ? ROUTINE->( $in => [%$_])
      :               IN( $in => $_ => '* ' );
   }
}
sub S (@) {
   my $title = shift;
   IN 1 => 'slide{';
   IN 2 => qq|h3{$title}|;
   foreach (@_) {
      is_array $_ || is_hash $_
      ? LI 2 => $_
      : IN 2 => $_;
   }
   IN 1 => '}';
};

say q|slides{|;
for my $slide (@$slides) {
   S %$slide;
}
say qq|}|;




