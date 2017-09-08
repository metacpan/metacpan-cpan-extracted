package XML::TMX::FromPO;
$XML::TMX::FromPO::VERSION = '0.36';
# ABSTRACT: Generates a TMX file from a group of PO files

use 5.010;
use warnings;
use strict;
use XML::TMX::Writer;
use Exporter ();


our @ISA = 'Exporter';
our @EXPORT_OK = qw(&new &parse_dir &create_tmx &clean_tmx);


sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self = {};

   $self->{LANG} = undef;
   $self->{OUTPUT} = undef;
   $self->{DEBUG} = 0;

   __common_conf($self, @_);

   unless(defined($self->{CONVER})) {
      if(system('recode >/dev/null 2>&1')) {
         $self->{CONVERT} = 'iconv -f %t -t utf8 < %f';
      } else {
         $self->{CONVERT} = 'recode %t..utf8 < %f';
      }
   }

   $self->{TMX} = {};
   bless($self, $class);
   return($self);
}



sub rec_get_po {
   my $self = shift;
   my $dir = shift;
   my $lan1 = shift;
   __common_conf($self, @_);

   # check if directory is readable
   if(-f $dir) {
      my $file=$dir;
      my $lang = lc($lan1);

      if(!defined($self->{LANG}) || __check_lang($self, $lang)) {
            __processa($self, $file, $lang);
      }
   }
   else {
    die("$dir is not a readable directory\n") unless(-d $dir);
    for my $file (<$dir/*>) {

      if($file =~ /(.*)\.(po|messages)$/) {
         my $lang = lc($lan1);

         if(!defined($self->{LANG}) || __check_lang($self, $lang)) {
            __processa($self, $file, $lang);
         }
      }
      elsif($file =~ /(.*)\.(\w+)\.(po|messages)$/) {
         my $lang = lc($lan1);
         ## ??? my $lang = "\L$2";

         if(!defined($self->{LANG}) || __check_lang($self, $lang)) {
            __processa($self, $file, $lang);
         }
      }
      elsif(-d $file) {
         rec_get_po($self,$file,$lan1)
      }
      else {
         ## warn ("$file ... não tem lingua\n") if($self->{DEBUG});
      }
    }
   }

   __add_en($self)  if(__check_lang($self, 'en'));
   __limpa($self);
}



sub parse_dir {
   my $self = shift;
   my $dir = shift;

   __common_conf($self, @_);

   # check if directory is readable
   die("$dir is not a readable directory\n") unless(-d $dir);

   for my $file ((<$dir/*.po>),(<$dir/*.messages>)) {
      if($file =~ /(\w+)\.(po|messages)$/) {
         my $lang = "\L$1";

         if(!defined($self->{LANG}) || __check_lang($self, $lang)) {
            __processa($self, $file, $lang);
         }
      } elsif($file =~ /(.*)\.(\w+)\.(po|messages)$/) {
         my $lang = "\L$2";

         if(!defined($self->{LANG}) || __check_lang($self, $lang)) {
            __processa($self, $file, $lang);
         }
      } else {
         warn ("$file ... não tem lingua\n") if($self->{DEBUG});
      }
   }

   __add_en($self) if(__check_lang($self, 'en'));
   __limpa($self);
}

# return value:
#   * 0 -> lang does not exist
#   * 1 -> lang exists
sub __check_lang {
   my $self = shift;
   my $lang = shift;
   my @regex = @{$self->{LANG}};

   while(my $regex = shift(@regex)) {
      last if($regex gt $lang);
      if($lang =~ /^$regex$/i) {
         return(1);
      }
   }
   return(0);
}

sub __add_en {
   my $self = shift;

   for my $str (keys %{$self->{TMX}}) {
      $self->{TMX}{$str}{'en'} = $str;
   }
}


sub create_tmx {
   my $self = shift;
   my $tmx = new XML::TMX::Writer();

   __common_conf($self, @_);

   my $n_langs = @{$self->{LANG}};

   if(defined($self->{OUTPUT})) {
      $tmx->start_tmx(ID => 'XML::TMX::FromPO', OUTPUT => $self->{OUTPUT});
   } else {
      $tmx->start_tmx(ID => 'XML::TMX::FromPO');
   }

   for my $chave (keys %{$self->{TMX}}) {
      my $reg = __make_tu($self, $self->{TMX}{$chave});
      # only write to file if all languages are defined
      $tmx->add_tu(%{$reg}) if(keys(%{$reg}) >= $n_langs);
   }
   $tmx->end_tmx();
}


sub clean_tmx {
   my $self = shift;
   $self->{TMX} = {};
}

sub __make_tu {
   my $self = shift;
   my $block = shift;
   my $reg = {};

   if(!defined($self->{LANG})) {
      return($block);
   }

   for my $lang (keys %$block) {
      $reg->{$lang} = $block->{$lang} if(__check_lang($self, $lang));
   }
   return($reg);
}

sub __processa {
   my $self = shift;
   my $a = shift;
   my $l = shift;

   local $/ = "\nmsgid";
   #local $/ = "\nmsgid ";
   print STDERR "$a\n" if($self->{DEBUG});

   my $codeline = `grep -i Content-Type $a | grep -i charset`;
   my $code = "?";

   if($codeline =~ /charset=([\w-]+)/) { $code = $1; }

   my $convert = $self->{CONVERT};

   $convert =~ s/\%t/$code/i;
   $convert =~ s/\%f/$a/i;

   if($code eq "?" || $code =~ /utf-?8/i ) { open(F,$a) or die;}
   else { open(F,"$convert|") or die;}

   my $mi = 0;

   while(<F>) {
      chomp;
      next if($mi == 0 && /^msgid\s+""/);
      if(/"Content-Type:/ && /charset=([\w-]+)/) { $code = $1; next }
      s/(^|\n)\s*#.*//g;

#      s/_//g unless $under;

      next unless(/\n\s*msgstr/);
      my ($m1,$m2) = ($`,$');

      $m1 =~ s/(^\s*"|"\s*$)//g;
      $m1 =~ s/("\s*\n\s*")/ /g;
      $m2 =~ s/(^\s*"|"\s*$)//g;
      $m2 =~ s/("\s*\n\s*")/ /g;

      unless($m1) {
         warn "\n====M1 vazio... \n$m1\n=$m2\n";
         next;
      }

      if($m2) {
         $self->{TMX}{$m1}{$l} = $m2;
      } # || "????? $m1";

      #$self->{TMX}{$m1}{'en'} = $m1;
      # print "\n====\n$m1\n=$m2\n";

      $mi++;
   }
   print STDERR "Charset: $code\n" if($self->{DEGUB});
   close F;
}

sub __limpa {
   my $self = shift;

   # possíveis limpezas
   # (1) eliminar traduções que sejam igual ao original
   # (2) eliminar strings que não contenham pelo menos 2 letras
   #     consecutivas
   # (3) eliminar frases que fiquem sem traduções
   #
   # um teste realizado com os po's do evolution mostrou uma redução do
   # ficheiro final de 12M para 8,6M, uma análise com o diff aos dumps
   # permitiu ver que grande parte do ''lixo'' eram de (1)

   for my $h1 (keys %{$self->{TMX}}) {
      if($h1 =~ /[a-z][a-z]/i) {
         for my $h2 (keys %{$self->{TMX}{$h1}}) {
            # optimização (1)
            delete($self->{TMX}{$h1}{$h2}) if($h2 !~ /^en/i && $h1 eq $self->{TMX}{$h1}{$h2});
         }
         # optimização (3)
         delete($self->{TMX}{$h1}) unless(keys %{$self->{TMX}{$h1}});
      } else {
         # optimização (2)
         delete($self->{TMX}{$h1});
      }
   }
}



sub __common_conf {
   my $self = shift;
   my %opt = @_;

   if(defined($opt{LANG})) {
      my @list;
      for my $l (sort(split(/\s+/, $opt{LANG}))) {
         push(@list, $l) if($l =~ /^[a-z0-9_]+$/i);
      }
      $self->{LANG} = \@list if(@list);
   }

   $self->{CONVERT} = $opt{CONVERT} if defined($opt{CONVERT});
   $self->{OUTPUT}  = $opt{OUTPUT}  if defined($opt{OUTPUT});
   $self->{DEBUG}   = $opt{DEBUG}   if defined($opt{DEBUG});
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

XML::TMX::FromPO - Generates a TMX file from a group of PO files

=head1 VERSION

version 0.36

=head1 SYNOPSIS

   use XML::TMX::FromPO;

   my $conv = new XML::TMX::FromPO(OUTPUT => '%f.tmx');

=head1 DESCRIPTION

This module can be used to generate TMX files from a group of PO files.

=head1 METHODS

The following methods are available:

=head2 new

  $tmx = new XML::TMX::FromPO();

Creates a new XML::TMX::FromPO object. Please check the L<COMMON
CONFIGURATION> section for details on the options.

=head2 rec_get_po

TODO: Document method

=head2 parse_dir

TODO: Document method

=head2 create_tmx

TODO: Document function

=head2 clean_tmx

TODO: Document method

=head1 COMMON CONFIGURATION

These configuration options can be passed to all methods in the module:

=over

=item LANG => 'list'

A case insensitive list of regular expression separated by whitespaces
that matches the code of the languages that are to be processed.
Defaults to all.

=item CONVERT => 'iconv -f %t -t utf8 < %f'

A string that contains the command to convert a file (%f) from some
charset (%t) to Unicode. If none is specified, the module tries to
use L<recode(1)>, if it fails then the module defaults to L<iconv(1)>.

=item OUTPUT => 'x.tmx'

The name of the output file. If none is specified it defaults to the
standard output.

=item DEBUG => 1

Activate debugging information. Defaults to 0.

=back

=head1 SEE ALSO

L<XML::TMX::Writer(3)>, L<gettext(1)>, L<recode(1)>, L<iconv(1)>

=head1 CONTRIBUTORS

Paulo Jorge Jesus Silva, E<lt>paulojjs@bragatel.ptE<gt>

=head1 AUTHORS

=over 4

=item *

Alberto Simões <ambs@cpan.org>

=item *

José João Almeida <jj@di.uminho.pt>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2017 by Projeto Natura <natura@di.uminho.pt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
