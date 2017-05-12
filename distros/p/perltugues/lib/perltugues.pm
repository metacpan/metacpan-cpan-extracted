package perltugues;

require 5.005_62;
use strict;
use warnings;
use utf8;

our $VERSION = '0.19';

use Filter::Simple;

FILTER_ONLY
  all => sub {
  my $package = shift;
  my %par = @_;
  my $DEBUG = $par{DEBUG} if $par{DEBUG};
  return unless $DEBUG;
  my $i = 0;
  my @qq = /"(.*?)"/g;
  push @qq, /'(.*?)'/g;
  s/"(.*?)"/'"$' . ($i++) . '$"'/ge;
  s/'(.*?)'/"'\$" . ($i++) . "\$'"/ge;
  filter($_);
  s/"\$(\d+)\$"/'"' . (shift @qq) . '"'/ge;
  s/'\$(\d+)\$'/"'" . (shift @qq) . "'"/ge;
  Perl::Tidy::perltidy(source => \$_, destination => \$_)
   if eval "require Perl::Tidy";
  print if $DEBUG;
  exit;
},
  code_no_comments  => \&filter;
my $tipo = "inteiro|texto|real|caracter";
#my $tipo = '\w+';

sub filter {
   my @var;
   my @varArray;
   $_ = "use strict;$/" . $_;

   s/#.*$//g;

   s# \bse\b \s* \(? (.*?) \)? \s* \{
    #if ($1)\{$/
    #gmx;

   s# \bse \s* n[ãa]o
    #else
    #gmx;

   s# \ba \s+ n[aã]o \s+ ser (?:\s+ q(?:ue)? )?\b \s* (.*?) \s* \{
    #unless ($1)\{$/
    #gmx;

   s# \bpara\b \s+ (\w+) \s* \( (.*?) \) \s* \{
    #for ($2){\$$1->vale(\$_);$/
    #gmx;

   s# \bpara\b \s+ (\w+) \s* <- \s* \(? (.*?) \)? \s* \{
    #for ($2){\$$1->vale(\$_);$/
    #gmx;

   s# \bpara\b \s* \(? (.*?)\) \)? \s* \{
    #for ($1){
    #gmx;

   s/ (\(?) \bde \s+ (\w+) \s+ a \s+ (\w+) (?:\s+ (?:a|para) \s+ cada \s+ (.+?) ) (\)?)
    /$1map({(\$_ * $4) + $2} 0 .. (int($3\/$4) - ($2?1:0)))$5
    /gmx;

   s/ (\(?) \bde \s+ (\w+) \s+ a \s+ (\w+) (\)?)
    /$1$2 .. $3$4
    /gmx;

   s# \benquanto\b \s* \(? (.*?) \)? \s*\{
    #while ($1)\{$/
    #gmx;

   s# \bat(?:eh?|é) (?:\s+q(?:ue)?)?\b \s* (\()? (.*?) \)? \{
    #until($2)\{$/
    #gmx;

   s/ \bescrev[ae]\b \s* \(? (.*?) \)? (;)
    /print($1)$2
    /gmx;

   s/\bleia\b(?:\s*\(?(.*?)\)?)?\s*;/chomp(my \$_tmp_=<>);\$$1->vale(\$_tmp_);/g;
   s/\bsaia do (?:loop|la[cç]o)\b/last/g;
   s/\bpr[óo]ximo\b/next/g;
   s/\bde novo\b/redo/g;
   s/\brefa[çc]a\b/redo/g;
   s/\bv[aá] para\b/goto/g;
   s/\(([^()]*?)\)\s*separado\s+por\s*((["']?).*?\3)(\s*[,;])/join($2, $1)$4/g;
   s#quebra\s+de\s+linha#\$/#g;
   s#fim de texto#"\\0"#g;
   s/\bin[íi]cio:?\b/{/g;
   s/\bfim\b/}/g;
   s/\bfun[cç][aã]o\b/sub/g;

### ___   Tipos Array  ___ ###

   {
      my @varB = grep {!/^\s*$/} m#\barray\s+(?:$tipo)\s*:\s*([]\w, []+)\s*;#gsm;
      @varB = map {/^(\w+)/; $1} @varB;
      push(@varArray, split /\s*,\s*/, join ",", @varB);

      my $redef = (grep{my $v=$_; 1 < grep {$v eq $_} @varArray} @varArray)[0];
      die qq#Variavel "$redef" redefinida!$/# if defined $redef;

      my $err_var = (grep{!/^[a-z,A-Z]/} @varArray)[0];
      die qq#Nome invalido da variavel "$err_var".$/# if defined $err_var;

      my($t, $v);
      my %tipo = m#\barray\s+($tipo)\s*:\s*([]\w, []+)\s*;#gxsm;
      for my $t(keys %tipo){
         $_ = "use perltugues::$t;$/" . $_;
      }
      s#\barray\s+($tipo)\s*:\s*([]\w, []+)\s*;
       #my $_tipo = $1;
        my $_var  = $2;
        join$/,map{
                     "my \@$1 = (" . (join",", ("perltugues::$_tipo->new") x $2) . ");"
                        if /^(\w+)\[(\d+)\]$/
                  }split/\s*,\s*/, $_var
       #gexsm;
      for my $var(@varArray){
         s/\btamanho\s*\($var\)/scalar \@$var/g;
         s/([^\$])\b$var\[(.+?)\]\s*=\s*((['"])?.*?\3?)\s*;/$1($2 <= \$#$var?\${$var}[$2]->vale($3):die qq#O array "\\$var" esta sendo acessado numa posicao inexistente\$\/#);/g;
         s/([^\$])\b$var\[(.+?)\]/$1($2 <= \$#$var?\$$var\[$2]:die qq#O array "$var" esta sendo acessado numa posicao inexistente\$\/#)/g;
         s/([^@#])\b$var\b(?!\[.*?\])/$1\@$var/g;
      }
   }
### ___   Tipos Escalares  ___ ###

   my @varB = grep {!/^\s*$/} m#\s*\b(?:$tipo)\s*:\s*([\w, ]+)\s*;#gsm;
   #my @varB = grep {!/^\s*$/} m#(?:^|;)\s*\b(?:$tipo)\s*:\s*([\w, ]+)\s*;#gsm;
   push(@var, split /\s*,\s*/, join ",", @varB);

   my $redef = (grep{my $v=$_; 1 < grep {$v eq $_} @var} @var)[0];
   die qq#Variavel "$redef" redefinida!$/# if defined $redef;

   my $err_var = (grep{!/^[a-z,A-Z]/} @var)[0];
   die qq#Nome invalido da variavel "$err_var".$/# if defined $err_var;

   my($t, $v);
   my %tipo = m#\s*\b($tipo)\s*:\s*([\w, ]+)\s*;#gsmx;
   #my %tipo = m#(?:^|;)\s*\b($tipo)\s*:\s*([\w, ]+)\s*;#gsmx;
   for my $t(keys %tipo){
      $_ = "use perltugues::$t;$/" . $_;
   }
   #s#((?:^|;)\s*)\b($tipo)\s*:\s*([\w, ]+)\s*;
   s#(\s*)\b($tipo)\s*:\s*([\w, ]+)\s*;
    #$1 . join$/,map{"my \$$_ = perltugues::$2->new;"}split/\s*,\s*/, $3
    #gesmx;
   for my $var(@var){
      s/([^\$])\b$var\s*=\s*((['"])?.*?\3?)\s*;/$1\$$var->vale($2);/g;
      s/([^\$])\b$var\b/$1\$$var/g;
   }

};

42;
__END__
=encoding utf8

=head1 NAME

perltugues - pragma para programar usando português estruturado

=head1 VERSION

0.19

=head1 SYNOPSIS

    use perltugues;
    
    inteiro: i, j;
    texto: k;
    inteiro: l;
    
    para i (de 1 a 100 a cada 5) {
       escreva i, quebra de linha;
       k = "lalala";
       escreva k, quebra de linha;
       escreva j, quebra de linha;
    }
    
    enquanto(i >= j){
       escreva 'i e j => ', i, " >= ", j++, quebra de linha;
    }
    
    escreva quebra de linha; 
    
    escreva de 0 a 50 a cada 10, quebra de linha;

=head1 DESCRIPTION

C<Perltugues> é uma forma facil de se aprender algoritmo. Com ele você tem uma "linguagem" (quase) completa em português, o que facilita muito a aprendizagempor pseudocódigo. E a transição para o C<perl> é muito simples.

=head2 Declarações

Declarações em C<Perltugues> são separadas por ponto-e-vírgula (C<;>)

=head2 Blocos

Podemos criar blocos com chaves:

  {
	  ...
  }

ou com declarações de início e fim:

  inicio:
      ...
  fim

O sinal de dois pontos (C<:>) antes de "inicio" é opcional.

=head2 Variáveis

Todos os nomes de variáveis em C<perltugues> devem começar com uma letra (/^[a-zA-Z]/). Existem quatro tipos de variáveis que podem ser usados:

=head3 caractere

Armazena um único caractere.

=head3 texto

Armazena uma sequência (string) de caracteres, de qualquer tamanho.

=head3 inteiro

Armazena números inteiros.

=head3 real

Armazena números reais (ponto flutuante).


=head3 Declaração de variáveis

Variáveis são declaradas da seguinte forma:

    inteiro: i;
    inteiro: j;

    inteiro: i, j;

    texto: str;

    caractere: chr1, chr2;


=head2 Entrada e Saída

=head3 escreve

=head3 escreva

=head3 leia

=head2 Estruturas condicionais

=head3 se

   se a > b {
	   ...
   }

Executa o bloco apenas se a expressão fornecida for verdadeira. Note que, em qualquer estrutura do C<perltugues>, parêntesis envolvendo a expressão são opcionais (i.e., no exemplo acima, as expressões C<< a > b >> e C<< (a > b) >> são aceitas da mesma forma.


=head3 a não ser que

=head3 a nao ser que

   TODO

=head2 Estruturas de Iteração (laços):

=head3 para

A estrutura C<para> atribui a uma variável a sequência de valores definida. Por exemplo, o trecho de código:

    para i (de 1 a 10) {
        ...
    }

realizará o bloco entre chaves 10 vezes e, para cada vez, atribuirá o valor à variável determinada (no caso, C<i>).

Nessa construção é possivel ainda utilizar a expressão 'a cada X', onde X indica quantos elementos serão pulados a cada iteração. Por exemplo:

   para i de 1 a 10 a cada 2 {
	   ...
   }

executará com os valores 1, 3, 5, 7 e 9. 

=head3 enquanto

    enquanto i != j {
        ...
    }

Executa o bloco enquanto a expressão definida for verdadeira.

=head3 ateh que

=head3 até que

=head3 ate que

    ateh que i == j {
        ...
    }

Executa o bloco até que a expressão fornecida seja verdadeira. Note que o "que" é opcional, então:

    até (i == j) {
		...
	}

produz o mesmo resultado que o exemplo anterior. Para facilitar ainda mais a legibilidade de seus algoritmos, é possível usar apenas o 'q' como um sinônimo para 'que'. As mesmas regras do 'que' valem para todas as expressões do C<perltugues> que a utilize em sua sintaxe.

=head3 controlando o fluxo de seus laços

Algumas expressões podem ser usadas para controlar o fluxo dos laços. Em casos de laços aninhados, elas serão aplicadas sempre em relação ao laço mais específico. Para tratar laços externos, é possível rotulá-los e referenciar o rótulo. As expressões são:

=head4 saia do laço

=head4 saia do laco

=head4 saia do loop

sai do laço completamente.

=head4 próximo

=head4 proximo

inicia a próxima iteração no laço.

=head4 de novo

=head4 refaça

=head4 refaca

executa novamente o laço, mas sem reavaliar a condição.


   enquanto (CONDICAO) {  # <-- "próximo" vem para cá
      # <-- "de novo" vem para cá
      ...
   }
   # <-- "saia do laço" vem para cá


=head4 vá para ROTULO

=head4 va para ROTULO

posiciona o fluxo do seu código em um local arbitrário do mesmo, definido a partir de um rótulo.

  INICIO: 
  ...
  vá para INICIO;


=head1 AUTHOR

Fernando Correa de Oliveira <fco@cpan.org>


=head1 CONTRIBUTORS

Breno G. de Oliveira


=head1 LICENSE AND COPYRIGHT

Copyright 2008 Fernanco Correa de Oliveira C<< <fco at cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


