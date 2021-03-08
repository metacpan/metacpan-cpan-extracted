package Win32::Mechanize::NotepadPlusPlus::Editor::Messages;

use warnings;
use strict;
use Exporter 5.57 ('import');

our @EXPORT = qw/
    %SCIMSG
    %SCINTILLANOTIFICATION
    %SCN_ARGS
    %SC_ACCESSIBILITY
    %SC_ALPHA
    %SC_ANNOTATION
    %SC_AUTOC_ORDER
    %SC_AUTOMATICFOLD
    %SC_BIDIRECTIONAL
    %SC_CACHE
    %SC_CARETPOLICY
    %SC_CARETSTICKY
    %SC_CARETSTYLE
    %SC_CASE
    %SC_CASEINSENSITIVE
    %SC_CHARSET
    %SC_CODEPAGE
    %SC_CURSOR
    %SC_DOCUMENTOPTION
    %SC_EDGEMODE
    %SC_EOL
    %SC_EOLSUPPORT
    %SC_FIND
    %SC_FOLDACTION
    %SC_FOLDDISPLAYTEXT
    %SC_FOLDFLAG
    %SC_FOLDLEVEL
    %SC_FONTQUAL
    %SC_FONTSIZE
    %SC_IDLESTYLING
    %SC_IME
    %SC_INDENTGUIDE
    %SC_INDIC
    %SC_INDICSTYLE
    %SC_KEY
    %SC_KEYWORDSET
    %SC_LINECHARACTERINDEX
    %SC_MARGIN
    %SC_MARK
    %SC_MARKNUM
    %SC_MOD
    %SC_MULTIAUTOC
    %SC_MULTIPASTE
    %SC_PHASES
    %SC_POPUP
    %SC_PRINTCOLOURMODE
    %SC_SEL
    %SC_STATUS
    %SC_STYLE
    %SC_TABDRAW
    %SC_TECHNOLOGY
    %SC_TEXTRETRIEVAL
    %SC_TIMEOUT
    %SC_TYPE
    %SC_UNDO
    %SC_VIRTUALSPACE
    %SC_VISIBLE
    %SC_WEIGHT
    %SC_WHITESPACE
    %SC_WRAPINDENT
    %SC_WRAPMODE
    %SC_WRAPVISUALFLAG
    %SC_WRAPVISUALFLAGLOC
/;

=encoding utf8

=head1 NAME

Win32::Mechanize::NotepadPlusPlus::Editor::Messages - Define values for using messages, notifications, and their arguments

=head1 SYNOPSIS

    use Win32::Mechanize::NotepadPlusPlus ':vars';
    print "$_\n" for sort { $SCIMSG{$a} <=> $SCIMSG{$b} } keys %SCIMSG;             # prints all message keys in numerical order


=head1 DESCRIPTION

Scintilla uses message-based communication, which is described in the L<ScintillaDoc|https://www.scintilla.org/ScintillaDoc.html>.

The hashes in L<Win32::Mechanize::NotepadPlusPlus::Editor::Messages> give named access to the underlying messages, as well as named versions of the constants used as arguments for those messages.

=head2 MESSAGES

=over

=item %SCIMSG

Many of the Scintilla Messages are already implemented in the L<Win32::Mechanize::NotepadPlusPlus::Editor> interface, and under normal circumstances, the end-user should never need to access this %SCIMSG hash directly.

However, if you have a reason to use L<editor-E<gt>SendMessage|Win32::Mechanize::NotepadPlusPlus::Editor/SendMessage> directly,
you can use the values from this hash.  Usually, this would only be done if you want a unique wrapper
around the message, or want to implement a new or unimplemented message.


=cut

our %SCIMSG = (
    'SCI_ADDREFDOCUMENT'                                         => 2376,
    'SCI_ADDSELECTION'                                           => 2573,
    'SCI_ADDSTYLEDTEXT'                                          => 2002,
    'SCI_ADDTABSTOP'                                             => 2676,
    'SCI_ADDTEXT'                                                => 2001,
    'SCI_ADDUNDOACTION'                                          => 2560,
    'SCI_ALLOCATE'                                               => 2446,
    'SCI_ALLOCATEEXTENDEDSTYLES'                                 => 2553,
    'SCI_ALLOCATELINECHARACTERINDEX'                             => 2711,
    'SCI_ALLOCATESUBSTYLES'                                      => 4020,
    'SCI_ANNOTATIONCLEARALL'                                     => 2547,
    'SCI_ANNOTATIONGETLINES'                                     => 2546,
    'SCI_ANNOTATIONGETSTYLE'                                     => 2543,
    'SCI_ANNOTATIONGETSTYLEOFFSET'                               => 2551,
    'SCI_ANNOTATIONGETSTYLES'                                    => 2545,
    'SCI_ANNOTATIONGETTEXT'                                      => 2541,
    'SCI_ANNOTATIONGETVISIBLE'                                   => 2549,
    'SCI_ANNOTATIONSETSTYLE'                                     => 2542,
    'SCI_ANNOTATIONSETSTYLEOFFSET'                               => 2550,
    'SCI_ANNOTATIONSETSTYLES'                                    => 2544,
    'SCI_ANNOTATIONSETTEXT'                                      => 2540,
    'SCI_ANNOTATIONSETVISIBLE'                                   => 2548,
    'SCI_APPENDTEXT'                                             => 2282,
    'SCI_ASSIGNCMDKEY'                                           => 2070,
    'SCI_AUTOCACTIVE'                                            => 2102,
    'SCI_AUTOCCANCEL'                                            => 2101,
    'SCI_AUTOCCOMPLETE'                                          => 2104,
    'SCI_AUTOCGETAUTOHIDE'                                       => 2119,
    'SCI_AUTOCGETCANCELATSTART'                                  => 2111,
    'SCI_AUTOCGETCASEINSENSITIVEBEHAVIOUR'                       => 2635,
    'SCI_AUTOCGETCHOOSESINGLE'                                   => 2114,
    'SCI_AUTOCGETCURRENT'                                        => 2445,
    'SCI_AUTOCGETCURRENTTEXT'                                    => 2610,
    'SCI_AUTOCGETDROPRESTOFWORD'                                 => 2271,
    'SCI_AUTOCGETIGNORECASE'                                     => 2116,
    'SCI_AUTOCGETMAXHEIGHT'                                      => 2211,
    'SCI_AUTOCGETMAXWIDTH'                                       => 2209,
    'SCI_AUTOCGETMULTI'                                          => 2637,
    'SCI_AUTOCGETORDER'                                          => 2661,
    'SCI_AUTOCGETSEPARATOR'                                      => 2107,
    'SCI_AUTOCGETTYPESEPARATOR'                                  => 2285,
    'SCI_AUTOCPOSSTART'                                          => 2103,
    'SCI_AUTOCSELECT'                                            => 2108,
    'SCI_AUTOCSETAUTOHIDE'                                       => 2118,
    'SCI_AUTOCSETCANCELATSTART'                                  => 2110,
    'SCI_AUTOCSETCASEINSENSITIVEBEHAVIOUR'                       => 2634,
    'SCI_AUTOCSETCHOOSESINGLE'                                   => 2113,
    'SCI_AUTOCSETDROPRESTOFWORD'                                 => 2270,
    'SCI_AUTOCSETFILLUPS'                                        => 2112,
    'SCI_AUTOCSETIGNORECASE'                                     => 2115,
    'SCI_AUTOCSETMAXHEIGHT'                                      => 2210,
    'SCI_AUTOCSETMAXWIDTH'                                       => 2208,
    'SCI_AUTOCSETMULTI'                                          => 2636,
    'SCI_AUTOCSETORDER'                                          => 2660,
    'SCI_AUTOCSETSEPARATOR'                                      => 2106,
    'SCI_AUTOCSETTYPESEPARATOR'                                  => 2286,
    'SCI_AUTOCSHOW'                                              => 2100,
    'SCI_AUTOCSTOPS'                                             => 2105,
    'SCI_BACKTAB'                                                => 2328,
    'SCI_BEGINUNDOACTION'                                        => 2078,
    'SCI_BRACEBADLIGHT'                                          => 2352,
    'SCI_BRACEBADLIGHTINDICATOR'                                 => 2499,
    'SCI_BRACEHIGHLIGHT'                                         => 2351,
    'SCI_BRACEHIGHLIGHTINDICATOR'                                => 2498,
    'SCI_BRACEMATCH'                                             => 2353,
    'SCI_CALLTIPACTIVE'                                          => 2202,
    'SCI_CALLTIPCANCEL'                                          => 2201,
    'SCI_CALLTIPPOSSTART'                                        => 2203,
    'SCI_CALLTIPSETBACK'                                         => 2205,
    'SCI_CALLTIPSETFORE'                                         => 2206,
    'SCI_CALLTIPSETFOREHLT'                                      => 2207,
    'SCI_CALLTIPSETHLT'                                          => 2204,
    'SCI_CALLTIPSETPOSITION'                                     => 2213,
    'SCI_CALLTIPSETPOSSTART'                                     => 2214,
    'SCI_CALLTIPSHOW'                                            => 2200,
    'SCI_CALLTIPUSESTYLE'                                        => 2212,
    'SCI_CANCEL'                                                 => 2325,
    'SCI_CANPASTE'                                               => 2173,
    'SCI_CANREDO'                                                => 2016,
    'SCI_CANUNDO'                                                => 2174,
    'SCI_CHANGEINSERTION'                                        => 2672,
    'SCI_CHANGELEXERSTATE'                                       => 2617,
    'SCI_CHARLEFT'                                               => 2304,
    'SCI_CHARLEFTEXTEND'                                         => 2305,
    'SCI_CHARLEFTRECTEXTEND'                                     => 2428,
    'SCI_CHARPOSITIONFROMPOINT'                                  => 2561,
    'SCI_CHARPOSITIONFROMPOINTCLOSE'                             => 2562,
    'SCI_CHARRIGHT'                                              => 2306,
    'SCI_CHARRIGHTEXTEND'                                        => 2307,
    'SCI_CHARRIGHTRECTEXTEND'                                    => 2429,
    'SCI_CHOOSECARETX'                                           => 2399,
    'SCI_CLEAR'                                                  => 2180,
    'SCI_CLEARALL'                                               => 2004,
    'SCI_CLEARALLCMDKEYS'                                        => 2072,
    'SCI_CLEARCMDKEY'                                            => 2071,
    'SCI_CLEARDOCUMENTSTYLE'                                     => 2005,
    'SCI_CLEARREGISTEREDIMAGES'                                  => 2408,
    'SCI_CLEARREPRESENTATION'                                    => 2667,
    'SCI_CLEARSELECTIONS'                                        => 2571,
    'SCI_CLEARTABSTOPS'                                          => 2675,
    'SCI_COLOURISE'                                              => 4003,
    'SCI_CONTRACTEDFOLDNEXT'                                     => 2618,
    'SCI_CONVERTEOLS'                                            => 2029,
    'SCI_COPY'                                                   => 2178,
    'SCI_COPYALLOWLINE'                                          => 2519,
    'SCI_COPYRANGE'                                              => 2419,
    'SCI_COPYTEXT'                                               => 2420,
    'SCI_COUNTCHARACTERS'                                        => 2633,
    'SCI_COUNTCODEUNITS'                                         => 2715,
    'SCI_CREATEDOCUMENT'                                         => 2375,
    'SCI_CREATELOADER'                                           => 2632,
    'SCI_CUT'                                                    => 2177,
    'SCI_DELETEBACK'                                             => 2326,
    'SCI_DELETEBACKNOTLINE'                                      => 2344,
    'SCI_DELETERANGE'                                            => 2645,
    'SCI_DELLINELEFT'                                            => 2395,
    'SCI_DELLINERIGHT'                                           => 2396,
    'SCI_DELWORDLEFT'                                            => 2335,
    'SCI_DELWORDRIGHT'                                           => 2336,
    'SCI_DELWORDRIGHTEND'                                        => 2518,
    'SCI_DESCRIBEKEYWORDSETS'                                    => 4017,
    'SCI_DESCRIBEPROPERTY'                                       => 4016,
    'SCI_DESCRIPTIONOFSTYLE'                                     => 4032,
    'SCI_DISTANCETOSECONDARYSTYLES'                              => 4025,
    'SCI_DOCLINEFROMVISIBLE'                                     => 2221,
    'SCI_DOCUMENTEND'                                            => 2318,
    'SCI_DOCUMENTENDEXTEND'                                      => 2319,
    'SCI_DOCUMENTSTART'                                          => 2316,
    'SCI_DOCUMENTSTARTEXTEND'                                    => 2317,
    'SCI_DROPSELECTIONN'                                         => 2671,
    'SCI_EDITTOGGLEOVERTYPE'                                     => 2324,
    'SCI_EMPTYUNDOBUFFER'                                        => 2175,
    'SCI_ENCODEDFROMUTF8'                                        => 2449,
    'SCI_ENDUNDOACTION'                                          => 2079,
    'SCI_ENSUREVISIBLE'                                          => 2232,
    'SCI_ENSUREVISIBLEENFORCEPOLICY'                             => 2234,
    'SCI_EXPANDCHILDREN'                                         => 2239,
    'SCI_FINDCOLUMN'                                             => 2456,
    'SCI_FINDINDICATORFLASH'                                     => 2641,
    'SCI_FINDINDICATORHIDE'                                      => 2642,
    'SCI_FINDINDICATORSHOW'                                      => 2640,
    'SCI_FINDTEXT'                                               => 2150,
    'SCI_FOLDALL'                                                => 2662,
    'SCI_FOLDCHILDREN'                                           => 2238,
    'SCI_FOLDDISPLAYTEXTGETSTYLE'                                => 2707,
    'SCI_FOLDDISPLAYTEXTSETSTYLE'                                => 2701,
    'SCI_FOLDLINE'                                               => 2237,
    'SCI_FORMATRANGE'                                            => 2151,
    'SCI_FORMFEED'                                               => 2330,
    'SCI_FREESUBSTYLES'                                          => 4023,
    'SCI_GETACCESSIBILITY'                                       => 2703,
    'SCI_GETADDITIONALCARETFORE'                                 => 2605,
    'SCI_GETADDITIONALCARETSBLINK'                               => 2568,
    'SCI_GETADDITIONALCARETSVISIBLE'                             => 2609,
    'SCI_GETADDITIONALSELALPHA'                                  => 2603,
    'SCI_GETADDITIONALSELECTIONTYPING'                           => 2566,
    'SCI_GETALLLINESVISIBLE'                                     => 2236,
    'SCI_GETANCHOR'                                              => 2009,
    'SCI_GETAUTOMATICFOLD'                                       => 2664,
    'SCI_GETBACKSPACEUNINDENTS'                                  => 2263,
    'SCI_GETBIDIRECTIONAL'                                       => 2708,
    'SCI_GETBUFFEREDDRAW'                                        => 2034,
    'SCI_GETCARETFORE'                                           => 2138,
    'SCI_GETCARETLINEBACK'                                       => 2097,
    'SCI_GETCARETLINEBACKALPHA'                                  => 2471,
    'SCI_GETCARETLINEFRAME'                                      => 2704,
    'SCI_GETCARETLINEVISIBLE'                                    => 2095,
    'SCI_GETCARETLINEVISIBLEALWAYS'                              => 2654,
    'SCI_GETCARETPERIOD'                                         => 2075,
    'SCI_GETCARETSTICKY'                                         => 2457,
    'SCI_GETCARETSTYLE'                                          => 2513,
    'SCI_GETCARETWIDTH'                                          => 2189,
    'SCI_GETCHARACTERCATEGORYOPTIMIZATION'                       => 2721,
    'SCI_GETCHARACTERPOINTER'                                    => 2520,
    'SCI_GETCHARAT'                                              => 2007,
    'SCI_GETCODEPAGE'                                            => 2137,
    'SCI_GETCOLUMN'                                              => 2129,
    'SCI_GETCOMMANDEVENTS'                                       => 2718,
    'SCI_GETCONTROLCHARSYMBOL'                                   => 2389,
    'SCI_GETCURLINE'                                             => 2027,
    'SCI_GETCURRENTPOS'                                          => 2008,
    'SCI_GETCURSOR'                                              => 2387,
    'SCI_GETDEFAULTFOLDDISPLAYTEXT'                              => 2723,
    'SCI_GETDIRECTFUNCTION'                                      => 2184,
    'SCI_GETDIRECTPOINTER'                                       => 2185,
    'SCI_GETDOCPOINTER'                                          => 2357,
    'SCI_GETDOCUMENTOPTIONS'                                     => 2379,
    'SCI_GETEDGECOLOUR'                                          => 2364,
    'SCI_GETEDGECOLUMN'                                          => 2360,
    'SCI_GETEDGEMODE'                                            => 2362,
    'SCI_GETENDATLASTLINE'                                       => 2278,
    'SCI_GETENDSTYLED'                                           => 2028,
    'SCI_GETEOLMODE'                                             => 2030,
    'SCI_GETEXTRAASCENT'                                         => 2526,
    'SCI_GETEXTRADESCENT'                                        => 2528,
    'SCI_GETFIRSTVISIBLELINE'                                    => 2152,
    'SCI_GETFOCUS'                                               => 2381,
    'SCI_GETFOLDEXPANDED'                                        => 2230,
    'SCI_GETFOLDLEVEL'                                           => 2223,
    'SCI_GETFOLDPARENT'                                          => 2225,
    'SCI_GETFONTQUALITY'                                         => 2612,
    'SCI_GETGAPPOSITION'                                         => 2644,
    'SCI_GETHIGHLIGHTGUIDE'                                      => 2135,
    'SCI_GETHOTSPOTACTIVEBACK'                                   => 2495,
    'SCI_GETHOTSPOTACTIVEFORE'                                   => 2494,
    'SCI_GETHOTSPOTACTIVEUNDERLINE'                              => 2496,
    'SCI_GETHOTSPOTSINGLELINE'                                   => 2497,
    'SCI_GETHSCROLLBAR'                                          => 2131,
    'SCI_GETIDENTIFIER'                                          => 2623,
    'SCI_GETIDLESTYLING'                                         => 2693,
    'SCI_GETIMEINTERACTION'                                      => 2678,
    'SCI_GETINDENT'                                              => 2123,
    'SCI_GETINDENTATIONGUIDES'                                   => 2133,
    'SCI_GETINDICATORCURRENT'                                    => 2501,
    'SCI_GETINDICATORVALUE'                                      => 2503,
    'SCI_GETKEYSUNICODE'                                         => 2522, # deprecated sci3.56
    'SCI_GETLASTCHILD'                                           => 2224,
    'SCI_GETLAYOUTCACHE'                                         => 2273,
    'SCI_GETLENGTH'                                              => 2006,
    'SCI_GETLEXER'                                               => 4002,
    'SCI_GETLEXERLANGUAGE'                                       => 4012,
    'SCI_GETLINE'                                                => 2153,
    'SCI_GETLINECHARACTERINDEX'                                  => 2710,
    'SCI_GETLINECOUNT'                                           => 2154,
    'SCI_GETLINEENDPOSITION'                                     => 2136,
    'SCI_GETLINEENDTYPESACTIVE'                                  => 2658,
    'SCI_GETLINEENDTYPESALLOWED'                                 => 2657,
    'SCI_GETLINEENDTYPESSUPPORTED'                               => 4018,
    'SCI_GETLINEINDENTATION'                                     => 2127,
    'SCI_GETLINEINDENTPOSITION'                                  => 2128,
    'SCI_GETLINESELENDPOSITION'                                  => 2425,
    'SCI_GETLINESELSTARTPOSITION'                                => 2424,
    'SCI_GETLINESTATE'                                           => 2093,
    'SCI_GETLINEVISIBLE'                                         => 2228,
    'SCI_GETMAINSELECTION'                                       => 2575,
    'SCI_GETMARGINBACKN'                                         => 2251,
    'SCI_GETMARGINCURSORN'                                       => 2249,
    'SCI_GETMARGINLEFT'                                          => 2156,
    'SCI_GETMARGINMASKN'                                         => 2245,
    'SCI_GETMARGINOPTIONS'                                       => 2557,
    'SCI_GETMARGINRIGHT'                                         => 2158,
    'SCI_GETMARGINS'                                             => 2253,
    'SCI_GETMARGINSENSITIVEN'                                    => 2247,
    'SCI_GETMARGINTYPEN'                                         => 2241,
    'SCI_GETMARGINWIDTHN'                                        => 2243,
    'SCI_GETMAXLINESTATE'                                        => 2094,
    'SCI_GETMODEVENTMASK'                                        => 2378,
    'SCI_GETMODIFY'                                              => 2159,
    'SCI_GETMOUSEDOWNCAPTURES'                                   => 2385,
    'SCI_GETMOUSEDWELLTIME'                                      => 2265,
    'SCI_GETMOUSESELECTIONRECTANGULARSWITCH'                     => 2669,
    'SCI_GETMOUSEWHEELCAPTURES'                                  => 2697,
    'SCI_GETMOVEEXTENDSSELECTION'                                => 2706,
    'SCI_GETMULTIPASTE'                                          => 2615,
    'SCI_GETMULTIPLESELECTION'                                   => 2564,
    'SCI_GETNAMEDSTYLES'                                         => 4029,
    'SCI_GETNEXTTABSTOP'                                         => 2677,
    'SCI_GETOVERTYPE'                                            => 2187,
    'SCI_GETPASTECONVERTENDINGS'                                 => 2468,
    'SCI_GETPHASESDRAW'                                          => 2673,
    'SCI_GETPOSITIONCACHE'                                       => 2515,
    'SCI_GETPRIMARYSTYLEFROMSTYLE'                               => 4028,
    'SCI_GETPRINTCOLOURMODE'                                     => 2149,
    'SCI_GETPRINTMAGNIFICATION'                                  => 2147,
    'SCI_GETPRINTWRAPMODE'                                       => 2407,
    'SCI_GETPROPERTY'                                            => 4008,
    'SCI_GETPROPERTYEXPANDED'                                    => 4009,
    'SCI_GETPROPERTYINT'                                         => 4010,
    'SCI_GETPUNCTUATIONCHARS'                                    => 2649,
    'SCI_GETRANGEPOINTER'                                        => 2643,
    'SCI_GETREADONLY'                                            => 2140,
    'SCI_GETRECTANGULARSELECTIONANCHOR'                          => 2591,
    'SCI_GETRECTANGULARSELECTIONANCHORVIRTUALSPACE'              => 2595,
    'SCI_GETRECTANGULARSELECTIONCARET'                           => 2589,
    'SCI_GETRECTANGULARSELECTIONCARETVIRTUALSPACE'               => 2593,
    'SCI_GETRECTANGULARSELECTIONMODIFIER'                        => 2599,
    'SCI_GETREPRESENTATION'                                      => 2666,
    'SCI_GETSCROLLWIDTH'                                         => 2275,
    'SCI_GETSCROLLWIDTHTRACKING'                                 => 2517,
    'SCI_GETSEARCHFLAGS'                                         => 2199,
    'SCI_GETSELALPHA'                                            => 2477,
    'SCI_GETSELECTIONEMPTY'                                      => 2650,
    'SCI_GETSELECTIONEND'                                        => 2145,
    'SCI_GETSELECTIONMODE'                                       => 2423,
    'SCI_GETSELECTIONNANCHOR'                                    => 2579,
    'SCI_GETSELECTIONNANCHORVIRTUALSPACE'                        => 2583,
    'SCI_GETSELECTIONNCARET'                                     => 2577,
    'SCI_GETSELECTIONNCARETVIRTUALSPACE'                         => 2581,
    'SCI_GETSELECTIONNEND'                                       => 2587,
    'SCI_GETSELECTIONNSTART'                                     => 2585,
    'SCI_GETSELECTIONS'                                          => 2570,
    'SCI_GETSELECTIONSTART'                                      => 2143,
    'SCI_GETSELEOLFILLED'                                        => 2479,
    'SCI_GETSELTEXT'                                             => 2161,
    'SCI_GETSTATUS'                                              => 2383,
    'SCI_GETSTYLEAT'                                             => 2010,
    'SCI_GETSTYLEBITS'                                           => 2091, # deprecated npp7.8
    'SCI_GETSTYLEBITSNEEDED'                                     => 4011, # deprecated  npp7.8
    'SCI_GETSTYLEDTEXT'                                          => 2015,
    'SCI_GETSTYLEFROMSUBSTYLE'                                   => 4027,
    'SCI_GETSUBSTYLEBASES'                                       => 4026,
    'SCI_GETSUBSTYLESLENGTH'                                     => 4022,
    'SCI_GETSUBSTYLESSTART'                                      => 4021,
    'SCI_GETTABDRAWMODE'                                         => 2698,
    'SCI_GETTABINDENTS'                                          => 2261,
    'SCI_GETTABWIDTH'                                            => 2121,
    'SCI_GETTAG'                                                 => 2616,
    'SCI_GETTARGETEND'                                           => 2193,
    'SCI_GETTARGETSTART'                                         => 2191,
    'SCI_GETTARGETTEXT'                                          => 2687,
    'SCI_GETTECHNOLOGY'                                          => 2631,
    'SCI_GETTEXT'                                                => 2182,
    'SCI_GETTEXTLENGTH'                                          => 2183,
    'SCI_GETTEXTRANGE'                                           => 2162,
    'SCI_GETTWOPHASEDRAW'                                        => 2283, # deprecated npp7.8
    'SCI_GETUNDOCOLLECTION'                                      => 2019,
    'SCI_GETUSEPALETTE'                                          => 2139, # deprecated in sci3.56
    'SCI_GETUSETABS'                                             => 2125,
    'SCI_GETVIEWEOL'                                             => 2355,
    'SCI_GETVIEWWS'                                              => 2020,
    'SCI_GETVIRTUALSPACEOPTIONS'                                 => 2597,
    'SCI_GETVSCROLLBAR'                                          => 2281,
    'SCI_GETWHITESPACECHARS'                                     => 2647,
    'SCI_GETWHITESPACESIZE'                                      => 2087,
    'SCI_GETWORDCHARS'                                           => 2646,
    'SCI_GETWRAPINDENTMODE'                                      => 2473,
    'SCI_GETWRAPMODE'                                            => 2269,
    'SCI_GETWRAPSTARTINDENT'                                     => 2465,
    'SCI_GETWRAPVISUALFLAGS'                                     => 2461,
    'SCI_GETWRAPVISUALFLAGSLOCATION'                             => 2463,
    'SCI_GETXOFFSET'                                             => 2398,
    'SCI_GETZOOM'                                                => 2374,
    'SCI_GOTOLINE'                                               => 2024,
    'SCI_GOTOPOS'                                                => 2025,
    'SCI_GRABFOCUS'                                              => 2400,
    'SCI_HIDELINES'                                              => 2227,
    'SCI_HIDESELECTION'                                          => 2163,
    'SCI_HOME'                                                   => 2312,
    'SCI_HOMEDISPLAY'                                            => 2345,
    'SCI_HOMEDISPLAYEXTEND'                                      => 2346,
    'SCI_HOMEEXTEND'                                             => 2313,
    'SCI_HOMERECTEXTEND'                                         => 2430,
    'SCI_HOMEWRAP'                                               => 2349,
    'SCI_HOMEWRAPEXTEND'                                         => 2450,
    'SCI_INDEXPOSITIONFROMLINE'                                  => 2714,
    'SCI_INDICATORALLONFOR'                                      => 2506,
    'SCI_INDICATORCLEARRANGE'                                    => 2505,
    'SCI_INDICATOREND'                                           => 2509,
    'SCI_INDICATORFILLRANGE'                                     => 2504,
    'SCI_INDICATORSTART'                                         => 2508,
    'SCI_INDICATORVALUEAT'                                       => 2507,
    'SCI_INDICGETALPHA'                                          => 2524,
    'SCI_INDICGETFLAGS'                                          => 2685,
    'SCI_INDICGETFORE'                                           => 2083,
    'SCI_INDICGETHOVERFORE'                                      => 2683,
    'SCI_INDICGETHOVERSTYLE'                                     => 2681,
    'SCI_INDICGETOUTLINEALPHA'                                   => 2559,
    'SCI_INDICGETSTYLE'                                          => 2081,
    'SCI_INDICGETUNDER'                                          => 2511,
    'SCI_INDICSETALPHA'                                          => 2523,
    'SCI_INDICSETFLAGS'                                          => 2684,
    'SCI_INDICSETFORE'                                           => 2082,
    'SCI_INDICSETHOVERFORE'                                      => 2682,
    'SCI_INDICSETHOVERSTYLE'                                     => 2680,
    'SCI_INDICSETOUTLINEALPHA'                                   => 2558,
    'SCI_INDICSETSTYLE'                                          => 2080,
    'SCI_INDICSETUNDER'                                          => 2510,
    'SCI_INSERTTEXT'                                             => 2003,
    'SCI_ISRANGEWORD'                                            => 2691,
    'SCI_LEXER_START'                                            => 4000,
    'SCI_LINECOPY'                                               => 2455,
    'SCI_LINECUT'                                                => 2337,
    'SCI_LINEDELETE'                                             => 2338,
    'SCI_LINEDOWN'                                               => 2300,
    'SCI_LINEDOWNEXTEND'                                         => 2301,
    'SCI_LINEDOWNRECTEXTEND'                                     => 2426,
    'SCI_LINEDUPLICATE'                                          => 2404,
    'SCI_LINEEND'                                                => 2314,
    'SCI_LINEENDDISPLAY'                                         => 2347,
    'SCI_LINEENDDISPLAYEXTEND'                                   => 2348,
    'SCI_LINEENDEXTEND'                                          => 2315,
    'SCI_LINEENDRECTEXTEND'                                      => 2432,
    'SCI_LINEENDWRAP'                                            => 2451,
    'SCI_LINEENDWRAPEXTEND'                                      => 2452,
    'SCI_LINEFROMINDEXPOSITION'                                  => 2713,
    'SCI_LINEFROMPOSITION'                                       => 2166,
    'SCI_LINELENGTH'                                             => 2350,
    'SCI_LINEREVERSE'                                            => 2354,
    'SCI_LINESCROLL'                                             => 2168,
    'SCI_LINESCROLLDOWN'                                         => 2342,
    'SCI_LINESCROLLUP'                                           => 2343,
    'SCI_LINESJOIN'                                              => 2288,
    'SCI_LINESONSCREEN'                                          => 2370,
    'SCI_LINESSPLIT'                                             => 2289,
    'SCI_LINETRANSPOSE'                                          => 2339,
    'SCI_LINEUP'                                                 => 2302,
    'SCI_LINEUPEXTEND'                                           => 2303,
    'SCI_LINEUPRECTEXTEND'                                       => 2427,
    'SCI_LOADLEXERLIBRARY'                                       => 4007,
    'SCI_LOWERCASE'                                              => 2340,
    'SCI_MARGINGETSTYLE'                                         => 2533,
    'SCI_MARGINGETSTYLEOFFSET'                                   => 2538,
    'SCI_MARGINGETSTYLES'                                        => 2535,
    'SCI_MARGINGETTEXT'                                          => 2531,
    'SCI_MARGINSETSTYLE'                                         => 2532,
    'SCI_MARGINSETSTYLEOFFSET'                                   => 2537,
    'SCI_MARGINSETSTYLES'                                        => 2534,
    'SCI_MARGINSETTEXT'                                          => 2530,
    'SCI_MARGINTEXTCLEARALL'                                     => 2536,
    'SCI_MARKERADD'                                              => 2043,
    'SCI_MARKERADDSET'                                           => 2466,
    'SCI_MARKERDEFINE'                                           => 2040,
    'SCI_MARKERDEFINEPIXMAP'                                     => 2049,
    'SCI_MARKERDEFINERGBAIMAGE'                                  => 2626,
    'SCI_MARKERDELETE'                                           => 2044,
    'SCI_MARKERDELETEALL'                                        => 2045,
    'SCI_MARKERDELETEHANDLE'                                     => 2018,
    'SCI_MARKERENABLEHIGHLIGHT'                                  => 2293,
    'SCI_MARKERGET'                                              => 2046,
    'SCI_MARKERLINEFROMHANDLE'                                   => 2017,
    'SCI_MARKERNEXT'                                             => 2047,
    'SCI_MARKERPREVIOUS'                                         => 2048,
    'SCI_MARKERSETALPHA'                                         => 2476,
    'SCI_MARKERSETBACK'                                          => 2042,
    'SCI_MARKERSETBACKSELECTED'                                  => 2292,
    'SCI_MARKERSETFORE'                                          => 2041,
    'SCI_MARKERSYMBOLDEFINED'                                    => 2529,
    'SCI_MOVECARETINSIDEVIEW'                                    => 2401,
    'SCI_MOVESELECTEDLINESDOWN'                                  => 2621,
    'SCI_MOVESELECTEDLINESUP'                                    => 2620,
    'SCI_MULTIEDGEADDLINE'                                       => 2694,
    'SCI_MULTIEDGECLEARALL'                                      => 2695,
    'SCI_MULTIPLESELECTADDEACH'                                  => 2689,
    'SCI_MULTIPLESELECTADDNEXT'                                  => 2688,
    'SCI_NAMEOFSTYLE'                                            => 4030,
    'SCI_NEWLINE'                                                => 2329,
    'SCI_NULL'                                                   => 2172,
    'SCI_OPTIONAL_START'                                         => 3000,
    'SCI_PAGEDOWN'                                               => 2322,
    'SCI_PAGEDOWNEXTEND'                                         => 2323,
    'SCI_PAGEDOWNRECTEXTEND'                                     => 2434,
    'SCI_PAGEUP'                                                 => 2320,
    'SCI_PAGEUPEXTEND'                                           => 2321,
    'SCI_PAGEUPRECTEXTEND'                                       => 2433,
    'SCI_PARADOWN'                                               => 2413,
    'SCI_PARADOWNEXTEND'                                         => 2414,
    'SCI_PARAUP'                                                 => 2415,
    'SCI_PARAUPEXTEND'                                           => 2416,
    'SCI_PASTE'                                                  => 2179,
    'SCI_POINTXFROMPOSITION'                                     => 2164,
    'SCI_POINTYFROMPOSITION'                                     => 2165,
    'SCI_POSITIONAFTER'                                          => 2418,
    'SCI_POSITIONBEFORE'                                         => 2417,
    'SCI_POSITIONFROMLINE'                                       => 2167,
    'SCI_POSITIONFROMPOINT'                                      => 2022,
    'SCI_POSITIONFROMPOINTCLOSE'                                 => 2023,
    'SCI_POSITIONRELATIVE'                                       => 2670,
    'SCI_POSITIONRELATIVECODEUNITS'                              => 2716,
    'SCI_PRIVATELEXERCALL'                                       => 4013,
    'SCI_PROPERTYNAMES'                                          => 4014,
    'SCI_PROPERTYTYPE'                                           => 4015,
    'SCI_REDO'                                                   => 2011,
    'SCI_REGISTERIMAGE'                                          => 2405,
    'SCI_REGISTERRGBAIMAGE'                                      => 2627,
    'SCI_RELEASEALLEXTENDEDSTYLES'                               => 2552,
    'SCI_RELEASEDOCUMENT'                                        => 2377,
    'SCI_RELEASELINECHARACTERINDEX'                              => 2712,
    'SCI_REPLACESEL'                                             => 2170,
    'SCI_REPLACETARGET'                                          => 2194,
    'SCI_REPLACETARGETRE'                                        => 2195,
    'SCI_RGBAIMAGESETHEIGHT'                                     => 2625,
    'SCI_RGBAIMAGESETSCALE'                                      => 2651,
    'SCI_RGBAIMAGESETWIDTH'                                      => 2624,
    'SCI_ROTATESELECTION'                                        => 2606,
    'SCI_SCROLLCARET'                                            => 2169,
    'SCI_SCROLLRANGE'                                            => 2569,
    'SCI_SCROLLTOEND'                                            => 2629,
    'SCI_SCROLLTOSTART'                                          => 2628,
    'SCI_SEARCHANCHOR'                                           => 2366,
    'SCI_SEARCHINTARGET'                                         => 2197,
    'SCI_SEARCHNEXT'                                             => 2367,
    'SCI_SEARCHPREV'                                             => 2368,
    'SCI_SELECTALL'                                              => 2013,
    'SCI_SELECTIONDUPLICATE'                                     => 2469,
    'SCI_SELECTIONISRECTANGLE'                                   => 2372,
    'SCI_SETACCESSIBILITY'                                       => 2702,
    'SCI_SETADDITIONALCARETFORE'                                 => 2604,
    'SCI_SETADDITIONALCARETSBLINK'                               => 2567,
    'SCI_SETADDITIONALCARETSVISIBLE'                             => 2608,
    'SCI_SETADDITIONALSELALPHA'                                  => 2602,
    'SCI_SETADDITIONALSELBACK'                                   => 2601,
    'SCI_SETADDITIONALSELECTIONTYPING'                           => 2565,
    'SCI_SETADDITIONALSELFORE'                                   => 2600,
    'SCI_SETANCHOR'                                              => 2026,
    'SCI_SETAUTOMATICFOLD'                                       => 2663,
    'SCI_SETBACKSPACEUNINDENTS'                                  => 2262,
    'SCI_SETBIDIRECTIONAL'                                       => 2709,
    'SCI_SETBUFFEREDDRAW'                                        => 2035,
    'SCI_SETCARETFORE'                                           => 2069,
    'SCI_SETCARETLINEBACK'                                       => 2098,
    'SCI_SETCARETLINEBACKALPHA'                                  => 2470,
    'SCI_SETCARETLINEFRAME'                                      => 2705,
    'SCI_SETCARETLINEVISIBLE'                                    => 2096,
    'SCI_SETCARETLINEVISIBLEALWAYS'                              => 2655,
    'SCI_SETCARETPERIOD'                                         => 2076,
    'SCI_SETCARETSTICKY'                                         => 2458,
    'SCI_SETCARETSTYLE'                                          => 2512,
    'SCI_SETCARETWIDTH'                                          => 2188,
    'SCI_SETCHARACTERCATEGORYOPTIMIZATION'                       => 2720,
    'SCI_SETCHARSDEFAULT'                                        => 2444,
    'SCI_SETCODEPAGE'                                            => 2037,
    'SCI_SETCOMMANDEVENTS'                                       => 2717,
    'SCI_SETCONTROLCHARSYMBOL'                                   => 2388,
    'SCI_SETCURRENTPOS'                                          => 2141,
    'SCI_SETCURSOR'                                              => 2386,
    'SCI_SETDEFAULTFOLDDISPLAYTEXT'                              => 2722,
    'SCI_SETDOCPOINTER'                                          => 2358,
    'SCI_SETEDGECOLOUR'                                          => 2365,
    'SCI_SETEDGECOLUMN'                                          => 2361,
    'SCI_SETEDGEMODE'                                            => 2363,
    'SCI_SETEMPTYSELECTION'                                      => 2556,
    'SCI_SETENDATLASTLINE'                                       => 2277,
    'SCI_SETEOLMODE'                                             => 2031,
    'SCI_SETEXTRAASCENT'                                         => 2525,
    'SCI_SETEXTRADESCENT'                                        => 2527,
    'SCI_SETFIRSTVISIBLELINE'                                    => 2613,
    'SCI_SETFOCUS'                                               => 2380,
    'SCI_SETFOLDEXPANDED'                                        => 2229,
    'SCI_SETFOLDFLAGS'                                           => 2233,
    'SCI_SETFOLDLEVEL'                                           => 2222,
    'SCI_SETFOLDMARGINCOLOUR'                                    => 2290,
    'SCI_SETFOLDMARGINHICOLOUR'                                  => 2291,
    'SCI_SETFONTQUALITY'                                         => 2611,
    'SCI_SETHIGHLIGHTGUIDE'                                      => 2134,
    'SCI_SETHOTSPOTACTIVEBACK'                                   => 2411,
    'SCI_SETHOTSPOTACTIVEFORE'                                   => 2410,
    'SCI_SETHOTSPOTACTIVEUNDERLINE'                              => 2412,
    'SCI_SETHOTSPOTSINGLELINE'                                   => 2421,
    'SCI_SETHSCROLLBAR'                                          => 2130,
    'SCI_SETIDENTIFIER'                                          => 2622,
    'SCI_SETIDENTIFIERS'                                         => 4024,
    'SCI_SETIDLESTYLING'                                         => 2692,
    'SCI_SETIMEINTERACTION'                                      => 2679,
    'SCI_SETINDENT'                                              => 2122,
    'SCI_SETINDENTATIONGUIDES'                                   => 2132,
    'SCI_SETINDICATORCURRENT'                                    => 2500,
    'SCI_SETINDICATORVALUE'                                      => 2502,
    'SCI_SETKEYSUNICODE'                                         => 2521, # deprecated sci 3.56
    'SCI_SETKEYWORDS'                                            => 4005,
    'SCI_SETLAYOUTCACHE'                                         => 2272,
    'SCI_SETLENGTHFORENCODE'                                     => 2448,
    'SCI_SETLEXER'                                               => 4001,
    'SCI_SETLEXERLANGUAGE'                                       => 4006,
    'SCI_SETLINEENDTYPESALLOWED'                                 => 2656,
    'SCI_SETLINEINDENTATION'                                     => 2126,
    'SCI_SETLINESTATE'                                           => 2092,
    'SCI_SETMAINSELECTION'                                       => 2574,
    'SCI_SETMARGINBACKN'                                         => 2250,
    'SCI_SETMARGINCURSORN'                                       => 2248,
    'SCI_SETMARGINLEFT'                                          => 2155,
    'SCI_SETMARGINMASKN'                                         => 2244,
    'SCI_SETMARGINOPTIONS'                                       => 2539,
    'SCI_SETMARGINRIGHT'                                         => 2157,
    'SCI_SETMARGINS'                                             => 2252,
    'SCI_SETMARGINSENSITIVEN'                                    => 2246,
    'SCI_SETMARGINTYPEN'                                         => 2240,
    'SCI_SETMARGINWIDTHN'                                        => 2242,
    'SCI_SETMODEVENTMASK'                                        => 2359,
    'SCI_SETMOUSEDOWNCAPTURES'                                   => 2384,
    'SCI_SETMOUSEDWELLTIME'                                      => 2264,
    'SCI_SETMOUSESELECTIONRECTANGULARSWITCH'                     => 2668,
    'SCI_SETMOUSEWHEELCAPTURES'                                  => 2696,
    'SCI_SETMULTIPASTE'                                          => 2614,
    'SCI_SETMULTIPLESELECTION'                                   => 2563,
    'SCI_SETOVERTYPE'                                            => 2186,
    'SCI_SETPASTECONVERTENDINGS'                                 => 2467,
    'SCI_SETPHASESDRAW'                                          => 2674,
    'SCI_SETPOSITIONCACHE'                                       => 2514,
    'SCI_SETPRINTCOLOURMODE'                                     => 2148,
    'SCI_SETPRINTMAGNIFICATION'                                  => 2146,
    'SCI_SETPRINTWRAPMODE'                                       => 2406,
    'SCI_SETPROPERTY'                                            => 4004,
    'SCI_SETPUNCTUATIONCHARS'                                    => 2648,
    'SCI_SETREADONLY'                                            => 2171,
    'SCI_SETRECTANGULARSELECTIONANCHOR'                          => 2590,
    'SCI_SETRECTANGULARSELECTIONANCHORVIRTUALSPACE'              => 2594,
    'SCI_SETRECTANGULARSELECTIONCARET'                           => 2588,
    'SCI_SETRECTANGULARSELECTIONCARETVIRTUALSPACE'               => 2592,
    'SCI_SETRECTANGULARSELECTIONMODIFIER'                        => 2598,
    'SCI_SETREPRESENTATION'                                      => 2665,
    'SCI_SETSAVEPOINT'                                           => 2014,
    'SCI_SETSCROLLWIDTH'                                         => 2274,
    'SCI_SETSCROLLWIDTHTRACKING'                                 => 2516,
    'SCI_SETSEARCHFLAGS'                                         => 2198,
    'SCI_SETSEL'                                                 => 2160,
    'SCI_SETSELALPHA'                                            => 2478,
    'SCI_SETSELBACK'                                             => 2068,
    'SCI_SETSELECTION'                                           => 2572,
    'SCI_SETSELECTIONEND'                                        => 2144,
    'SCI_SETSELECTIONMODE'                                       => 2422,
    'SCI_SETSELECTIONNANCHOR'                                    => 2578,
    'SCI_SETSELECTIONNANCHORVIRTUALSPACE'                        => 2582,
    'SCI_SETSELECTIONNCARET'                                     => 2576,
    'SCI_SETSELECTIONNCARETVIRTUALSPACE'                         => 2580,
    'SCI_SETSELECTIONNEND'                                       => 2586,
    'SCI_SETSELECTIONNSTART'                                     => 2584,
    'SCI_SETSELECTIONSTART'                                      => 2142,
    'SCI_SETSELEOLFILLED'                                        => 2480,
    'SCI_SETSELFORE'                                             => 2067,
    'SCI_SETSTATUS'                                              => 2382,
    'SCI_SETSTYLEBITS'                                           => 2090, # deprecated npp7.8
    'SCI_SETSTYLING'                                             => 2033,
    'SCI_SETSTYLINGEX'                                           => 2073,
    'SCI_SETTABDRAWMODE'                                         => 2699,
    'SCI_SETTABINDENTS'                                          => 2260,
    'SCI_SETTABWIDTH'                                            => 2036,
    'SCI_SETTARGETEND'                                           => 2192,
    'SCI_SETTARGETRANGE'                                         => 2686,
    'SCI_SETTARGETSTART'                                         => 2190,
    'SCI_SETTECHNOLOGY'                                          => 2630,
    'SCI_SETTEXT'                                                => 2181,
    'SCI_SETTWOPHASEDRAW'                                        => 2284, # deprecated npp7.8
    'SCI_SETUNDOCOLLECTION'                                      => 2012,
    'SCI_SETUSEPALETTE'                                          => 2039, # deprecated sci3.56
    'SCI_SETUSETABS'                                             => 2124,
    'SCI_SETVIEWEOL'                                             => 2356,
    'SCI_SETVIEWWS'                                              => 2021,
    'SCI_SETVIRTUALSPACEOPTIONS'                                 => 2596,
    'SCI_SETVISIBLEPOLICY'                                       => 2394,
    'SCI_SETVSCROLLBAR'                                          => 2280,
    'SCI_SETWHITESPACEBACK'                                      => 2085,
    'SCI_SETWHITESPACECHARS'                                     => 2443,
    'SCI_SETWHITESPACEFORE'                                      => 2084,
    'SCI_SETWHITESPACESIZE'                                      => 2086,
    'SCI_SETWORDCHARS'                                           => 2077,
    'SCI_SETWRAPINDENTMODE'                                      => 2472,
    'SCI_SETWRAPMODE'                                            => 2268,
    'SCI_SETWRAPSTARTINDENT'                                     => 2464,
    'SCI_SETWRAPVISUALFLAGS'                                     => 2460,
    'SCI_SETWRAPVISUALFLAGSLOCATION'                             => 2462,
    'SCI_SETXCARETPOLICY'                                        => 2402,
    'SCI_SETXOFFSET'                                             => 2397,
    'SCI_SETYCARETPOLICY'                                        => 2403,
    'SCI_SETZOOM'                                                => 2373,
    'SCI_SHOWLINES'                                              => 2226,
    'SCI_START'                                                  => 2000,
    'SCI_STARTRECORD'                                            => 3001,
    'SCI_STARTSTYLING'                                           => 2032,
    'SCI_STOPRECORD'                                             => 3002,
    'SCI_STUTTEREDPAGEDOWN'                                      => 2437,
    'SCI_STUTTEREDPAGEDOWNEXTEND'                                => 2438,
    'SCI_STUTTEREDPAGEUP'                                        => 2435,
    'SCI_STUTTEREDPAGEUPEXTEND'                                  => 2436,
    'SCI_STYLECLEARALL'                                          => 2050,
    'SCI_STYLEGETBACK'                                           => 2482,
    'SCI_STYLEGETBOLD'                                           => 2483,
    'SCI_STYLEGETCASE'                                           => 2489,
    'SCI_STYLEGETCHANGEABLE'                                     => 2492,
    'SCI_STYLEGETCHARACTERSET'                                   => 2490,
    'SCI_STYLEGETEOLFILLED'                                      => 2487,
    'SCI_STYLEGETFONT'                                           => 2486,
    'SCI_STYLEGETFORE'                                           => 2481,
    'SCI_STYLEGETHOTSPOT'                                        => 2493,
    'SCI_STYLEGETITALIC'                                         => 2484,
    'SCI_STYLEGETSIZE'                                           => 2485,
    'SCI_STYLEGETSIZEFRACTIONAL'                                 => 2062,
    'SCI_STYLEGETUNDERLINE'                                      => 2488,
    'SCI_STYLEGETVISIBLE'                                        => 2491,
    'SCI_STYLEGETWEIGHT'                                         => 2064,
    'SCI_STYLERESETDEFAULT'                                      => 2058,
    'SCI_STYLESETBACK'                                           => 2052,
    'SCI_STYLESETBOLD'                                           => 2053,
    'SCI_STYLESETCASE'                                           => 2060,
    'SCI_STYLESETCHANGEABLE'                                     => 2099,
    'SCI_STYLESETCHARACTERSET'                                   => 2066,
    'SCI_STYLESETEOLFILLED'                                      => 2057,
    'SCI_STYLESETFONT'                                           => 2056,
    'SCI_STYLESETFORE'                                           => 2051,
    'SCI_STYLESETHOTSPOT'                                        => 2409,
    'SCI_STYLESETITALIC'                                         => 2054,
    'SCI_STYLESETSIZE'                                           => 2055,
    'SCI_STYLESETSIZEFRACTIONAL'                                 => 2061,
    'SCI_STYLESETUNDERLINE'                                      => 2059,
    'SCI_STYLESETVISIBLE'                                        => 2074,
    'SCI_STYLESETWEIGHT'                                         => 2063,
    'SCI_SWAPMAINANCHORCARET'                                    => 2607,
    'SCI_TAB'                                                    => 2327,
    'SCI_TAGSOFSTYLE'                                            => 4031,
    'SCI_TARGETASUTF8'                                           => 2447,
    'SCI_TARGETFROMSELECTION'                                    => 2287,
    'SCI_TARGETWHOLEDOCUMENT'                                    => 2690,
    'SCI_TEXTHEIGHT'                                             => 2279,
    'SCI_TEXTWIDTH'                                              => 2276,
    'SCI_TOGGLECARETSTICKY'                                      => 2459,
    'SCI_TOGGLEFOLD'                                             => 2231,
    'SCI_TOGGLEFOLDSHOWTEXT'                                     => 2700,
    'SCI_UNDO'                                                   => 2176,
    'SCI_UPPERCASE'                                              => 2341,
    'SCI_USEPOPUP'                                               => 2371,
    'SCI_USERLISTSHOW'                                           => 2117,
    'SCI_VCHOME'                                                 => 2331,
    'SCI_VCHOMEDISPLAY'                                          => 2652,
    'SCI_VCHOMEDISPLAYEXTEND'                                    => 2653,
    'SCI_VCHOMEEXTEND'                                           => 2332,
    'SCI_VCHOMERECTEXTEND'                                       => 2431,
    'SCI_VCHOMEWRAP'                                             => 2453,
    'SCI_VCHOMEWRAPEXTEND'                                       => 2454,
    'SCI_VERTICALCENTRECARET'                                    => 2619,
    'SCI_VISIBLEFROMDOCLINE'                                     => 2220,
    'SCI_WORDENDPOSITION'                                        => 2267,
    'SCI_WORDLEFT'                                               => 2308,
    'SCI_WORDLEFTEND'                                            => 2439,
    'SCI_WORDLEFTENDEXTEND'                                      => 2440,
    'SCI_WORDLEFTEXTEND'                                         => 2309,
    'SCI_WORDPARTLEFT'                                           => 2390,
    'SCI_WORDPARTLEFTEXTEND'                                     => 2391,
    'SCI_WORDPARTRIGHT'                                          => 2392,
    'SCI_WORDPARTRIGHTEXTEND'                                    => 2393,
    'SCI_WORDRIGHT'                                              => 2310,
    'SCI_WORDRIGHTEND'                                           => 2441,
    'SCI_WORDRIGHTENDEXTEND'                                     => 2442,
    'SCI_WORDRIGHTEXTEND'                                        => 2311,
    'SCI_WORDSTARTPOSITION'                                      => 2266,
    'SCI_WRAPCOUNT'                                              => 2235,
    'SCI_ZOOMIN'                                                 => 2333,
    'SCI_ZOOMOUT'                                                => 2334,
    'WM_USER'                                                    => 1024,
);

=item %SC_ACCESSIBILITY

Used by L<setAccessibility|Win32::Mechanize::NotepadPlusPlus::Editor/setAccessibility>.

    Key                         | Value | Description
    ----------------------------+-------+---------------------------
    SC_ACCESSIBILITY_DISABLED   | 0     | Accessibility is disabled
    SC_ACCESSIBILITY_ENABLED    | 1     | Accessibility is enabled

All of these values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_ACCESSIBILITY = (
    SC_ACCESSIBILITY_DISABLED   => 0,
    SC_ACCESSIBILITY_ENABLED    => 1,
);


=item %SC_ALPHA

Used by L<setSelAlpha|Win32::Mechanize::NotepadPlusPlus::Editor/setSelAlpha>
and many other methods that set or retrieve transparency settings.

These actally indicate the range, from SC_ALPHA_TRANSPARENT (100% transparent)
to SC_ALPHA_OPAQUE (100% opaque), with SC_ALPHA_NOALPHA (which also indicates
100% opaque, but might make for a more efficient drawing of the Scintilla
window because ALPHA is disabled, rather than just being 100% opaque.)

When setting transparency, any value from SC_ALPHA_TRANSPARENT through
SC_ALPHA_OPAQUE (or SC_ALPHA_NOALPHA) can be used; alpha settings do not
have to be one of these three defined values.

=cut

our %SC_ALPHA = (
    'SC_ALPHA_NOALPHA'                                           => 256,
    'SC_ALPHA_OPAQUE'                                            => 255,
    'SC_ALPHA_TRANSPARENT'                                       => 0,
);

=item %SC_ANNOTATION

Used by L<annotationSetVisible|Win32::Mechanize::NotepadPlusPlus::Editor/annotationSetVisible>

    Key                 |   | Description
    --------------------+---+-------------------------------------
    ANNOTATION_HIDDEN   | 0 | Annotations are not displayed.
    ANNOTATION_STANDARD | 1 | Annotations are drawn left justified with no adornment.
    ANNOTATION_BOXED    | 2 | Annotations are indented to match the text and are surrounded by a box.
    ANNOTATION_INDENTED | 3 | Annotations are indented to match the text.

=cut

our %SC_ANNOTATION = (
    'ANNOTATION_BOXED'                                           => 2,
    'ANNOTATION_HIDDEN'                                          => 0,
    'ANNOTATION_INDENTED'                                        => 3,
    'ANNOTATION_STANDARD'                                        => 1,
);

=item %SC_AUTOC_ORDER

Used by L<autoCSetOrder|Win32::Mechanize::NotepadPlusPlus::Editor/autoCSetOrder>.

    Key                  |   | Description
    ---------------------|---|-------------
    SC_ORDER_PRESORTED   | 0 | List must be already sorted alphabetically
    SC_ORDER_PERFORMSORT | 1 | Scintilla will sort the list
    SC_ORDER_CUSTOM      | 2 | Use a custom order

=cut

our %SC_AUTOC_ORDER = (
    'SC_ORDER_CUSTOM'                                            => 2,
    'SC_ORDER_PERFORMSORT'                                       => 1,
    'SC_ORDER_PRESORTED'                                         => 0,
);

=item %SC_AUTOMATICFOLD

Used by L<setAutomaticFold|Win32::Mechanize::NotepadPlusPlus::Editor/setAutomaticFold>

    Key                     |   | Description
    ------------------------+---+-------------
    SC_AUTOMATICFOLD_SHOW   | 1 | Automatically show lines as needed. This avoids sending the SCN_NEEDSHOWN notification.
    SC_AUTOMATICFOLD_CLIC   | 2 | Handle clicks in fold margin automatically. This avoids sending the SCN_MARGINCLICK notification for folding margins.
    SC_AUTOMATICFOLD_CHANGE | 4 | Show lines as needed when fold structure is changed. The SCN_MODIFIED notification is still sent unless it is disabled by the container.

=cut

our %SC_AUTOMATICFOLD = (
    'SC_AUTOMATICFOLD_CHANGE'                                    => 0x0004,
    'SC_AUTOMATICFOLD_CLICK'                                     => 0x0002,
    'SC_AUTOMATICFOLD_SHOW'                                      => 0x0001,
);

=item %SC_BIDIRECTIONAL

Used by L<setBidirectional|Win32::Mechanize::NotepadPlusPlus::Editor/setBidirectional>.

The default C<$SC_BIDIRECTIONAL{SC_BIDIRECTIONAL_DISABLED}> (0) means that only one direction is supported.

Enabling C<$SC_BIDIRECTIONAL{SC_BIDIRECTIONAL_L2R}> (1) means that left-to-right is the normal active direction, but UTF sequences can change text to right-to-left.

Enabling C<$SC_BIDIRECTIONAL{SC_BIDIRECTIONAL_R2L}> (2) means that right-to-left is the normal active direction, but UTF sequences can change text to left-to-right.

    Key                       |   | Description
    --------------------------+---+-------------
    SC_BIDIRECTIONAL_DISABLED | 0 | Not bidirectional
    SC_BIDIRECTIONAL_L2R      | 1 | Bidirectional, with left-to-right as normal direction
    SC_BIDIRECTIONAL_R2L      | 2 | Bidirectional, with right-to-left as normal direction

All of these values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_BIDIRECTIONAL = (
    SC_BIDIRECTIONAL_DISABLED => 0,
    SC_BIDIRECTIONAL_L2R      => 1,
    SC_BIDIRECTIONAL_R2L      => 2,
);

=item %SC_CACHE

Used by L<setLayoutCache|Win32::Mechanize::NotepadPlusPlus::Editor/setLayoutCache>

    Key                 |   | Description
    --------------------+---+-------------
    SC_CACHE_NONE       | 0 | No lines are cached.
    SC_CACHE_CARET      | 1 | The line containing the text caret. This is the default.
    SC_CACHE_PAGE       | 2 | Visible lines plus the line containing the caret.
    SC_CACHE_DOCUMENT   | 3 | All lines in the document.

=cut

our %SC_CACHE = (
    'SC_CACHE_CARET'                                             => 1,
    'SC_CACHE_DOCUMENT'                                          => 3,
    'SC_CACHE_NONE'                                              => 0,
    'SC_CACHE_PAGE'                                              => 2,
);

=item %SC_CARETPOLICY

Used by L<setXCaretPolicy|Win32::Mechanize::NotepadPlusPlus::Editor/setXCaretPolicy> and related.

    CARET_SLOP      | 0x01 | Will honor the $caretSlop setting
    CARET_STRICT    | 0x04 | If set, CARET_SLOP is strictly enforced
    CARET_EVEN      | 0x08 | If set, use symmetric zones; if unset, shift the zones
    CARET_JUMPS     | 0x10 | Caret moves more "energetically"

See Scintilla documentation for L<SCI_SETXCARETPOLICY|https://www.scintilla.org/ScintillaDoc.html#SCI_SETXCARETPOLICY> for details, and how they work in combination.

=cut

our %SC_CARETPOLICY = (
    'CARET_SLOP'      => 0x01,
    'CARET_STRICT'    => 0x04,
    'CARET_EVEN'      => 0x08,
    'CARET_JUMPS'     => 0x10,
);

=item %SC_CARETSTICKY

Used by L<setCaretSticky|Win32::Mechanize::NotepadPlusPlus::Editor/setCaretSticky>

    Key                         |   | Description
    ----------------------------+---+-------------
    SC_CARETSTICKY_OFF          | 0 | All moves or text changes will change caret's horizontal position (default)
    SC_CARETSTICKY_ON           | 1 | Only cursor movements will change the caret position
    SC_CARETSTICKY_WHITESPACE   | 2 | Like OFF, but whitespace-only insertion will not change caret position

=cut

our %SC_CARETSTICKY = (
    'SC_CARETSTICKY_OFF'                                         => 0,
    'SC_CARETSTICKY_ON'                                          => 1,
    'SC_CARETSTICKY_WHITESPACE'                                  => 2,
);

=item %SC_CARETSTYLE

Used by L<setCaretStyle|Win32::Mechanize::NotepadPlusPlus::Editor/setCaretStyle>.

    Key                         |       | Description
    ----------------------------+-------+------------------------
    CARETSTYLE_INVISIBLE        | 0     | No visible caret
    ----------------------------+-------+------------------------
    CARETSTYLE_LINE             | 1     | Caret is a line (in insert mode)
    CARETSTYLE_BLOCK            | 2     | Caret is a block (in insert mode)
    CARETSTYLE_INS_MASK         | 0xF   | Mask used for the insert mode bits, above [npp7.8]
    ----------------------------+-------+------------------------
    CARETSTYLE_OVERSTRIKE_BAR   | 0     | Caret is a bar (in overtype mode) [npp7.8]
    CARETSTYLE_OVERSTRIKE_BLOCK | 16    | Caret is a block (in overtype mode) [npp7.8]
    ----------------------------+-------+------------------------
    CARETSTYLE_BLOCK_AFTER      | 0x100 | Option for how the block is drawn [npp7.8]


For insert mode, the style of the caret can be set to a line caret (CARETSTYLE_LINE=1) or a block caret (CARETSTYLE_BLOCK=2) for insert mode (lower 4-bits, CARETSTYLE_INS_MASK) combined with a bar caret (CARETSTYLE_OVERSTRIKE_BAR=0) or a block caret (CARETSTYLE_OVERSTRIKE_BLOCK=16) for overtype mode (bit 4), or to not draw at all (CARETSTYLE_INVISIBLE=0). The default value for insert mode is the line caret (CARETSTYLE_LINE=1).

For overtype mode, the style of the caret can be set to the bar caret (CARETSTYLE_OVERSTRIKE_BAR=0) or a block caret  (CARETSTYLE_OVERSTRIKE_BLOCK)=16).

When the caret end of a range is at the end and a block caret style is chosen, the block is drawn just inside the selection instead of after. This can be switched with an option (CARETSTYLE_BLOCK_AFTER=256).

The value passed can be a bitwise-or of the insert-mode choice, the overtype mode choice, and the option value.

[npp7.8]: Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_CARETSTYLE = (
    'CARETSTYLE_BLOCK'                                           => 2,
    'CARETSTYLE_BLOCK_AFTER'                                     => 0x100,
    'CARETSTYLE_INS_MASK'                                        => 0xF,
    'CARETSTYLE_INVISIBLE'                                       => 0,
    'CARETSTYLE_LINE'                                            => 1,
    'CARETSTYLE_OVERSTRIKE_BAR'                                  => 0,
    'CARETSTYLE_OVERSTRIKE_BLOCK'                                => 0x10,
);

=item %SC_CASE

Used by L<styleSetCase|Win32::Mechanize::NotepadPlusPlus::Editor/styleSetCase>

    Key             |   | Description
    ----------------+---+-------------
    SC_CASE_MIXED   | 0 | Displays normally (same case as stored in text)
    SC_CASE_UPPER   | 1 | Displays as all upper case, even if there are lower case characters
    SC_CASE_LOWER   | 2 | Displays as all lower case, even if there are upper case characters
    SC_CASE_CAMEL   | 3 | Displays as Camel Case, regardless of underlying text case [npp7.8]

[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_CASE = (
    'SC_CASE_LOWER'                                              => 2,
    'SC_CASE_MIXED'                                              => 0,
    'SC_CASE_UPPER'                                              => 1,
    'SC_CASE_CAMEL'                                              => 3,
);

=item %SC_CASEINSENSITIVE

Used by L<autoCSetCaseInsensitiveBehaviour|Win32::Mechanize::NotepadPlusPlus::Editor/autoCSetCaseInsensitiveBehaviour>

    Key                                         |   | Description
    --------------------------------------------+---+-------------
    SC_CASEINSENSITIVEBEHAVIOUR_RESPECTCASE     | 0 | Respect case
    SC_CASEINSENSITIVEBEHAVIOUR_IGNORECASE      | 1 | Ignore case

=cut

our %SC_CASEINSENSITIVE = (
    'SC_CASEINSENSITIVEBEHAVIOUR_IGNORECASE'                     => 1,
    'SC_CASEINSENSITIVEBEHAVIOUR_RESPECTCASE'                    => 0,
);

=item %SC_CHARSET

Used by L<styleSetCharacterSet|Win32::Mechanize::NotepadPlusPlus::Editor/styleSetCharacterSet>

    Key                     | Value
    ------------------------+-------
    SC_CHARSET_ANSI         | 0
    SC_CHARSET_DEFAULT      | 1
    SC_CHARSET_SYMBOL       | 2
    SC_CHARSET_MAC          | 77
    SC_CHARSET_SHIFTJIS     | 128
    SC_CHARSET_HANGUL       | 129
    SC_CHARSET_JOHAB        | 130
    SC_CHARSET_GB2312       | 134
    SC_CHARSET_CHINESEBIG5  | 136
    SC_CHARSET_GREEK        | 161
    SC_CHARSET_TURKISH      | 162
    SC_CHARSET_VIETNAMESE   | 163
    SC_CHARSET_HEBREW       | 177
    SC_CHARSET_ARABIC       | 178
    SC_CHARSET_BALTIC       | 186
    SC_CHARSET_RUSSIAN      | 204
    SC_CHARSET_THAI         | 222
    SC_CHARSET_EASTEUROPE   | 238
    SC_CHARSET_OEM          | 255
    SC_CHARSET_OEM866       | 866       [npp7.8]
    SC_CHARSET_8859_15      | 1000
    SC_CHARSET_CYRILLIC     | 1251

C<$SC_CHARSET{SC_CHARSET_ANSI}> and C<$SC_CHARSET{SC_CHARSET_DEFAULT}> specify European Windows code page 1252 unless the code page is set.

[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut


our %SC_CHARSET = (
    'SC_CHARSET_8859_15'                                         => 1000,
    'SC_CHARSET_ANSI'                                            => 0,
    'SC_CHARSET_ARABIC'                                          => 178,
    'SC_CHARSET_BALTIC'                                          => 186,
    'SC_CHARSET_CHINESEBIG5'                                     => 136,
    'SC_CHARSET_CYRILLIC'                                        => 1251,
    'SC_CHARSET_DEFAULT'                                         => 1,
    'SC_CHARSET_EASTEUROPE'                                      => 238,
    'SC_CHARSET_GB2312'                                          => 134,
    'SC_CHARSET_GREEK'                                           => 161,
    'SC_CHARSET_HANGUL'                                          => 129,
    'SC_CHARSET_HEBREW'                                          => 177,
    'SC_CHARSET_JOHAB'                                           => 130,
    'SC_CHARSET_MAC'                                             => 77,
    'SC_CHARSET_OEM'                                             => 255,
    'SC_CHARSET_OEM866'                                          => 866,
    'SC_CHARSET_RUSSIAN'                                         => 204,
    'SC_CHARSET_SHIFTJIS'                                        => 128,
    'SC_CHARSET_SYMBOL'                                          => 2,
    'SC_CHARSET_THAI'                                            => 222,
    'SC_CHARSET_TURKISH'                                         => 162,
    'SC_CHARSET_VIETNAMESE'                                      => 163,
);

=item %SC_CODEPAGE

Used by L<setCodePage|Win32::Mechanize::NotepadPlusPlus::Editor/setCodePage>

    Key                                 |       | Description
    ------------------------------------+-------+-------------
    SC_CP_UTF8                          | 65501 | Unicode
    UNOFFICIAL_SHIFT_JIS                | 932   | Japanese Shift-JIS
    UNOFFICIAL_SIMPLIFIED_CHINESE_GBK   | 936   | Simplified Chinese GBK
    UNOFFICIAL_KOREAN_UNIFIED_HANGUL    | 949   | Korean Unified Hangul Code
    UNOFFICIAL_TRADITIONAL_CHINESE_BIG5 | 950   | Traditional Chinese Big5
    UNOFFICIAL_KOREAN_JOHAB             | 1361  | Korean Johab

SC_CP_UTF8 is the only SC_CODEPAGE value defined by Scintilla.  The others
were added unofficially to support codepages listed in the L<SCI_SETCODEPAGE|https://www.scintilla.org/ScintillaDoc.html#SCI_SETCODEPAGE> documentation from Scintilla.

=cut


our %SC_CODEPAGE = (
    #'SC_CP_DBCS'                                                 => 1, # removed SCIv3.7.1
    'SC_CP_UTF8'                                                 => 65001,
);

=item %SC_CURSOR

Used by L<setMarginCursorN|Win32::Mechanize::NotepadPlusPlus::Editor/setMarginCursorN> and
L<setCursor|Win32::Mechanize::NotepadPlusPlus::Editor/setCursor>

SC_CURSORARROW and SC_CURSORREVERSEARROW will set the direction of the arrow in the margin with C<setMarginCursorN()>.

with C<setCursor()>, SC_CURSORNORMAL (-1) will set the normal cursor behavior, and SC_CURSORWAIT (4) will set the cursor to a spinning "waiting for action" cursor

=cut

our %SC_CURSOR = (
    'SC_CURSORARROW'                                             => 2,
    'SC_CURSORNORMAL'                                            => -1,
    'SC_CURSORREVERSEARROW'                                      => 7,
    'SC_CURSORWAIT'                                              => 4,
);

=item %SC_DOCUMENTOPTION

Use by L<createDocument|Win32::Mechanize::NotepadPlusPlus::Editor/createDocument>

    Key                             |       | Description
    --------------------------------+-------+-------------
    SC_DOCUMENTOPTION_DEFAULT       | 0     | Standard behaviour
    SC_DOCUMENTOPTION_STYLES_NONE   | 0x1   | Stop allocation of memory for styles and treat all text as style 0.
    SC_DOCUMENTOPTION_TEXT_LARGE    | 0x100 | Allow document to be larger than 2 GB. (Experimental as of Scintilla v4.2.0, Notepad++ v7.8)

All of these values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_DOCUMENTOPTION = (
    'SC_DOCUMENTOPTION_DEFAULT'                                  => 0,
    'SC_DOCUMENTOPTION_STYLES_NONE'                              => 0x1,
    'SC_DOCUMENTOPTION_TEXT_LARGE'                               => 0x100,
);

=item %SC_EDGEMODE

Used by L<setEdgeMode|Win32::Mechanize::NotepadPlusPlus::Editor/setEdgeMode>

    Key             |   | Description
    ----------------+---+-------------
    EDGE_NONE       | 0 | Long lines are not marked. This is the default state.
    EDGE_LINE       | 1 | A vertical line is drawn at the column number set by SCI_SETEDGECOLUMN. This works well for monospaced fonts. The line is drawn at a position based on the width of a space character in STYLE_DEFAULT, so it may not work very well if your styles use proportional fonts or if your style have varied font sizes or you use a mixture of bold, italic and normal text.
    EDGE_BACKGROUND | 2 | The background colour of characters after the column limit is changed to the colour set by SCI_SETEDGECOLOUR. This is recommended for proportional fonts.
    EDGE_MULTILINE  | 3 | This is similar to EDGE_LINE but in contrary to showing only one single line a configurable set of vertical lines can be shown simultaneously. This edgeMode uses a completely independent dataset that can only be configured by using the SCI_MULTIEDGE* messages. [npp7.8]

[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_EDGEMODE = (
    'EDGE_BACKGROUND'                                            => 2,
    'EDGE_LINE'                                                  => 1,
    'EDGE_NONE'                                                  => 0,
    'EDGE_MULTILINE'                                             => 3,
);

=item %SC_EOL

Used by L<the line endings methods|Win32::Mechanize::NotepadPlusPlus::Editor/"Line endings">.

    Key         |   | Description
    ------------+---+-------------
    SC_EOL_CRLF | 0 | Use Windows EOL (CRLF = "\r\n")
    SC_EOL_CR   | 1 | Use old Mac EOL (CR = "\r")
    SC_EOL_LF   | 2 | Use Unix/Linx EOL (LF = "\n")

=cut

our %SC_EOL = (
    'SC_EOL_CR'                                                  => 1,
    'SC_EOL_CRLF'                                                => 0,
    'SC_EOL_LF'                                                  => 2,
);

=item %SC_EOLSUPPORT

Used by L<getLineEndTypesSupported|Win32::Mechanize::NotepadPlusPlus::Editor/getLineEndTypesSupported>

    Key                      |   | Line ending support
    -------------------------+---+----------------------------
    SC_LINE_END_TYPE_DEFAULT | 0 | Just normal line-endings
    SC_LINE_END_TYPE_UNICODE | 1 | Extra Unicode line-endings

=cut


our %SC_EOLSUPPORT = (
    'SC_LINE_END_TYPE_DEFAULT'                                   => 0,
    'SC_LINE_END_TYPE_UNICODE'                                   => 1,
);

=item %SC_FIND

Used by L<findText|Win32::Mechanize::NotepadPlusPlus::Editor/findText>

The values should be bitwise-or'd together to form the findText argument.

    %scimsg key         | Value      | Description
    --------------------+------------+-----------------------------------------------------------------
    SCFIND_NONE         | 0x00000000 | (default) Case-insentitive, literal match
    SCFIND_MATCHCASE    | 0x00000004 | Case-sensitive
    SCFIND_WHOLEWORD    | 0x00000002 | Matches only whole words ( see editor()->setWordChars )
    SCFIND_WORDSTART    | 0x00100000 | Matches the start of whole words ( see editor()->setWordChars )
    SCFIND_REGEXP       | 0x00200000 | Matches as a Scintilla regular expression
    SCFIND_POSIX        | 0x00400000 | (*) Matches a regular expression, with POSIX () groups
    SCFIND_CXX11REGEX   | 0x00800000 | (*) Matches using C++11 <regex> library

    (*) means it should be used in conjunction with SCFIND_REGEXP

See Scintilla documentation for  L<searchFlags|https://www.scintilla.org/ScintillaDoc.html#searchFlags>

=cut

our %SC_FIND = (
    'SCFIND_NONE'                                                 => 0x0,
    'SCFIND_CXX11REGEX'                                           => 0x00800000,
    'SCFIND_MATCHCASE'                                            => 0x4,
    'SCFIND_POSIX'                                                => 0x00400000,
    'SCFIND_REGEXP'                                               => 0x00200000,
    'SCFIND_WHOLEWORD'                                            => 0x2,
    'SCFIND_WORDSTART'                                            => 0x00100000,
);

=item %SC_FOLDACTION

Used by L<foldLine|Win32::Mechanize::NotepadPlusPlus::Editor/foldLine> and related methods.

    Key                     |   | Description
    ------------------------+---+-------------
    SC_FOLDACTION_CONTRACT  | 0 | Contract
    SC_FOLDACTION_EXPAND    | 1 | Expand
    SC_FOLDACTION_TOGGLE    | 2 | Toggle between contracted and expanded


=cut

our %SC_FOLDACTION = (
    'SC_FOLDACTION_CONTRACT'                                     => 0,
    'SC_FOLDACTION_EXPAND'                                       => 1,
    'SC_FOLDACTION_TOGGLE'                                       => 2,
);

=item %SC_FOLDDISPLAYTEXT

Used by L<foldDisplayTextSetStyle|Win32::Mechanize::NotepadPlusPlus::Editor/foldDisplayTextSetStyle>.

    %scimsg key                 | Value | Description
    ----------------------------+-------+------------------------------------------------
    SC_FOLDDISPLAYTEXT_HIDDEN   | 0     | Do not display text tags
    SC_FOLDDISPLAYTEXT_STANDARD | 1     | Display text tags
    SC_FOLDDISPLAYTEXT_BOXED    | 2     | Display text tags with a box drawn around them

All of these values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_FOLDDISPLAYTEXT = (
    'SC_FOLDDISPLAYTEXT_BOXED'                                   => 2,
    'SC_FOLDDISPLAYTEXT_HIDDEN'                                  => 0,
    'SC_FOLDDISPLAYTEXT_STANDARD'                                => 1,
);


=item %SC_FOLDFLAG

Used by L<setFoldFlags|Win32::Mechanize::NotepadPlusPlus::Editor/setFoldFlags>.

Use a bitwise-or of one or more of the following flags:

    Key                                 |     | Description
    ------------------------------------+-----+-------------
    SC_FOLDFLAG_LINEBEFORE_EXPANDED     | 2   | Draw above if expanded
    SC_FOLDFLAG_LINEBEFORE_CONTRACTED   | 4   | Draw above if not expanded
    SC_FOLDFLAG_LINEAFTER_EXPANDED      | 8   | Draw below if expanded
    SC_FOLDFLAG_LINEAFTER_CONTRACTED    | 16  | Draw below if not expanded
    SC_FOLDFLAG_LEVELNUMBERS            | 64  | display hexadecimal fold levels (*)
    SC_FOLDFLAG_LINESTATE               | 128 | display hexadecimal line state (+)

*: The appearance of this feature may change in the future.
+: May not be used at the same time as SC_FOLDFLAG_LEVELNUMBERS

=cut

our %SC_FOLDFLAG = (
    'SC_FOLDFLAG_LEVELNUMBERS'                                   => 0x0040,
    'SC_FOLDFLAG_LINEAFTER_CONTRACTED'                           => 0x0010,
    'SC_FOLDFLAG_LINEAFTER_EXPANDED'                             => 0x0008,
    'SC_FOLDFLAG_LINEBEFORE_CONTRACTED'                          => 0x0004,
    'SC_FOLDFLAG_LINEBEFORE_EXPANDED'                            => 0x0002,
    'SC_FOLDFLAG_LINESTATE'                                      => 0x0080,
);

=item %SC_FOLDLEVEL

Used by L<setFoldLevel|Win32::Mechanize::NotepadPlusPlus::Editor/setFoldLevel>.

Use a bitwise-or of one or more of the following flags:

    Key                     |      | Description
    ------------------------+------+-------------
    SC_FOLDLEVELBASE        | 1024 | Default fold level setting
    SC_FOLDLEVELNUMBERMASK  | 4095 | Fold level can be set to 0 .. SC_FOLDLEVELNUMBERMASK
    SC_FOLDLEVELWHITEFLAG   | 4096 | Flag bit: line is blank and level is not as important
    SC_FOLDLEVELHEADERFLAG  | 8192 | Flag bit: indicates it's a header (fold point)

You can set the level to anything between 0 .. SC_FOLDLEVELNUMBERMASK, so you are not
restricted to using just these hash values.

See Scintilla documentation for  L<SCI_SETFOLDLEVEL|https://www.scintilla.org/ScintillaDoc.html#SCI_SETFOLDLEVEL>

=cut

our %SC_FOLDLEVEL = (
    'SC_FOLDLEVELBASE'                                           => 0x400,
    'SC_FOLDLEVELNUMBERMASK'                                     => 0x0FFF,
    'SC_FOLDLEVELHEADERFLAG'                                     => 0x2000,
    'SC_FOLDLEVELWHITEFLAG'                                      => 0x1000,
);

=item %SC_FONTQUAL

Used by L<setFontQuality|Win32::Mechanize::NotepadPlusPlus::Editor/setFontQuality> to
set the font quality (antialiasing method)

    Key                             |     | Description
    --------------------------------+-----+-------------
    SC_EFF_QUALITY_DEFAULT          | 0   | Default, backward compatible
    SC_EFF_QUALITY_NON_ANTIALIASED  | 1   | Not antialiased
    SC_EFF_QUALITY_ANTIALIASED      | 2   | Antialiased
    SC_EFF_QUALITY_LCD_OPTIMIZED    | 3   | Optimized for LCD
    SC_EFF_QUALITY_MASK             | 0xF | *Only 4 bits apply to antialiasing

(*: In the future, there may be more attributes set by C<setFontQuality()> than just antialiasing, so the SC_EFF_QUALITY_MASK is used to indicate that antialiasing settings will be limited to four bits.)

=cut

our %SC_FONTQUAL = (
    'SC_EFF_QUALITY_ANTIALIASED'                                 => 2,
    'SC_EFF_QUALITY_DEFAULT'                                     => 0,
    'SC_EFF_QUALITY_LCD_OPTIMIZED'                               => 3,
    'SC_EFF_QUALITY_MASK'                                        => 0xF,
    'SC_EFF_QUALITY_NON_ANTIALIASED'                             => 1,
);

=item %SC_FONTSIZE

Referenced by L<styleSetSizeFractional|Win32::Mechanize::NotepadPlusPlus::Editor/styleSetSizeFractional>.

The sole key, SC_FONT_SIZE_MULTIPLIER (100), is used for scaling a fractional number of points to an integer for use in C<styleSetSizeFractional()>.

=cut

our %SC_FONTSIZE = (
    'SC_FONT_SIZE_MULTIPLIER'                                    => 100,
);

=item %SC_IDLESTYLING

Used by L<setIdleStyling|Win32::Mechanize::NotepadPlusPlus::Editor/setIdleStyling>.

    Key                         |   | Description
    ----------------------------|---|-------------
    SC_IDLESTYLING_NONE         | 0 | (default) Syntax styling for all visible text (may be slow for large files)
    SC_IDLESTYLING_TOVISIBLE    | 1 | Syntax styling in small increments as background idle-task
    SC_IDLESTYLING_AFTERVISIBLE | 2 | Syntax styling for following text as idle-task
    SC_IDLESTYLING_ALL          | 3 | Syntax styling for preceding and following text as idle-task

All of these values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_IDLESTYLING = (
    'SC_IDLESTYLING_NONE'         => 0,
    'SC_IDLESTYLING_TOVISIBLE'    => 1,
    'SC_IDLESTYLING_AFTERVISIBLE' => 2,
    'SC_IDLESTYLING_ALL'          => 3,

);

=item %SC_IME

Used by L<setIMEInteraction|Win32::Mechanize::NotepadPlusPlus::Editor/setIMEInteraction>

    Key             |   | Description
    ----------------+---+-------------
    SC_IME_WINDOWED | 0 | Uses a floating window for IME
    SC_IME_INLINE   | 1 | Puts the IME inline with the text

The SC_IME_INLINE may work better with features like rectangular and multiple selection.

=cut

our %SC_IME = (
    'SC_IME_INLINE'                                              => 1,
    'SC_IME_WINDOWED'                                            => 0,
);

=item %SC_INDENTGUIDE

Used by L<setIndentationGuides|Win32::Mechanize::NotepadPlusPlus::Editor/setIndentationGuides>.

    Key               |   | Description
    ------------------+---+-------------
    SC_IV_NONE        | 0 | Not shown
    SC_IV_REAL        | 1 | Shown inside real indentation white space
    SC_IV_LOOKFORWARD | 2 | Shown beyond the actual indentation
    SC_IV_LOOKBOTH    | 3 | Shown beyond the actual indentation

The diffrence between the last two is subtle, and not single-line explainable; see the Scintilla documentation for  L<SCI_SETINDENTATIONGUIDES|https://www.scintilla.org/ScintillaDoc.html#SCI_SETINDENTATIONGUIDES> for details on the difference.

=cut

our %SC_INDENTGUIDE = (
    'SC_IV_LOOKBOTH'                                             => 3,
    'SC_IV_LOOKFORWARD'                                          => 2,
    'SC_IV_NONE'                                                 => 0,
    'SC_IV_REAL'                                                 => 1,
);

=item %SC_INDIC

There is only one predefined flag value defined for L<indicSetFlags|Win32::Mechanize::NotepadPlusPlus::Editor/indicSetFlags>,
plus a flag bit and a mask that can be used in conjunction with
L<setIndicatorValue|Win32::Mechanize::NotepadPlusPlus::Editor/setIndicatorValue>.

    Key                     |           | Description
    ------------------------+-----------+-------------
    SC_INDICFLAG_VALUEFORE  | 1         | The indicator foreground depends on file location
    ------------------------+-----------+-------------
    SC_INDICVALUEMASK       | 0x0FFFFFF | Mask for getting value without the flag bit
    SC_INDICVALUEBIT        | 0x1000000 | Flag bit set true in setIndicatorValue()

=cut


our %SC_INDIC = (
    'SC_INDICFLAG_VALUEFORE'                                     => 1,
    'SC_INDICVALUEBIT'                                           => 0x1000000,
    'SC_INDICVALUEMASK'                                          => 0xFFFFFF,
);

#=item %SC_INDICS_DEPRECATED
#
# not used, npp7.8
#
#=cut

our %SC_INDICS_DEPRECATED = ( # not used by scintilla anymore
    'INDIC0_MASK'                                                => 0x20,
    'INDIC1_MASK'                                                => 0x40,
    'INDIC2_MASK'                                                => 0x80,
    'INDICS_MASK'                                                => 0xE0,
);

=item %SC_INDICSTYLE

Used by L<indicSetStyle|Win32::Mechanize::NotepadPlusPlus::Editor/indicSetStyle>

    ------------------------+----+--------------------------------------
    INDIC_PLAIN             | 0  | A plain underline.
    INDIC_SQUIGGLE          | 1  | A squiggly underline.
    INDIC_TT                | 2  | A line of small T shapes.
    INDIC_DIAGONAL          | 3  | Diagonal hatching.
    INDIC_STRIKE            | 4  | Strike out.
    INDIC_HIDDEN            | 5  | An indicator with no visual effect.
    INDIC_BOX               | 6  | A rectangle around the text.
    INDIC_ROUNDBOX          | 7  | A rectangle with rounded corners
    INDIC_STRAIGHTBOX       | 8  | A rectangle, filled but semi-transparent
    INDIC_FULLBOX           | 16 | A rectangle, filled but semi-transparent (larger)
    INDIC_DASH              | 9  | A dashed underline.
    INDIC_DOTS              | 10 | A dotted underline.
    INDIC_SQUIGGLELOW       | 11 | Smaller squiggly underline.
    INDIC_DOTBOX            | 12 | A dotted rectangle around the text.
    INDIC_GRADIENT          | 20 | A vertical gradient, top to bottom.
    INDIC_GRADIENTCENTRE    | 21 | A vertical gradient, center to outside.
    INDIC_SQUIGGLEPIXMAP    | 13 | A squiggle drawn more efficiently but not as pretty.
    INDIC_COMPOSITIONTHICK  | 14 | A 2-pixel underline, lower than INDIC_PLAIN
    INDIC_COMPOSITIONTHIN   | 15 | A 1-pixel underline.
    INDIC_TEXTFORE          | 17 | Change text foreground.
    INDIC_POINT             | 18 | A triangle below the start of the indicator.
    INDIC_POINTCHARACTER    | 19 | A triangle below the center of the first character.
    INDIC_EXPLORERLINK      | 22 | Indicator used for hyperlinks [npp7.9]
    ------------------------+----+--------------------------------------
    INDICATOR_CONTAINER     | 8  | Containers use indexes 8-31 [npp7.8]
    INDICATOR_IME           | 32 | IME use indexes 32 - IME_MAX [npp7.8]
    INDICATOR_IME_MAX       | 35 | Maximum IME index [npp7.8]
    INDICATOR_MAX           | 35 | Maximum indicator index [npp7.8]

Note that the INDICATOR_* values are used as style indexes, not style values.  (The Scintilla
Documentation also gives older INDIC_ values for those, but claims that the INDICATOR_ name is
preferred, so that is all that is implemented here.)

[npp#.#] Value added in particular version of Notepad++; not available in earlier versions.
[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_INDICSTYLE = (
    'INDIC_BOX'                                                  => 6,
    'INDIC_COMPOSITIONTHICK'                                     => 14,
    'INDIC_COMPOSITIONTHIN'                                      => 15,
    'INDIC_DASH'                                                 => 9,
    'INDIC_DIAGONAL'                                             => 3,
    'INDIC_DOTBOX'                                               => 12,
    'INDIC_DOTS'                                                 => 10,
    'INDIC_EXPLORERLINK'                                         => 22, # v7.9.0
    'INDIC_FULLBOX'                                              => 16,
    'INDIC_GRADIENT'                                             => 20,
    'INDIC_GRADIENTCENTRE'                                       => 21,
    'INDIC_HIDDEN'                                               => 5,
    'INDIC_PLAIN'                                                => 0,
    'INDIC_POINT'                                                => 18,
    'INDIC_POINTCHARACTER'                                       => 19,
    'INDIC_ROUNDBOX'                                             => 7,
    'INDIC_SQUIGGLE'                                             => 1,
    'INDIC_SQUIGGLELOW'                                          => 11,
    'INDIC_SQUIGGLEPIXMAP'                                       => 13,
    'INDIC_STRAIGHTBOX'                                          => 8,
    'INDIC_STRIKE'                                               => 4,
    'INDIC_TEXTFORE'                                             => 17,
    'INDIC_TT'                                                   => 2,
    'INDICATOR_CONTAINER'                                            => 8,
    'INDICATOR_IME'                                                  => 32,
    'INDICATOR_IME_MAX'                                              => 35,
    'INDICATOR_MAX'                                                  => 35,
);

=item %SC_KEY

Used by L<key binding methods|Win32::Mechanize::NotepadPlusPlus::Editor/"Key bindings">

Available Keys:

    Hash-Key Name | Keycode | Description
    --------------+---------+-------------
    SCK_ESCAPE    | 7       | Esc/Escape
    SCK_BACK      | 8       | Backspace
    SCK_TAB       | 9       | Tab
    SCK_RETURN    | 13      | Return/Enter
    SCK_DOWN      | 300     | Down arrow
    SCK_UP        | 301     | Up arrow
    SCK_LEFT      | 302     | Left arrow
    SCK_RIGHT     | 303     | Right arrow
    SCK_HOME      | 304     | Home
    SCK_END       | 305     | End
    SCK_PRIOR     | 306     | PageUp
    SCK_NEXT      | 307     | PageDown
    SCK_DELETE    | 308     | Del/Delete
    SCK_INSERT    | 309     | Ins/Insert
    SCK_ADD       | 310     | Numeric Keypad +
    SCK_SUBTRACT  | 311     | Numeric Keypad -
    SCK_DIVIDE    | 312     | Numeric Keypad /
    SCK_WIN       | 313     | Windows Key
    SCK_RWIN      | 314     | Right Windows Key
    SCK_MENU      | 315     | Menu Key

Key Modifiers:

    Hash-Key Name | Value   | Description
    --------------+---------+-------------
    SCMOD_NORM    | 0       | Unmodified
    SCMOD_SHIFT   | 1       | Shift
    SCMOD_CTRL    | 2       | Ctrl
    SCMOD_ALT     | 4       | Alt
    SCMOD_SUPER   | 8       | Super can indicate the Windows key as the modifier
    SCMOD_META    | 16      | Some systems may use Meta instead of Ctrl or Alt

For normal keys (letters, numbers, punctuation), the $km ("key+modifier") code is the
codepoint for that character.  For special keys (arrows, Escape, and similar), use the
C<$SCKEY{SCK_*}> entry for that key.  If you want to indicate a modified key, add on
the C<$SCKEY{SCK_*}> shifted 16 bits up.

    # Ctrl+HOME being assigned to SCI_HOME
    my $km_ctrl_home = $SCKEY{SCK_HOME} + ($SCKEY{SCMOD_CTRL}<<16);
    notepad->assignCmdKey($km_alt_q, $SCIMSG{SCI_HOME});

    # Alt+Q being assigned to SCI_SELECTALL
    my $km_alt_q = ord('Q') + ($SCKEY{SCMOD_ALT}<<16);
    notepad->assignCmdKey($km_alt_q, $SCIMSG{SCI_SELECTALL});


=cut

our %SC_KEY = (
    'SCK_ADD'                                                    => 310,
    'SCK_BACK'                                                   => 8,
    'SCK_DELETE'                                                 => 308,
    'SCK_DIVIDE'                                                 => 312,
    'SCK_DOWN'                                                   => 300,
    'SCK_END'                                                    => 305,
    'SCK_ESCAPE'                                                 => 7,
    'SCK_HOME'                                                   => 304,
    'SCK_INSERT'                                                 => 309,
    'SCK_LEFT'                                                   => 302,
    'SCK_MENU'                                                   => 315,
    'SCK_NEXT'                                                   => 307,
    'SCK_PRIOR'                                                  => 306,
    'SCK_RETURN'                                                 => 13,
    'SCK_RIGHT'                                                  => 303,
    'SCK_RWIN'                                                   => 314,
    'SCK_SUBTRACT'                                               => 311,
    'SCK_TAB'                                                    => 9,
    'SCK_UP'                                                     => 301,
    'SCK_WIN'                                                    => 313,
    'SCMOD_ALT'                                                  => 4,
    'SCMOD_CTRL'                                                 => 2,
    'SCMOD_META'                                                 => 16,
    'SCMOD_NORM'                                                 => 0,
    'SCMOD_SHIFT'                                                => 1,
    'SCMOD_SUPER'                                                => 8,
);

=item %SC_KEYWORDSET

Used by L<setKeyWords|Win32::Mechanize::NotepadPlusPlus::Editor/setKeyWords>.

The only key is KEYWORDSET_MAX, which indicates the maximum index for the keywordSet.
It is zero based, so there are $KEYWORDSET{KEYWORDSET_MAX}+1 sets of keywords allowed,
with indexes from 0 to $KEYWORDSET{KEYWORDSET_MAX}.

This is generally used by lexers, to define the different groups of keywords (like
"NUMBER", "INSTRUCTION WORD", "STRING", "REGEX" and similar in the Perl lexer).

=cut

our %SC_KEYWORDSET = (
    'SC_KEYWORDSET_MAX'                                             => 30,
);

=item %SC_LINECHARACTERINDEX

Used by L<getLineCharacterIndex|Win32::Mechanize::NotepadPlusPlus::Editor/getLineCharacterIndex>.

    Key                         |   | Description
    ----------------------------|---|-------------
    SC_LINECHARACTERINDEX_NONE  | 0 | If only bytes are indexed
    SC_LINECHARACTERINDEX_UTF32 | 1 | If whole 32bit (4byte) UTF32 characters are indexed
    SC_LINECHARACTERINDEX_UTF16 | 2 | If whole 16bit (2byte) UTF16 code units are indexed

All of these values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_LINECHARACTERINDEX = (
    'SC_LINECHARACTERINDEX_NONE'                                 => 0,
    'SC_LINECHARACTERINDEX_UTF16'                                => 2,
    'SC_LINECHARACTERINDEX_UTF32'                                => 1,
);


=item %SC_MARGIN

Used by L<setMarginTypeN|Win32::Mechanize::NotepadPlusPlus::Editor/setMarginTypeN> and other margin-related commands

    Key                           |   | Description
    ------------------------------+---+-------------
                   margin indexes |   |
    SC_MAX_MARGIN                 | 4 | The initial margins are indexed 0 .. SC_MAX_MARGIN
    ------------------------------+---+-------------
                     margin types |   |
    SC_MARGIN_SYMBOL              | 0 | Use a symbol in the margin
    SC_MARGIN_NUMBER              | 1 | Use line number in the margin
    SC_MARGIN_TEXT                | 4 | Use left-justified text in the margin
    SC_MARGIN_RTEXT               | 5 | Use right-justified text in the margin
    SC_MARGIN_BACK                | 2 | Use STYLE_DEFAULT's background color on a margin-symbol
    SC_MARGIN_FORE                | 3 | Use STYLE_DEFAULT's foreground color on a margin-symbol
    SC_MARGIN_COLOUR              | 6 | Use spefied color on a margin-symbol [npp7.8]
    ------------------------------+---+-------------
                   margin options |   |
    SC_MARGINOPTION_NONE          | 0 | No option set via setMarginOptions()
    SC_MARGINOPTION_SUBLINESELECT | 1 | Affects whole-line selection of wrapped text

If the SUBLINESELECT is enabled, clicking on the margin will only select the visible "line" (even if line-wrap extends the real line to more than one screen line); if disabled (default), clicking on the margin will select the entire real line (even if line-wrap extends the real line to more than one screen line)

See also Scintilla's L<MARGIN|https://www.scintilla.org/ScintillaDoc.html#Margins> documentation.

[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_MARGIN = (
    'SC_MARGINOPTION_NONE'                                       => 0,
    'SC_MARGINOPTION_SUBLINESELECT'                              => 1,
    'SC_MARGIN_SYMBOL'                                           => 0,
    'SC_MARGIN_NUMBER'                                           => 1,
    'SC_MARGIN_BACK'                                             => 2,
    'SC_MARGIN_FORE'                                             => 3,
    'SC_MARGIN_TEXT'                                             => 4,
    'SC_MARGIN_RTEXT'                                            => 5,
    'SC_MARGIN_COLOUR'                                           => 6,
    'SC_MAX_MARGIN'                                              => 4,
);

=item %SC_MARK

Used as the $markerSymbol by L<markerDefine|Win32::Mechanize::NotepadPlusPlus::Editor/markerDefine> and related metbhods.

    Key                             |
    --------------------------------|-------
    SC_MARK_ARROW                   | 2
    SC_MARK_ARROWDOWN               | 6
    SC_MARK_ARROWS                  | 24
    SC_MARK_AVAILABLE               | 28
    SC_MARK_BACKGROUND              | 22
    SC_MARK_BOOKMARK                | 31
    SC_MARK_BOXMINUS                | 14
    SC_MARK_BOXMINUSCONNECTED       | 15
    SC_MARK_BOXPLUS                 | 12
    SC_MARK_BOXPLUSCONNECTED        | 13
    SC_MARK_CHARACTER               | 10000
    SC_MARK_CIRCLE                  | 0
    SC_MARK_CIRCLEMINUS             | 20
    SC_MARK_CIRCLEMINUSCONNECTED    | 21
    SC_MARK_CIRCLEPLUS              | 18
    SC_MARK_CIRCLEPLUSCONNECTED     | 19
    SC_MARK_DOTDOTDOT               | 23
    SC_MARK_EMPTY                   | 5
    SC_MARK_FULLRECT                | 26
    SC_MARK_LCORNER                 | 10
    SC_MARK_LCORNERCURVE            | 16
    SC_MARK_LEFTRECT                | 27
    SC_MARK_MINUS                   | 7
    SC_MARK_PIXMAP                  | 25
    SC_MARK_PLUS                    | 8
    SC_MARK_RGBAIMAGE               | 30
    SC_MARK_ROUNDRECT               | 1
    SC_MARK_SHORTARROW              | 4
    SC_MARK_SMALLRECT               | 3
    SC_MARK_TCORNER                 | 11
    SC_MARK_TCORNERCURVE            | 17
    SC_MARK_UNDERLINE               | 29
    SC_MARK_VERTICALBOOKMARK        | 32    [npp7.8]
    SC_MARK_VLINE                   | 9

Hopefully, the names describe the symbol.  If it's not sufficient,
then see the Scintilla documentation for  L<SCI_MARKERDEFINE|https://www.scintilla.org/ScintillaDoc.html#SCI_MARKERDEFINE>, which has an image of the marker symbols.

[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_MARK = (
    'SC_MARK_ARROW'                                              => 2,
    'SC_MARK_ARROWDOWN'                                          => 6,
    'SC_MARK_ARROWS'                                             => 24,
    'SC_MARK_AVAILABLE'                                          => 28,
    'SC_MARK_BACKGROUND'                                         => 22,
    'SC_MARK_BOOKMARK'                                           => 31,
    'SC_MARK_BOXMINUS'                                           => 14,
    'SC_MARK_BOXMINUSCONNECTED'                                  => 15,
    'SC_MARK_BOXPLUS'                                            => 12,
    'SC_MARK_BOXPLUSCONNECTED'                                   => 13,
    'SC_MARK_CHARACTER'                                          => 10000,
    'SC_MARK_CIRCLE'                                             => 0,
    'SC_MARK_CIRCLEMINUS'                                        => 20,
    'SC_MARK_CIRCLEMINUSCONNECTED'                               => 21,
    'SC_MARK_CIRCLEPLUS'                                         => 18,
    'SC_MARK_CIRCLEPLUSCONNECTED'                                => 19,
    'SC_MARK_DOTDOTDOT'                                          => 23,
    'SC_MARK_EMPTY'                                              => 5,
    'SC_MARK_FULLRECT'                                           => 26,
    'SC_MARK_LCORNER'                                            => 10,
    'SC_MARK_LCORNERCURVE'                                       => 16,
    'SC_MARK_LEFTRECT'                                           => 27,
    'SC_MARK_MINUS'                                              => 7,
    'SC_MARK_PIXMAP'                                             => 25,
    'SC_MARK_PLUS'                                               => 8,
    'SC_MARK_RGBAIMAGE'                                          => 30,
    'SC_MARK_ROUNDRECT'                                          => 1,
    'SC_MARK_SHORTARROW'                                         => 4,
    'SC_MARK_SMALLRECT'                                          => 3,
    'SC_MARK_TCORNER'                                            => 11,
    'SC_MARK_TCORNERCURVE'                                       => 17,
    'SC_MARK_UNDERLINE'                                          => 29,
    'SC_MARK_VERTICALBOOKMARK'                                   => 32,
    'SC_MARK_VLINE'                                              => 9,
);

=item %SC_MARKNUM

Used by L<marker-related methods|Win32::Mechanize::NotepadPlusPlus::Editor/Markers>.

    Key                      |            | Description
    -------------------------+------------+------------------------------------
    MARKER_MAX               | 31         | The highest $markerNumber available
    SC_MARKNUM_FOLDEROPEN    | 31         | Start of uncollapsed folding region
    SC_MARKNUM_FOLDER        | 30         | Start of collapsed folding region
    SC_MARKNUM_FOLDERSUB     | 29         | Inside of uncollapsed folding region
    SC_MARKNUM_FOLDERTAIL    | 28         | End of uncollapsed folding region
    SC_MARKNUM_FOLDEREND     | 25         | Branch of collapsed folding region (such as "else" block)
    SC_MARKNUM_FOLDEROPENMID | 26         | Branch of uncollapsed folding region (such as "else" block)
    SC_MARKNUM_FOLDERMIDTAIL | 27         | Branch-of uncollapsed folding region (such as "else" block)
    -------------------------+------------+------------------------------------
    SC_MASK_FOLDERS          | 0xFE000000 | Useful for setMarginMaskN


=cut


our %SC_MARKNUM = (
    'SC_MARKNUM_FOLDER'                                          => 30,
    'SC_MARKNUM_FOLDEREND'                                       => 25,
    'SC_MARKNUM_FOLDERMIDTAIL'                                   => 27,
    'SC_MARKNUM_FOLDEROPEN'                                      => 31,
    'SC_MARKNUM_FOLDEROPENMID'                                   => 26,
    'SC_MARKNUM_FOLDERSUB'                                       => 29,
    'SC_MARKNUM_FOLDERTAIL'                                      => 28,
    'MARKER_MAX'                                                 => 31, # SC_MARKNUM{MARKER_MAX}
    'SC_MASK_FOLDERS'                                            => 0xFE000000,
);

=item %SC_MOD

Used by L<setModEventMask|Win32::Mechanize::NotepadPlusPlus::Editor/setModEventMask> and the SCN_MODIFIED L<notification|/NOTIFICATIONS>.

    Key                     | Value    |
    ------------------------+----------+-
    SC_LASTSTEPINUNDOREDO   | 0x100    |
    SC_MULTISTEPUNDOREDO    | 0x80     |
    SC_MULTILINEUNDOREDO    | 0x1000   |
    SC_STARTACTION          | 0x2000   |
    SC_MOD_NONE             | 0x0      |
    SC_MOD_BEFOREDELETE     | 0x800    |
    SC_MOD_BEFOREINSERT     | 0x400    |
    SC_MOD_CHANGEANNOTATION | 0x20000  |
    SC_MOD_CHANGEFOLD       | 0x8      |
    SC_MOD_CHANGEINDICATOR  | 0x4000   |
    SC_MOD_CHANGELINESTATE  | 0x8000   |
    SC_MOD_CHANGEMARGIN     | 0x10000  |
    SC_MOD_CHANGEMARKER     | 0x200    |
    SC_MOD_CHANGESTYLE      | 0x4      |
    SC_MOD_CHANGETABSTOPS   | 0x200000 |
    SC_MOD_CONTAINER        | 0x40000  |
    SC_MOD_DELETETEXT       | 0x2      |
    SC_MOD_INSERTCHECK      | 0x100000 |
    SC_MOD_INSERTTEXT       | 0x1      |
    SC_MOD_LEXERSTATE       | 0x80000  |
    SC_PERFORMED_REDO       | 0x40     |
    SC_PERFORMED_UNDO       | 0x20     |
    SC_PERFORMED_USER       | 0x10     |
    SC_MODEVENTMASKALL      | 0x3FFFFF |

If you details on what they each mean, you should see L<SCN_MODIFIED in the Scintilla Docs|https://www.scintilla.org/ScintillaDoc.html#SCN_MODIFIED>.

=cut

our %SC_MOD = (
    'SC_LASTSTEPINUNDOREDO'                                      => 0x100,
    'SC_MULTISTEPUNDOREDO'                                       => 0x80,
    'SC_MULTILINEUNDOREDO'                                       => 0x1000,
    'SC_STARTACTION'                                             => 0x2000,
    'SC_MOD_NONE'                                                => 0x0,
    'SC_MOD_BEFOREDELETE'                                        => 0x800,
    'SC_MOD_BEFOREINSERT'                                        => 0x400,
    'SC_MOD_CHANGEANNOTATION'                                    => 0x20000,
    'SC_MOD_CHANGEFOLD'                                          => 0x8,
    'SC_MOD_CHANGEINDICATOR'                                     => 0x4000,
    'SC_MOD_CHANGELINESTATE'                                     => 0x8000,
    'SC_MOD_CHANGEMARGIN'                                        => 0x10000,
    'SC_MOD_CHANGEMARKER'                                        => 0x200,
    'SC_MOD_CHANGESTYLE'                                         => 0x4,
    'SC_MOD_CHANGETABSTOPS'                                      => 0x200000,
    'SC_MOD_CONTAINER'                                           => 0x40000,
    'SC_MOD_DELETETEXT'                                          => 0x2,
    'SC_MOD_INSERTCHECK'                                         => 0x100000,
    'SC_MOD_INSERTTEXT'                                          => 0x1,
    'SC_MOD_LEXERSTATE'                                          => 0x80000,
    'SC_PERFORMED_REDO'                                          => 0x40,
    'SC_PERFORMED_UNDO'                                          => 0x20,
    'SC_PERFORMED_USER'                                          => 0x10,
    'SC_MODEVENTMASKALL'                                         => 0x3FFFFF,
);

=item %SC_MULTIAUTOC

Used by L<autoCSetMulti|Win32::Mechanize::NotepadPlusPlus::Editor/autoCSetMulti>.
Affects how autocompletion interacts with multi-selection (having more than one area selelected at once).

    Key                |   | Autocompletion affects ...
    -------------------|---|-------------
    SC_MULTIAUTOC_ONCE | 0 | ... only the first area of a multi-selection (default)
    SC_MULTIAUTOC_EACH | 1 | ... each area of the multi-selection

=cut

our %SC_MULTIAUTOC = (
    'SC_MULTIAUTOC_EACH'                                         => 1,
    'SC_MULTIAUTOC_ONCE'                                         => 0,
);

=item %SC_MULTIPASTE

Used by L<setMultiPaste|Win32::Mechanize::NotepadPlusPlus::Editor/setMultiPaste>.

    Key                |   | Paste into ...
    -------------------|---|-------------
    SC_MULTIPASTE_ONCE | 0 | ... only the first area of a multi-selection (default)
    SC_MULTIPASTE_EACH | 1 | ... each area of the multi-selection

=cut

our %SC_MULTIPASTE = (
    'SC_MULTIPASTE_EACH'                                         => 1,
    'SC_MULTIPASTE_ONCE'                                         => 0,
);

=item %SC_PHASES

Used by L<setPhasesDraw|Win32::Mechanize::NotepadPlusPlus::Editor/setPhasesDraw>.

    Key                 |   | Description
    --------------------|---|-------------
    SC_PHASES_ONE       | 0 | (deprecated) Single drawing phase
    SC_PHASES_TWO       | 1 | Draw background first, then text above it
    SC_PHASES_MULTIPLE  | 2 | Draw whole area multiple times, once per feature

=cut

our %SC_PHASES = (
    'SC_PHASES_ONE'                                              => 0,
    'SC_PHASES_TWO'                                              => 1,
    'SC_PHASES_MULTIPLE'                                         => 2,
);

=item %SC_POPUP

Used by L<usePopUp|Win32::Mechanize::NotepadPlusPlus::Editor/usePopUp>.

    Key             |   | Description
    ----------------|---|-------------
    SC_POPUP_NEVER  | 0 | Never show default editing menu
    SC_POPUP_ALL    | 1 | Show default editing menu if clicking on scintilla
    SC_POPUP_TEXT   | 2 | Show default editing menu only if clicking on text area

All of these values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_POPUP = (
    'SC_POPUP_ALL'                                               => 1, #
    'SC_POPUP_NEVER'                                             => 0, #
    'SC_POPUP_TEXT'                                              => 2, #
);


=item %SC_PRINTCOLOURMODE

Used by L<setPrintColourMode|Win32::Mechanize::NotepadPlusPlus::Editor/setPrintColourMode>.

    Key                             |   | Description
    --------------------------------|---|-------------
    SC_PRINT_NORMAL                 | 0 | Use screen colours, excluding line numbers in margins
    SC_PRINT_INVERTLIGHT            | 1 | For dark background, invert print colour and use white background
    SC_PRINT_BLACKONWHITE           | 2 | All text as black on white
    SC_PRINT_COLOURONWHITE          | 3 | All text as displayed colour, on white
    SC_PRINT_COLOURONWHITEDEFAULTBG | 4 | Use displayed foreground colour, background depends on style
    SC_PRINT_SCREENCOLOURS          | 5 | Use screen colours, including line numbers in margins [npp7.8]

[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_PRINTCOLOURMODE = (
    'SC_PRINT_NORMAL'                                            => 0,
    'SC_PRINT_INVERTLIGHT'                                       => 1,
    'SC_PRINT_BLACKONWHITE'                                      => 2,
    'SC_PRINT_COLOURONWHITE'                                     => 3,
    'SC_PRINT_COLOURONWHITEDEFAULTBG'                            => 4,
    'SC_PRINT_SCREENCOLOURS'                                     => 5,
);


#    'SC_SEARCHRESULT_LINEBUFFERMAXLENGTH'                        => 2048, # no longer documented # changed from 1024 in v7.9 to 2048 in v7.9.1

=item %SC_SEL

Used by L<setSelectionMode|Win32::Mechanize::NotepadPlusPlus::Editor/setSelectionMode>.

    Key              |   | Description
    -----------------|---|-------------
    SC_SEL_STREAM    | 0 | Stream selection (default)
    SC_SEL_RECTANGLE | 1 | Rectangular (column) selection
    SC_SEL_LINES     | 2 | Select by lines
    SC_SEL_THIN      | 3 | Thin rectangle (allows zero-width column-selection)

=cut

our %SC_SEL = (
    'SC_SEL_STREAM'                                              => 0,
    'SC_SEL_RECTANGLE'                                           => 1,
    'SC_SEL_LINES'                                               => 2,
    'SC_SEL_THIN'                                                => 3,
);

=item %SC_STATUS

Used by L<getStatus|Win32::Mechanize::NotepadPlusPlus::Editor/getStatus>.

    Key                     |      | Description
    ------------------------|------|-------------
    SC_STATUS_OK            | 0    | No failures
    SC_STATUS_FAILURE       | 1    | Generic failure
    SC_STATUS_BADALLOC      | 2    | Memory is exhausted
    SC_STATUS_WARN_REGEX    | 1001 | Regular expression is invalid

=cut

our %SC_STATUS = (
    'SC_STATUS_BADALLOC'                                         => 2,
    'SC_STATUS_FAILURE'                                          => 1,
    'SC_STATUS_OK'                                               => 0,
    'SC_STATUS_WARN_REGEX'                                       => 1001,
    'SC_STATUS_WARN_START'                                       => 1000,
);

=item %SC_STYLE

Used by L<Style definition methods|Win32::Mechanize::NotepadPlusPlus::Editor/"Style definition">.

These styles correspond to Dialog Entries in Settings > Style Configurator > Global Styles

    Key                    |     | Dialog Entry
    -----------------------|-----|-------------
    STYLE_DEFAULT          | 32  | Default Style
    STYLE_LINENUMBER       | 33  | Line number margin
    STYLE_BRACELIGHT       | 34  | Brace highlight style
    STYLE_BRACEBAD         | 35  | Brace bad colour
    STYLE_CONTROLCHAR      | 36  | (*) Control Characters
    STYLE_INDENTGUIDE      | 37  | Indent guideline style
    STYLE_CALLTIP          | 38  | (*) Call tips
    STYLE_FOLDDISPLAYTEXT  | 39  | (*) Call tips [npp7.8]
    -----------------------|-----|-------------
    STYLE_LASTPREDEFINED   | 39  | (*) This is the last of Scintilla's predefined style indexes
    STYLE_MAX              | 255 | (*) This is the last style number index available
    -----------------------|-----|-------------
    NPP_STYLE_MARK5        | 21  | (+) Mark Style 5
    NPP_STYLE_MARK4        | 22  | (+) Mark Style 4
    NPP_STYLE_MARK3        | 23  | (+) Mark Style 3
    NPP_STYLE_MARK2        | 24  | (+) Mark Style 2
    NPP_STYLE_MARK1        | 25  | (+) Mark Style 1
    NPP_STYLE_TAGATTR      | 26  | (+) Tags attribute
    NPP_STYLE_TAGMATCH     | 27  | (+) Tags match highlighting
    NPP_STYLE_HILITE_INCR  | 28  | (+) Incremental highlight all
    NPP_STYLE_HILITE_SMART | 29  | (+) Smart HighLighting
    NPP_STYLE_FINDMARK     | 31  | (+) Find Mark Style

*: these keys do not have a corresponding entry in the Style Configurator.

+: This hash also has values not defined by Scintilla, but used by Notepad++'s Global Styles.
It still doesn't cover all of Notepad++'s Global Styles available, because they do not use
Scintilla's styler rules to implement those styles (many use the same styleID of 0, and one
uses a styleID greater than STYLE_MAX), so you might not be able to set those using the style
defintion methods.

[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_STYLE = (
    'STYLE_DEFAULT'                                              => 32,
    'STYLE_LINENUMBER'                                           => 33,
    'STYLE_BRACELIGHT'                                           => 34,
    'STYLE_BRACEBAD'                                             => 35,
    'STYLE_CONTROLCHAR'                                          => 36,
    'STYLE_INDENTGUIDE'                                          => 37,
    'STYLE_CALLTIP'                                              => 38,
    'STYLE_FOLDDISPLAYTEXT'                                      => 39,
    'STYLE_LASTPREDEFINED'                                       => 39,
    'STYLE_MAX'                                                  => 255,
    'NPP_STYLE_MARK5'                                            => 21,
    'NPP_STYLE_MARK4'                                            => 22,
    'NPP_STYLE_MARK3'                                            => 23,
    'NPP_STYLE_MARK2'                                            => 24,
    'NPP_STYLE_MARK1'                                            => 25,
    'NPP_STYLE_TAGATTR'                                          => 26,
    'NPP_STYLE_TAGMATCH'                                         => 27,
    'NPP_STYLE_HILITE_INCR'                                      => 28,
    'NPP_STYLE_HILITE_SMART'                                     => 29,
    'NPP_STYLE_FINDMARK'                                         => 31,
);

=item %SC_TABDRAW

Used by L<setTabDrawMode|Win32::Mechanize::NotepadPlusPlus::Editor/setTabDrawMode>.

    Key            |   | Description
    ---------------|---|-------------
    SCTD_LONGARROW | 0 | Arrow stretching until tabstop
    SCTD_STRIKEOUT | 1 | Horizontal line stretching until tabstop

All of these values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_TABDRAW = (
    SCTD_LONGARROW => 0,
    SCTD_STRIKEOUT => 1,
);

=item %SC_TECHNOLOGY

Used by L<setTechnology|Win32::Mechanize::NotepadPlusPlus::Editor/setTechnology>.

    Key                             |   | Description
    --------------------------------|---|-------------
    SC_TECHNOLOGY_DEFAULT           | 0 | Use standard API
    SC_TECHNOLOGY_DIRECTWRITE       | 1 | Use DirectWrite API
    SC_TECHNOLOGY_DIRECTWRITERETAIN | 2 | Use DirectWrite API, retaining the frame
    SC_TECHNOLOGY_DIRECTWRITEDC     | 3 | use DirectWrite API to draw into a GDI DC

In Windows XP (and earlier), only SC_TECHNOLOGY_DEFAULT is supported.

=cut

our %SC_TECHNOLOGY = (
    'SC_TECHNOLOGY_DEFAULT'                                      => 0,
    'SC_TECHNOLOGY_DIRECTWRITE'                                  => 1,
    'SC_TECHNOLOGY_DIRECTWRITERETAIN'                            => 2,
    'SC_TECHNOLOGY_DIRECTWRITEDC'                                => 3,
);

=item %SC_TEXTRETRIEVAL

Used internally by L<Text retrieval and modification methods|Win32::Mechanize::NotepadPlusPlus::Editor/"Text retrieval and modification">
to indicate an invalid position was passed.  Never returned to the user.

=cut

our %SC_TEXTRETRIEVAL = (
    'INVALID_POSITION'                                           => -1,
);

=item %SC_TIMEOUT

Used by L<setMouseDwellTime|Win32::Mechanize::NotepadPlusPlus::Editor/setMouseDwellTime>.

    Key             |          | Description
    ----------------|----------|-------------
    SC_TIME_FOREVER | 10000000 | No dwell events are generated

=cut

our %SC_TIMEOUT = (
    'SC_TIME_FOREVER'                                            => 10000000,
);

=item %SC_TYPE

Used by L<propertyType|Win32::Mechanize::NotepadPlusPlus::Editor/propertyType>.

    Key             |   | Description
    ----------------|---|-------------
    SC_TYPE_BOOLEAN | 0 | Property is true/false
    SC_TYPE_INTEGER | 1 | Property is integer
    SC_TYPE_STRING  | 2 | Property is string


=cut

our %SC_TYPE = (
    'SC_TYPE_BOOLEAN'                                            => 0,
    'SC_TYPE_INTEGER'                                            => 1,
    'SC_TYPE_STRING'                                             => 2,
);

=item %SC_UNDO

Used by L<addUndoAction|Win32::Mechanize::NotepadPlusPlus::Editor/addUndoAction>.

    Key               |   | Description
    ------------------|---|-------------
    UNDO_MAY_COALESCE | 1 | combine this action with insert/delete for single group undo
    UNDO_NONE         | 0 | keep undo separate from insert/delete (default)

=cut

our %SC_UNDO = (
    'UNDO_NONE'                                                  => 0,
    'UNDO_MAY_COALESCE'                                          => 1,
);

=item %SC_VIRTUALSPACE

Used by L<setVirtualSpaceOptions|Win32::Mechanize::NotepadPlusPlus::Editor/setVirtualSpaceOptions>

    Key                         |   | Description
    ----------------------------+---+--------------------------------------------------
    SCVS_NONE                   | 0 | Disables all use of virtual space
    SCVS_RECTANGULARSELECTION   | 1 | Enable virtual space for rectangular selections
    SCVS_USERACCESSIBLE         | 2 | Enable virtual space for other circumstances
    SCVS_NOWRAPLINESTART        | 4 | Prevents left-arrow movement from column 0 wrapping to previous line [npp7.8]

[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_VIRTUALSPACE = (
    'SCVS_NONE'                                                  => 0,
    'SCVS_NOWRAPLINESTART'                                       => 4,
    'SCVS_RECTANGULARSELECTION'                                  => 1,
    'SCVS_USERACCESSIBLE'                                        => 2,
);

=item %SC_VISIBLE

Used by L<setVisiblePolicy|Win32::Mechanize::NotepadPlusPlus::Editor/setVisiblePolicy>.

    Key            |   | Description
    ---------------|---|-------------
    VISIBLE_SLOP   | 1 | Adds a buffer zone
    VISIBLE_STRICT | 4 | Enforces the zone strictly; caret is centered in slop

=cut

our %SC_VISIBLE = (
    'VISIBLE_SLOP'                                               => 0x01,
    'VISIBLE_STRICT'                                             => 0x04,
);

=item %SC_WEIGHT

Used by L<styleSetWeight|Win32::Mechanize::NotepadPlusPlus::Editor/styleSetWeight>.

    Key                 |     | Description
    --------------------|-----|-------------
    SC_WEIGHT_NORMAL    | 400 | Normal
    SC_WEIGHT_BOLD      | 700 | Bold
    SC_WEIGHT_SEMIBOLD  | 600 | Between normal and bold

=cut

our %SC_WEIGHT = (
    'SC_WEIGHT_BOLD'                                             => 700,
    'SC_WEIGHT_NORMAL'                                           => 400,
    'SC_WEIGHT_SEMIBOLD'                                         => 600,
);

=item %SC_WHITESPACE

Used by L<setViewWS|Win32::Mechanize::NotepadPlusPlus::Editor/setViewWS>

    Key                         |   | Description
    ----------------------------+---+--------------------------------------------------
    SCWS_INVISIBLE              | 0 | The normal display mode with white space displayed as an empty background colour.
    SCWS_VISIBLEALWAYS          | 1 | White space characters are drawn as dots and arrows,
    SCWS_VISIBLEAFTERINDENT     | 2 | White space used for indentation is displayed normally but after the first visible character, it is shown as dots and arrows.
    SCWS_VISIBLEONLYININDENT    | 3 | White space used for indentation is displayed as dots and arrows. [npp7.8]

[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_WHITESPACE = (
    'SCWS_INVISIBLE'                                             => 0,
    'SCWS_VISIBLEALWAYS'                                         => 1,
    'SCWS_VISIBLEAFTERINDENT'                                    => 2,
    'SCWS_VISIBLEONLYININDENT'                                   => 3,
);

=item %SC_WRAPINDENT

Used by L<setWrapIndent|Win32::Mechanize::NotepadPlusPlus::Editor/setWrapIndent>.

    Key                         |   | Description
    ----------------------------|---|-------------
    SC_WRAPINDENT_FIXED         | 0 | Wrapped lines are based on setWrapStartIndent
    SC_WRAPINDENT_SAME          | 1 | Wrapped lines match the starting indentation
    SC_WRAPINDENT_INDENT        | 2 | Wrapped sublines are aligned to first subline indent plus one more level of indentation
    SC_WRAPINDENT_DEEPINDENT    | 3 | Wrapped sublines are aligned to first subline indent plus two more levels of indentation [npp7.8]

[npp7.8] Noted values require at least Scintilla v4.2.0, found in Notepad++ v7.8 and newer.

=cut

our %SC_WRAPINDENT = (
    'SC_WRAPINDENT_FIXED'                                        => 0,
    'SC_WRAPINDENT_SAME'                                         => 1,
    'SC_WRAPINDENT_INDENT'                                       => 2,
    'SC_WRAPINDENT_DEEPINDENT'                                   => 3,
);

=item %SC_WRAPMODE

Used by L<setWrapMode|Win32::Mechanize::NotepadPlusPlus::Editor/setWrapMode>.

    Key                |   | Description
    -------------------|---|-------------
    SC_WRAP_NONE       | 0 | No wrap
    SC_WRAP_WORD       | 1 | Wrap on word or style boundaries
    SC_WRAP_CHAR       | 2 | Wrap between any char
    SC_WRAP_WHITESPACE | 3 | Wrap at whitespace

=cut

our %SC_WRAPMODE = (
    'SC_WRAP_NONE'                                               => 0,
    'SC_WRAP_WORD'                                               => 1,
    'SC_WRAP_CHAR'                                               => 2,
    'SC_WRAP_WHITESPACE'                                         => 3,
);

=item %SC_WRAPVISUALFLAG

Used by L<setWrapVisualFlags|Win32::Mechanize::NotepadPlusPlus::Editor/setWrapVisualFlags>.

    Key                      |        | Description
    -------------------------|--------|-------------
    SC_WRAPVISUALFLAG_NONE   | 0x0000 | No visual flags
    SC_WRAPVISUALFLAG_END    | 0x0001 | Visual flag at end of each subline
    SC_WRAPVISUALFLAG_START  | 0x0002 | Visual flag at start of each subline
    SC_WRAPVISUALFLAG_MARGIN | 0x0004 | Visual flag in the line-number margin

=cut

our %SC_WRAPVISUALFLAG = (
    'SC_WRAPVISUALFLAG_NONE'                                     => 0x0000,
    'SC_WRAPVISUALFLAG_END'                                      => 0x0001,
    'SC_WRAPVISUALFLAG_START'                                    => 0x0002,
    'SC_WRAPVISUALFLAG_MARGIN'                                   => 0x0004,
);

=item %SC_WRAPVISUALFLAGLOC

Used by L<setWrapVisualFlagsLocation|Win32::Mechanize::NotepadPlusPlus::Editor/setWrapVisualFlagsLocation>.

    Key                                |        | Description
    -----------------------------------|--------|-------------
    SC_WRAPVISUALFLAGLOC_DEFAULT       | 0x0000 | Near border
    SC_WRAPVISUALFLAGLOC_END_BY_TEXT   | 0x0001 | End of subline
    SC_WRAPVISUALFLAGLOC_START_BY_TEXT | 0x0002 | Beginning of subline

=cut

our %SC_WRAPVISUALFLAGLOC = (
    'SC_WRAPVISUALFLAGLOC_DEFAULT'                               => 0x0000,
    'SC_WRAPVISUALFLAGLOC_END_BY_TEXT'                           => 0x0001,
    'SC_WRAPVISUALFLAGLOC_START_BY_TEXT'                         => 0x0002,
);

=back

=head2 NOTIFICATIONS

Not yet used, but the constants are available

=over

=item %SCINTILLANOTIFICATION

If you are interested, you can find all the message keys with code like the following:

    use Win32::Mechanize::NotepadPlusPlus ':vars';
    printf "%-39s => %d\n", $_, $SCINTILLANOTIFICATION{$_} for sort { $SCINTILLANOTIFICATION{$a} <=> $SCINTILLANOTIFICATION{$b} } keys %SCINTILLANOTIFICATION;   # prints all scintilla notification keys in numerical order

=item %SCN_ARGS

When notifications are implemented, these will be split into multiple hashes and documented more fully.

=cut

our %SCINTILLANOTIFICATION = (
    'SCN_AUTOCCANCELLED'                                         => 2025,
    'SCN_AUTOCCHARDELETED'                                       => 2026,
    'SCN_AUTOCCOMPLETED'                                         => 2030,
    'SCN_AUTOCSELECTION'                                         => 2022,
    'SCN_AUTOCSELECTIONCHANGE'                                   => 2032,
    'SCN_CALLTIPCLICK'                                           => 2021,
    'SCN_CHARADDED'                                              => 2001,
    'SCN_DOUBLECLICK'                                            => 2006,
    'SCN_DWELLEND'                                               => 2017,
    'SCN_DWELLSTART'                                             => 2016,
    'SCN_FOCUSIN'                                                => 2028,
    'SCN_FOCUSOUT'                                               => 2029,
    'SCN_FOLDINGSTATECHANGED'                                    => 2081,
    'SCN_HOTSPOTCLICK'                                           => 2019,
    'SCN_HOTSPOTDOUBLECLICK'                                     => 2020,
    'SCN_HOTSPOTRELEASECLICK'                                    => 2027,
    'SCN_INDICATORCLICK'                                         => 2023,
    'SCN_INDICATORRELEASE'                                       => 2024,
    'SCN_KEY'                                                    => 2005,
    'SCN_MACRORECORD'                                            => 2009,
    'SCN_MARGINCLICK'                                            => 2010,
    'SCN_MARGINRIGHTCLICK'                                       => 2031,
    'SCN_MODIFIED'                                               => 2008,
    'SCN_MODIFYATTEMPTRO'                                        => 2004,
    'SCN_NEEDSHOWN'                                              => 2011,
    'SCN_PAINTED'                                                => 2013,
    'SCN_SAVEPOINTLEFT'                                          => 2003,
    'SCN_SAVEPOINTREACHED'                                       => 2002,
    'SCN_SCROLLED'                                               => 2080,
    'SCN_STYLENEEDED'                                            => 2000,
    'SCN_UPDATEUI'                                               => 2007,
    'SCN_URIDROPPED'                                             => 2015,
    'SCN_USERLISTSELECTION'                                      => 2014,
    'SCN_ZOOM'                                                   => 2018,
);

our %SCN_ARGS = (
    'SCEN_CHANGE'                                                => 768,
    'SCEN_KILLFOCUS'                                             => 256,
    'SCEN_SETFOCUS'                                              => 512,

    'SC_UPDATE_CONTENT'                                          => 0x1,
    'SC_UPDATE_H_SCROLL'                                         => 0x8,
    'SC_UPDATE_SELECTION'                                        => 0x2,
    'SC_UPDATE_V_SCROLL'                                         => 0x4,

    'SC_AC_COMMAND'                                              => 5,      # [npp7.8]
    'SC_AC_DOUBLECLICK'                                          => 2,      # [npp7.8]
    'SC_AC_FILLUP'                                               => 1,      # [npp7.8]
    'SC_AC_NEWLINE'                                              => 4,      # [npp7.8]
    'SC_AC_TAB'                                                  => 3,      # [npp7.8]

    'SC_CHARACTERSOURCE_DIRECT_INPUT'                            => 0,      # [npp7.8]
    'SC_CHARACTERSOURCE_IME_RESULT'                              => 2,      # [npp7.8]
    'SC_CHARACTERSOURCE_TENTATIVE_INPUT'                         => 1,      # [npp7.8]
);

=back

=head1 INSTALLATION

Installed as part of L<Win32::Mechanize::NotepadPlusPlus>

=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

Please report any bugs or feature requests emailing C<E<lt>bug-Win32-Mechanize-NotepadPlusPlus AT rt.cpan.orgE<gt>>
or thru the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Mechanize-NotepadPlusPlus>,
or thru the repository's interface at L<https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues>.

=head1 COPYRIGHT

Copyright (C) 2019,2020 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
