package pullword;

use 5.010;
use strict;
use warnings;
use Encode;
use Mojo::UserAgent;

our @ISA    = qw(Exporter);
our @EXPORT = qw(PWhash PWget);

=encoding utf8
=head1 NAME

pullword - The perl agent for Pullword(a online Chinese segmentation System) api!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use pullword;

    print PWget("清华大学是好学校",0,1);
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 PWget($source,$param1,$param2)

get pullword api result.
source=[a paragraph of chinese words] for example: source=清华大学是好学校
param1=[threshold] for example: param1=0 to pull all word, param1=1 to pull word with probability with 100%.
param2=[debug] for example: param2=0 debug model is off, param2=1 debug mode in on(show all probabilities of each word)

OUT text reslut;

=head2 PWhash($source)

get pullword word  distribution hash.
source=[a paragraph of chinese words] for example: source=清华大学是好学校

OUT hash: word as kery and It's frequency count;


=cut


sub PWhash {
  my $res=shift;
  my $result=PWget($res,0,0);
  my @fc=split /\n/ms,$result;
  my %fc;
  for(@fc) {
     chmod;
     next if /^$/;
     $fc{$_}++;
    }
  return \%fc;
}

sub PWget {
my ($source,$threshold,$debug)=@_;
 $source=decode("utf8",$source);
my $myurl="http://api.pullword.com/post.php?source=".$source."&param1=".$threshold."&param2=".$debug;
#$myurl="http://43.241.223.121/post.php?source=".$source."&param1=".$threshold."&param2=".$debug;
#$myurl="http://120.26.6.172/post.php?source=".$source."&param1=".$threshold."&param2=".$debug;
my $ua = Mojo::UserAgent->new;
$ua->transactor->name("Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.124 Safari/537.36");
my $tx=$ua->get($myurl);
my $replys=$tx->res->body;
my $out;
my @tmsg=split /\r\n/sm,$replys;
        for(@tmsg){
        next if /^$/;
        $out.=$_."\n";
        }

return $out;
}

=head1 AUTHOR

ORANGE, C<< <bollwarm at ijz.me> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pullword at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=pullword>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc pullword


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=pullword>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/pullword>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/pullword>

=item * Search CPAN

L<http://search.cpan.org/dist/pullword/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 ORANGE.

This program is released under the following license: Perl


=cut

1; # End of pullword
