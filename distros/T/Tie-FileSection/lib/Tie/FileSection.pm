use strict;
package Tie::FileSection;
$Tie::FileSection::VERSION = '0.171861';
# ABSTRACT: restrict files sequential access using array like boundaries
require Tie::Handle;
our @ISA  = qw( Tie::StdHandle );

sub new{
   my $pkg = $_[0] eq __PACKAGE__ ? shift : __PACKAGE__ ;
   my %opts = @_;
   $opts{filename} || $opts{file} or die "filename|file parameter is mandatory!";
   my $first_line       = $opts{first_line} // 0;
   my $last_line        = $opts{last_line} // 0;
   my $use_real_line_nr = $opts{use_real_line_nr};
   my $FH = $opts{file};
   if(!$FH && defined $opts{filename}){
      open $FH, '<', $opts{filename} or die "** could not open file $opts{filename} : $!\n";
   }
   tie *F, $pkg, $FH, $first_line, $last_line, $use_real_line_nr;
   return \*F;
}

sub TIEHANDLE{
   my ($pkg, $FH, $first_line, $last_line, $use_real_line_nr) = @_;
   my $self = bless { 
         handle           => $FH, 
         first_line       => $first_line,
         last_line        => $last_line,
         init             => 0, #lazy read
         curr_line        => 0,
         use_real_line_nr => $use_real_line_nr,
         line_buffer      => [],
         tell_buffer      => [],
      }, $pkg;
   return $self;
}

sub UNTIE{
   my $fh = $_[0]->{handle};
   undef $_[0];
   close( $fh );
}

sub EOF{
   my $self = shift;
   my $f = $self->{first_line};
   my $l = $self->{last_line};
   if($f>=0 && $l>0 && $f > $l){ #static EOF
      return 1;
   }
   if($f<0 && $l<0 && $l < $f ){ #static EOF
      return 1;
   }
   
   if($f<0 && $l>0){
      return abs($f) + $self->{curr_line} >= $l;
   }
   
   if($self->{init} && 0 <= $l && $l >= $self->{curr_line}){
      return 1;
   }
   
   if(eof( $self->{handle} )){
      #take in account buffer here
      if($l < 0 && scalar(@{$self->{line_buffer}})<abs($l)){
         return 1;
      }
      else{
         #buffer not empty
         return if @{$self->{line_buffer}};
      }
   
      return 1;
   }
   return;
}

sub TELL { 
   my $self = shift;
   $. = $self->{curr_line};
   return tell($self->{handle}) unless $self->{use_buffer};
   return $self->{tell_buffer}[0];
}

sub _readline{
   my $self = shift;
   my $fh   = $self->{handle};
   my $l    = $self->{last_line};
   my $tellbuff = $self->{tell_buffer};
   my $linebuff = $self->{line_buffer};
   unless($self->{init}++){
      my $f    = $self->{first_line};
      if($f > 0){
         my $i = $f;
         while(--$i && defined scalar <$fh>){
         }
      }
      elsif($f < 0){
         #need to read until eof for abs($f) records
         for(1..abs $f){
            push @$tellbuff, tell($fh);
            push @$linebuff, scalar <$fh>;
         }
         $self->{use_buffer}++;
         while(!eof $fh){
            shift @$tellbuff;
            shift @$linebuff;
            push @$tellbuff, tell($fh);
            push @$linebuff, scalar <$fh>;
         }
      }
      if($f > 0 && $l < 0){
         for(1..abs $l){
            push @$tellbuff, tell($fh);
            push @$linebuff, scalar <$fh>;
         }
         $self->{use_buffer}++;
      }
      if(eof($fh)){
         #add the final pos if requested aftere EOF.
         push @$tellbuff, tell($fh);
      }
      if($self->{use_real_line_nr}){
         $. -= @$linebuff if $self->{use_buffer};
         $self->{curr_line} = $.;
      }
      else {
         $. = undef;
      }
   }
   #read one line and return it, take in accound first_line/last_line and buffer
   my $eof = eof($fh);
   my $pos  = tell($fh);
   my $line = $eof ? undef : <$fh>;
   if($self->{use_buffer}){
      unless($eof){
         push @$linebuff, $line;
         push @$tellbuff, $pos;
      }
      elsif($l < 0 && scalar(@$linebuff)<abs($l)){
         return;
      }
      $line = shift @$linebuff;
      shift @$tellbuff unless @$tellbuff == 1;  #always keep last pos
   }
   $self->{curr_line}++;
   $. = $self->{curr_line};
   return $line;
}

sub READLINE { 
   my $self = shift;
   return if $self->EOF;   #test basics boundaries
   unless(wantarray){
      return $self->_readline;
   }
   #ARRAY
   my @rows;
   while(defined($_=$self->READLINE)){ 
      push @rows, $_;
   }
   @rows;
}

sub CLOSE   { close($_[0]->{handle}) }
sub FILENO  { fileno($_[0]->{handle}) }
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::FileSection - restrict files sequential access using array like boundaries

=head1 VERSION

version 0.171861

=head1 SYNOPSIS

   use Tie::FileSection;
   my $filename = 'some/text/file.txt';
   #Lines are indexed starting from 1
   my $Header = Tie::FileSection->new( 
         filename => $filename, 
         first_line => 1, 
         last_line => 1
      );
   say "Header========";
   say <$Header>;
   my $Content = Tie::FileSection->new( 
         filename => $filename, 
         first_line =>2, 
         last_line => -2
      );
   say "Content=======";
   say <$Content>;
   my $Footer = Tie::FileSection->new( 
         filename => $filename, 
         first_line => -1
      );
   say "Footer========";
   say <$Footer>;

=head1 DESCRIPTION

   `Tie::FileSection` represent a regular text file specified by the file name, with boundaries 
   to restrict to a specific section of the file. It is possible to use negative boundaries that
   will be relative to the end of the file. It is designed to works for sequential read accesses.

=head1 NAME

   Tie::FileSection - restrict files sequential access using array like boundaries

=head1 METHOD 

=head2 C<new> - Create a file section and return it as a file handle.

   my $fh = Tie::FileSection->new ( filename => $path, first_line => $i, last_line => $end );
   my $fh = Tie::FileSection->new ( file => $FH,       first_line => $i, last_line => $end );

   filename argument is the file path to read from.
   file argument is the file handle to read from.
   optional first_line argument is the first line index in the file where the section start, omit this argument to mean from start of the file.
   optional last_line argument is the last line index in the file where the section end, omit this argument to mean until EOF.
   optional use_real_line_nr argument when specified with a true value, will make $. to return the original line number, default to relative to the section.

A negative indexes is relative to the end of the file.

=head1 WARRANTY

   `Tie::FileSection`comes with ABSOLUTELY NO WARRANTY. For details, see the license.

=head1 TODO

   Add more tests
   Support random and write accesses

=cut

=head1 AUTHOR

Nicolas Georges <xlat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nicolas Georges.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
