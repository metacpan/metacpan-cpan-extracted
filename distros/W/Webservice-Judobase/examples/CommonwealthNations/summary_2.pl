#!/usr/env/perl
use strict;
use warnings;
use v5.10;

$|++;

use Webservice::Judobase;
use Data::Dumper;
$Data::Dumper::Sortkeys=1;


my $srv = Webservice::Judobase->new;

my %annual_data;
my %data;
my @countries = (
    qw/
        ANT
        AUS
        BAH
        BAN
        BAR
        BIZ
        BOT
        BRU
        CAM
        CAN
        CYP
        DOM
        FIJ
        GAM
        GHA
        GRN
        GUY
        IND
        JAM
        KEN
        KIR
        LES
        MAW
        MAS
        MLT
        MRI
        MOZ
        NAM
        NZL
        NGR
        PAK
        PNG
        RWA
        SKN
        LCA
        VIN
        SAM
        SEY
        SLE
        SGP
        SIN
        SOL
        RSA
        SRI
        TAN
        TGA
        TTO
        TRI
        TUV
        UGA
        GBR
        VAN
        ZAM
    /
);
# loop through events:
#        1039 to 1753
#  Sofia 2009 to Santo Domingo 2019
for my $event_id ( 1039 .. 1039 ) {
    #print "X";
    my $event = $srv->general->competition( id => $event_id );
    next unless defined $event;

    my $contests = $srv->contests->competition( id => $event_id );
    next unless scalar @{$contests};

    

    for ( @{$contests} ) {
        #print ".";
        my $white_nation = $_->{country_short_white};
        my $blue_nation = $_->{country_short_blue};

        if ( $blue_nation && grep /^$blue_nation$/, @countries ) {
            # say Dumper $_;
            #say "$_->{country_short_blue},$_->{family_name_blue},$_->{given_name_blue}";    
	        $data{years}{$blue_nation}{$_->{comp_year}}++;        
            $data{$blue_nation}{"$_->{family_name_blue} $_->{given_name_blue}"}++;
        }

        if ( $white_nation && grep /^$white_nation$/, @countries ) {
            # say Dumper $_;
            # say "$_->{country_short_white},$_->{family_name_white},$_->{given_name_white}";            
	        $data{years}{$white_nation}{$_->{comp_year}}++;        
            $data{$white_nation}{"$_->{family_name_white} $_->{given_name_white}"}++;
        } 


        $data{All}{Athletes}++;
        $data{years}{All}{$_->{comp_year}}++;

    }


}

#say Dumper \%data;

for my $nation (keys %data) {
    next if $nation eq "years";
    for my $athlete (keys %{$data{$nation}}) {
        say "$nation,$athlete,$data{$nation}{$athlete}";
    }
}
say Dumper $data{years};
1;
