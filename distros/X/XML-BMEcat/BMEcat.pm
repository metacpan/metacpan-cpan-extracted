#!/usr/bin/perl

use strict 'vars';
use vars qw/ $VERSION /;

$VERSION=0.55;

#----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*
package XML::BMEcat;

use IO::File;
use XML::Generator;

sub new {
   my $class  = shift;

   my $self = {};

   bless $self, $class;
}


sub setOutfile {
   my $self = shift;

   return unless $_[0];

   my $XMLFILE = new IO::File "> $_[0]" or die "Can't open $_[0]: $!";

   return $self->{'XMLFILE'} = $XMLFILE;
}


sub creatHeader {
   my $self = shift;

   return $self->{'INFO'} = Header->new();
}


sub creatFeatureSystem {
   my $self = shift;

   return $self->{'FEATURE_GROUP_LIST'} = FeatureSystem->new();
}


sub creatGroupSystem {
   my $self = shift;

   return $self->{'NODE_LIST'} = GroupSystem->new();
}


sub getGroupSystem {
   my $self = shift;

   ($self->{'NODE_LIST'}) ? return $self->{'NODE_LIST'} : 0;
}


sub creatArticleSystem {
   my $self = shift;
   
   $self->{'ART_MAP'} = ArticleSystem->new();
   
   $self->{'ART_MAP'}->bind2GroupSystem($self->getGroupSystem);
   
   return $self->{'ART_MAP'}
}


sub writeHeader {
   my $self = shift;

   ( $self->{'INFO'} ) ? my $INFO = $self->{'INFO'} : return -1;

   print "... Creating BME-Header ...\n" if $self->{'INFO'}->{'Config'}->{'VERBOSE'};

   my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
   my $agreement;

   my $transaction = $INFO->{'TRANSACTION'};

   $transaction .= " prev_version=\"$INFO->{'PREV_VERSION'}\"" if $INFO->{'PREV_VERSION'};

   $agreement =
      CreateTAGf (2, "AGREEMENT", "\n",
         CreateTAGf (3, "AGREEMENT_ID",       $INFO->{'Agreement'}->{'AGREEMENT_ID'}),
         CreateTAGf (3, "DATETIME",         {'type' => "agreement_start_date"}, "\n",
            CreateTAGf (4, "DATE",            $INFO->{'Agreement'}->{'AGREEMENT_start_date'}), "         "
         ),
         CreateTAGf (3, "DATETIME",         {'type' => "agreement_end_date"}, "\n",
            CreateTAGf (4, "DATE",            $INFO->{'Agreement'}->{'AGREEMENT_end_date'}), "         "
         ),  "      "
      ) if $INFO->{'AGREEMENT'};

   $self->{'XMLFILE'}->print(
      '<?xml version="1.0" encoding="' .      $INFO->{'Config'}->{'CHAR_SET'} . "\"?>\n\n",
      '<!DOCTYPE BMECAT SYSTEM "' .           $INFO->{'Config'}->{'DTD'} . "\">\n\n",
      '<BMECAT version="' . ($INFO->{'Config'}->{'VERSION'} ? $INFO->{'Config'}->{'VERSION'} : '1.2') . '">' . "\n" .
      CreateTAGf (1, "HEADER", "\n",
         CreateTAGf (2, "GENERATOR_INFO",     $INFO->{'General'}->{'GENERATOR_INFO'}),
         CreateTAGf (2, "CATALOG", "\n", 
            CreateTAGf (3, "LANGUAGE",        $INFO->{'General'}->{'LANGUAGE'}),
            CreateTAGf (3, "CATALOG_ID",      $INFO->{'General'}->{'CATALOG_ID'}),
            CreateTAGf (3, "CATALOG_VERSION", $INFO->{'General'}->{'CATALOG_VERSION'}),
            CreateTAGf (3, "CATALOG_NAME",    $INFO->{'General'}->{'CATALOG_NAME'} ),
            CreateTAGf (3, "DATETIME",      {'type' => "generation_date"}, "\n",
               CreateTAGf (4, "DATE",         $INFO->{'General'}->{'DATE'}),
               CreateTAGf (4, "TIME",         $INFO->{'General'}->{'TIME'}), "         ",
            ),
            CreateTAGf (3, "TERRITORY",       $INFO->{'General'}->{'TERRITORY'}),
            CreateTAGf (3, "CURRENCY",        $INFO->{'General'}->{'CURRENCY'}),
            CreateTAGf (3, "MIME_ROOT",       $INFO->{'General'}->{'MIME_ROOT'}), "      "
         ),
         CreateTAGf (2, "BUYER", "\n",
            CreateTAGf (3, "BUYER_ID",        $INFO->{'Buyer'}->{'BUYER_ID'}),
            CreateTAGf (3, "BUYER_NAME",      $INFO->{'Buyer'}->{'BUYER_NAME'}),
            CreateTAGf (3, "ADDRESS",       {'type' => "buyer"}, "\n",
               CreateTAGf (4, "NAME",         $INFO->{'Buyer'}->{'NAME'}),
               CreateTAGf (4, "NAME2",        $INFO->{'Buyer'}->{'NAME2'}),
               CreateTAGf (4, "CONTACT",      $INFO->{'Buyer'}->{'CONTACT'}),
               CreateTAGf (4, "STREET",       $INFO->{'Buyer'}->{'STREET'}),
               CreateTAGf (4, "ZIP",          $INFO->{'Buyer'}->{'ZIP'}),
               CreateTAGf (4, "CITY",         $INFO->{'Buyer'}->{'CITY'}),
               CreateTAGf (4, "COUNTRY",      $INFO->{'Buyer'}->{'COUNTRY'}),
               CreateTAGf (4, "PHONE",        $INFO->{'Buyer'}->{'PHONE'}),
               CreateTAGf (4, "FAX",          $INFO->{'Buyer'}->{'FAX'}),
               CreateTAGf (4, "EMAIL",        $INFO->{'Buyer'}->{'EMAIL'}),
               CreateTAGf (4, "URL",          $INFO->{'Buyer'}->{'URL'}), "         "
            ), "      "
         ) .
         $agreement .
         CreateTAGf (2, "SUPPLIER", "\n",
            CreateTAGf (3, "SUPPLIER_ID",   {'type' => $INFO->{'Supplier'}->{'SUPPLIER_ID'}->[0]},
                                              $INFO->{'Supplier'}->{'SUPPLIER_ID'}->[1]),
            CreateTAGf (3, "SUPPLIER_NAME",   $INFO->{'Supplier'}->{'SUPPLIER_NAME'}),
            CreateTAGf (3, "ADDRESS",       {'type' => "supplier"}, "\n",
               CreateTAGf (4, "NAME",         $INFO->{'Supplier'}->{'NAME'}),
               CreateTAGf (4, "NAME2",        $INFO->{'Supplier'}->{'NAME2'}),
               CreateTAGf (4, "CONTACT",      $INFO->{'Supplier'}->{'CONTACT'}),
               CreateTAGf (4, "STREET",       $INFO->{'Supplier'}->{'STREET'}),
               CreateTAGf (4, "ZIP",          $INFO->{'Supplier'}->{'ZIP'}),
               CreateTAGf (4, "CITY",         $INFO->{'Supplier'}->{'CITY'}),
               CreateTAGf (4, "COUNTRY",      $INFO->{'Supplier'}->{'COUNTRY'}),
               CreateTAGf (4, "PHONE",        $INFO->{'Supplier'}->{'PHONE'}),
               CreateTAGf (4, "FAX",          $INFO->{'Supplier'}->{'FAX'}),
               CreateTAGf (4, "EMAIL",        $INFO->{'Supplier'}->{'EMAIL'}),
               CreateTAGf (4, "URL",          $INFO->{'Supplier'}->{'URL'}), "         "
            ), "      "
         ), "   "
      ) .
      "   <$transaction>" . "\n"
   );
   return 0;
}


sub writeFeatureSystem {
   my $self = shift;

   ( $self->{'FEATURE_GROUP_LIST'} ) ? my $FEATURE_GROUP_LIST = $self->{'FEATURE_GROUP_LIST'} : return -1 ;

   my $FeatureGroupID = "";
   my $type;

   print "... Creating BME-Feature-System ...\n" if $self->{'INFO'}->{'Config'}->{'VERBOSE'};

   $self->{'XMLFILE'}->print(
      "      <FEATURE_SYSTEM>\n",
      "         <FEATURE_SYSTEM_NAME>$self->{'INFO'}->{'Config'}->{'FEATURE_SYSTEM_NAME'}</FEATURE_SYSTEM_NAME>\n"
   );

   foreach $FeatureGroupID ( sort keys( %$FEATURE_GROUP_LIST ) ) {

      $self->{'XMLFILE'}->print(
             "         <FEATURE_GROUP>\n",
             "            <FEATURE_GROUP_ID>$FeatureGroupID</FEATURE_GROUP_ID>\n",
             "            <FEATURE_GROUP_NAME>", sprintf ("GENERIC_%d", $FeatureGroupID),
                        "</FEATURE_GROUP_NAME>\n"
      );

      my $sort = 10;

      foreach (@{$FEATURE_GROUP_LIST->{"$FeatureGroupID"}}) {

         my ($feature, $unit) = @{$_};

         if ($unit) { $type = "free_entry" } else { $type = "defaults" };

         $self->{'XMLFILE'}->print(
                "            <FEATURE_TEMPLATE type=\"$type\">\n",
                "               <FT_NAME>$feature</FT_NAME>\n"
         );

         $self->{'XMLFILE'}->print(
                "               <FT_UNIT>$unit</FT_UNIT>\n");

         $self->{'XMLFILE'}->print(
                "               <FT_ORDER>$sort</FT_ORDER>\n",
                "            </FEATURE_TEMPLATE>\n"
         );

         $sort +=10;
      }

      $self->{'XMLFILE'}->print("         </FEATURE_GROUP>\n");
   }

   $self->{'XMLFILE'}->print("      </FEATURE_SYSTEM>\n");

   return 0
}


sub writeGroupSystem {
   my $self      = shift;

   ( $self->{'NODE_LIST'} ) ? my $NODE_LIST = $self->{'NODE_LIST'} : return -1;
   ( $self->{'INFO'} )      ? my $INFO = $self->{'INFO'}           : return -1;

   my ($type, %ReverseIdx);

   print "... Creating BME-Catalog-Structure ...\n" if $self->{'INFO'}->{'Config'}->{'VERBOSE'};

   $self->{'XMLFILE'}->print(
      "      <CATALOG_GROUP_SYSTEM>\n",
         CreateTAGf (3, "GROUP_SYSTEM_ID", $INFO->{'Config'}->{'GROUP_SYSTEM_ID'})
      );

   foreach (keys %$NODE_LIST) { $ReverseIdx{$NODE_LIST->{$_}} = $_ }

   foreach (@$NODE_LIST) {
   	
      next unless $ReverseIdx{$_};                         # because the Pseudohash !
      my $group_id = $ReverseIdx{$_};
   
      my $desc;

      if ( ! $NODE_LIST->{$group_id}->{'PARENT'} ) {       # no parents :-(, root ?

         $type = "root";
      }

      elsif ( $NODE_LIST->{$group_id}->{'LEAF'} ) {        # leaf ?

         $type = "leaf";

      } else {                                             # "normal" node ?

         $type = "node";
      }

      if ($NODE_LIST->{$group_id}->{'DESCR'}) {            # node-description ?

         my $txt;

         foreach ( @{$NODE_LIST->{$group_id}->{'DESCR'}} ) {

            my ($TextArt, $Text) = @{$_}[1,2];

            if ( ! ($TextArt =~ /Tabellenunterschrift.*/i) ) {

               $txt .= ' ' if ($txt);

               $txt .= "$Text" ;
            }
         }

         $desc = CreateTAGf (4, "GROUP_DESCRIPTION", $txt ) if ( $txt );
      }

      $self->{'XMLFILE'}->print (

         CreateTAGf (3, "CATALOG_STRUCTURE", {'type' => $type}, "\n",

            CreateTAGf (4, "GROUP_ID", $group_id),

            CreateTAGf (4, "GROUP_NAME", $NODE_LIST->{$group_id}->{'NAME'}),

            $desc,

            CreateTAGf (4, "PARENT_ID", $NODE_LIST->{$group_id}->{'PARENT'}),

            CreateTAGf (4, "GROUP_ORDER", $NODE_LIST->{$group_id}->{'SORT'}),

            MIME_INFO($NODE_LIST->{$group_id}->{'MIME'}, 4), "         "
         )     
      )
   }

   $self->{'XMLFILE'}->print("      </CATALOG_GROUP_SYSTEM>\n");

   return 0
}


sub writeArticleSystem {
   my $self = shift;

   ( $self->{'ART_MAP'} ) ? my $ART_MAP = $self->{'ART_MAP'} : return -1;

   my $ret;

   print "... Creating BME-Articles-Details ...\n" if $self->{'INFO'}->{'Config'}->{'VERBOSE'};

   foreach my $IDX (sort keys ( %$ART_MAP )) {

      next if $IDX =~ /^#~_/ or ! $IDX;

      my $str = "";

      $str .= $ret if $ret = ArticleDetails($ART_MAP->{$IDX}, 'ARTICLE_DETAILS');

      if ( $self->{'FEATURE_GROUP_LIST'} and $ART_MAP->{$IDX}->{FT_GROUP} ) {
           $str .= $ret if $ret = ArticleFeatures( $ART_MAP->{$IDX},
                                                   $self->{'FEATURE_GROUP_LIST'},
						   $self->{'INFO'}->{'Config'}->{'FEATURE_SYSTEM_NAME'}
						 )
      };

      $str .= $ret if $ret = ArticleDetails($ART_MAP->{$IDX}, 'ARTICLE_ORDER_DETAILS');

      $str .= $ret if $ret = ArticleDetails($ART_MAP->{$IDX}, 'ARTICLE_PRICE_DETAILS');

      $str .= $ret if $ret = MIME_INFO($ART_MAP->{$IDX}->{'MIME'}, 3);

      $self->{'XMLFILE'}->print (
         CreateTAGf (2, "ARTICLE", {'mode' => $ART_MAP->{$IDX}->{'mode'}}, "\n",
            CreateTAGf (3, "SUPPLIER_AID", $ART_MAP->{$IDX}->{'SUPPLIER_AID'}),
            $str, "      "
         )
      )
   }

   return 0
}


sub ArticleDetails {
   return unless ( $_[0] && ref $_[0] );            # no reference to ART_DETAILS ?
   my $ref = shift;
   my $key1 = shift;
   my ($str);

   if ($key1 eq 'ARTICLE_PRICE_DETAILS') {

      foreach my $key2 ( qw/DATETIME ARTICLE_PRICE /) {

         foreach my $r_list ( @{$ref->{$key1}->{$key2}} ) {

            my $str1 = "";

            my ($type, $value) = splice @{$r_list}, 0, 2;

            while (my ($tag, $val) = splice @{$r_list}, 0, 2) {

               $str1 .= CreateTAGf (5, $tag, $val);
            }         

            $str .= CreateTAGf (4, $key2, {$type => $value}, "\n", $str1, "            ") if $str1;
         }
      }

   } else {

      foreach (@{$ref->{$key1}}) {

         if ( ref $_ && $_->[1] ) {

            if ( ref $_->[1] ) {

               $str .= CreateTAGf (4, $_->[0], {'type' => $_->[1]->[0]}, $_->[1]->[1]);

            } else {

               $str .= CreateTAGf (4, $_->[0], $_->[1]);
            }
         }
      }         
   }
   return CreateTAGf (3, "$key1", "\n", $str, "         ") if $str;
}


sub ArticleFeatures {
   my $ref = shift;
   my $FEATURE_GROUP_LIST = shift;
   my $str1  = CreateTAGf (4, 'REFERENCE_FEATURE_SYSTEM_NAME', shift);

#   unless ($ref->{'FT_GROUP'}) { printf "Skipping ArticleFeatures for: %s\n", $ref->{'SUPPLIER_AID'}; return ""};

   $str1 .= CreateTAGf (4, 'REFERENCE_FEATURE_GROUP_ID', $ref->{'FT_GROUP'});

   foreach ( @{$FEATURE_GROUP_LIST->{$ref->{'FT_GROUP'}}} ) {

      my $str = "";

      my ($feature, $unit) = @{$_};

      my $value = shift @{$ref->{'ARTICLE_FEATURES'}};

      $str .= CreateTAGf (5, 'FNAME', $feature) .
              CreateTAGf (5, 'FVALUE', $value);
      $str .= CreateTAGf (5, 'FUNIT', $unit) if $unit;

      $str1 .= CreateTAGf (4, 'FEATURE', "\n", $str, "            ") if $str; 
   }

   return CreateTAGf (3, 'ARTICLE_FEATURES', "\n", $str1, "         ") if $str1;
}


sub writeArticleGroupMap {
   my $self = shift;

   ( $self->{'ART_MAP'} ) ? my $ART_MAP = $self->{'ART_MAP'} : return -1;

   my $art_id;

   print "... Creating BME-Catalog-Article-Mapping ...\n" if $self->{'INFO'}->{'Config'}->{'VERBOSE'};

   foreach my $IDX (keys %$ART_MAP) {

      next if $IDX =~ /^#~_/ or ! $IDX;
      
      if ( @{$ART_MAP->{$IDX}->{'ARTICLE_DETAILS'}}[2] ) {             # EAN exists ?

            $art_id = $ART_MAP->{$IDX}->{'ARTICLE_DETAILS'}->[2]->[1];

      } else {

            $art_id = $ART_MAP->{$IDX}->{'SUPPLIER_AID'}
      }

      foreach my $LEAF (@{$ART_MAP->{$IDX}->{'PARENTS'}}) {

         $self->{'XMLFILE'}->print(
                CreateTAGf (2, "ARTICLE_TO_CATALOGGROUP_MAP", "\n",
                CreateTAGf (3, "ART_ID", $art_id),
                CreateTAGf (3, "CATALOG_GROUP_ID", $LEAF), "      "
                )
         )
      }
   }
   return 0
}


sub writeTail {
   my $self = shift;

   ( $self->{'INFO'} ) ? my $INFO = $self->{'INFO'} : return -1;

   print "... Creating BME-Tail ...\n" if $self->{'INFO'}->{'Config'}->{'VERBOSE'};

   $self->{'XMLFILE'}->print("   </$INFO->{'TRANSACTION'}>\n</BMECAT>\n");

   return 0
}


sub MIME_INFO {
   return unless ( $_[0] && ref $_[0] );            # no reference to MIME_INFOS ?

   my $REF    = shift;
   my $indent = shift;

   my $mime = "";
   my $morder = 1;

   foreach ( @{$REF} ) {

      my ($mtype, $msource, $description, $purpose) = @{$_};

      $mime .= CreateTAGf ($indent + 1, "MIME", "\n",

               CreateTAGf ($indent + 2, "MIME_TYPE",    $mtype),

               CreateTAGf ($indent + 2, "MIME_SOURCE",  $msource),
               
               CreateTAGf ($indent + 2, "MIME_DESCR",   $description),

               CreateTAGf ($indent + 2, "MIME_PURPOSE", $purpose),

               CreateTAGf ($indent + 2, "MIME_ORDER",   $morder++), 
               substr "                                    ", 0, 3*($indent+1)
              )
   }

   return CreateTAGf ($indent, "MIME_INFO", "\n", $mime,
                      substr "                              ", 0, 3*$indent);
}

my $xmlgen;

sub CreateTAGf {
   my ($indent, $TAG, @rest) = @_;

   my $xmlgen = new XML::Generator or die $! unless defined $xmlgen;

   map {
           s/&([^amp])/&amp;$1/g;

#           s/</&lt;/g;

#           s/>/&gt;/g;

           s/\x96{1}/x/g

   } @rest;                                             # clean fields

   my $Spaces = substr "                              ", 0, 3*$indent;

   return ($Spaces . $xmlgen->$TAG(@rest) . "\n");
}


#----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*
package Header;

sub new {
   my $class  = shift;

   my $self = {};

   bless $self, $class;
}


sub setTransaction {
   my $self = shift;

   $self->{'TRANSACTION'} = shift;

   $self->{'PREV_VERSION'} = $_[0]->[1] if ref $_[0] and $_[0]->[0] =~ /^prev_version/i;
}


sub setGeneralInfo {
   my $self = shift;

   while (my ($tag, $val) = splice @_, 0, 2) {

	$self->{'General'}->{$tag} = $val;
   }
}


sub setBuyerInfo {
   my $self = shift;

   while (my ($tag, $val) = splice @_, 0, 2) {

	$self->{'Buyer'}->{$tag} = $val;
   }
}


sub setAgreementInfo {
   my $self = shift;

   while (my ($tag, $val) = splice @_, 0, 2) {

	$self->{'Agreement'}->{$tag} = $val;
   }
}


sub setSupplierInfo {
   my $self = shift;

   while (my ($tag, $val) = splice @_, 0, 2) {

	$self->{'Supplier'}->{$tag} = $val;
   }
}


sub setConfigInfo {
   my $self = shift;

   while (my ($tag, $val) = splice @_, 0, 2) {

	$self->{'Config'}->{$tag} = $val;
   }
}


#----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*
package FeatureSystem;

sub new {
   my $class  = shift;

   my $self = {};

   bless $self, $class;
}


sub addFeatureGroup {
   my $self = shift;

   my $key  = shift;

   return "" if exists $self->{$key};

   $self->{$key} = [];

   while (my ($tag, $val) = splice @_, 0, 2) {

	push @{$self->{$key}}, [ "$tag"	=>	"$val" ];
   }

   return $self->{$key};
}


#----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*
package GroupSystem;

sub new {
   my $class  = shift;

   my $self = [{}];

   bless $self, $class;
}


sub creatCatalogGroup {
   my ($self, $key) = @_;

# pls.don't forget this problem
  (exists $self->{$key}) ? return $self->{$key} :
				   return Push2PsH($self, $key, CatalogGroup->new());
}


sub Push2PsH {
   my ($struct, $key, $val) = @_;
   
   $struct->[0]->{$key} = @$struct;
   push @$struct, $val;	
   return $val;
}


sub getCatalogGroup {
   my ($self, $key) = @_;

    if (exists $self->{$key}) {
    	
    	return $self->{$key}
    	
    } else {
    	
        return 0
    }
}


#----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*
package CatalogGroup;

sub new {
   my $class  = shift;

   my $self = {};
   $self->{'MEMBERS'} = [];
   
   bless $self, $class;
}


sub setData {
   my $self = shift;

   while (my ($tag, $val) = splice @_, 0, 2) {

	$self->{$tag} = "$val";
   }
}


sub getData {
   my $self = shift;

   my $Key  = shift;
   
   return $self->{$Key} if exists $self->{$Key};
}


sub addDescription {
   my $self = shift;

   push @{$self->{'DESCR'}}, [ "", ""	=> shift ];
}


sub addMime {
   my $self = shift;

   my @list = @_;

   push @{$self->{'MIME'}}, \@list;
}


sub addMember {
   my $self = shift;
   
   push @{$self->{'MEMBERS'}}, shift;
}


sub getMembers {
   my $self = shift;
   
   return $self->{'MEMBERS'};
}


#----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*
package ArticleSystem;

sub new {
   my $class = shift;

   my $self = {};

   bless $self, $class;
}


sub bind2GroupSystem {
   my $self = shift;

   $self->{'#~_GROUP_SYSTEM'} = shift;
}


sub getGroupSystem {
   my $self = shift;

   return $self->{'#~_GROUP_SYSTEM'} if exists $self->{'#~_GROUP_SYSTEM'};
}


sub creatArticle {
   my $self = shift;

   my $key = shift; 
   
   return $self->{$key} = Article->new($key, $self->getGroupSystem);
}


sub getArticel {
   my ($self, $key) = @_;

   return $self->{$key};
}


#----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*
package Article;

sub new {
   my ($class, $Key, $GroupSystem)  = @_;

   my $self = {};

   $self->{'ART_KEY'} = $Key;

   $self->{'#~_GROUP_SYSTEM'} = $GroupSystem if $GroupSystem;
   
   bless $self, $class;
}


sub getKey {
   my $self = shift;

   return $self->{'ART_KEY'} if exists $self->{'ART_KEY'};
}


sub setMainInfo {
   my $self = shift;

   while (my ($tag, $val) = splice @_, 0, 2) {

	$self->{$tag} = $val;
   }
}


sub setFeatureGroup {
   my $self = shift;

   $self->{'FT_GROUP'} = shift if $_[0];
}


sub setFeatureValues {
   my $self = shift;

   my @list = @_;

   $self->{'ARTICLE_FEATURES'} = \@list;
}


sub addMime {
   my $self = shift;

   my @list = @_;

   push @{$self->{'MIME'}}, \@list;
}


sub setDetails {
   my $self = shift;

   my $idx = {	'DESCRIPTION_SHORT'	  =>  0,	'DESCRIPTION_LONG'	=>  1,
		'EAN'			  =>  2,	'SUPPLIER_ALT_AID'	=>  3,
		'BUYER_AID'		  =>  4,	'MANUFACTURER_AID'	=>  5,
		'MANUFACTURER_NAME'	  =>  6,	'ERP_GROUP_BUYER'	=>  7,
		'ERP_GROUP_SUPPLIER'	  =>  8,	'DELIVERY_TIME'		=>  9,
		'SPECIAL_TREATMENT_CLASS' => 10,	'KEYWORD'		=> 11,
		'REMARKS'		  => 12,	'ARTICLE_ORDER'		=> 13,
		'SEGMENT'		  => 14,	'ARTICLE_STATUS'	=> 15 };

   while (my ($tag, $val) = splice @_, 0, 2) {

	unless ( defined $idx->{$tag} ) {

	   warn "### ArticleDetails: wrong tag \"$tag\" !";

	   next;
	};

	@{$self->{'ARTICLE_DETAILS'}}[$idx->{$tag}] = [ $tag	=> $val ];
   }
}


sub setOrderDetails {
   my $self = shift;

   my $idx = {	'ORDER_UNIT'		=> 0,	'CONTENT_UNIT'		=> 1,
		'NO_CU_PER_OU'		=> 2,	'PRICE_QUANTITY'	=> 3,
		'QUANTITY_MIN'		=> 4,	'QUANTITY_INTERVAL'	=> 5 };

   while (my ($tag, $val) = splice @_, 0, 2) {

	unless ( defined $idx->{$tag} ) {

	   warn "### ArticleOrderDetails: wrong tag \"$tag\" !";

	   next;
	};

	@{$self->{'ARTICLE_ORDER_DETAILS'}}[$idx->{$tag}] = [ $tag	=> $val ];
   }
}


sub setPriceDetails {
   my $self = shift;

   while (my ($typ, $val) = splice @_, 0, 2) {

      push @{$self->{'ARTICLE_PRICE_DETAILS'}->{'DATETIME'}},
	 [
		'type'  	        => $typ,
		'DATE'          	=> $val
	 ];
   }
}


sub addPrice {
   my $self = shift;

   my @list = ();
   my $order;

   while (my ($tag, $val) = splice @_, 0, 2) {

      if ( $tag =~ /^order$/i ) {

         $order = $val;

         next;
      }

      push @list, $tag, $val;
   }

   if ( $order ) {

      $self->{'ARTICLE_PRICE_DETAILS'}->{'ARTICLE_PRICE'}[$order] = \@list;

   } else {

      push @{$self->{'ARTICLE_PRICE_DETAILS'}->{'ARTICLE_PRICE'}}, \@list
   }
}


sub map2Group {
   my ($self, $GroupKey) = @_;

   push @{$self->{PARENTS}}, $GroupKey;

   my $CatalogGroup = "";

   $CatalogGroup = $self->{'#~_GROUP_SYSTEM'}->getCatalogGroup($GroupKey)
      if exists $self->{'#~_GROUP_SYSTEM'};
         
   if ($CatalogGroup) {
   	
	$CatalogGroup->addMember($self->getKey);
	
   } else {
   	
	print "No Groupssystem or Cataloggroup: $GroupKey\n";
   }
}


#----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*
1;
__END__

=head1 NAME

XML::BMEcat - Perl extension for generating BMEcat-XML


=head1 SYNOPSIS

  use XML::BMEcat;

  my $BMEcat = XML::BMEcat->new();

  $BMEcat->setOutfile("catalog.xml");


=head1 DESCRIPTION

  XML::BMEcat is a simple module to help in the generation of BMEcat-XML.
  Basically, you create an XML::BMEcat object and then call the related
  methods with the necessary parameters.


=head1 METHODS

  The following methods are provided: 


=head2 HEADER

  Writes the BMEcat-Header:

=over 4

=item * createHeader

  my $Header = $BMEcat->creatHeader();

=item * setTransaction

  $Header->setTransaction($TRANSACTION, [ 'PREV_VERSION' => $prev_version ]);

=item * setGeneralInfo

  $Header->setGeneralInfo(
			'GENERATOR_INFO'	=> $GENERATOR_INFO,
         		'LANGUAGE'		=> $LANGUAGE,
         		'CATALOG_ID'		=> $CATALOG_ID,
         		'CATALOG_VERSION'	=> $CATALOG_VERSION,
         		'CATALOG_NAME'		=> $CATALOG_NAME,
         		'DATE'			=> $DATE,
         		'TIME'			=> $TIME,
         		'CURRENCY'		=> $CURRENCY,
         		'MIME_ROOT'		=> $MIME_ROOT
		   );

=item * setBuyerInfo

  $Header->setBuyerInfo(
			'BUYER_ID'		=> $BUYER_ID,
         		'BUYER_NAME'		=> $BUYER_NAME,
         		'NAME'			=> $NAME,
         		'STREET'		=> $STREET,
         		'ZIP'			=> $ZIP,
         		'CITY'			=> $CITY,
         		'COUNTRY'		=> $COUNTRY,
         		'EMAIL'			=> $EMAIL,
         		'URL'			=> $URL
		   );

=item * setAgreementInfo

  $Header->setAgreementInfo(
			'AGREEMENT_ID'		=> $AGREEMENT_ID,
         		'AGREEMENT_start_date'	=> $AGREEMENT_start_date,
         		'AGREEMENT_end_date'	=> $AGREEMENT_end_date
		   );

=item * setSupplierInfo

  $Header->setSupplierInfo(
			'SUPPLIER_ID'		=> $SUPPLIER_ID,
         		'SUPPLIER_NAME'		=> $SUPPLIER_NAME,
         		'NAME'			=> $NAME,
         		'NAME2'			=> $NAME2,
         		'CONTACT'		=> $CONTACT,
         		'STREET'		=> $STREET,
         		'ZIP'			=> $ZIP,
         		'CITY'			=> $CITY,
         		'COUNTRY'		=> $COUNTRY,
         		'PHONE'			=> $PHONE,
         		'FAX'			=> $FAX,
         		'EMAIL'			=> $EMAIL,
         		'URL'			=> $URL
		   );

=item * setConfigInfo

  $Header->setConfigInfo(
			'VERSION'               => $BMEcat_VERSION,
			'CHAR_SET'              => $CHAR_SET,
                        'DTD'		        => $DTD,
			'VERBOSE'		=> 1
		   );

=item * writeHeader

  $BMEcat->writeHeader();

=back


=head2 FEATURE_SYSTEM

  Writes the BMEcat - Feature-System:

=over 4

=item * setConfigInfo

  $Header->setConfigInfo('FEATURE_SYSTEM_NAME'	=> $FEATURE_SYSTEM_NAME);

=item * creatFeatureSystem

  my $FeatureSystem = $BMEcat->creatFeatureSystem();

=item * addFeatureGroup

  $FeatureSystem->addFeatureGroup( 'ftg1',

				'ft1' => $unit_a,
				'ft2' => $unit_b,
				'ft3' => $unit_c,
		   );

  $FeatureSystem->addFeatureGroup( 'ftg2',

				'ft4' => $unit_d,
				'ft5' => $unit_e,
				'ft6' => $unit_f,
		   );

=item * writeFeatureSystem

   $BMEcat->writeFeatureSystem();

=back


=head2 GROUP_SYSTEM

  Writes the BMEcat - Catalog-Structure:

=over 4

=item * setConfigInfo

  $Header->setConfigInfo('GROUP_SYSTEM_ID'	=> $GROUP_SYSTEM_ID);

=item * creatGroupSystem

  my $GroupSystem = $BMEcat->creatGroupSystem();

=item * creatCatalogGroup

  my $CatalogGroup = $GroupSystem->creatCatalogGroup($group_id);

=item * getCatalogGroup

  my $CatalogGroup = $GroupSystem->getCatalogGroup($group_id);

=item * setData

  $CatalogGroup->setData( 'PARENT'	=>	0,
			  'NAME'	=>	$name02,
			  'SORT'	=>	5 );

  $CatalogGroup = $GroupSystem->creatCatalogGroup('04');
  $CatalogGroup->setData( 'PARENT'	=>	2,
		   	  'NAME'	=>	$name04,
			  'SORT'	=>	5 );

  $CatalogGroup = $GroupSystem->creatCatalogGroup('06');
  $CatalogGroup->setData( 'PARENT'	=>	2,
		   	  'NAME'	=>	$name06,
			  'SORT'	=>	10 );

  $CatalogGroup = $GroupSystem->creatCatalogGroup('08');
  $CatalogGroup->setData( 'PARENT'	=>	4,
			  'NAME'	=>	$name08,
			  'SORT'	=>	5,
			  'LEAF'	=>      1 );

=item * getData

  $CatalogGroup->getData('PARENT');

=item * addDescription

  $CatalogGroup->addDescription($Description08);

=item * addMime

  $CatalogGroup->addMime($type, $source, $description, $purpose);

  $CatalogGroup = $GroupSystem->creatCatalogGroup('10');
  $CatalogGroup->setData( 'PARENT'	=>	4,
			  'NAME'	=>	$name10,
			  'SORT'	=>	10,
			  'LEAF'	=>      1 );

=item * addMember

  $CatalogGroup->addMember('foo');

=item * getMembers

  my @members = $CatalogGroup->getMembers;

=item * writeGroupSystem

  $BMEcat->writeGroupSystem() and print "not ";

=back

=head2 ARTICLES

  Writes the BMEcat - Article-Entrys:


=head3 General

=over 4

=item * creatArticleSystem

  my $ArticleSystem = $BMEcat->creatArticleSystem();

=item * writeArticleSystem

  $BMEcat->writeArticleSystem();

=item * getGroupSystem

  my $GroupSystem = ArticleSystem->getGroupSystem();

=item * creatArticle

  my $Article = $ArticleSystem->creatArticle($index);

=item * getArticel

  my $Article = $ArticleSystem->getArticle($index);

=item * getKey

  my $ArticleKey = $Article->getKey;

=item * setMainInfo

  $Article->setMainInfo('mode'		=>	$mode,
			'SUPPLIER_AID'  =>	$SUPPLIER_AID );

=back


=head3 Features

=over 4

=item * setFeatureGroup

  $Article->setFeatureGroup($group_id);

=item * setFeatureValues

  $Article->setFeatureValues(
		$ft_val1,
		$ft_val2, 
		$ft_val3,
		$ft_val4
	);

=back


=head3 Details

=over 4

=item * addMime

  Several mimes are possible. See the BMEcat-spezification for more details.

  $Article->addMime(
		$mime_type, 
		$mime_source,
		$description,
		$mime_purpose
	);

=item * setDetails

  All in the BMEcat-spezification described elements are allowed to set in free order
  and at several times.

  $Article->setDetails(
		'DESCRIPTION_SHORT'	=> $DESCRIPTION_SHORT,
		'DESCRIPTION_LONG'	=> $DESCRIPTION_LONG,
		'EAN'			=> $EAN,
		. . .	,

		'SPECIAL_TREATMENT_CLASS' => [ $type => $val ],
		. . .
	   );

=back


=head3 Orderdetails

=over 4

  All in the BMEcat-spezification described elements are allowed to set in free order
  and at several times.

  $Article->setOrderDetails(
		'ORDER_UNIT'		=> $ORDER_UNIT,
		'CONTENT_UNIT'		=> $CONTENT_UNIT,
		'NO_CU_PER_OU'		=> $NO_CU_PER_OU
		. . .
	   );

=back


=head3 Pricedetails

=over 4

  Several prices and types are possible. See the BMEcat-Spezification for more details.

=item * setPriceDetails

  $Article->setPriceDetails(
		'valid_start_date'	=> $start_date,
		'valid_end_date'	=> $end_date
	   );

=item * addPrice

  $Article->addPrice(
		'price_type'		=> $price_type,
		'PRICE_AMOUNT'		=> $price_amount,
		'PRICE_CURRENCY'	=> $currency,
		'TAX'			=> $tax
	   );

=back

=head2 ART_GROUP_MAP

=over 4

  Maps Articles to the BMEcat - Catalog-Structure:

=item * map2Group

  $Article->map2Group($group_id);

=item * writeArticleGroupMap

  $BMEcat->writeArticleGroupMap();

=back


=head2 TAIL

=over 4

=item * writeTail

  Writes the Tail and closes the BMEcat - Document

  $BMEcat->writeTail();

=back


=head1 BUGS

  At this time not usable:
  - FEATURE_GROUP_NAME
  - DAILY_PRICE


=head1 LIMITATIONS

  Not all BMEcat-features (eg. CLASSIFICATION_SYSTEM) have been implemented yet.
  See method-descriptions for detailed informations.


=head1 SEE ALSO

=over 4

=item The BMEcat-Authors

  http://www.BMEcat.org

=item Perl-XML FAQ

  http://www.perlxml.com/faq/perl-xml-faq.html

=back


=head1 ACKNOWLEDGMENTS

  I'd like to thank Larry Wall, Randolph Schwarz, Tom Christiansen,
  Gurusamy Sarathy and many others for making Perl what it is today.
  I had the privilege of working with a really excellent teacher,
  Robert Krüger. He have guided me through the entire process and his
  criticisms where always right on.


=head1 COPYRIGHT

  Copyright 2000-2003  by Frank-Peter Reich (fp$), fpreich@cpan.org
 
  This library is free software; you can redistribute it and/or modify it under
  the same terms as Perl itself.
 
  BMEcat is a trademark of BME - Bundesverband Materialwirtschaft, Einkauf und Logistik e.V.

