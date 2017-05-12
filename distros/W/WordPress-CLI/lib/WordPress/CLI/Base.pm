package WordPress::CLI::Base;
use strict;
use vars qw(@EXPORT_OK %EXPORT_TAGS @ISA);
our $VERSION = sprintf "%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)/g;
use LEOCHARRE::Strings ':all';
use Exporter;
@ISA = qw/Exporter/;
@EXPORT_OK = qw/_resolve_cat_arg _date2wordpressdate _wordpress_xmlrpc_object_or_die _opts_from_file/;

%EXPORT_TAGS = ( all => \@EXPORT_OK );


###############################################################################
# pass it the optsref, \%OPT
# this checks login credentials
sub _wordpress_xmlrpc_object_or_die {
   my $href = shift;
   for (qw/u p x/){ $href->{$_} or die("missing -$_ flag"); }

   require WordPress::XMLRPC;
   # check login credentials
   my $wp= WordPress::XMLRPC->new({
      username => $href->{u},
      password => $href->{p},
      proxy    => $href->{x},
   });
   $wp->server or die('cant establish server'); # this doesnt really work the way expected
   $wp->getCategories or die($wp->errstr);
   ### server ok

   return $wp;
}


# argument is wordpress object, and number or name for category
# returns category name, and category id, or undef on fail
sub _resolve_cat_arg { # does not return if not exists
   my ($wp, $category_arg) = @_;
   $category_arg or die('missing arg');

   my $catdata;
   my $cats = $wp->getCategories or die("cant getCategories ? ". $wp->errstr);
   

   if ($category_arg=~/^\d+$/){ # by id
      $catdata = $wp->getCategory($category_arg) 
         or warn("not a category '$category_arg'?")
         and return;
   }   
   else {    
      CATFIND: for my $c ( @{$cats} ){    
         if ($c->{categoryName} eq $category_arg){
            $catdata = $c; 
            last CATFIND;
         }
      }   
   }   

   $catdata or warn("cant figure out category $category_arg") and return;
   return($catdata->{categoryName}, $catdata->{categoryId}); 

}

# date is string such as 'June 8 2010' or such, fuzzy logic
sub _date2wordpressdate {
   my $val = shift;
   $val or die;

   ### $val

   # is it a valid date?
   require Date::Manip;
   my $date = Date::Manip::ParseDate($val)
            or warn("dateCreated value '$val' is not a valid date")
            and return;

   ### $date
   my $wpdate =
         Date::Manip::UnixDate($date,"%Y%m%dT%H:%M:%S");

      ### $wpdate

   # This has to be upped by some to equal that date, otherwise wordpress 
   # sets date one day back, weird
   # if no hour was specified, let's forceit to noon
   $wpdate=~s/00:00:00$/12:00:00/;# 
   ### $wpdate

   return $wpdate;
}



# this is to feed the options in the cli from a config file, optionally
# must be passed a ref to the %OPT in the command script, and path to file
sub _opts_from_file {
   my ($href, $path) = @_;

   -f $path or return;

   open( FILE, '<',$path) or die($!);

   while (my $line = <FILE>){
      $line=~/\w/ or next; # blank ?
      $line=~/^\s*#/ and next; # comment ?

      $line=~s/\s*-?([a-zA-Z])[\s\=\:\n]//
         or die("cant make sense of line $line as arg in $path");
      my $opt_letter = $1;
      shomp $line;
      my $arg = $line;
      defined $arg and $arg=~/\w/  or $arg = 1;
      ### $arg
      ### $opt_letter
      exists $href->{$opt_letter} or die("no such option $opt_letter in $path");
      $href->{$opt_letter}=$arg;
   }
   close FILE;
   1;
}





1;


__END__

All of these subs are to support shell commands.
None of these are public. Use at your own peril. You have been warned.
