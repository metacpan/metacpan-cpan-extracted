#!/usr/bin/perl

package Win32::Shortkeys::Ripper;

use strict;
use warnings;
use Config::YAML::Tiny;
#use IO::File;
use Encode;
#use locale;
use XML::Parser;
use Data::Dumper;
#use File::Copy;
#use Getopt::Long;

#use File::BOM qw( :all );
my $shk_path    = "";
my $shkold_path = "";
my $tmp_path    = "";

#GetOptions('fpath=s'=> \$shk_path, 'foldpath=s' => \$shkold_path, 'tmpath=s'=> \$tmp_path);
my $erasesignal;
my $comchain;
my $TF=undef;

my $keepsit;
my $afterstarttag;
my $beforestarttag;

=head1 SYNOPSIS

        Win32::Shortkeys::Ripper::catch( 
            shk_file => "shortkey_utf8.xml", 
            tmp_file => "mytmp.txt", 
            shk_old => "shortkeys_utf8.xml_old.txt", 
            encoding => "UTF-8", 
            properties => "ripper.properties"
        );

Make a backup of shortkeys_utf8.xml in shortkeys_utf8.xml_old.txt and remove the content of the data elememts in shortkeys_utf8.xml. 
Other parameters are given in a properties file described below.

Default values 

=over

=item *

for encoding : UTF-8

=item *

for tmp_file : tmp.txt

=item *

for properties file name : ripper.properties

=back

=cut

sub catch {
    my %defaults = (tmp_file => "tmp.txt", encoding=> "UTF-8", properties=> "ripper.properties");
    my %args = (%defaults, @_);
     my $config = Config::YAML::Tiny->new( config => $args{properties} );
     $keepsit = $config->get_tag_to_keep;
    
     $afterstarttag = $config->get_after_start_tag;
     $beforestarttag = $config->get_before_start_tag;

     #die Dumper $keepsit;

    #open( my $FH, "<:raw:utf8", $args{shk_file} )
    open( my $FH, "<:encoding($args{encoding})", $args{shk_file} )
        or die "Unable to open xml file: $!";

# http://blogs.msdn.com/brettsh/archive/2006/06/07/620986.aspx
#open (my $TF, ">:raw:encoding(UTF16-LE):crlf:utf8", $tmp_path)  or die "Unable to make new temporary file: $!";
    #with utf-8 this would suffice  open( $TF, ">:encoding($args{encoding})", $args{tmp_file} ) 
    # http://grokbase.com/t/perl/unicode/111hf8z9as/encoding-utf16-le-on-windows
    # Files opened on Windows already have the :crlf layer pushed by default,
    #so you somehow need to get the :encoding layer *below* it. If you have it on top, 
    #then the crlf substitution happens *after* the encoding, leading to incorrect data.
    #this open( $TF, ">:encoding($args{encoding})", $args{tmp_file} ) or die "Unable to make new temporary file: $!";
    #insert "blank" between each character, I suspect this comes from the explanation above
   open( $TF, ">:raw:encoding($args{encoding}):crlf", $args{tmp_file} ) or die "Unable to make new temporary file: $!";
    

print $TF "\N{BOM}" if ($args{encoding} eq "UTF-8" || $args{encoding} eq "UTF-16BE");

#commentaire vide : <!-----> trois lignes sucessives font que les données ne sont plus
#produites. Le prochain commentaire non vide remet le compteur à zéro

    $erasesignal = 2;
    $comchain = 0;
    #  ProtocolEncoding => $args{encoding}, #with this accetended char in shortkey's name are preserved
    my $p = XML::Parser->new(
        ErrorContext     => 2, 
        ProtocolEncoding => $args{encoding}
    );

    $p->setHandlers(
        'Start'   => \&Win32::Shortkeys::Ripper::MySubs::start,
        'Char'    => \&Win32::Shortkeys::Ripper::MySubs::char,
        'End'     => \&Win32::Shortkeys::Ripper::MySubs::end,
        'Comment' => \&Win32::Shortkeys::Ripper::MySubs::com,
        'Default' => \&Win32::Shortkeys::Ripper::MySubs::def,

    );

    $p->parse($FH);

    close $FH;
    close $TF;

#rename ("../../shortkeys.xml", "../../shortkeys.xml_old.txt") or die "can't rename $!";
#rename ("../../tmp.txt", "../../shortkeys.xml") or die "can't rename $!";
    
    rename( $args{shk_file}, $args{old_file} ) or die "can't copy $!";
    rename( $args{tmp_file}, $args{shk_file} )    or die "can't rename $!";

}

package Win32::Shortkeys::Ripper::MySubs;

#use Data::Dumper;

my $current;

sub start {
    my ( $p, $el, %atts ) = @_;
    my $k = $atts{k};
    $comchain = 0 unless $comchain > 2;

    my $rtl = get_rtl( $k, $beforestarttag->{$el} );

    if ( $el eq "dataref" ) { $k = "dataref"; }

    if ( $k && $keepsit->{$k} ) {
        $current = $k;
    }

    #print "comments : $comchain ";
    return if $comchain > $erasesignal;

   # print "rtl : " . ($rtl eq "" ? " vide" : " retour ligne") . " el: $el\n";
    print $TF $rtl . "<" . $el;
    my $at;
    foreach my $v ( keys %atts ) {

        $at .= " " . $v . "= '" . $atts{$v} . "'";
    }

    print $TF $at if ($at);

    #print $TF ">$end", "$afterstarttag{$el}";
    print $TF ">" . get_rtl( $atts{k}, $afterstarttag->{$el} );

}

sub def {
    my ( $p, $el ) = @_;
    print $TF "$el";

}

sub end {
    my ( $p, $el ) = @_;
    return if $comchain > $erasesignal;
    if ( $current && $current ne "dataref" ) {
        $current = undef;
    }
    print $TF "</" . $el . ">";

}

sub char {
    my ( $p, $s ) = @_;
    return if $comchain > $erasesignal;

    if ( $current && $keepsit->{$current} ) {
        print $TF "$s";
    }

}

sub com {
    my ( $p, $s ) = @_;
    if ( $s eq "" ) {
        $comchain++;
    }
    else {
        $comchain = 0;
    }

    print $TF "\n<!--" . $s . "-->";

}

sub get_rtl {
    my ( $at, $mhref ) = @_;
    my $rtl = "";

    #	print "el: $at ";
    if ( $mhref && ref($mhref) eq "HASH" ) {

        #my $href = $beforestarttag{$el};
        #print "get_rtl: " . $href->{$at}. "\n" ;
        $rtl = $mhref->{$at} if ( $at && exists ${$mhref}{$at} );

    }
    else {
        $rtl = $mhref if ($mhref);
    }

    return $rtl;
}

=head1 DESCRIPTION

=head2 Properties file

It's name default to C<ripper.properties>. Use the C<properties => $file_name> to change that.

The file must follow YANL::Tiny::Simple syntax and contain three elements C<before_start_tag after_start_tag tag_to_keep>. 

 after_start_tag:
  data:
    a: "\n\n"
    d: "\n"
    t: "\n\n"
    ....

  dataref: ''
  shortkey: ''
 before_start_tag:
  data:
    a: "\n"
    d: "\n"
    t: "\n"
    ....
  dataref: ''
  shortkey: ''
 tag_to_keep:
  a: 0
  d: 0
  dataref: 1
  f: 1
  hg: 1
  hj: 1
  j: 0
  k: 0
  l: 1
  y: 0
  z: 1


See the files in the example folder: ripper.properties is used clear shorkeys_utf8.xml.

=over 

=item * before_start_tag after_start_tag 

contains the sub elements C<data dataref shortkey>. The data element enumerates, using the k attribute, the element's start tag that are preceded (C<before_start_tag> or followed C<after_start_tag> by  line break(s).

=item * tag_to_keep

Enumerate the data element using the value of the k attribute that you want to clear C<attribute:0>  or keep unchanged C<attribute:1>. C<dataref> is also listed.

=back

=head1 SUPPORT

Any questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from

L<http://sourceforge.net/projects/win32-shortkeys/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>


=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
