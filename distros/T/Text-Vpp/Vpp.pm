############################################################
#
# $Header: /home/domi/perlDev/Text_Vpp/RCS/Vpp.pm,v 1.27 2005/06/09 13:52:13 domi Exp $
#
# $Source: /home/domi/perlDev/Text_Vpp/RCS/Vpp.pm,v $
# $Revision: 1.27 $
# $Locker:  $
# 
############################################################

package Text::Vpp;

require 5.6.0;
use strict;
use vars qw($VERSION);
use IO::File ;
use Carp ;

use AutoLoader qw/AUTOLOAD/ ;

$VERSION = '1.17' ;

# tiny FiFo "package"

sub F_new  { return [1]; }

sub F_reset { my $FiFo = $_[0]; $FiFo->[0]= 1; $#$FiFo= 0; }

sub F_tell { return $_[0]->[0]; }

sub F_seek { $_[0]->[0]= $_[1]; }

sub F_print { push @{$_[0]}, $_[1]; }

sub F_getline { my $FiFo = $_[0]; return $FiFo->[($FiFo->[0])++]; }

#---------------------


sub new
  {
    my $type = shift ;
	
    my $self      = {} ;
    my $file      = shift ;
    my $ref       = shift ;
    my $action    = shift ;
    my $comment   = shift ;
    my $prefix    = shift;
    my $suffix    = shift;
    my $substitute= shift;
    my $backslash = shift;
    
    if (defined $ref && (ref($ref) eq "HASH"))
      {
        $self->{var} = $ref ;
      }
    
    $self->{action}    = defined $action    ? $action    : '@' ;
    $self->{comment}   = defined $comment   ? $comment   : '#' ;
    $prefix= '$'  unless defined($prefix); #';  # for xemacs
    $self->{prefix}    = $prefix ;
    $self->{suffix}    = $suffix;
    $self->{substitute}= $substitute;
    $self->{backslash} = defined $backslash ? $backslash :  1  ;
    if ( UNIVERSAL::can($file,'getline') )
      { $self->{fileDesc}= $file; $self->{name}= ref($file); }
    else
      { $self->{fileDesc} = new IO::File;
        $self->{fileDesc}->open($file) || die "can't open $file \n";
        $self->{name} = $file ;
      }

    $self->{Fifo}= F_new;
	
    $self= bless $self,$type ;

    $self->setActionChar($self->{action});
    $self->setPrefixChar($self->{prefix});
    $self->setSuffixChar($self->{suffix});
    $self->setSubstitute($self->{substitute});
    $self->setCommentChar($self->{comment});
    
    return $self;
  }


sub myEval 
  {
    my $self = shift ;
    my $expression = shift ;
    my $out = shift ;

    # transform each $xxx into $self->{var}{$xxx}
    # this allows for the creation of new variables
    # one may use the construction ${\w} to protect against this
    $expression =~ s[\$(\w+)\b] [\$self->{var}{$1}]g ;

    local *Vpp_Out= ref $out ? sub{push @$out,@_;} : 
      sub {die "Cannot call Vpp_Out in \@INCLUDE line";} ;
    my $return = eval($expression) ;

    if ($@ ne "") 
      {
        die "Error in eval : $@ \n",
        "line : $expression \nfile: $self->{name} line $.\n";
      }

    return ($return);
  }

sub ReplaceVars
  {
    my $self = shift ;

    $_[0] =~ s[\$({?)(\w+)\b(}?)]
      [if (defined($self->{var}{$2}))
       { "\$self->{var}{$2}" . ( !$1 ? $3 : '' ); }
       else {"\$$1$2$3";}
      ]ge ;

  }

sub myExpression
  {
    my $self = shift ;
    my $expression = shift ;
	
    $self->ReplaceVars($expression);
	
    my $return = eval($expression) ;
	
    if ($@ ne "") 
      {
        die "Error in eval : $@ \n",
        "line : $expression \nfile: $self->{name} line $.\n";
      }

    return ($return);
  }


sub substitute
  {
    #return array ref made of new file
    my ($self,$fileOut) = @_ ;
    
    $self->{errorText} = [] ;
    $self->{error} = 0;
    
    $self->{IF_Level}= 0;  $self->{FOR_Level}= 0;
    
    my $res = $self->processBlock(1,1,0,0,0) ;

    chomp @$res ;

    if (defined $fileOut)
      { 
        if ( UNIVERSAL::can($fileOut,'print') )
          { 
            $fileOut->print(join("\n",@$res) ,"\n") ; 
          }
        else
          { 
            print "writing $fileOut\n";
            my $FileOut = $fileOut;
            $FileOut= ">$fileOut"  unless $fileOut =~/^>/;
            my $SubsOut = new IO::File;
            unless( $SubsOut->open($FileOut) )
              {
                $self->snitch("cannot open $fileOut") ;
                return 0 ;
              }
            print $SubsOut join("\n",@$res) ,"\n" ;
            close $SubsOut ;
          }
      }
    else
      {
        $self->{result} = $res ;
      }
    
    return  (not $self->{error} ) ;
  }

sub getText
  {
    my $self = shift ;
    return $self->{result} ;
  }

sub getErrors
  {
    my $self = shift  ;
    return $self->{errorText} ;
  }

sub Vpp_Out {croak "Original Vpp_Out called";}

sub do_shell
  {
    my $self=shift;
    my $shell_code = shift;
    my $out= `$shell_code`;
    warn "Error in SHELL code : status is $? \n",
      "in file: $self->{name} line $.\n",
        "code was\n$shell_code"  if  $? > 0;
    split(/\n/,$out) ;
  }

sub processBlock 
  {
	# three parameters :
	# GlobExpand : false if nothing should be expanded
	# Expand : true if the calling ifdef is true
    my ($self,$globExpand,$expand,$EnterLoop,$useFiFo,$ScanOnly)=@_ ;
    $expand= 0  unless $globExpand;
    my $FiFo      = $self->{Fifo};
    
    my $out = [] ;
    
    # Done is used to evaluate the elsif
    my ($done) = $expand ;
    
    # Stage is used for syntax check
    my ($stage) = ($self->{IF_Level} == 0 || $EnterLoop) ? 0 : 1 ;
    
    my ($line,$keep,$SubsIt) ;
    local $/ = "\n";            # revert to standard line ending
    
    my $Within_Perl_Input = 0;
    my $Perl_Input_Termination;
    my $Perl_Code;

    my $Within_Shell_Input = 0;
    my $Shell_Input_Termination;
    my $Shell_Code;

    # attention: keep the following declaration in sync with
    #            the assignments whence processing 'EVAL' line
    my $action    = $self->{action} ;
    my $comment   = $self->{comment};
    my $prefix    = $self->{prefix} ;
    my $suffix    = $self->{suffix} ;
    my $substitute= $self->{substitute};
    my $backslash = $self->{backslash};
    my $VarPat    = $self->{VarPat};
    my $commentPat = $self->{commentPat};
    my $actionPat  = $self->{actionPat};
    my $ifPat      = $self->{ifPat};
    my $elsifPat   = $self->{elsifPat};
    my $elsePat    = $self->{elsePat};
    my $endifPat   = $self->{endifPat};
    my $includePat = $self->{includePat};
    my $evalPat    = $self->{evalPat};
    my $quotePat   = $self->{quotePat};
    my $endquotePat= $self->{endquotePat};
    my $subsPat    = $self->{subsPat};
    my $subsLeadPat= $self->{subsLeadPat};
    my $foreachPat = $self->{foreachPat};
    my $endforPat  = $self->{endforPat};
    my $perlPat    = $self->{perlPat};
    my $shellPat  = $self->{shellPat};

    if ( $useFiFo )
      { 
        $line= F_getline($FiFo); 
      }
    else 
      { 
        $line = $self->{fileDesc}->getline;
        F_print($FiFo,$line)  if  $ScanOnly;
      }
    
    while (defined($line)) 
      {
        if ( $Within_Perl_Input ) {
          if ( $line =~ /$Perl_Input_Termination/ ) {
            $Within_Perl_Input= 0;
            if ( $expand ) {
	      # $VAR may be used in eval'ed code
	      my $VAR = $self->{var} ;
	      local *Vpp_Out= sub {push @$out, @_; };
              my $res = eval($Perl_Code);
              die "Error in eval(uating) PERL code : $@ \n",
                "in file: $self->{name} line $.\n",
                "code was\n$Perl_Code"  if  $@;
            }
          } else {
            $Perl_Code.= $line;
          }
          next;
        }

        if ( $Within_Shell_Input ) {
          if ( $line =~ /$Shell_Input_Termination/ ) {
            $Within_Shell_Input= 0;
            push (@$out, $self->do_shell($Shell_Code)) if ( $expand );
          } else {
            $Shell_Code.= $line;
          }
          next;
        }

        chomp($line);
        #skip commented lines
        next if (defined $commentPat and $line =~ $commentPat);
		
        # get following line if the line is ended by \
        # (followed by tab or whitespaces)
        if ($backslash == 1 and $line =~ s/\\\s*$//) 
          {
            $keep .= $line ;
            next ;
          }
        
        my $lineIn;
        if (defined $keep)
          {
            $lineIn = $keep.$line ;
            undef $keep ;
          } 
        else
          {
            $lineIn = $line ;
          }
        
        study $lineIn;
        if ($lineIn =~ s/$ifPat//i) 
          {
            # process the lines after the IF,
            # don't evaluate the boolean expression if  ! $expand
            my ($expandLoc) = $expand && $self->myExpression($lineIn) ;
            my $Current_IF_Level = $self->{IF_Level}++;
            push @$out, 
            @{$self->processBlock($expand,$expandLoc,0,$useFiFo,$ScanOnly)};

            if ( $self->{IF_Level} != $Current_IF_Level )
              { 
                $self->snitch("illegal nesting of FOREACH and IF"); return [];
	      }
          }
        elsif ($lineIn =~ s/$elsifPat//) 
          {
            # process the lines after the ELSIF, done is set if the block
            # is expanded
            unless ($stage == 1 or $stage ==2) 
              {
                $self->snitch("unexpected elsif");
              }
            $stage = 2 ;
            if ( $done )       # if-condition was true
              { $expand= 0; }  # now we are in the else
            else
              { # if-condition was false, so here we have a new chance
                $expand = $globExpand  &&  $self->myExpression($lineIn) ;
                $done = $expand ;
              }
          }
        elsif ($lineIn =~ $elsePat) 
          {
            if ($stage == 0 || $stage == 3 ) 
              {
                $self->snitch("unexpected else");
              }
            $stage = 3 ;
            $expand = $globExpand  &&  !$done ;
          } 
        elsif ($lineIn =~ $endifPat) 
          {
            if ($stage == 0) {$self->snitch("unexpected endif");}
            $self->{IF_Level}--;
            return $out ;
          }
        elsif ($lineIn =~ s/$foreachPat//)
          { 
            my ($emptyLoop,$Current_FOR_Level,$Start_of_Loop) 
              = (1,$self->{FOR_Level},1);

            if ( $expand )
              { 
                my $LoopExpr = $lineIn;
                $LoopExpr =~ s/^\s*my\s//;  # remove my if there
                my $LoopVar ;
		$LoopVar = $1 if $LoopExpr =~ s/\$(\w+)//;

                $self->ReplaceVars($LoopExpr);
                my @LoopList= eval $LoopExpr;
                if ( $@ ) 
                  { 
                    die "Error in FOREACH-List-Expression: $@\n",
                    "line : $lineIn\nfile: $self->{name} line $.\n";
                  }
                $emptyLoop= scalar(@LoopList) == 0;

                unless ($emptyLoop)
                  { 
                    if ( $self->{FOR_Level} == 0 )
                      { 
                        F_reset($FiFo);
                        $self->{FOR_Level}++;
                        $self->processBlock(0,0,1,0,1); # Scan Only
                        if ( $Current_FOR_Level != $self->{FOR_Level} )
                          { 
                            $self->snitch("illegal nesting for IF and FOREACH"); 
                            return []; 
                          }
                        $Start_of_Loop= 1;
                      }
                    else { $Start_of_Loop= F_tell($FiFo); }

                    foreach my $LpVar (@LoopList)
                      { 
                        $self->{var}{$LoopVar}= $LpVar;
                        $self->{FOR_Level}++;
                        F_seek($FiFo,$Start_of_Loop);

                        push @$out, @{$self->processBlock(1,1,1,1,0)} ;

                        if ( $Current_FOR_Level != $self->{FOR_Level} )
                          { 
                            $self->snitch("illegal nesting for IF and FOREACH"); 
                            return []; 
                          }
                      }
                  }
              }

            if ($emptyLoop) # loop has never been executed
              { 
                if ( $self->{FOR_Level} == 0 )
                  { 
                    $self->{FOR_Level}++;
                    $self->processBlock(0,0,1,0,0); # just skip
                  }
                else
                  { 
                    $self->{FOR_Level}++;
                    $self->processBlock(0,0,1,$useFiFo,$ScanOnly); # process but don't expand
                  }
                if ( $Current_FOR_Level != $self->{FOR_Level} )
                  { 
                    $self->snitch("illegal nesting for IF and FOREACH"); 
                    return []; 
                  }
              }
          }
        elsif ($lineIn =~ $endforPat)
          {  
            $self->{FOR_Level}--; return $out;
          }
        elsif ($lineIn =~ $includePat)
          { 
            if ( $expand )
              {
                # look like we've got a new file to slurp
                $lineIn =~ s/$includePat//;
                my $newFile;
                my $Incl = $lineIn =~ /^[\w_\-.]+$/ ? 
                  $lineIn : $self->myEval($lineIn);

                if ( ref($Incl) eq 'HASH' )
                  { 
                    $Incl->{action}=	$action     unless defined $Incl->{action};
                    $Incl->{comment}=	$comment    unless defined $Incl->{comment};
                    $Incl->{prefix}=	$prefix     unless defined $Incl->{prefix};
                    $Incl->{suffix}=	$suffix     unless defined $Incl->{suffix};
                    $Incl->{substitute}=    $substitute unless defined $Incl->{substitute};
                    $Incl->{backslash}=	$backslash  unless defined $Incl->{backslash};
                    unless ( defined $Incl->{file} )
                      { 
                        $self->snitch("illegal file at include $lineIn");  
                        return []; 
                      }
                        
                    $newFile =  Text::Vpp-> new ($Incl->{file}, $self->{var},
                                                 $Incl->{action}, $Incl->{comment},
                                                 $Incl->{prefix}, $Incl->{suffix},
                                                 $Incl->{substitute}, $Incl->{backslash});
                  }
                else
                  { 
                    $newFile =  Text::Vpp-> new ($Incl, $self->{var},
				                 $action,$comment,$prefix,$suffix,
                                                 $substitute,$backslash) ;
                  }

                if ($newFile->substitute())
                  {
                    my $res = $newFile->getText() ;
                    push @$out, @$res ;
                  } 
                else
                  {
                    # an error occured
                    push @{$self->{errorText}}, @{$newFile->getErrors()} ;
                    $self->{error} = 1;
                    return $out  ;
                  }
                undef $newFile ;
              }
          }
        elsif ($lineIn =~ s/$evalPat//)
          {
            if ( $expand ) {$self->myEval($lineIn, $out);}

            # reassign in case there was a change to some
            # of the following
            # attention: keep the following assignments in sync with
            #            with the declarations at the beginning of this sub
            $action     = $self->{action} ;
            $comment    = $self->{comment};
            $prefix     = $self->{prefix} ;
            $suffix     = $self->{suffix} ;
            $substitute = $self->{substitute};
            $backslash  = $self->{backslash};
            $VarPat     = $self->{VarPat};
            $commentPat = $self->{commentPat};
            $actionPat  = $self->{actionPat};
            $ifPat      = $self->{ifPat};
            $elsifPat   = $self->{elsifPat};
            $elsePat    = $self->{elsePat};
            $endifPat   = $self->{endifPat};
            $includePat = $self->{includePat};
            $evalPat    = $self->{evalPat};
            $quotePat   = $self->{quotePat};
            $endquotePat= $self->{endquotePat};
            $subsPat    = $self->{subsPat};
            $subsLeadPat= $self->{subsLeadPat};
            $foreachPat = $self->{foreachPat};
            $endforPat  = $self->{endforPat};
            $perlPat    = $self->{perlPat};
            $shellPat   = $self->{shellPat};
          }
        elsif ($lineIn =~ s/$perlPat//)
          {  $Within_Perl_Input= 1;
             $Perl_Code= "";
             $lineIn =~ s/\s*$//;
             $Perl_Input_Termination= qr/$lineIn/;
          }
        elsif ($lineIn =~ s/$shellPat//)
          {  
            if ($lineIn =~ s/<<\s*//)
              {
                $Within_Shell_Input= 1;
                $Shell_Code= "";
                $lineIn =~ s/\s*$//;
                $Shell_Input_Termination= qr/$lineIn/;
              }
            else
              {
                push @$out, $self->do_shell($lineIn);
              }
          }
        elsif ( $lineIn =~ /$quotePat/ )
          { 
            my $Str = $lineIn; $Str =~ s/$quotePat//;
            my ($ListSeparator,$ListPrefix);
            #  format   @QUOTE (ListPrefix,ListSeparator)
            if ( $Str =~ /^\(/ )
              {
                if ( $Str =~ /^\(\s*(\S)([^\1]*?)\1\s*(?:,\s*(\S)([^\2]*?)\3\s*\))?/ )
                  { $ListPrefix= $2; $ListSeparator= $4; }
                else { $self->snitch("illegal QUOTE action : $lineIn"); }
              }
            $Str= '';
            
            while(1)
              { 
                if ( $useFiFo ) { $line= F_getline($FiFo); }
                else 
                  { 
                    $line = $self->{fileDesc}->getline;
                    F_print($FiFo,$line)  if  $ScanOnly;
                  }
                last if $line =~ $endquotePat;
                
                unless ( defined $line )
                  { 
                    $self->snitch("EOF while scanning QUOTE"); 
                    return []; 
                  }

                $Str.= $line if ( $expand );
              }
                    
            if ( $expand )
              { 
                # protect '$' and '@'
                if ( "$prefix$suffix" !~ /\$/  
                     && ( !defined($ListPrefix)  || $ListPrefix !~ /\$/ ) )
                  { $Str =~ s/(?<!\\)\$/\\\$/g; }
                
                if ( "$prefix$suffix" !~ /\@/  
                     && ( !defined($ListPrefix)  || $ListPrefix !~ /\@/ ) )
                  { $Str =~ s/(?<!\\)\@/\\\@/g; }
                      
                if ( defined $ListPrefix ) { $Str =~ s/\Q$ListPrefix\E/\@/g; }

                # substitute variables
                if ( defined $suffix )
                  {
                    $Str =~ s[$VarPat][\$self->{var}{$1}]g;
                  }
                else
                  {
                    $Str =~ s[$VarPat]
                      [ { "\$self->{var}{$2}" . ( !$1 ? $3 : '' ) ;} ]ge ;
                  }
                
                if ( defined $ListSeparator )
                  { local $"= $ListSeparator; $Str = eval("qq($Str)"); }
                else { $Str = eval("qq($Str)"); }
                
                if ($@ ne "")
                  {
                    die "Error in QUOTE/eval : $@ \n",
                    "expression:\n$Str\n\nfile: $self->{name} line $.\n";
                  }
                
                chomp $Str;
                push @$out, split /\n/,$Str;
              }
          }
        elsif ( $SubsIt=($lineIn =~ $subsLeadPat)  ||  $lineIn !~ $actionPat )
          {
            # process the line
            if ($expand) 
              { 
                if ( $SubsIt )  # eval substitution parts
                  { 
                    $lineIn =~ s/$subsPat/$self->myExpression($1)/ge;
                  }
                            
                # substitute variables
                if ( defined $suffix )
                  {
                    $lineIn =~ s[$VarPat]
                      [ if (defined($self->{var}{$1})) 
                        { $self->{var}{$1};}
                        else    {"$prefix$1$suffix"  ;}
                      ]ge ;
                  }
                else
                  {
                    $lineIn =~ s[$VarPat]
                      [ if (defined($self->{var}{$2})) 
                        { $self->{var}{$2} . ( !$1 ? $3 : '' ) ;}
                        else    {"$prefix$1$2$3"  ;}
                      ]ge ;
                  }
                
                push @$out, $lineIn ;
              }
          }
        else
          {
            $self->snitch("Unknown command :$lineIn") ;
          }
      }
    
    continue
      { 
        if ( $useFiFo ) 
          { $line= F_getline($FiFo); }
        else 
          { 
            $line = $self->{fileDesc}->getline;
            F_print($FiFo,$line)  if  $ScanOnly;
          }
      }

	
    if ($self->{IF_Level} > 0 ) 
      {
        $self->snitch("Finished inside a conditionnal block");
      }
    elsif ( $self->{FOR_Level} > 0 ) 
      {
        $self->snitch("Finished inside a FOREACH block");
      }

    return $out ;
  }

1;

__END__


# Preloaded methods go here.

=head1 NAME

Text::Vpp - Perl extension for a versatile text pre-processor

=head1 SYNOPSIS

 use Text::Vpp ;

 $fin = Text::Vpp-> new('input_file_name') ;

 $fin->setVar('one_variable_name' => 'value_one', 
              'another_variable_name' => 'value_two') ;

 $res = $fin -> substitute ; # or directly $fin -> substitute('file_out') 

 die "Vpp error ",$fin->getErrors,"\n" unless $res ;

 $fout = $fin->getText ;

 print "Result is : \n\n",join("\n",@$fout) ,"\n";

=head1 DESCRIPTION

This class enables to preprocess a file a bit like cpp. 

First you create a Vpp object passing the name of the file to process, then
you call setvar() to set the variables you need.

Finally you call substitute on the Vpp object. 

=head1 NON-DESCRIPTION

Note that it's not designed to replace the well known cpp. Note also
that if you think of using it to pre-process a perl script, you're
likely to shoot yourself in the foot. Perl has a lot of built-in
mechanisms so that a pre-processor is not necessary for most cases.

On the other hand some advanced perl users do use Vpp to pre-process their
code to gain speed. But in this case you should really think hard about the
maintenance of your code. Adding Vpp syntax in your code will make it
more difficult to maintain. Even more so if the code maintainer will not
be yourself. Furthermore, the build procedure may also be more complex.
So please, do consider the trade-off between speed and complexity.

=head1 INPUT FILE SYNTAX

=head2 Comments

All lines beginning with '#' are skipped. (May be changed with 
setCommentChar())

When setActionChar() is called with '#' as a parameter, Vpp doesn't 
skip lines beginning with '#'. In this case, there's no comment possible.

=head2 in-line eval

Lines beginning with '@EVAL' (@ being pompously named the 'action char') 
are evaluated as small perl script. 
If a line contains (multiple) @@ Perl-Expression @@ constructs these
are replaced by the value of that Perl-Expression.
You can access all (non-lexically scoped) variables and subroutines from
any Perl package iff you use fully qualified names, i.e. for a subroutine
I<foo> in package I<main>  use  I<::foo> or I<main::foo>
To call one of the methods of a Vpp-object, like setActionChar, this
has to called as  "${self}-E<gt>setActionChar('@');"
Be sure you know what you do, if you call such methods from within
an @EVAL line.

=head2 Multi-line input

Lines ending with \ are concatenated with the following line.

=head2 Variables substitution

You can specify variables in your text beginning with $ (like in perl,
but may be changed with setPrefixChar() ) and optionally ending
in a Suffix which can be specified by setSuffixChar().
These variables can be set either by the setVar() method, the
setVarFromFile() method or by the 'eval' capability of Vpp (See below).

=head2 Advanced variables substitution

To use more complicated variables like hash or array accesses you have to
use either the 'in-line eval' above or a cheaper and more convenient
method. For that you can 'QUOTE' lines like

 @QUOTE
 any lines
 @ENDQUOTE

or

 @QUOTE ( ListPrefix [,ListSeparator] )
 any lines
 @ENDQUOTE

In both cases the lines between the '@QUOTE' and '@ENDQUOTE' are
concatenated while keeping the end-of-line character.

In the resulting string all '$' are protected unless $prefix or $suffix
or $ListPrefix contains a '$'. Furthermore all '@' are protected unless
one of these variables contains a '@'. 

Then all variables (defined by $prefix/$suffix) are preprocessed to
make them ready for substitution later on.  Likewise $ListPrefix (if
given) is converted to '@'.

Then this possible multiline construct is quoted by Perl's 'qq' and given
to Perl's eval. 

Therefore any constructs which interpolate in a double quoted string,
will interpolate here too, i.e. variable starting with '$' or '@'
(unless protected, see above) and all characters escaped by '\'.

Note the standard trick to interpolate everything within a double
quoted string by using the anonymous array construct " @{[expression]}
".  The $ListSeparator is used to locally set Perl's variable '$"' (or
$LIST_SEPARATOR in module English.pm).  You can take any delimiting
character but not brackets of any sort to delimit either ListPrefix or
ListSeparator .

Note that this feature which raised a lot of discussions between the
Vpp contributors should be considered as 'alpha' stage. We may have
simpler ideas in the future to implement the same functionnality (hint:
all other ideas are welcome). So the interface or the feature itself
may be changed. Contact Helmut for further discussions.

=head2 Output generation by Perl code

For complex generation of output one can specify one or more Perl
subroutines which can be called from within an @PERL statement.
To specify the Perl code you say

 @PERL  <<  Termination_Regexp
 any perl source lines not matching 'Termination_Regexp'
 termination line matching 'Termination_Regexp'

Note, that any output B<have to> use the predefined
Perl sub C<Vpp_Out>. Note, that the subroutine names
should be I<unique> even across included files.
To access the variables set by e.g. setVar, you
B<have to> use the predefined hash-ref C<$VAR>.
Here is an example which generates constants for a
C-program which amount to the probability that you
draw a specified sequence out of a set.

 @PERL << ^END_OF_PERL$
 sub Chances($$) {
   my ($nseq,$num) = @_;
   # compute the chance to draw a sequence of nseq specific balls
   # out of num balls.
   my $chance;
   if ( $nseq > $num ) {
     $chance= 0;
   } else {
     $chance= 1;
     for (my $k=1; $k <= $nseq; $k++) {
       $chance*= $k/($num-$k);
     }
   }
   Vpp_Out("const double chance_${nseq}_of_$num = $chance;");
 }
 END_OF_PERL

This produces no output by itself. Lateron you can use it as

 @EVAL &Chances(7,49)

to produce the C-statement

 const double chance_7_of_49 = 1.35815917929809e-08;

=cut

#'

=head2 Output generation by shell code

For complex generation of output one can also specify one or more shell
commands which can be called from within an @SHELL statement.

To include the output of the shell command into your text, you can
specify: 
 @SHELL [some shell command]

For instance:
 @SHELL ls Vpp.pm

You can also specify a more complex shell command with:
 @SHELL  <<  Termination_Regexp
 any shell code not matching 'Termination_Regexp'
 termination line matching 'Termination_Regexp'

Unlike the @PERL command, there's no need to call Vpp_Out from the
shell code.  All the STDOUT of the shell commands will be included in
the text.

=head2 Setting variables

Lines beginning by @ are 'evaled' using variables defined by setVar()
or setVarFromFile(). You can use only scalar variables. This way, you can
also define variables in your text which can be used later.


=head2 Conditional statements

Text::Vpp understands @IF, @ELSIF, @ENDIF,and so on.  @INCLUDE and @IF
can be nested.

@IF and @ELSIF are followed by a Perl expression which will be evaled using
the variables you have defined (either with setVar(), setVarFromFile()
or in an @EVAL line).

=head2 Loop statements

Text::Vpp also understands

@FOREACH $MyLoopVar ( Perl-List-Expression )
... (any) lines which may depend on $MyLoopVar
@ENDFOR

These loops may be nested.

=head2 Inclusion

Text::Vpp understands
@INCLUDE  Filename or Perl-Expression
@INCLUDE { action => '\\', backslash => 0, file => 'add_on.001' }

The file name may be a bare words if it contains only alphanumeric
characters or '-', '.' or '_'. Otherwise, the file name must be quoted.

If the Perl-Expression is a string, it is taken as a
filename. 

If it is an anonymous hash, it must have a value for the key 'file'
and it may have values for 'action', 'comment', 'prefix', 'suffix',
'substitute' and 'backslash'.  If given these values will override the
current values during the processing of the included file.

=head1 Constructor

=head2 new(file, optional_var_hash_ref, ...)

The constructor call
C<new(file, optional_var_hash_ref,optional_action_char,>
C<          optional_comment_char, optional_prefix_char,>
C<          optional_suffix_char, optional_substitute,>
C<                             optional_backslash_switch);>

creates the Vpp object. The file parameter may be a filename or
a blessed reference for an object which "can('getline')".
The second parameter can be a hash containing all
variables needed for the substitute method, the following (optional)
parameters specify the corresponding special characters.

=cut

=head1 Methods

=head2 substitute([output_file])

Perform the substitute, inclusion, and so on and write the result in 
I<output_file>. This maybe a filename or a blessed reference which
"can('print')" .
Returns 1 on completion, 0 in case of an error.

If output_file is not specified this function stores the substitution result
in an internal variable. The result can be retrieved with getText()

 You may prefix the filename with >> to get the output
 appended to an existing file.

=cut

#'

=head2 rewind()

If method 'substitute' is called more than once, you have to call
'rewind' in between.
CAUTION  If you have called method 'new' with a blessed reference
         instead of a filename, you must not call 'rewind' unless
         your object has a 'seek' method. Otherwise you have to do
         actions yourself which simulate 'rewind' for your object.

=cut

sub rewind
  {
    my $self = shift ;
    $self->{fileDesc}->seek(0,0);
  }

=head2 getText()

  Returns an array ref containing the result. You can then get the total
  file with  join "\n",@{VppObj->getText}

=cut

=head2 getErrors()

Returns an array ref containing the errors.

=cut

# Autoload methods go after __END__ and are processed by the autosplit program.

=head2 setVar( key1=> value1, key2 => value2 ,...) or setVar(hash_ref)

Declare variables for the substitute.
Note that calling this function clobbers previously stored values.

=cut

sub setVar 
  {
    my $self = shift ;
    
    if (ref($_[0]) eq 'HASH')
      {
        $self->{var} = shift ;
      }
    else
      {
        %{$self->{var}} = @_ ;
      }
  }

=head2 setVarFromFile( Filename_or_Ref )

Declares a File or an object which can 'getline'.
The file must contain a valid Perl expression yielding an
anonymous hash, as created e.g. by Data::Dumper
Note that calling this function clobbers previously stored values.

=cut

sub setVarFromFile
  {
    my ($self,$file) = @_ ;
    my ($expression, $line) = '';
    
    if ( UNIVERSAL::can($file,'getline') )
      { 
        while ( defined ($line= $file->getline) )
          { $expression.= $line; }
      }
    else
      { 
        my $Input = new IO::File $file
          or die "couldn't find file $file";
        local $/; $expression= <$Input>;
        close $Input;
      }

    require Safe;
    my $SafeObj = Safe->new;
    $self->{var}= $SafeObj->reval($expression);
  }


=head2 setActionChar(char)

Enables the user to use different char as action char. (default @)

Example: setActionChar('#') will enable Vpp to understand #include, #ifdef ..

=cut

sub setActionChar
  {
    my ($self,$action) = @_ ;
    
    $self->{action} 	= $action ;
    $self->{ifPat} 		= qr/^\s*\Q$action\Eif(?=\W)\s*/i;
    $self->{elsePat} 	= qr/^\s*\Q$action\Eelse\s*/i;
    $self->{elsifPat} 	= qr/^\s*\Q$action\Eelsif(?=\W)\s*/i;
    $self->{endifPat} 	= qr/^\s*\Q$action\Eendif\s*/i;
    $self->{includePat} 	= qr/^\s*\Q$action\Einclude(?=\W)\s*/i;
    $self->{evalPat} 	= qr/^\s*\Q$action\Eeval(?=\W)\s*/i;
    $self->{quotePat} 	= qr/^\s*\Q$action\Equote\s*/i;
    $self->{endquotePat} 	= qr/^\Q$action\Eendquote\s*/i;
    $self->{foreachPat} 	= qr/^\s*\Q$action\Eforeach(?=\W)\s*/i;
    $self->{endforPat} 	= qr/^\s*\Q$action\Eendfor\s*/i;
    $self->{perlPat}        = qr/^\s*\Q$action\Eperl\s+<<\s*/i;
    $self->{shellPat}        = qr/^\s*\Q$action\Eshell\s*/i;
    $self->{actionPat} 	= qr/^\s*\Q$action\E\w/; # unknown action
    $self->setSubstitute(undef)  unless defined $self->{substitute}
  }

=head2 setCommentChar(char)

Enables the user to use different char as comment char. (default #)
This value may be set to undef so that no comments are possible.

=cut

sub setCommentChar
  {
    my ($self,$comment) = @_ ;
    if ( defined $comment )
      { $self->{commentPat}= qr/^\s*\Q$comment\E/i; }
    else {$self->{commentPat}= undef; }
    $self->{comment} = $comment;
  }

=head2 setPrefixChar(char)

Enables the user to use different char(s) as prefix char(s), i.e. variables
in your text (only) are prefixed by that character(s) instead of the
default '$'. If no suffix character(s) has been defined (or set to 'undef')
variables may be specified in the form ${variable} where '$' is the
current prefix char(s). This form is necessary, if any character which
is allowed within a name (regexp '\w') immediately follows the variable.
Note, that all variables in 'actions' (like @@ @EVAL @FOREACH @IF)
must still be prefixed by '$'.

=cut

#'

sub setPrefixChar
  {
    my ($self,$prefix) = @_;
    my $suffix;
    $self->{prefix}    = $prefix ;
    if ( defined ($suffix= $self->{suffix}) )
      { $self->{VarPat}= qr/\Q$prefix\E(\w+)\b\Q$suffix\E/; }
    else
      { $self->{VarPat}= qr/\Q$prefix\E({?)(\w+)\b(}?)/; }
  }
                                                         

=head2 setSuffixChar(char)

Enables the user to use different char(s) as suffix char(s), i.e. variables
in your text (only) are suffixed by that character(s).
Note, that all variables in 'actions' (like @@ @EVAL @FOREACH @IF)
don't use this.

=cut

#'

sub setSuffixChar
  {
    my ($self,$suffix) = @_;
    $self->{suffix}    = $suffix ;
    my $prefix = $self->{prefix};
    if ( defined $suffix )
      { $self->{VarPat}= qr/\Q$prefix\E(\w+)\b\Q$suffix\E/; }
    else
      { $self->{VarPat}= qr/\Q$prefix\E({?)(\w+)\b(}?)/; } 
  }
                                                         

=head2 setSubstitute([prefix,suffix])

Enables the user to specify the prefix and suffix used to mark
a Perl expression within the text that will be replaced by its
value. The default value is twice the 'action' char as suffix
and prefix.

=cut

sub setSubstitute
  {
	my ($self,$subs) = @_;
        die "invalid call to setSubstitute : $subs"
          if ( defined($subs) && ref($subs) ne 'ARRAY' );
        
        $self->{substitute}    = $subs ;
        
        if ( defined $subs )
          { my ($subspre,$subssuf) = @$subs;
            $self->{subsPat} = qr/\Q$subspre\E(.*?)\Q$subssuf\E/;
            $self->{subsLeadPat}= qr/\Q$subspre\E/;
          }
        else
          { my $action= $self->{action};
            $self->{subsPat} = qr/\Q$action$action\E(.*?)\Q$action$action\E/;
            $self->{subsLeadPat}= qr/\Q$action$action\E/;
          }
  }


=head2 ignoreBackslash()

By default, line ending with '\' are glued to the following line (like in
ksh). Once this method is called '\' will be left as is.

=cut

sub ignoreBackslash
  {
    my $self =shift ;
	
    $self->{backslash} = 0 ;
  }

sub snitch
  {
    my $self = shift ;
    my $msg = shift ;
    my $emsg = "Error in $self->{name} line ".
      $self->{fileDesc}->input_line_number. " : $msg\n" ;

    push @{$self->{errorText}}, $emsg ;
    $self->{error} = 1;
    warn ($emsg);
  }

=head1 CAVEATS

Version 1.0 now requires files included with '@INCLUDE' to be quoted.
Version 1.1 now requires calls to method 'rewind' if 'substitute' is
called more than once for the same Vpp-object.

=head1 AUTHOR

Dominique Dumont    Dominique_Dumont@grenoble.hp.com

Copyright (c) 1996-2001 Dominique Dumont. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Additional bugs have been introduced by
Helmut Jarausch    jarausch@igpm.rwth-aachen.de

=head1 SEE ALSO

perl(1),Text::Template(3).

=cut
