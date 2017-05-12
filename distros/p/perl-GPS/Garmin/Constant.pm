# Copyright (c) 1999-2000 João Pedro Gonçalves <joaop@sl.pt>.
#All rights reserved. This program is free software;
#you can redistribute it and/or modify it under the same terms as Perl itself.

package GPS::Garmin::Constant;

$VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

require Exporter;
@ISA = ("Exporter");

@EXPORT_OK = ( grep /^GRMN_/, keys %{'GPS::Garmin::Constant::'} );
%EXPORT_TAGS = (

	'all' => \@EXPORT_OK,

	'pids' => [qw[
			GRMN_ACK_BYTE		GRMN_COMMAND_DATA
			GRMN_ETX_BYTE
			GRMN_XFER_CMPLT		GRMN_DATE_TIME_DATA
			GRMN_DLE_BYTE		GRMN_POSITION_DATA
			GRMN_PRX_WPT_DATA	GRMN_NAK_BYTE
			GRMN_RECORDS		GRMN_RTE_HDR
			GRMN_RTE_WPT_DATA	GRMN_ALMANAC_DATA
			GRMN_TRK_DATA		GRMN_WPT_DATA
			GRMN_PVT_DATA		GRMN_RTE_LINK_DATA
			GRMN_TRK_HDR		GRMN_PROTOCOL_ARRAY
			GRMN_PRODUCT_RQST	GRMN_PRODUCT_DATA]],

	'commands' => [qw[
			GRMN_ABORT_TRANSFER GRMN_TRANSFER_ALM
			GRMN_TRANSFER_POSN	GRMN_TRANSFER_PRX
			GRMN_TRANSFER_RTE	GRMN_TRANSFER_TIME
			GRMN_TRANSFER_TRK	GRMN_TRANSFER_WPT
			GRMN_TURN_OFF_PWR	GRMN_START_PVT_DATA
			GRMN_STOP_PVT_DATA
			]],

	'templates' => [qw[
			GRMN_HEADER			GRMN_FOOTER
			GRMN_UTC_DIFF
			]]

);

##
## The constants
##

#PID Types
sub GRMN_NUL			() { 0x00 }
sub GRMN_ETX			() { 0x03 }
sub GRMN_ETX_BYTE		() { 0x03 }
sub GRMN_ACK			() { 0x06 }
sub GRMN_ACK_BYTE		() { 0x06 }
sub GRMN_COMMAND_DATA	() { 0x0A }
sub GRMN_XFER_CMPLT		() { 0x0C }
sub GRMN_DATE_TIME_DATA () { 0x0E }
sub GRMN_ESC			() { 0x0E }
sub GRMN_DLE			() { 0x10 }
sub GRMN_DLE_BYTE		() { 0x10 }
sub GRMN_POSITION_DATA	() { 0x11 }
sub GRMN_PRX_WPT_DATA	() { 0x13 }
sub GRMN_NAK			() { 0x15 }
sub GRMN_NAK_BYTE		() { 0x15 }
sub GRMN_RECORDS		() { 0x1B }
sub GRMN_RTE_HDR		() { 0x1D }
sub GRMN_RTE_WPT_DATA	() { 0x1E }
sub GRMN_ALMANAC_DATA	() { 0x1F }
sub GRMN_TRK_DATA		() { 0x22 }
sub GRMN_WPT_DATA		() { 0x23 }
sub GRMN_PVT_DATA		() { 0x33 }
sub GRMN_RTE_LINK_DATA	() { 0x62 }
sub GRMN_TRK_HDR		() { 0x63 }
sub GRMN_PROTOCOL_ARRAY () { 0xFD }
sub GRMN_PRODUCT_RQST	() { 0xFE }
sub GRMN_PRODUCT_DATA	() { 0xFF }

#Command ID's
sub GRMN_ABORT_TRANSFER () { 0x00 }
sub GRMN_TRANSFER_ALM	() { 0x01 }
sub GRMN_TRANSFER_POSN	() { 0x02 }
sub GRMN_TRANSFER_PRX	() { 0x03 }
sub GRMN_TRANSFER_RTE	() { 0x04 }
sub GRMN_TRANSFER_TIME	() { 0x05 }
sub GRMN_TRANSFER_TRK	() { 0x06 }
sub GRMN_TRANSFER_WPT	() { 0x07 }
sub GRMN_TURN_OFF_PWR	() { 0x08 }
sub GRMN_START_PVT_DATA () { 0x31 } #Only works in GPS III
sub GRMN_STOP_PVT_DATA	() { 0x50 } #

#Templates

sub GRMN_HEADER			() { pack "C1",GRMN_DLE }
sub GRMN_FOOTER			() { pack "C2",GRMN_DLE,GRMN_ETX };
sub GRMN_PACKET_FILL	() { 0x01 }

#Constant vars
sub GRMN_UTC_DIFF		() { 631065600 }; #UTC to Unix time epoch
#sub GRMN_UTC_DIFF		() { 631152000 }; #UTC to Unix time epoch

# Symbol_Type
my %sym =
	(
	 # Symbols for marine (group 0...0-8191...bits 15-13=000).
	 sym_anchor			 =>	  0, # white anchor symbol
	 sym_bell			 =>	  1, # white bell symbol
	 sym_diamond_grn	 =>	  2, # green diamond symbol
	 sym_diamond_red	 =>	  3, # red diamond symbol
	 sym_dive1			 =>	  4, # diver down flag 1
	 sym_dive2			 =>	  5, # diver down flag 2
	 sym_dollar			 =>	  6, # white dollar symbol
	 sym_fish			 =>	  7, # white fish symbol
	 sym_fuel			 =>	  8, # white fuel symbol
	 sym_horn			 =>	  9, # white horn symbol
	 sym_house			 =>	 10, # white house symbol
	 sym_knife			 =>	 11, # white knife & fork symbol
	 sym_light			 =>	 12, # white light symbol
	 sym_mug			 =>	 13, # white mug symbol
	 sym_skull			 =>	 14, # white skull and crossbones symbol
	 sym_square_grn		 =>	 15, # green square symbol
	 sym_square_red		 =>	 16, # red square symbol
	 sym_wbuoy			 =>	 17, # white buoy waypoint symbol
	 sym_wpt_dot		 =>	 18, # waypoint dot
	 sym_wreck			 =>	 19, # white wreck symbol
	 sym_null			 =>	 20, # null symbol (transparent)
	 sym_mob			 =>	 21, # man overboard symbol

	 #marine navaid symbols
	 sym_buoy_ambr		 =>	 22, # amber map buoy symbol
	 sym_buoy_blck		 =>	 23, # black map buoy symbol
	 sym_buoy_blue		 =>	 24, # blue map buoy symbol
	 sym_buoy_grn		 =>	 25, # green map buoy symbol
	 sym_buoy_grn_red	 =>	 26, # green/red map buoy symbol
	 sym_buoy_grn_wht	 =>	 27, # green/white map buoy symbol
	 sym_buoy_orng		 =>	 28, # orange map buoy symbol
	 sym_buoy_red		 =>	 29, # red map buoy symbol
	 sym_buoy_red_grn	 =>	 30, # red/green map buoy symbol
	 sym_buoy_red_wht	 =>	 31, # red/white map buoy symbol
	 sym_buoy_violet	 =>	 32, # violet map buoy symbol
	 sym_buoy_wht		 =>	 33, # white map buoy symbol
	 sym_buoy_wht_grn	 =>	 34, # white/green map buoy symbol
	 sym_buoy_wht_red	 =>	 35, # white/red map buoy symbol
	 sym_dot			 =>	 36, # white dot symbol
	 sym_rbcn			 =>	 37, # radio beacon symbol

	 # leave space for more navaids (up to 128 total)
	 sym_boat_ramp		 => 150, # boat ramp symbol
	 sym_camp			 => 151, # campground symbol
	 sym_restrooms		 => 152, # restrooms symbol
	 sym_showers		 => 153, # shower symbol
	 sym_drinking_wtr	 => 154, # drinking water symbol
	 sym_phone			 => 155, # telephone symbol
	 sym_1st_aid		 => 156, # first aid symbol
	 sym_info			 => 157, # information symbol
	 sym_parking		 => 158, # parking symbol
	 sym_park			 => 159, # park symbol
	 sym_picnic			 => 160, # picnic symbol
	 sym_scenic			 => 161, # scenic area symbol
	 sym_skiing			 => 162, # skiing symbol
	 sym_swimming		 => 163, # swimming symbol
	 sym_dam			 => 164, # dam symbol
	 sym_controlled		 => 165, # controlled area symbol
	 sym_danger			 => 166, # danger symbol
	 sym_restricted		 => 167, # restricted area symbol
	 sym_null_2			 => 168, # null symbol
	 sym_ball			 => 169, # ball symbol
	 sym_car			 => 170, # car symbol
	 sym_deer			 => 171, # deer symbol
	 sym_shpng_cart		 => 172, # shopping cart symbol
	 sym_lodging		 => 173, # lodging symbol
	 sym_mine			 => 174, # mine symbol
	 sym_trail_head		 => 175, # trail head symbol
	 sym_truck_stop		 => 176, # truck stop symbol
	 sym_user_exit		 => 177, # user exit symbol
	 sym_flag			 => 178, # flag symbol
	 sym_circle_x		 => 179, # circle with x in the center

	 #	 Symbols for land (group 1...8192-16383...bits 15-13=001).
	 sym_is_hwy			=> 8192, # interstate hwy symbol
	 sym_us_hwy			=> 8193, # us hwy symbol
	 sym_st_hwy			=> 8194, # state hwy symbol
	 sym_mi_mrkr		=> 8195, # mile marker symbol
	 sym_trcbck			=> 8196, # TracBack (feet) symbol
	 sym_golf			=> 8197, # golf symbol
	 sym_sml_cty		=> 8198, # small city symbol
	 sym_med_cty		=> 8199, # medium city symbol
	 sym_lrg_cty		=> 8200, # large city symbol
	 sym_freeway		=> 8201, # intl freeway hwy symbol
	 sym_ntl_hwy		=> 8202, # intl national hwy symbol
	 sym_cap_cty		=> 8203, # capitol city symbol (star)
	 sym_amuse_pk		=> 8204, # amusement park symbol
	 sym_bowling		=> 8205, # bowling symbol
	 sym_car_rental		=> 8206, # car rental symbol
	 sym_car_repair		=> 8207, # car repair symbol
	 sym_fastfood		=> 8208, # fast food symbol
	 sym_fitness		=> 8209, # fitness symbol
	 sym_movie			=> 8210, # movie symbol
	 sym_museum			=> 8211, # museum symbol
	 sym_pharmacy		=> 8212, # pharmacy symbol
	 sym_pizza			=> 8213, # pizza symbol
	 sym_post_ofc		=> 8214, # post office symbol
	 sym_rv_park		=> 8215, # RV park symbol
	 sym_school			=> 8216, # school symbol
	 sym_stadium		=> 8217, # stadium symbol
	 sym_store			=> 8218, # dept. store symbol
	 sym_zoo			=> 8219, # zoo symbol
	 sym_gas_plus		=> 8220, # convenience store symbol
	 sym_faces			=> 8221, # live theater symbol
	 sym_ramp_int		=> 8222, # ramp intersection symbol
	 sym_st_int			=> 8223, # street intersection symbol
	 sym_weigh_sttn		=> 8226, # inspection/weigh station symbol
	 sym_toll_booth		=> 8227, # toll booth symbol
	 sym_elev_pt		=> 8228, # elevation point symbol
	 sym_ex_no_srvc		=> 8229, # exit without services symbol
	 sym_geo_place_mm	=> 8230, # Geographic place name, man-made
	 sym_geo_place_wtr	=> 8231, # Geographic place name, water
	 sym_geo_place_lnd	=> 8232, # Geographic place name, land
	 sym_bridge			=> 8233, # bridge symbol
	 sym_building		=> 8234, # building symbol
	 sym_cemetery		=> 8235, # cemetery symbol
	 sym_church			=> 8236, # church symbol
	 sym_civil			=> 8237, # civil location symbol
	 sym_crossing		=> 8238, # crossing symbol
	 sym_hist_town		=> 8239, # historical town symbol
	 sym_levee			=> 8240, # levee symbol
	 sym_military		=> 8241, # military location symbol
	 sym_oil_field		=> 8242, # oil field symbol
	 sym_tunnel			=> 8243, # tunnel symbol
	 sym_beach			=> 8244, # beach symbol
	 sym_forest			=> 8245, # forest symbol
	 sym_summit			=> 8246, # summit symbol
	 sym_lrg_ramp_int	=> 8247, # large ramp intersection symbol
	 sym_lrg_ex_no_srvc => 8248, # large exit without services smbl
	 sym_badge			=> 8249, # police/official badge symbol
	 sym_cards			=> 8250, # gambling/casino symbol
	 sym_snowski		=> 8251, # snow skiing symbol
	 sym_iceskate		=> 8252, # ice skating symbol
	 sym_wrecker		=> 8253, # tow truck (wrecker) symbol
	 sym_border			=> 8254, # border crossing (port of entry)

	 #	Symbols for aviation (group 2...16383-24575...bits 15-13=010).
	 sym_airport		=> 16384, # airport symbol
	 sym_int			=> 16385, # intersection symbol
	 sym_ndb			=> 16386, # non-directional beacon symbol
	 sym_vor			=> 16387, # VHF omni-range symbol
	 sym_heliport		=> 16388, # heliport symbol
	 sym_private		=> 16389, # private field symbol
	 sym_soft_fld		=> 16390, # soft field symbol
	 sym_tall_tower		=> 16391, # tall tower symbol
	 sym_short_tower	=> 16392, # short tower symbol
	 sym_glider			=> 16393, # glider symbol
	 sym_ultralight		=> 16394, # ultralight symbol
	 sym_parachute		=> 16395, # parachute symbol
	 sym_vortac			=> 16396, # VOR/TACAN symbol
	 sym_vordme			=> 16397, # VOR-DME symbol
	 sym_faf			=> 16398, # first approach fix
	 sym_lom			=> 16399, # localizer outer marker
	 sym_map			=> 16400, # missed approach point
	 sym_tacan			=> 16401, # TACAN symbol
	 sym_seaplane		=> 16402, # Seaplane Base
);

my %smbl =
	(
	 smbl_dot		  =>  0,			# dot symbol
	 smbl_house		  =>  1,			# house symbol
	 smbl_gas		  =>  2,			# gas symbol
	 smbl_car		  =>  3,			# car symbol
	 smbl_fish		  =>  4,			# fish symbol
	 smbl_boat		  =>  5,			# boat symbol
	 smbl_anchor	  =>  6,			# anchor symbol
	 smbl_wreck		  =>  7,			# wreck symbol
	 smbl_exit		  =>  8,			# exit symbol
	 smbl_skull		  =>  9,			# skull symbol
	 smbl_flag		  => 10,			# flag symbol
	 smbl_camp		  => 11,			# camp symbol
	 smbl_circle_x	  => 12,			# circle with x symbol
	 smbl_deer		  => 13,			# deer symbol
	 smbl_1st_aid	  => 14,			# first aid symbol
	 smbl_back_track  => 15,			# back track symbol
	);

my %dspl =
	(
	 dspl_name => 0, # Display symbol with waypoint name
	 dspl_none => 1, # Display symbol by itself
	 dspl_cmnt => 2, # Display symbol with comment
	);

# also for D155, but without dspl_smbl_none
my %dspl_smbl =
	(
	 dspl_smbl_none => 0, # Display symbol by itself
	 dspl_smbl_only => 1, # Display symbol by itself
	 dspl_smbl_name => 3, # Display symbol with waypoint name
	 dspl_smbl_cmnt => 5, # Display symbol with comment
	);

my %clr =
	(
	 clr_default  => 0,			 # Default waypoint color
	 clr_red	  => 1,			 # Red
	 clr_green	  => 2,			 # Green
	 clr_blue	  => 3,			 # Blue
	);

my %wpt_class =
	(
	 USER_WPT		=> 0x00,		# User waypoint
	 AVTN_APT_WPT	=> 0x40,		# Aviation Airport waypoint
	 AVTN_INT_WPT	=> 0x41,		# Aviation Intersection waypoint
	 AVTN_NDB_WPT	=> 0x42,		# Aviation NDB waypoint
	 AVTN_VOR_WPT	=> 0x43,		# Aviation VOR waypoint
	 AVTN_ARWY_WPT	=> 0x44,		# Aviation Airport Runway waypoint
	 AVTN_AINT_WPT	=> 0x45,		# Aviation Airport Intersection
	 AVTN_ANDB_WPT	=> 0x46,		# Aviation Airport NDB waypoint
	 MAP_PNT_WPT	=> 0x80,		# Map Point waypoint
	 MAP_AREA_WPT	=> 0x81,		# Map Area waypoint
	 MAP_INT_WPT	=> 0x82,		# Map Intersection waypoint
	 MAP_ADRS_WPT	=> 0x83,		# Map Address waypoint
	 MAP_LABEL_WPT	=> 0x84,		# Map Label Waypoint
	 MAP_LINE_WPT	=> 0x85,		# Map Line Waypoint
	);

my %color =
	(Black			 => 0,
	 Dark_Red		 => 1,
	 Dark_Green		 => 2,
	 Dark_Yellow	 => 3,
	 Dark_Blue		 => 4,
	 Dark_Magenta	 => 5,
	 Dark_Cyan		 => 6,
	 Light_Gray		 => 7,
	 Dark_Gray		 => 8,
	 Red			 => 9,
	 Green			 => 10,
	 Yellow			 => 11,
	 Blue			 => 12,
	 Magenta		 => 13,
	 Cyan			 => 14,
	 White			 => 15,
	 Default_Color	 => 0xFF
	);

my %wpt_class_150 =
	(
	 apt_wpt_class	   => 0,		# airport waypoint class
	 int_wpt_class	   => 1,		# intersection waypoint class
	 ndb_wpt_class	   => 2,		# NDB waypoint class
	 vor_wpt_class	   => 3,		# VOR waypoint class
	 usr_wpt_class	   => 4,		# user defined waypoint class
	 rwy_wpt_class	   => 5,		# airport runway threshold waypoint class
	 aint_wpt_class	   => 6,		# airport intersection waypoint class
	 locked_wpt_class  => 7			# locked waypoint class
	);

my %wpt_class_151 =
	(
	 apt_wpt_class_151	   => 0,		# airport waypoint class
	 vor_wpt_class_151	   => 1,		# VOR waypoint class
	 usr_wpt_class_151	   => 2,		# user defined waypoint class
	 locked_wpt_class_151  => 3			# locked waypoint class
	);

my %wpt_class_152 =
	(
	 apt_wpt_class_152	   => 0,		# airport waypoint class
	 int_wpt_class_152	   => 1,		# intersection waypoint class
	 ndb_wpt_class_152	   => 2,		# NDB waypoint class
	 vor_wpt_class_152	   => 3,		# VOR waypoint class
	 usr_wpt_class_152	   => 4,		# user defined waypoint class
	 locked_wpt_class_152  => 5			# locked waypoint class
	);

my %wpt_class_154 =
	(
	 apt_wpt_class_154	   => 0,	# airport waypoint class
	 int_wpt_class_154	   => 1,	# intersection waypoint class
	 ndb_wpt_class_154	   => 2,	# NDB waypoint class
	 vor_wpt_class_154	   => 3,	# VOR waypoint class
	 usr_wpt_class_154	   => 4,	# user defined waypoint class
	 rwy_wpt_class_154	   => 5,	# airport runway threshold waypoint class
	 aint_wpt_class_154	   => 6,	# airport intersection waypoint class
	 andb_wpt_class_154	   => 7,	# airport NDB waypoint class
	 sym_wpt_class_154	   => 8,	# user defined symbol-only waypoint class
	 locked_wpt_class_154  => 9		# locked waypoint class
	);

my %wpt_class_155 =
	(
	 apt_wpt_class_155	   => 0,		# airport waypoint class
	 int_wpt_class_155	   => 1,		# intersection waypoint class
	 ndb_wpt_class_155	   => 2,		# NDB waypoint class
	 vor_wpt_class_155	   => 3,		# VOR waypoint class
	 usr_wpt_class_155	   => 4,		# user defined waypoint class
	 locked_wpt_class_155  => 5			# locked waypoint class
	);

my %link_class =
	(
	 line	 => 0,
	 link	 => 1,
	 net	 => 2,
	 direct	 => 3,
	 snap	 => 0xFF,
	);

my %position_fix =
	(
	 unusable	=> 0,			  # failed integrity check
	 invalid	=> 1,			  # invalid or unavailable
	 '2D'		=> 2,			  # two dimensional
	 '3D'		=> 3,			  # three dimensional
	 '2D_diff'	=> 4,			  # two dimensional differential
	 '3D_diff'	=> 5			  # three dimensional differential
	);

{
	foreach my $def (qw(sym smbl dspl dspl_smbl clr wpt_class color
						wpt_class_150 wpt_class_151 wpt_class_152
						wpt_class_154 wpt_class_155 link_class
						position_fix)) {
		my @constants;
		my $ref = eval '\%'.$def;
		my $code = "";
		while(my($k,$v) = each %$ref) {
			my $subname = "GRNM_" . uc($k);
			$code .= "sub $subname () { $v };\n";
			push @constants, $subname;
		}
		#warn $code;
		eval $code; die $@ if $@;

		$EXPORT_TAGS{$def."s"} = [@constants];
		push @EXPORT_OK, @constants;
	}
}


1;
__END__
