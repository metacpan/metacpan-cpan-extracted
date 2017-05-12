#!/usr/bin/perl
use strict;
use LEOCHARRE::CLI2 'OCsx';
use LEOCHARRE::Debug;

sub usage {
   qq{

   -O print as pod
   -C print as perl code
   -s just show server methods
   -x just show xmlrpc methods

   };
}


my $in = $ARGV[0];
$in and ( $in=~/php$/ or die("arg in must be .php file") );

$in ||= './t/xmlrpc.php';

debug("File in : $in");

# INIT SOURCE
#
open(FILE,'<', $in ) or die;
my @src_lines = <FILE>;
close FILE;

debug("got $#src_lines lines.");

my $src_code = join( "\n", @src_lines);

debug('length'.length $src_code );


my($POD,$CODE,$OUT) = (
q{
=pod

=head1 NAME

name

=head1 DESCRIPTION

=head1 XML RPC METHODS

},
q{package name;
use strict;
use Carp;

},
undef
);


# EXAMINE SOURCE
my @perl_method_names;
my @external_method_names;
my $external_method_names={};
my $_imethod=qr/\w+\.\w+/o;

while( $src_code=~/'($_imethod)'\s*=>\s*'this:(\w+)'/g ){ #\s*=>\s*'$ismethod'/ ){
   push @external_method_names, $1;
   $external_method_names->{$1} = $2;
}






my $functs = __init_functions(\@src_lines);
my $functs_args = __init_function_args();

# choose which we want to view

my @interesting_methods = grep { /^wp\.|^metaWeblog/ } @external_method_names;

for (@interesting_methods) {
   _analize_method($_);
}

# just show xmlrpc methods?
$opt_s and print "@external_method_names\n" and exit;
$opt_x and print "@perl_method_names\n" and exit;

# close the outputs


$CODE.= sprintf q/

sub server {
   my $self = shift;
   unless( $self->{_server} ){
      $self->proxy or croak('missing proxy');
      require XMLRPC::Lite;

      $self->{_server} ||= XMLRPC::Lite->proxy( $self->proxy );
   }
   return $self->{_server};
}


sub _call_has_fault {
   my $call = shift;
   my $err = $call->fault or return 0;
   
   for( keys %$err ){
      print STDERR "ERROR:$_ $$err{$_}\n";
   }
   return 1;
}

sub server_methods {
   my $self = shift;
   return qw(%s);   
}

sub xmlrpc_methods {
   my $self = shift;
   return qw(%s);
}


/, 
join(' ',@external_method_names),
join(' ',@perl_method_names);

$CODE.="\n1;\n\n__END__\n\n";
$POD.= '

=head1 METHODS

=head2 server_methods()

returns array of server methods accessible via xmlrpc.

=head2 xmlrpc_methods()

returns array of methods in this package that make calls via xmlrpc

'.
"\n=head1 AUTHOR\n\n=head1 BUGS\n\n=head1 CAVEATS\n\n=head1 SEE ALSO\n\n=cut\n";

no warnings;
print $OUT if !($opt_O + $opt_C);
print $CODE if $opt_C;
print $POD if $opt_O;







exit;




sub _analize_method {
   my ($external_method_name) = shift;
   my $internal_method_name = $external_method_names->{$external_method_name} or die;

   my $suggested_perl_name = $external_method_name;
   $suggested_perl_name=~s/^.+\.//;
   push @perl_method_names, $suggested_perl_name;
   
   if( !$opt_O and !$opt_C ){

      my $args;
      my $argcount;
      if( my $_args = $functs_args->{$internal_method_name} ){
         $args = join ', ',@$_args;
         $argcount = scalar @$_args;
      }


      $OUT.=         "external name: '$external_method_name'\n";
      $OUT.=         "internal name: function $internal_method_name()\n";
      $OUT.=         "    perl name: $suggested_perl_name\n";
      $OUT.=(sprintf "      %s args: %s\n", $argcount, $args ) if $args;

      if ($opt_d){
         my $code = $functs->{$internal_method_name};
         if($code and scalar @$code){
            $OUT.= "code:yes\n";
            $OUT.= "@$code\n";
         }
      }
   }

   elsif ($opt_O or $opt_C){  # if P(O)D or CODE OO
      my $_all_args = $functs_args->{$internal_method_name};

      my @_args = grep { ! _call_arg_should_be_method($_) } 
         @{$functs_args->{$internal_method_name}}; # leave out args fed by oo
      

      if($opt_C){


         my $code = "# xmlrpc.php: function $internal_method_name\nsub $suggested_perl_name {\n";
         $code.=    "\tmy \$self = shift;\n";
         my @call_args;

         for my $_argname ( @$_all_args ){
            my $argname= lc($_argname);
            push @call_args, $argname;

            if (my $object_method = _call_arg_should_be_method($_argname)){
               
               $code.= "\tmy \$$argname = \$self->$object_method;\n";
            }
            else {
               $code.= "\tmy \$$argname = shift;\n";
            }
         }
         $code.="\n";

         # the call
         $code.="\tmy \$call = \$self->server->call(\n\t\t'$external_method_name',\n";
         for my $a (@call_args){
            $code.="\t\t\$$a,\n";
         }
         $code.="\t);\n\n";

         $code.="\tif (_call_has_fault(\$call)){\n";
         $code.="\t\treturn;\n";
         $code.="\t}\n\n";

         $code.="\tmy \$result = \$call->result;\n";
         $code.="\tdefined \$result\n\t\tor die('no result');\n\n";
         $code.="\treturn \$result;\n";
         $code.="}\n\n";
      
         $CODE.= $code;      

      }

      if($opt_O){
         $POD.= "=head2 $suggested_perl_name()\n\n";
         $POD.=(sprintf "takes %s args: %s\n\n", scalar @_args, join(', ',@_args) ) if @_args;
         #$POD.= "\n";#=cut\n\n";
      }

   }



   $OUT.= "\n\n";
}

sub _call_arg_should_be_method {
   my $name = shift;

   return 'blog_id' if $name=~/blog_id/i;

   return 'username' if $name=~/user_login|username/i;

   return 'password' if $name=~/user_pass|password/i;

   return;
}

sub _functions { # the internal function names
   my @inames = keys %$functs; #internal php function  names
   return @inames;   
}


sub _function_lines { # name in php file
   my $imethod = shift;
   my $codelines = $functs->{$imethod} or return;
   scalar @$codelines or return;
   return @$codelines;
}




sub __init_function_args {
   my $hash={};

   METHOD: for my $imethod (_functions()){
      my @codelines = _function_lines($imethod) or next METHOD;

      my @args;
      for my $line (@codelines){
         if( $line=~/\$(\w+)\s*\=\s*.+\$args\[(\d)\];/ ){
            my $argname = $1;
            my $num= $2;
            #debug("$argname $num");
            push @args, $argname;
            #$args[$num] = $argname;
         }
      }
      $hash->{$imethod} = \@args;
   }

   # what type of arg is it??

   return $hash; 
}


sub __init_functions {
   my $src_lines = shift;

   my $hash={};

   my $function_lines;
   my $function_name;
   
   

   LINE: for my $_line (@$src_lines){

      if($_line=~/function (\w+)\(/){
         $function_name = $1;
      }
      
      if(defined $function_name){
         push @{$hash->{$function_name}}, $_line;
      }
   

   }


   return $hash;


}

__END__


for(@src_lines){
   



}





