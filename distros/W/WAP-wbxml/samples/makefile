
test:
	wbxmlc sample_10.wml
	wbxmlc sample_11.wml
	wbxmlc sample_12.wml
	wbxmlc sample_13.wml
	wbxmlc sample_10.si
	wbxmlc sample_10.sl
	wbxmlc sample_10.co
	wbxmlc sample_11.channel
	wbxmlc sample_12.channel
	wbxmlc sample_12.wta-wml
	wbxmlc basic_10.html
	wbxmlc strict_10.html
	wbxmlc personal.xml
	wbxmlc -p ../lib/WAP/wbxml/activesync.wbrules.xml airsync.xml

out:
	wbxmld sample_10.wmlc		sample_wml10.out
	wbxmld sample_11.wmlc		sample_wml11.out
	wbxmld sample_12.wmlc		sample_wml12.out
	wbxmld sample_13.wmlc		sample_wml13.out
	wbxmld sample_10.sic		sample_si10.out
	wbxmld sample_10.slc		sample_sl10.out
	wbxmld sample_10.coc		sample_co10.out
	wbxmld sample_11.channelc	sample_channel11.out
	wbxmld sample_12.channelc	sample_channel12.out
	wbxmld sample_12.wta-wmlc	sample_wta-wml12.out
	wbxmld basic_10.htmlc		basic_10.out
	wbxmld strict_10.htmlc		strict_10.out
	wbxmld personal.wbxml		personal.out
	wbxmld -p ../../wap-saxdriver-wbxml/lib/WAP/SAXDriver/wbxml/activesync.wbrules2.pl airsync.wbxml	airsync.out

