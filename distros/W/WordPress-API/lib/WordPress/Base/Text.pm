package WordPress::Base::Text;
use strict;
use warnings;
use Carp;
use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
@ISA = qw/Exporter/;
@EXPORT_OK = qw(__slurp __cleanup_html slurp cleanup_html);
@EXPORT = @EXPORT_OK;
%EXPORT_TAGS = ( all => \@EXPORT_OK );

*slurp = \&__slurp;
*cleanup_html = \&__cleanup_html;


sub __slurp {
   my $abs = shift;
   $abs or die('missing arg');
   require Cwd;

   -f $abs or carp("!-f $abs") and return;
   local $/;
   open(FILE,'<',$abs) or die ($!);
   my $guts = <FILE>;
   close FILE;
   return $guts;
}


sub __cleanup_html {
   my $txt = shift;

   $txt=~s/.+<body[^>]*>//s;
   $txt=~s/<\/body>.+$//s;

   $txt=~s/([\w ])\n/$1/sig;

   $txt=~s/<font[^>]*>|<\/font>//sig;

   $txt=~s/&nbsp;//sig;

   $txt=~s/[[^\n]\s]+/ /g;

   $txt=~s/ {2,}/ /g;

   return $txt;
}





1;



__END__

=pod

=head1 NAME

WordPress::Base::Text - text helpers


=head1 SYNOPSIS

   use WordPress::Base::Text;

   my $content = slurp('./file');
   my $clean_content = cleanup_html($content);

   my $quick_clean = cleanup_html( slurp('./file');



=head1 SUBS

These are not oo

=head2 __slurp() and slurp()

argument is abs path, returns content
if file not there, returns undef

=head2 __cleanup_html() and cleanup_html()

argument is html text, returns cleaned up, takes out font tags, etc






