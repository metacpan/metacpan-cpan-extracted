package VJF::Emphase; 
use strict;
use vars qw(@ISA $VERSION @EXPORT_OK %EXPORT_TAGS 
             $VERBOSE %FAM %CI $NB_FAM $NB_IND $NB_SNP  
             $NB_HAP @HAPLOTYPES @HAP_FREQ @HAP_FREQ2 @DIP_FREQ
             $HAP_TRIM_FREQ $EM_CUT_THRESHOLD $MAX_CONF
             $STEPS $CURRENT_LENGTH $PREV_LENGTH $EM_stop);

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw( $STEPS $HAP_TRIM_FREQ $EM_CUT_THRESHOLD $MAX_CONF $NB_FAM %CI
                 $NB_SNP $NB_HAP @HAPLOTYPES @HAP_FREQ @HAP_FREQ2 @DIP_FREQ %FAM $NB_IND 
                 $VERBOSE $CURRENT_LENGTH $PREV_LENGTH $EM_stop 
                 read_link compare is_trio run_EM_trios run_EM_trios_hd run_EM_CC_h run_EM_CC_d run_EM_CC_g);

%EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

$VERSION   = '0.11';
$; = "-";
require XSLoader;
XSLoader::load('VJF::Emphase', $VERSION);

my $EM_data;
our %LINK; 

# et encore des variables globales, na.

my @Alleles;             # liste des allèles présents au SNP #i
my %Haplotypes;

$HAP_TRIM_FREQ = 1e-5;      # min freq des conf familiales
$EM_CUT_THRESHOLD = 1e-10;  # min freq des haplotypes
$EM_stop = 0;
$MAX_CONF = 20000;

# gestion des 'prefixes' 
my @REV_HAPLO;
my @REV_GENO;

my %PROBAS;      # table de proba des haplotypes/genotypes (par prefixes !!)
$PROBAS{''} = 1; # Eh oui !!

$STEPS = 2;  
$CURRENT_LENGTH = 0;
$PREV_LENGTH = 0;

# read_link('fichier')
# Lit le contenu d'un fichier linkage et le place dans le hash %LINK
# Pour la structure du hash, lire ci-dessous ça doit être
# assez parlant.
sub read_link ($\%) 
{
  my $file   = shift();
  my $r_hash = shift();
  my $titre;
  %FAM = ();
  
  my $i = 0;
  my $re = '(\S+)\s*';
  
  my ($fam, $ind, $mere, $pere, $sexe, $phen);
  my $id;
  local $_;

  # Teste l'existence d'un titre.
  my $title;
  open IN, $file or die "Ouverture de $file :\n$!";
  my $ligne1 = <IN>;
  my $ligne2 = <IN>;

  $ligne1 =~ s/^\s*//;  # Si il y a des blancs en début de ligne...
  $ligne2 =~ s/^\s*//;

  my @lin1 = split /\s+/, $ligne1;
  my @lin2 = split /\s+/, $ligne2;

  if(scalar(@lin1) != scalar(@lin2))
  {
    $title = 1;
    $titre = $ligne1;
  }
  if( $lin1[4] =~ /\D/ )  # la case 'sex' est-elle numérique ?
  {
    $title = 1;
    $titre = $ligne1;
  }
 
  if(scalar(@lin2) % 2)
  {
    die "$file: Uneven number of cols.\n";
  }

  $NB_SNP = (scalar(@lin2) - 6)/2;
  # C'est parti.
  seek IN, 0, 0; 

  <IN> if $title;  # skip 1st line
	  
  my (@line, $x, $y);
  $NB_IND = 0;
  while(<IN>) 
  {
    $NB_IND++;
    s/^\s*//;
    @line = split;

    if(scalar(@line) != scalar(@lin2))
    {
      die "$file: cols with different lengths.\n"
    }

    $fam  = $line[0];
    $ind  = $line[1];

    $id = "$fam$;$ind";   # $link{$id} équivaut à $link{$fam,$ind}
    if(defined($$r_hash{$id})) 
    {
      die "Fatal : dans $file, deux individus différents avec même identification",
          " [$fam,$ind]\n";
    }
 
    $$r_hash{$id}{'fam'}  = $fam;
    $$r_hash{$id}{'ind'}  = $ind;
    $$r_hash{$id}{'pere'} = $line[2];
    $$r_hash{$id}{'mere'} = $line[3];
    $$r_hash{$id}{'sexe'} = $line[4];
    $$r_hash{$id}{'phen'} = $line[5];

    @{$$r_hash{$id}{'geno'}} = @line[6..$#line];
    push @{$FAM{$fam}}, $ind;
  }

  close IN;

  $NB_FAM = scalar(keys %FAM);
  return $titre;
}

# Fait l'analyse du hash %LINK
# Met à jour @Alleles, %FAM, $NB_SNP, $NB_FAM, $NB_IND;
# Le hash %FAM aura pour clef les numéros de familles, 
# pour valeurs la liste des individus présents dans chaque famille.

sub analyse_hash
{
  my ($fam, $ind, $i);
  my $id;
  my ($x, $y, @alle);

  @Alleles = ();
  %FAM = ();

  $id = (keys %LINK)[0];
  $NB_SNP = scalar(@{$LINK{$id}{'geno'}})/2; 
  $NB_IND = 0;

  for $id (keys %LINK)
  {
    $NB_IND++;
    if(2*$NB_SNP != scalar(@{$LINK{$id}{'geno'}}) )
    {
      die "Linkage format not respected\n";
    }

    $fam = $LINK{$id}{'fam'};
    $ind = $LINK{$id}{'ind'};

    push @{$FAM{$fam}}, $ind;
 
    for($i=0; $i<$NB_SNP; $i++)
    {
      $x = $LINK{$id}{'geno'}->[2*$i];
      $y = $LINK{$id}{'geno'}->[2*$i+1];
      $alle[$i]{$x} = $alle[$i]{$y} = 1;
    }
  }

  for($i=0; $i<$NB_SNP; $i++)
  {
    @{$Alleles[$i]} = sort {compare($a,$b)} (keys %{$alle[$i]});
  }

  $NB_FAM = scalar(keys %FAM);
  close IN;

  # On en profite pour tuer les variables globales dans lesquelles pourraient trainer
  # des trucs, avant de commencer tout calcul...
  %CI = ();
  %Haplotypes = ();
  @HAPLOTYPES = ();
  @HAP_FREQ   = ();
  @HAP_FREQ2  = ();
  @DIP_FREQ   = ();
  @REV_HAPLO  = ();
  @REV_GENO   = ();
  %PROBAS = ();
  $PROBAS{''} = 1; 
}


# Comparaison d'abord numérique (avec 0 < Z) 
# puis lexicographique.
#
# -> comparaison de 2 snps. On a 0 < 1,2,3,4,A,C,G,T...
# Ce qui permet que 'non défini' arrive en tête !
#
# Peut aussi servir à trier les familles.
sub compare
{
  my $x = shift();
  my $y = shift();

  if($x eq $y)
  {
    return 0;
  }
  if($x eq '0')
  { 
    return -1;
  } 
  if($y eq '0')
  {
    return 1;
  }
  if($x != $y)
  {
    return ($x <=> $y);
  } 
  return ($x cmp $y);
}  

# is_trio($n)
# La famille $n est elle un trio ?
# Retour : undef ou (1, id_pere, id_mere, id_fils)

sub is_trio
{
  my $fam = shift();
  if(scalar(@{$FAM{$fam}}) != 3)
  {
    return undef;
  }
  my ($fils, $pere, $mere);
  foreach my $ind (@{$FAM{$fam}})
  {
    $pere = $LINK{$fam,$ind}{'pere'};
    $mere = $LINK{$fam,$ind}{'mere'};
    if ($pere ne '0' and $mere ne '0' and defined($LINK{$fam,$pere}) and defined($LINK{$fam,$mere}) and ($pere ne $mere))
    { 
      $fils = $ind;
      last;
    }
  }
  unless(defined($fils))
  {
    return undef;
  }
  return undef unless(defined($LINK{$fam,$pere}) and defined($LINK{$fam,$mere}));
  return (1,$pere,$mere,$fils);
}


# Construction des listes de diplotypes 
# possibles pour un individu.

sub diplotypes_possibles
{
  my $n = shift();        # numero du SNP en cours
  my $al1 = pop();
  my $al2 = pop();
  my @res;

  if($al1 ne '0' && $al2 ne '0')
  {
    if(scalar(@_) == 0)
    {
      return $al1, $al2;
    }
    @res = prepend_hap($al1, $al2, diplotypes_possibles($n-1, @_));
  }
  else
  {
    # Données manquantes.
    my @pot = geno_potentiels($n);
    # #############################  if($n == 0)  # C'est le début...
    if(scalar(@_) == 0)  # C'est le début...
    {
      return (@pot);
    }
    my @list = diplotypes_possibles($n-1, @_);
    for(my $i=0; $i<scalar(@pot)/2; $i++)
    {
      push @res, prepend_hap($pot[2*$i], $pot[2*$i+1], @list);
    }
  }
  return (@res);
}

#
sub genotypes_possibles
{
  my $n = shift();        # numero du SNP en cours
  my $al1 = pop();
  my $al2 = pop();
  my @res;

  if($al1 ne '0' && $al2 ne '0')
  {
    if(scalar(@_) == 0)
    {
      return "$al1$;$al2";
    }
    @res = prepend_geno("$al1$;$al2", genotypes_possibles($n-1, @_));
  }
  else
  {
    # Données manquantes. (seul cas vraiment intéressant ici)
    my @pot = geno_potentiels($n);
    if(scalar(@_) == 0)  # C'est le début...
    {
      while(scalar(@pot)>0)
      {
	my $x =shift(@pot);
	my $y =shift(@pot);
	push @res, "$x$;$y";
      }
      return (@res);
    }
    my @list = genotypes_possibles($n-1, @_);
    for(my $i=0; $i<scalar(@pot)/2; $i++)
    {
      push @res, prepend_geno("$pot[2*$i]$;$pot[2*$i+1]", @list);
    }
  }
  return (@res);
}

# Construction de la liste des génotypes possibles au SNP numéro n
sub geno_potentiels
{
  my $n = shift;
  if($Alleles[$n][0] ne '0')
  {
    die "Critical bug. Please warn the author.\n[You may check SNP #$n in your data]\n";
  }
  # SNP $l-allélique
  my $l = scalar(@{$Alleles[$n]})-1;
  my @list1 = @{$Alleles[$n]}[1..$l];

  # Si personne n'a été génotypé à cet endroit on met '0' qd meme...
  # (eh oui, il faut penser qu'il y a des gens qui ont
  #  des données du CNG)
  if(scalar(@list1) == 0)
  {
    @list1 = (0);
  }

  my @list2 = @list1;
  my @res;
  for my $x (@list1)
  {
    for my $y (@list2)
    {
      push @res, $x, $y;
    }
    shift @list2;
  }
  return @res; 
}


sub prepend_hap
{
  my $al1 = shift();
  my $al2 = shift();
  $al1 =~ s/^\s+//;
  $al2 =~ s/^\s+//;
  # le reste des données est lu dans @_ au fur et à mesure !
  my @res = ();
  if($al1 eq $al2)
  {
    for my $x (@_)
    {
      push @res, "$x $al1";
    }
    return (@res);
  }
  while(scalar(@_)>0)
  {
    my $x = shift(@_);
    my $y = shift(@_);
    $x =~ s/\s+$//;
    $y =~ s/\s+$//;
    if( $x ne $y )
    {
      push @res, "$x $al1", "$y $al2", "$x $al2", "$y $al1";
    }
    else 
    {
      push @res, "$x $al1", "$x $al2";
    }
  }
  return (@res);
}

sub prepend_geno
{
  my $g = shift();
  $g =~ s/^\s+//;
  # le reste des données est lu dans @_ au fur et à mesure !
  my @res = ();
  while(scalar(@_)>0)
  {
    my $x = shift(@_);
    $x =~ s/\s+$//;
    push @res, "$x $g";
  }
  return (@res);
}

# Individu par individu, crée la liste @{$LINK{fam,ind}{'diplos'}}
# des diplotypes possibles en mettant à jour le hash %Haplotypes
# et $NB_HAP
# UTILISE intensément @REV_HAPLO et $PREV_LENGTH
# ! mettre à jour @REV_HAPLO au fur et à mesure !

sub cree_diplos
{
  my @diplo;
  my ($x, $y);

  %Haplotypes = ();
  $NB_HAP = 0;

  my ($I, @suff, @pref); 
  for my $id (keys %LINK)
  {
    $I = $LINK{$id}{'geno'};   # référence à un tableau de génotypes
    # On construit toutes les possibilités pour un nouveau segment de SNP
    @suff  = diplotypes_possibles($CURRENT_LENGTH-1, @{$I}[2*$PREV_LENGTH..2*$CURRENT_LENGTH-1]);

    if($PREV_LENGTH>0)
    {
      # On récupère les possibilités déjà construites pour le début.
      @pref  = (map {$REV_HAPLO[$_]} (@{$LINK{$id}{'diplos'}}));  

      # On recolle le tout.
      @diplo = ();
      while(scalar(@suff))
      {
        $x = shift @suff;
        $y = shift @suff;
        push @diplo, prepend_hap($x,$y,@pref);
      }
    }
    else
    {
      @diplo = @suff;
    }

    @{$LINK{$id}{'diplos'}} = ();
    for(my $i=0; $i<scalar(@diplo)/2; $i++)
    {
      $x = $diplo[2*$i];
      $y = $diplo[2*$i + 1];
      $Haplotypes{$x} = $NB_HAP++ unless exists($Haplotypes{$x});
      $Haplotypes{$y} = $NB_HAP++ unless exists($Haplotypes{$y});
      push @{$LINK{$id}{'diplos'}}, $Haplotypes{$x}, $Haplotypes{$y};
    }
  }
}

# Idem pour créer les génotypes !!

sub cree_genos
{
  my @geno;
  my ($x, $y);

  %Haplotypes = ();
  $NB_HAP = 0;

  my ($I, @suff, @pref); 
  for my $id (keys %LINK)
  {
    $I = $LINK{$id}{'geno'};   # référence à un tableau de génotypes
    # On construit toutes les possibilités pour un nouveau segment de SNP
    @suff  = genotypes_possibles($CURRENT_LENGTH-1, @{$I}[2*$PREV_LENGTH..2*$CURRENT_LENGTH-1]);
    if($PREV_LENGTH>0)
    {
      # On récupère les possibilités déjà construites pour le début.
      @pref  = (map {$REV_HAPLO[$_]} (@{$LINK{$id}{'genos'}}));  

      # On recolle le tout.
      @geno = ();
      while(scalar(@suff))
      {
        $x = shift @suff;
        push @geno, prepend_geno($x,@pref);
      }
    }
    else
    {
      @geno = @suff;
    }

    @{$LINK{$id}{'genos'}} = ();
    for my $x (@geno) 
    {
      $Haplotypes{$x} = $NB_HAP++ unless exists($Haplotypes{$x});
      push @{$LINK{$id}{'genos'}}, $Haplotypes{$x};
    }
  }
}

# Pour des données « non familiales ».
# Met à jour $EM_data 
# Appelle cree_diplos() !
sub make_EM_data_h
{
  cree_diplos();
  my $ind = 0;

  for my $id (keys %LINK)
  {
    $LINK{$id}{'unit'} = $ind;
    set_unit_h($EM_data,$ind++,@{$LINK{$id}{'diplos'}});
  }
  extend_possibilities($EM_data, $NB_HAP);
}

# Idem pour le modèle « diplo »
sub make_EM_data_d
{
  cree_diplos();
  my $ind = 0;

  for my $id (keys %LINK)
  {
    $LINK{$id}{'unit'} = $ind;
    set_unit_h($EM_data,$ind++,@{$LINK{$id}{'diplos'}});
  }
  set_N($EM_data, $NB_HAP);
  extend_possibilities2($EM_data, $NB_HAP**2);
}

# Idem, mais pour la reconstruction génotypique
sub make_EM_data_g
{
  cree_genos();
  my $ind = 0;

  for my $id (keys %LINK)
  {
    $LINK{$id}{'unit'} = $ind;
    set_unit($EM_data,$ind++,@{$LINK{$id}{'genos'}});
  }
  extend_possibilities($EM_data, $NB_HAP);
}

# Pour des données trio
# Met à jour $EM_data 
# Appelle trio_configs() !
sub make_EM_data_t
{
  trio_configs();
  my $k = 0;
  my ($fam, $pere, $mere, $fils, $x);
  my (@fi, @pe, @me, @ci);
  my @list;
  for $fam (sort {compare($a,$b)} (keys %FAM))
  {
    ($x, $pere, $mere, $fils) = is_trio($fam);
    @fi = @{$LINK{$fam,$fils}{'conf'}};
    @pe = @{$LINK{$fam,$pere}{'conf'}};
    @me = @{$LINK{$fam,$mere}{'conf'}};
    @ci = @{$CI{$fam}};
    @list = ();
    for(my $i=0; $i<scalar(@fi)/2; $i++)
    {
      push @list, $pe[2*$i], $pe[2*$i+1], $me[2*$i], $me[2*$i+1], $fi[2*$i], $fi[2*$i+1], $ci[2*$i], $ci[2*$i+1];
    }
    set_unit_t($EM_data,$k++,@list);
  }
  extend_possibilities($EM_data, $NB_HAP);
}

# Pour des données trio
# Met à jour $EM_data 
# Appelle trio_configs() !
sub make_EM_data_thd
{
  trio_configs();
  my $k = 0;
  my ($fam, $pere, $mere, $fils, $x);
  my (@fi, @pe, @me, @ci);
  my @list;
  for $fam (sort {compare($a,$b)} (keys %FAM))
  {
    ($x, $pere, $mere, $fils) = is_trio($fam);
    @fi = @{$LINK{$fam,$fils}{'conf'}};
    @pe = @{$LINK{$fam,$pere}{'conf'}};
    @me = @{$LINK{$fam,$mere}{'conf'}};
    @ci = @{$CI{$fam}};
    @list = ();
    for(my $i=0; $i<scalar(@fi)/2; $i++)
    {
      push @list, $pe[2*$i], $pe[2*$i+1], $me[2*$i], $me[2*$i+1], $fi[2*$i], $fi[2*$i+1], $ci[2*$i], $ci[2*$i+1];
    }
    set_unit_t($EM_data,$k++,@list);
  }
  extend_possibilities($EM_data, $NB_HAP);
  extend_possibilities2($EM_data, $NB_HAP**2);
}


# Prend en entrée les génotypes du père, de la mère, et du fils
# pour un marqueur donné, et génére un génotype correspondant 
# aux allèles non transmises.
#
#    !!!!!!!!!!!!!!!!!!!!!
#    !!!!! ATTENTION !!!!!
#    !!!!!!!!!!!!!!!!!!!!!
#
# Le fils est suppose donné dans l'ordre 'allele paternel' 
# puis 'allele maternel' !
# '0' est considéré comme un numéro d'haplotype valide !
# L'allèle paternel de l'anti-jumeau est donné le premier !
# Syntaxe : anti_twin($pere1, $pere2, $mere1, $mere2, $fils1, $fils2);
sub anti_twin 
{
  my ($a, $b, $c, $d, $e, $f) = @_; 
  my @result;
  
  if($e eq $a)
  {
    push @result, $b;
  }
  elsif($e eq $b)
  {
    push @result, $a;
  }
  else
  {
    die "($a $b) ($c $d) ($e $f) : First allele of offspring is not a paternal allele\n";
  }

  if($f eq $c)
  {
    push @result, $d;
  }
  elsif($f eq $d)
  {
    push @result, $c;
  }
  else
  {
    die "($a $b) ($c $d) ($e $f) : Second allele of offspring is not a maternal allele\n";
  }

  return (@result);
}

# Pour des données trio
# Crée la liste @{$LINK{$id}{'conf'}
sub trio_configs
{
  my ($fam, $pere, $mere, $fils, $x);
  my ($dfils, $dpere, $dmere);
  my ($f1, $f2, $p1, $p2, $m1, $m2);

  cree_diplos();

  for $fam (keys %FAM)
  {
    my $trim_flag = 0;
    ($x, $pere, $mere, $fils) = is_trio($fam);
    # die "Family $fam is not a trio\n" unless $x;
    if(!$x) # HACK rapide pour virer les familles qui ne sont pas des trios !
    {
      print "$fam : not a trio \n";
      delete $FAM{$fam}; 
      next;
    }

    @{$LINK{$fam,$fils}{'conf'}} = ();
    @{$LINK{$fam,$pere}{'conf'}} = ();
    @{$LINK{$fam,$mere}{'conf'}} = ();
    @{$CI{$fam}} = ();
    $dfils = $LINK{$fam,$fils}{'diplos'};
    $dpere = $LINK{$fam,$pere}{'diplos'};
    $dmere = $LINK{$fam,$mere}{'diplos'};
    for(my $i=0; $i<scalar(@$dfils)/2; $i++)
    {
      $f1 = $$dfils[2*$i];
      $f2 = $$dfils[2*$i + 1];
      for(my $j=0; $j<scalar(@$dpere)/2; $j++)
      {
        $p1 = $$dpere[2*$j];
        $p2 = $$dpere[2*$j + 1];
	next unless (($p1 == $f1) or (($p1 == $f2)) or ($p2 == $f1) or ($p2 == $f2));
	for(my $k=0; $k<scalar(@$dmere)/2; $k++)
	{
          $m1 = $$dmere[2*$k];
          $m2 = $$dmere[2*$k + 1];
	  next unless comp_fpm($f1, $f2, $p1, $p2, $m1, $m2);
          # Les diplotypes sont compatibles. On les ordonne
          # pour que le premier haplotype du fils soit paternel...
          if($f1 != $p1 and $f1 != $p2)
	  {
	    my $tmp = $f1;
	    $f1 = $f2;
	    $f2 = $tmp;
	  }
          # et que le second soit maternel !  
          if($f2 != $m1 and $f2 != $m2)
	  {
	    my $tmp = $f1;
	    $f1 = $f2;
	    $f2 = $tmp;
	  }
          push @{$LINK{$fam,$fils}{'conf'}}, $f1, $f2;
          push @{$LINK{$fam,$pere}{'conf'}}, $p1, $p2;
          push @{$LINK{$fam,$mere}{'conf'}}, $m1, $m2;
          push @{$CI{$fam}}, (anti_twin($p1, $p2, $m1, $m2, $f1, $f2)); 
          # et il ne faut pas oublier le cas ambigu !!!
          if(triple_hetero($f1, $f2, $p1, $p2, $m1, $m2))
	  {          
	    push @{$LINK{$fam,$fils}{'conf'}}, $f2, $f1;
            push @{$LINK{$fam,$pere}{'conf'}}, $p1, $p2;
            push @{$LINK{$fam,$mere}{'conf'}}, $m1, $m2;
            push @{$CI{$fam}}, (anti_twin($p1, $p2, $m1, $m2, $f2, $f1)); 
	  }		  
	}
      }
      if(scalar(@{$LINK{$fam,$mere}{'conf'}})/2 > $MAX_CONF)
      {
        print "Family $fam: more than $MAX_CONF configurations computed\n" if $VERBOSE;
        print "-->Removing this family.\n" if $VERBOSE;
        @{$LINK{$fam,$fils}{'conf'}} = ();    
        @{$LINK{$fam,$pere}{'conf'}} = ();    
        @{$LINK{$fam,$mere}{'conf'}} = ();    
	@{$CI{$fam}} = ();
	$trim_flag++;
	last;
      }
    }
    if(scalar(@{$LINK{$fam,$mere}{'conf'}}) == 0 and $trim_flag == 0)
    {
# print "Family $fam: no possible configurations were found.\n";
    }
  }
}

# compatiblilité fils / père / mere
sub comp_fpm
{
  my $f1 = shift;
  my $f2 = shift;
  my $p1 = shift;
  my $p2 = shift;
  my $m1 = shift;
  my $m2 = shift;
  return ((($f1 == $p1) and (($f2 == $m1) or ($f2 == $m2))) or 
	 (($f1 == $p2) and (($f2 == $m1) or ($f2 == $m2))) or
         (($f1 == $m1) and (($f2 == $p1) or ($f2 == $p2))) or 
	 (($f1 == $m2) and (($f2 == $p1) or ($f2 == $p2))));
}

sub run_EM_h
{
  my ($L, $L0, $i);
  E_step_h($EM_data);
  M_step_h($EM_data);
  $i = 1;
  $L = Likelihood_h($EM_data);
  $L0 = $L - $EM_stop - 1;
  while($L - $L0 > $EM_stop or $i < 4)
  {
    $L0 = $L;
    cut_at_threshold($EM_data, $EM_CUT_THRESHOLD);
    E_step_h($EM_data);
    M_step_h($EM_data);
    $L = Likelihood_h($EM_data); 
    $i++;
  } 
  print " EM stopped after $i iterations\n" if $VERBOSE;
}

sub run_EM_d
{
  my ($L, $L0, $i);
  E_step_d($EM_data);
  M_step_d($EM_data);
  $i = 1;
  $L = Likelihood_d($EM_data);
  $L0 = $L - $EM_stop - 1;
  while($L - $L0 > $EM_stop or $i < 4)
  {
    $L0 = $L;
    cut_at_threshold2($EM_data, $EM_CUT_THRESHOLD);
    E_step_d($EM_data);
    M_step_d($EM_data);
    $L = Likelihood_d($EM_data); 
    $i++;
  } 
  print ">EM stopped after $i iterations\n" if $VERBOSE;
}

sub run_EM_g
{
  my ($L, $L0, $i);
  E_step($EM_data);
  M_step($EM_data);
  $i = 1;
  $L = Likelihood($EM_data);
  $L0 = $L - $EM_stop - 1;
  while($L - $L0 > $EM_stop or $i < 4)
  {
    $L0 = $L;
    cut_at_threshold($EM_data, $EM_CUT_THRESHOLD);
    E_step($EM_data);
    M_step($EM_data);
    $L = Likelihood($EM_data); 
    $i++;
  } 
  print " EM stopped after $i iterations\n" if $VERBOSE;
}

sub run_EM_t
{
  my ($L, $L0, $i);
  E_step_t($EM_data);
  M_step_t($EM_data);
  $i = 1;
  $L = Likelihood_t($EM_data); 
  $L0 = $L - $EM_stop - 1;
  while($L - $L0 > $EM_stop or $i < 4)
  {
    $L0 = $L;
    cut_at_threshold($EM_data, $EM_CUT_THRESHOLD);
    E_step_t($EM_data);
    M_step_t($EM_data);
    $L = Likelihood_t($EM_data); 
    $i++;
  } 
  print " EM stopped after $i iterations\n" if $VERBOSE;
}

sub run_EM_thd
{
  my ($L, $L0, $i);
  E_step_thd($EM_data);
  M_step_thd($EM_data);
  $i = 1;
  $L = Likelihood_thd($EM_data); 
  $L0 = $L - $EM_stop - 1;
  while($L - $L0 > $EM_stop or $i < 4)
  {
    $L0 = $L;
    cut_at_threshold($EM_data, $EM_CUT_THRESHOLD);
    cut_at_threshold2($EM_data, $EM_CUT_THRESHOLD);
    E_step_thd($EM_data);
    M_step_thd($EM_data);
    $L = Likelihood_thd($EM_data); 
    $i++;
  } 
  print " EM stopped after $i iterations\n" if $VERBOSE;
}

# Est ce que c'est du type (A B) (A B) (A B) ?
# avec A != B
sub triple_hetero
{
  my $f1 = shift();
  my $f2 = shift();
  my $g1 = shift();
  my $g2 = shift();
  my $h1 = shift();
  my $h2 = shift();
  return undef if( ($f1 == $f2) or ($g1 == $g2) or ($h1 == $h2) );
  my %hash;

  $hash{$f1} = $hash{$f2} = 1;
  return ($hash{$g1} and $hash{$g2} and $hash{$h1} and $hash{$h2});
}

# Cette routine est du pur luxe (a priori ça n'accèlére pas fameusement la convergence)
# !!! Attention %Haplotypes peut contenir des génotypes ou des haplotypes.
# !!! Attention encore : ça n'est pas adapté aux modèles avec fréquences dipltypiques
#     (ie les modèles où on ne suppose pas HW);
sub a_priori_probas
{
  my %rameaux;
  my $prefix;
  my @probas;
  for my $k (keys %Haplotypes)
  {
    $prefix = join " ", (split /\s+/, $k)[0..$PREV_LENGTH-1]; 
    unless(exists $PROBAS{$prefix})
    {
      warn "current length = $CURRENT_LENGTH\nprevious length = $PREV_LENGTH\n";
      die "Haplotype [$k]: prefix [$prefix] doesn't exists.\nThis should never happen. A serious bug occured.\n" 
    }
    $rameaux{$prefix}++;
  }
  for my $k (keys %Haplotypes)
  {
    $prefix = join " ", (split /\s+/, $k)[0..$PREV_LENGTH-1];
    my $proba = $PROBAS{$prefix}/$rameaux{$prefix};
    $probas[$Haplotypes{$k}] = $proba;
  } 
  set_probas($EM_data, @probas);
}

##############################################################
#                                                            #
#                   Données CC                               #
#                                                            #
##############################################################
sub run_EM_CC_h (\%)
{
  my $r_hash = shift();
  *LINK = $r_hash;
  analyse_hash();

  $EM_data = new_d($NB_IND);
  my @list_probas;
  local $| = 1;
  while($CURRENT_LENGTH < $NB_SNP)
  {
    $PREV_LENGTH = $CURRENT_LENGTH;
    $CURRENT_LENGTH += $STEPS;
    $CURRENT_LENGTH = $NB_SNP if $CURRENT_LENGTH > $NB_SNP;
  
    %Haplotypes = ();
    make_EM_data_h();
    a_priori_probas();
    print "Haplotypes de longueur $CURRENT_LENGTH, $NB_HAP possibilités retenues\n" if $VERBOSE;
    run_EM_h();
    last if $CURRENT_LENGTH == $NB_SNP;
 
    @list_probas = get_prob($EM_data);
    foreach my $k (keys %Haplotypes)
    {
      $PROBAS{$k} = $list_probas[$Haplotypes{$k}];
    }

    # Pour chaque individu, on épure la liste de diplotypes construite à l'étape
    # précédente en virant tout ceux dont le proba finale est < $HAP_TRIM_FREQ
    for my $id (keys %LINK)
    {
      @{$LINK{$id}{'diplos'}} = ();
      my $i = $LINK{$id}{'unit'};
      my $n = nbpos_unit($EM_data, $i);
      for(my $j=0; $j<$n; $j++)
      {
        my ($a1, $a2, $p) = get_unit_h($EM_data,$i,$j);
        push @{$LINK{$id}{'diplos'}}, $a1, $a2 if $p>$HAP_TRIM_FREQ; 
      }
    } 
    # Et on met à jour @REV_HAPLO !
    @REV_HAPLO = (sort {$Haplotypes{$a} <=> $Haplotypes{$b}} (keys %Haplotypes));
  
    # C'est reparti pour un tour...
  }
  ###############################################################
  #                                                             #
  #               Place les résultats dans le hash              #
  #               en renumérotant les haplotypes...             #
  #               et en triant les configs par proba...         #
  #                                                             #
  ###############################################################

  my $i=1;
  @list_probas = get_prob($EM_data);
  my @Ordered;  # numéros des haplotypes réordonnés
  foreach my $k (sort {$list_probas[$Haplotypes{$b}] <=> $list_probas[$Haplotypes{$a}]} (keys %Haplotypes))
  {
    next if $list_probas[$Haplotypes{$k}] == 0;
    $Ordered[$Haplotypes{$k}] = $i;
    $HAPLOTYPES[$i] = $k;
    $HAP_FREQ[$i] = $list_probas[$Haplotypes{$k}];
    $i++;
  }
  $NB_HAP = $i-1;
  
  for my $fam (sort {compare($a,$b)} (keys %FAM))
  {
    for my $ind (sort {compare($a, $b)} (@{$FAM{$fam}}))
    {
      @{$LINK{$fam,$ind}{'diplos'}} = ();
      my $i = $LINK{$fam,$ind}{'unit'};
      my $n = nbpos_unit($EM_data, $i);
      my @haps;
      my @prob;
      for(my $j=0; $j<$n; $j++)
      {
        my ($a1, $a2, $p) = get_unit_h($EM_data,$i,$j);
	push @haps, $a1, $a2;
	push @prob, $p
      }
      @{$LINK{$fam, $ind}{'probas'}} = ();
      for my $j (sort {$prob[$b] <=> $prob[$a]} (0..($n-1)))
      { 
        last if $prob[$j] == 0;
	push @{$LINK{$fam, $ind}{'diplos'}}, $Ordered[$haps[2*$j]], $Ordered[$haps[2*$j+1]];
        push @{$LINK{$fam, $ind}{'probas'}}, $prob[$j];
      }
    }
  }
  del_data($EM_data);
}



##############################################################
#                                                            #
#                   Données CC, sans supposer HW             #
#                                                            #
##############################################################

# Ici l'EM roule sur des fréquences diplotypiques, mais, à
# toutes fins utiles, maintient une table de fréquences 
# haplotypiques.
# --> get_prob() récupère les probas haplotypiques
#  et get_prob2() les probas diplotypiques !

sub run_EM_CC_d (\%)
{
  my $r_hash = shift();
  *LINK = $r_hash;
  analyse_hash();

  $EM_data = new_d($NB_IND);
  my @list_probas;
  local $| = 1;
  while($CURRENT_LENGTH < $NB_SNP)
  {
    $PREV_LENGTH = $CURRENT_LENGTH;
    $CURRENT_LENGTH += $STEPS;
    $CURRENT_LENGTH = $NB_SNP if $CURRENT_LENGTH > $NB_SNP;
  
    %Haplotypes = ();
    make_EM_data_d();
# a_priori_probas();
    print "Haplotypes de longueur $CURRENT_LENGTH, $NB_HAP possibilités retenues\n" if $VERBOSE;
    run_EM_d();
    last if $CURRENT_LENGTH == $NB_SNP;
 
#    @list_probas = get_prob($EM_data);
#    foreach my $k (keys %Haplotypes)
#    {
#      $PROBAS{$k} = $list_probas[$Haplotypes{$k}];
#    }

    # Pour chaque individu, on épure la liste de diplotypes construite à l'étape
    # précédente en virant tout ceux dont le proba finale est < $HAP_TRIM_FREQ
    for my $id (keys %LINK)
    {
      @{$LINK{$id}{'diplos'}} = ();
      my $i = $LINK{$id}{'unit'};
      my $n = nbpos_unit($EM_data, $i);
      for(my $j=0; $j<$n; $j++)
      {
        my ($a1, $a2, $p) = get_unit_h($EM_data,$i,$j);
        push @{$LINK{$id}{'diplos'}}, $a1, $a2 if $p>$HAP_TRIM_FREQ; 
      }
    } 
    # Et on met à jour @REV_HAPLO !
    @REV_HAPLO = (sort {$Haplotypes{$a} <=> $Haplotypes{$b}} (keys %Haplotypes));
  
    # C'est reparti pour un tour...
  }
  ###############################################################
  #                                                             #
  #               Place les résultats dans le hash              #
  #               en renumérotant les haplotypes...             #
  #               et en triant les configs par proba...         #
  #                                                             #
  ###############################################################

  my $i=1;
  @list_probas = get_marginal2($EM_data);
  print "**[@list_probas]**\n";
  my @Ordered;  # numéros des haplotypes réordonnés
  foreach my $k (sort {$list_probas[$Haplotypes{$b}] <=> $list_probas[$Haplotypes{$a}]} (keys %Haplotypes))
  {
    next if $list_probas[$Haplotypes{$k}] == 0;
    $Ordered[$Haplotypes{$k}] = $i;
    $HAPLOTYPES[$i] = $k;
    $HAP_FREQ[$i] = $list_probas[$Haplotypes{$k}];
    $i++;
  }
  my $nb_hap = $NB_HAP; 
  $NB_HAP = $i-1;

  # Et les fréquences diplotypiques !!!
  @list_probas = get_prob2($EM_data); 
  for(my $i = 0; $i<$nb_hap; $i++)
  {
    for(my $j = 0; $j<$nb_hap; $j++)
    {
      my $p = $list_probas[$i*$nb_hap + $j];
      warn "There must be an error if haplotypic frequencies ??\n" if ($Ordered[$i] > $NB_HAP or $Ordered[$i] > $NB_HAP) and $p !=0; 
      next if $Ordered[$i] > $NB_HAP or $Ordered[$i] > $NB_HAP;
      $DIP_FREQ[$Ordered[$i]][$Ordered[$j]] = $p;
    }
  }

  for my $fam (sort {compare($a,$b)} (keys %FAM))
  {
    for my $ind (sort {compare($a, $b)} (@{$FAM{$fam}}))
    {
      @{$LINK{$fam,$ind}{'diplos'}} = ();
      my $i = $LINK{$fam,$ind}{'unit'};
      my $n = nbpos_unit($EM_data, $i);
      my @haps;
      my @prob;
      for(my $j=0; $j<$n; $j++)
      {
        my ($a1, $a2, $p) = get_unit_h($EM_data,$i,$j);
	push @haps, $a1, $a2;
	push @prob, $p
      }
      @{$LINK{$fam, $ind}{'probas'}} = ();
      for my $j (sort {$prob[$b] <=> $prob[$a]} (0..($n-1)))
      { 
        last if $prob[$j] == 0;
	push @{$LINK{$fam, $ind}{'diplos'}}, $Ordered[$haps[2*$j]], $Ordered[$haps[2*$j+1]];
        push @{$LINK{$fam, $ind}{'probas'}}, $prob[$j];
      }
    }
  }
  del_data($EM_data);
}


sub expand_genotype
{
  my $g = shift();
  my $r = '';
  for my $x (split /\s+/, $g)
  {
    if($x =~ /(.*)$;(.*)/)
    {
      $r .= "$1 $2  ";
    }
    else
    {
      die "Error, [$g] is not a valid genotype???\n";
    }
  }
  $r =~ s/  $//;
  return $r;
}


##############################################################
#                                                            #
#                   Données CC, EM génotypique !             #
#                                                            #
##############################################################
sub run_EM_CC_g (\%)
{
  my $r_hash = shift();
  *LINK = $r_hash;
  analyse_hash();

  $EM_data = new_d($NB_IND);
  my @list_probas;
  local $| = 1;
  while($CURRENT_LENGTH < $NB_SNP)
  {
    $PREV_LENGTH = $CURRENT_LENGTH;
    $CURRENT_LENGTH += $STEPS;
    $CURRENT_LENGTH = $NB_SNP if $CURRENT_LENGTH > $NB_SNP;
  
    # Le hash Haplotypes va contenir des génotypes !!
    %Haplotypes = ();
    make_EM_data_g();
    a_priori_probas(); # Les génotypes sont codés pour que cette routine
                         # marche aussi bien que pour les haplotypes.

    print "Génotypes de longueur $CURRENT_LENGTH, $NB_HAP possibilités retenues\n" if $VERBOSE;
    run_EM_g();
    last if $CURRENT_LENGTH == $NB_SNP;
 
    @list_probas = get_prob($EM_data);
    foreach my $k (keys %Haplotypes)
    {
      $PROBAS{$k} = $list_probas[$Haplotypes{$k}];
    }

    # Pour chaque individu, on épure la liste de génotypes construite à l'étape
    # précédente en virant tout ceux dont le proba finale est < $HAP_TRIM_FREQ
    for my $id (keys %LINK)
    {
      @{$LINK{$id}{'genos'}} = ();
      my $i = $LINK{$id}{'unit'};
      my $n = nbpos_unit($EM_data, $i);
      for(my $j=0; $j<$n; $j++)
      {
        my ($g, $p) = get_unit($EM_data,$i,$j);
        push @{$LINK{$id}{'genos'}}, $g if $p>$HAP_TRIM_FREQ; 
      }
    } 
    # Et on met à jour @REV_HAPLO -- ici ses valeurs sont des génotypes. 
    @REV_HAPLO = (sort {$Haplotypes{$a} <=> $Haplotypes{$b}} (keys %Haplotypes));
  
    # C'est reparti pour un tour...
  }
  ###############################################################
  #                                                             #
  #               Place les résultats dans le hash              #
  #               en renumérotant les génotypes...              #
  #               et en triant les configs par proba...         #
  #                                                             #
  ###############################################################

  my $i=1;
  @list_probas = get_prob($EM_data);
  my @Ordered;  # numéros des haplotypes réordonnés
  foreach my $k (sort {$list_probas[$Haplotypes{$b}] <=> $list_probas[$Haplotypes{$a}]} (keys %Haplotypes))
  {
    next if $list_probas[$Haplotypes{$k}] == 0;
    $Ordered[$Haplotypes{$k}] = $i;
    $HAPLOTYPES[$i] = expand_genotype($k);
    $HAP_FREQ[$i] = $list_probas[$Haplotypes{$k}];
    $i++;
  }
  $NB_HAP = $i-1;
  
  for my $fam (sort {compare($a,$b)} (keys %FAM))
  {
    for my $ind (sort {compare($a, $b)} (@{$FAM{$fam}}))
    {
      @{$LINK{$fam,$ind}{'genos'}} = ();
      my $i = $LINK{$fam,$ind}{'unit'};
      my $n = nbpos_unit($EM_data, $i);
      my @genos;
      my @prob;
      for(my $j=0; $j<$n; $j++)
      {
        my ($g, $p) = get_unit($EM_data,$i,$j);
	push @genos, $g;
	push @prob, $p
      }
      @{$LINK{$fam, $ind}{'probas'}} = ();
      for my $j (sort {$prob[$b] <=> $prob[$a]} (0..($n-1)))
      { 
        last if $prob[$j] == 0;
	push @{$LINK{$fam, $ind}{'genos'}}, $Ordered[$genos[$j]];
        push @{$LINK{$fam, $ind}{'probas'}}, $prob[$j];
      }
    }
  }
  del_data($EM_data);
}



##############################################################
#                                                            #
#                   Données trio                             #
#                                                            #
##############################################################
sub run_EM_trios (\%)
{
  my $r_hash = shift();
  *LINK = $r_hash;
  analyse_hash();

  $EM_data = new_d($NB_FAM);
  my @list_probas;
  local $| = 1;
  while($CURRENT_LENGTH < $NB_SNP)
  {
    $PREV_LENGTH = $CURRENT_LENGTH;
    $CURRENT_LENGTH += $STEPS;
    $CURRENT_LENGTH = $NB_SNP if $CURRENT_LENGTH > $NB_SNP;

    %Haplotypes = ();
    print "Haplotypes of length=$CURRENT_LENGTH\n" if $VERBOSE;

    make_EM_data_t();
    a_priori_probas();

    print "--> $NB_HAP haplotypes kept\n" if $VERBOSE;
    print "EM starting..." if $VERBOSE;
    run_EM_t();
    # Ce qui suit n'a d'utilité que pour préparer la prochaine boucle, donc...
    last if $CURRENT_LENGTH == $NB_SNP;

    # Et donc, préparons la prochaine boucle.
    my @list_probas = get_prob($EM_data);
    foreach my $k (keys %Haplotypes)
    {
      $PROBAS{$k} = $list_probas[$Haplotypes{$k}];
    }

    # Pour chaque individu, on épure la liste de diplotypes construite à l'étape
    # précédente en prenant en compte les données familiales --> on prend les
    # diplotypes qui apparaissent dans une configurations avec p > ...
    my $k = 0;
    my ($fam, $tt, $pere, $mere, $fils, @fi, @pe, @me, @list, %seen);
    for $fam (sort {compare($a,$b)} (keys %FAM))
    {
      ($tt, $pere, $mere, $fils) = is_trio($fam);
      @fi = @{$LINK{$fam,$fils}{'conf'}};
      @pe = @{$LINK{$fam,$pere}{'conf'}};
      @me = @{$LINK{$fam,$mere}{'conf'}};
      @{$LINK{$fam,$fils}{'diplos'}} = ();
      @{$LINK{$fam,$pere}{'diplos'}} = ();
      @{$LINK{$fam,$mere}{'diplos'}} = ();
      %seen = ();
      my $j=0;
      for(my $i=0; $i<scalar(@fi)/2; $i++)
      {
        next if get_proba_unit_t($EM_data,$k,$i) <= $HAP_TRIM_FREQ; 
        push @{$LINK{$fam,$fils}{'diplos'}}, $fi[2*$i], $fi[2*$i+1] unless $seen{'fils'}{$fi[2*$i],$fi[2*$i+1]}++;
        push @{$LINK{$fam,$pere}{'diplos'}}, $pe[2*$i], $pe[2*$i+1] unless $seen{'pere'}{$pe[2*$i],$pe[2*$i+1]}++;
        push @{$LINK{$fam,$mere}{'diplos'}}, $me[2*$i], $me[2*$i+1] unless $seen{'mere'}{$me[2*$i],$me[2*$i+1]}++;
        $j++;
      }
      if( $j == 0 and scalar(@fi)>0 )
      {
        print "Family $fam trimmed out (trimming thresholds probabily too high ?)\n" if $VERBOSE;
      }
      $k++;
    }

    # Et on met à jour @REV_HAPLO !
    @REV_HAPLO = (sort {$Haplotypes{$a} <=> $Haplotypes{$b}} (keys %Haplotypes));
  }

  ###############################################################
  #                                                             #
  #               Place les résultats dans le hash              #
  #               en renumérotant les haplotypes...             #
  #               et en triant les configs par proba...         #
  #                                                             #
  ###############################################################

  my $i=1;
  @list_probas = get_prob($EM_data);
  my @Ordered;  # numéros des haplotypes réordonnés
  foreach my $k (sort {$list_probas[$Haplotypes{$b}] <=> $list_probas[$Haplotypes{$a}]} (keys %Haplotypes))
  {
    next if $list_probas[$Haplotypes{$k}] == 0;
    $Ordered[$Haplotypes{$k}] = $i;
    $HAPLOTYPES[$i] = $k;
    $HAP_FREQ[$i] = $list_probas[$Haplotypes{$k}];
    $i++;
  }
  $NB_HAP = $i-1;

  my $k = 0;
  my ($fam, $pere, $mere, $fils, $tt);
  my (@fi, @pe, @me, @ci);
  my @list;
  my $format = "%5s %5s %5s %5s %5s %10s\n"; 
  for $fam (sort {compare($a,$b)} (keys %FAM))
  {
    my @proba;
    my @out;
    ($tt, $pere, $mere, $fils) = is_trio($fam);
    @fi = @{$LINK{$fam,$fils}{'conf'}};
    @pe = @{$LINK{$fam,$pere}{'conf'}};
    @me = @{$LINK{$fam,$mere}{'conf'}};
    @ci = @{$CI{$fam}};
    
    @{$LINK{$fam,$fils}{'conf'}} = ();
    @{$LINK{$fam,$pere}{'conf'}} = ();
    @{$LINK{$fam,$mere}{'conf'}} = ();
    @{$CI{$fam}} = ();

    for(my $i=0; $i<scalar(@fi)/2; $i++)
    {
      $proba[$i] = get_proba_unit_t($EM_data,$k,$i);
    }

    @{$LINK{$fam}{'probas'}} = ();
    for my $i (sort {$proba[$b] <=> $proba[$a]} (0..(scalar(@fi)/2-1)))
    {
      last if $proba[$i] == 0;
      push @{$LINK{$fam}{'probas'}}, $proba[$i];
      push @{$LINK{$fam,$pere}{'conf'}}, $Ordered[$pe[2*$i]],$Ordered[$pe[2*$i+1]];
      push @{$LINK{$fam,$mere}{'conf'}}, $Ordered[$me[2*$i]],$Ordered[$me[2*$i+1]];
      push @{$LINK{$fam,$fils}{'conf'}}, $Ordered[$fi[2*$i]],$Ordered[$fi[2*$i+1]];
      push @{$CI{$fam}}, $Ordered[$ci[2*$i]],$Ordered[$ci[2*$i+1]];
    }
    $k++;
  }
  del_data($EM_data);
}


##############################################################
#                                                            #
#        Données trio, modèle haplo/diplo                    #
#                                                            #
##############################################################
sub run_EM_trios_hd (\%)
{
  my $r_hash = shift();
  *LINK = $r_hash;
  analyse_hash();

  $EM_data = new_d($NB_FAM);
  my @list_probas;
  local $| = 1;
  my @list_probas;
  while($CURRENT_LENGTH < $NB_SNP)
  {
    $PREV_LENGTH = $CURRENT_LENGTH;
    $CURRENT_LENGTH += $STEPS;
    $CURRENT_LENGTH = $NB_SNP if $CURRENT_LENGTH > $NB_SNP;

    %Haplotypes = ();
    print "Haplotypes of length=$CURRENT_LENGTH\n" if $VERBOSE;

    make_EM_data_thd();
# a_priori_probas();

    print "--> $NB_HAP haplotypes kept\n" if $VERBOSE;
    print "EM starting..." if $VERBOSE;
    run_EM_thd();
    # Ce qui suit n'a d'utilité que pour préparer la prochaine boucle, donc...
    last if $CURRENT_LENGTH == $NB_SNP;

#    # Et donc, préparons la prochaine boucle.
#    @list_probas = get_prob($EM_data);
#    foreach my $k (keys %Haplotypes)
#    {
#      $PROBAS{$k} = $list_probas[$Haplotypes{$k}];
#    }

    # Pour chaque individu, on épure la liste de diplotypes construite à l'étape
    # précédente en prenant en compte les données familiales --> on prend les
    # diplotypes qui apparaissent dans une configurations avec p > ...
    my $k = 0;
    my ($fam, $tt, $pere, $mere, $fils, @fi, @pe, @me, @list, %seen);
    for $fam (sort {compare($a,$b)} (keys %FAM))
    {
      ($tt, $pere, $mere, $fils) = is_trio($fam);
      @fi = @{$LINK{$fam,$fils}{'conf'}};
      @pe = @{$LINK{$fam,$pere}{'conf'}};
      @me = @{$LINK{$fam,$mere}{'conf'}};
      @{$LINK{$fam,$fils}{'diplos'}} = ();
      @{$LINK{$fam,$pere}{'diplos'}} = ();
      @{$LINK{$fam,$mere}{'diplos'}} = ();
      %seen = ();
      my $j=0;
      for(my $i=0; $i<scalar(@fi)/2; $i++)
      {
        next if get_proba_unit_t($EM_data,$k,$i) <= $HAP_TRIM_FREQ; 
        push @{$LINK{$fam,$fils}{'diplos'}}, $fi[2*$i], $fi[2*$i+1] unless $seen{'fils'}{$fi[2*$i],$fi[2*$i+1]}++;
        push @{$LINK{$fam,$pere}{'diplos'}}, $pe[2*$i], $pe[2*$i+1] unless $seen{'pere'}{$pe[2*$i],$pe[2*$i+1]}++;
        push @{$LINK{$fam,$mere}{'diplos'}}, $me[2*$i], $me[2*$i+1] unless $seen{'mere'}{$me[2*$i],$me[2*$i+1]}++;
        $j++;
      }
      if( $j == 0 and scalar(@fi)>0 )
      {
        print "Family $fam trimmed out (trimming thresholds probabily too high ?)\n" if $VERBOSE;
      }
      $k++;
    }

    # Et on met à jour @REV_HAPLO !
    @REV_HAPLO = (sort {$Haplotypes{$a} <=> $Haplotypes{$b}} (keys %Haplotypes));
  }

  ###############################################################
  #                                                             #
  #               Place les résultats dans le hash              #
  #               en renumérotant les haplotypes...             #
  #               et en triant les configs par proba...         #
  #                                                             #
  ###############################################################

  my $i=1;
  @list_probas = get_prob($EM_data);
  my @list_probas2 = get_marginal2($EM_data);
  my @Ordered;  # numéros des haplotypes réordonnés
  foreach my $k (sort {($list_probas[$Haplotypes{$b}] + $list_probas2[$Haplotypes{$b}]) <=> ($list_probas[$Haplotypes{$a}] + $list_probas2[$Haplotypes{$a}])} (keys %Haplotypes))
  {
    next if ($list_probas[$Haplotypes{$k}] + $list_probas2[$Haplotypes{$k}]) == 0;
    $Ordered[$Haplotypes{$k}] = $i;
    $HAPLOTYPES[$i] = $k;
    $HAP_FREQ[$i]   = $list_probas[$Haplotypes{$k}];
    $HAP_FREQ2[$i]  = $list_probas2[$Haplotypes{$k}];
    $i++;
  }
  my $nb_hap = $NB_HAP; 
  $NB_HAP = $i-1;

  # Et les fréquences diplotypiques !!!
  @list_probas = get_prob2($EM_data); 
  for(my $i = 0; $i<$nb_hap; $i++)
  {
    for(my $j = 0; $j<$nb_hap; $j++)
    {
      my $p = $list_probas[$i*$nb_hap + $j];
      warn "There must be an error if haplotypic frequencies ??\n" if ($Ordered[$i] > $NB_HAP or $Ordered[$i] > $NB_HAP) and $p !=0; 
      next if $Ordered[$i] > $NB_HAP or $Ordered[$i] > $NB_HAP;
      $DIP_FREQ[$Ordered[$i]][$Ordered[$j]] = $p;
    }
  }

  my $k = 0;
  my ($fam, $pere, $mere, $fils, $tt);
  my (@fi, @pe, @me, @ci);
  my @list;
  my $format = "%5s %5s %5s %5s %5s %10s\n"; 
  for $fam (sort {compare($a,$b)} (keys %FAM))
  {
    my @proba;
    my @out;
    ($tt, $pere, $mere, $fils) = is_trio($fam);
    @fi = @{$LINK{$fam,$fils}{'conf'}};
    @pe = @{$LINK{$fam,$pere}{'conf'}};
    @me = @{$LINK{$fam,$mere}{'conf'}};
    @ci = @{$CI{$fam}};
    
    @{$LINK{$fam,$fils}{'conf'}} = ();
    @{$LINK{$fam,$pere}{'conf'}} = ();
    @{$LINK{$fam,$mere}{'conf'}} = ();
    @{$CI{$fam}} = ();

    for(my $i=0; $i<scalar(@fi)/2; $i++)
    {
      $proba[$i] = get_proba_unit_t($EM_data,$k,$i);
    }

    @{$LINK{$fam}{'probas'}} = ();
    for my $i (sort {$proba[$b] <=> $proba[$a]} (0..(scalar(@fi)/2-1)))
    {
      last if $proba[$i] == 0;
      push @{$LINK{$fam}{'probas'}}, $proba[$i];
      push @{$LINK{$fam,$pere}{'conf'}}, $Ordered[$pe[2*$i]],$Ordered[$pe[2*$i+1]];
      push @{$LINK{$fam,$mere}{'conf'}}, $Ordered[$me[2*$i]],$Ordered[$me[2*$i+1]];
      push @{$LINK{$fam,$fils}{'conf'}}, $Ordered[$fi[2*$i]],$Ordered[$fi[2*$i+1]];
      push @{$CI{$fam}}, $Ordered[$ci[2*$i]],$Ordered[$ci[2*$i+1]];
    }
    $k++;
  }
  del_data($EM_data);
}

return 1;

=head1 NAME

VJF::Emphase - EM likelihood maximisation for familial data. 

=head1 SYNOPSIS

  use VJF::Emphase qw(:all);

=head1 DESCRIPTION

This version is only intended to be used by L<VJF::MITDT>. 

=cut

