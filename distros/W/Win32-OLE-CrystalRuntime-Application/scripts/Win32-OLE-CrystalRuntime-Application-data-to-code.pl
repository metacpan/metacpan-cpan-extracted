#!/usr/bin/perl

=head1 NAME

Win32-OLE-CrystalRuntime-Application-data-to-code.pl - CrystalRuntime-Application Constants Source Generator

=cut

use strict;
use warnings;

my @head=();
my %line=();
my $head='';
my $line=<DATA>;
while (1) {
  chomp($line);
  if ($line) {
    if ($line=~m/^:/) {
      $head=$line;
      push @head, $head;
    } else {
      $line{$head}||=[];
      push @{$line{$head}}, [split(/\s+/, $line, 3)];
    }
  }
  $line=<DATA>;
  last unless defined($line);
} 

#use Data::Dumper;
#print Dumper([{head=>\@head, line=>\%line, count=>scalar(@head)}]);

foreach my $head (@head) {
  my $tag=$head;
  $tag=~s/^://;
  my $list=join(" ", map {$_->[0]} @{$line{$head}});
  my $cont=join("\n", map {sprintf("use constant %s => %s;%s", @$_[0,1], (defined($_->[2]) ? "  # ".$_->[2] : ''))} @{$line{$head}});

  print qq|
=head2 $head
 
$list

=cut

\$EXPORT_TAGS{"$tag"}=[qw{$list}];
 
$cont
|;

}
  #$EXPORT_TAGS{"CRAlignment"}=[qw{crDefaultAlign crHorCenterAlign crJustified crLeftAlign crRightAlign}];
  #use constant crDefaultAlign   => 0;



__DATA__
:CRAlignment

crDefaultAlign 0
crHorCenterAlign 2
crJustified 4
crLeftAlign 1
crRightAlign 3

:CRAMPMType

crAmPmAfter 1
crAmPmBefore 0

:CRAreaKind

crDetail 4
crGroupFooter 5
crGroupHeader 3
crPageFooter 7
crPageHeader 2
crReportFooter 8
crReportHeader 1

:CRBarSize

crMinimumBarSize 0
crSmallBarSize 1
crAverageBarSize 2
crLargeBarSize 3
crMaximumBarSize 4

:CRBindingMatchType

crBMTName 0
crBMTNameAndValue 1

:CRBooleanFieldFormatConditionFormulaType

crOutputFormatConditionFormulaType 20 (&H14)

:CRBooleanOutputType

crOneOrZero 4
crTOrF 1
crTrueOrFalse 0
crYesOrNo 2
crYOrN 3

:CRBorderConditionFormulaType

crBackgroundColorConditionFormulaType 45 (&H2D)
crBorderColorConditionFormulaType 46 (&H2E)
crBottomLineStyleConditionFormulaType 43 (&H2B)
crHasDropShadowConditionFormulaType 44 (&H2C)
crLeftLineStyleConditionFormulaType 40 (&H28)
crRightLineStyleConditionFormulaType 41 (&H29)
crTightHorizontalConditionFormulaType 47 (&H2F)
crTightVerticalConditionFormulaType 48 (&H30)
crTopLineStyleConditionFormulaType 42 (&H2A)

:CRCommonFieldFormatConditionFormulaType

crSuppressIfDuplicatedConditionFormulaType 80
crUseSystemDefaultConditionFormulaType 81 (&H51)

:CRConvertDateTimeType

crConvertDateTimeToDate 1
crConvertDateTimeToString 0
crKeepDateTimeType 2

:CRCurrencyPositionType

crLeadingCurrencyInsideNegative 0
crLeadingCurrencyOutsideNegative 1
crTrailingCurrencyInsideNegative 2
crTrailingCurrencyOutsideNegative 3

:CRCurrencySymbolType

crCSTFixedSymbol 1
crCSTFloatingSymbol 2
crCSTNoSymbol 0

:CRDatabaseType

crSQLDatabase 2
crStandardDatabase 1

:CRDateCalendarType

crGregorianCalendar 1
crGregorianUSCalendar 2
crGregorianArabicCalendar 10
crGregorianMEFrenchCalendar 9
crGregorianXlitEnglishCalendar 11
crGregorianXlitFrenchCalendar 12
crHebrewCalendar 8
crHijriCalendar 6
crJapaneseCalendar 3
crKoreanCalendar 5
crTaiwaneseCalendar 4
crThaiCalendar 7

:CRDateEraType

crLongEra 1
crNoEra 2
crShortEra 0

:CRDateFieldFormatConditionFormulaType

crCalendarTypeConditionFormulaType 131 (&H83)
crDateFirstSeparatorCondidtionFormulaType 128 (&H80)
crDateOrderConditionFormulaType 124 (&H7C)
crDatePrefixSeparatorConditionFormulaType 132 (&H84)
crDateSecondSeparatorConditionFormulaType 129 (&H81)
crDateSuffixSeparatorConditionFormulaType 133 (&H85)
crDayFormatConditionFormulaType 122 (&H7A)
crDayOfWeekEnclosureConditionFormulaType 134 (&H86)
crDayOfWeekPositionConditionFormulaType 127 (&H7F)
crDayOfWeekSeparatorConditionFormulaType 126 (&H7E)
crDayOfWeekTypeConditionFormulaType 125 (&H7D)
crEraTypeConditionFormulaType 130 (&H82)
crMonthFormatConditionFormulaType 121 (&H79)
crWindowsDefaultTypeConditionFormulaType 123 (&H7B)
crYearFormatConditionFormulaType 120 (&H78)

:CRDateOrder

crDayMonthYear 1
crMonthDayYear 2
crYearMonthDay 0

:CRDateTimeFieldFormatConditionFormulaType

crDateTimeOrderConditionFormulaType 140 (&H8C)
crDateTimeSeparatorConditionFormulaType 141 (&H8D)

:CRDateWindowsDefaultType

crNotUsingWindowsDefaults 2
crUseWindowsLongDate 0
crUseWindowsShortDate 1

:CRDayType

crLeadingZeroNumericDay 1
crNoDay 2
crNumericDay 0

:CRDiscreteOrRangeKind

crDiscreteValue 0
crRangeValue 1
crDiscreteAndRangeValue 2

:CRDivisionMethod

crAutomaticDivision 0
crManualDivision 1

:CRExchangeDestinationType

crExchangeFolderType 0
crExchangePostDocMessage 1011 (&H3F3)

:CRExportDestinationType

crEDTApplication 5
crEDTDiskFile 1
crEDTEMailMAPI 2
crEDTEMailVIM 3
crEDTLotusDomino 6
crEDTMicrosoftExchange 4
crEDTNoDestination 0

:CRExportFormatType

crEFTCharSeparatedValues 7
crEFTCommaSeparatedValues 5
crEFTCrystalReport 1
crEFTCrystalReport70 33
crEFTDataInterchange 2
crEFTExactRichText 35 (&H23)
crEFTExcel50 21 (&H15)
crEFTExcel50Tabular 22 (&H16)
crEFTExcel70 27 (&H1B)
crEFTExcel70Tabular 28 (&H1C)
crEFTExcel80 29 (&H1D)
crEFTExcel80Tabular 30 (&H1E)
crEFTExcel97 36 (&H24)
crEFTExplorer32Extend 25 (&H19)
crEFTHTML32Standard 24 (&H18)
crEFTHTML40 32 (&H20)
crEFTLotus123WK1 12
crEFTLotus123WK3 13
crEFTLotus123WKS 11
crEFTNoFormat 0
crEFTODBC 23 (&H17)
crEFTPaginatedText 10
crEFTPortableDocFormat 31 (&H1F)
crEFTRecordStyle 3
crEFTReportDefinition 34 (&H22)
crEFTTabSeparatedText 9
crEFTTabSeparatedValues 6
crEFTText 8
crEFTWordForWindows 14
crEFTXML 37 (&H25)

:CRFieldKind

crDatabaseField 1
crFormulaField 2
crGroupNameField 5
crRunningTotalField 7
crParameterField 6
crSpecialVarField 4
crSQLExpressionField 8
crSummaryField 3

:CRFieldMappingType

crAutoFieldMapping 0
crEventFieldMapping 2
crPromptFieldMapping 1

:CRFieldValueType

crBitmapField 17 (&H11)
crBlobField 15
crBooleanField 9
crChartField 21 (&H15)
crCurrencyField 8
crDateField 10
crDateTimeField 16 (&H10)
crIconField 18 (&H12)
crInt16sField 3
crInt16uField 4
crInt32sField 5
crInt32uField 6
crInt8sField 1
crInt8uField 2
crNumberField 7
crOleField 20 (&H14)
crPersistentMemoField 14
crPictureField 19 (&H13)
crStringField 12
crTimeField 11
crTransientMemoField 13
crUnknownField 22 (&H16)

:CRFontColorConditionFormulaType

crColorConditionFormulaType 180 (&HB4)
crFontConditionFormulaType 181 (&HB5)
crFontSizeConditionFormulaType 183 (&HB7)
crFontStrikeOutConditionFormulaType 184 (&HB8)
crFontStyleConditionFormulaType 182 (&HB6)
crFontUnderLineConditioneFormulaType 185 (&HB9)

:CRFormulaSyntax

crBasicSyntaxFormula 1
crCrystalSyntaxFormula 0 Default value

:CRGraphColor

crBlackAndWhiteGraph 1
crColorGraph 0

:CRGraphDataPoint

crNone 0
crShowLabel 1
crShowValue 2

:CRGraphDataType

crCrossTabGraph 2
crDetailGraph 1
crGroupGraph 0

:CRGraphDirection

crHorizontalGraph 0
crVerticalGraph 1

:CRGraphType

crAbsoluteAreaGraph 20 Obsolete
crDualAxisBubbleGraph 91 Obsolete
crFaked3DAbsoluteAreaGraph 23 Obsolete
crFaked3DPercentAreaGraph 25 (&H19)
crFaked3DPercentBarGraph 5
crFaked3DRegularPieGraph 31 (&H1F)
crFaked3DSideBySideBarGraph 3
crFaked3DStackedAreaGraph 24 (&H18)
crFaked3DStackedBarGraph 4
crHighLowDualAxisGraph 101 Obsolete.
crHighLowGraph 100 (&H64)
crHighLowOpenCloseDualAxisGraph 105 Obsolete.
crHighLowOpenCloseGraph 104 (&H68)
crHighLowOpenDualAxisGraph 103 Obsolete.
crHighLowOpenGraph 102 Obsolete.
crLineGraphWithMarkers 13
crMultipleDoughnutGraph 41 (&H29)
crMultiplePieGraph 32 (&H20)
crMultipleProportionalDoughnutGraph 42 (&H2A)
crMultipleProportionalPieGraph 33 (&H21)
crPercentageLineGraph 12
crPercentageLineGraphWithMarkers 15
crPercentAreaGraph 22 (&H16)
crPercentBarGraph 2
crRadarDualAxisGraph 82 Obsolete
crRegularBubbleGraph 90 (&H5A)
crRegularDoughnutGraph 40 (&H28)
crRegularLineGraph 10
crRegularPieGraph 30 (&H1E)
crRegularRadarGraph 80 (&H50)
crSideBySideBarGraph 0
crStackedAreaGraph 21 (&H15)
crStackedBarGraph 1
crStackedLineGraph 11
crStackedLineGraphWithMarkers 14
crStackedRadarGraph 81 (&H51)
crThreeDCutCornersGraph 53 (&H35)
crThreeDOctagonGraph 52 (&H34)
crThreeDPyramidGraph 51 (&H33)
crThreeDRegularGraph 50 (&H32)
crThreeDSurfaceHoneycombGraph 62 (&H3E)
crThreeDSurfaceRegularGraph 60 (&H3C)
crThreeDSurfaceWithSidesGraph 61 (&H3D)
crUnknownGraph 1000 (&H3E8)
crXyScatterGraph 70 (&H46)

:CRGridlineType

crMajorAndMinorGridlines 3
crMajorGridlines 2
crMinorGridlines 1
crNoGridlines 0

:CRGroupCondition

crGCAnnually 7
crGCAnyValue 14
crGCBiweekly 2
crGCByAMPM 18 (&H12)
crGCByHour 17 (&H11)
crGCByMinute 16 (&H10)
crGCBySecond 15
crGCDaily 0
crGCEveryNo 11
crGCEveryYes 10
crGCMonthly 4
crGCNextIsNo 13
crGCNextIsYes 12
crGCQuarterly 5
crGCSemiAnnually 6
crGCSemimonthly 3
crGCToNo 9
crGCToNoXXX 8 One of crGCToNo (8 or 9) has got to be an error in the documentation.
crGCWeekly 1

:CRHierarchicalSummaryType

crHierarchicalSummaryNone 0
crSummaryAcrossHierarchy 1

:CRHourType

crNoHour 2
crNumericHour 0
crNumericHourNoLeadingZero 1

:CRHTMLPageStyle

crFramePageStyle 2
crPlainPageStyle 0
crToolbarAtBottomPageStyle 4
crToolbarAtTopPageStyle 3
crToolbarPageStyle 1

:CRHTMLToolbarStyle

crToolbarRefreshButton 1
crToolbarSearchBox 2

:CRImageType

crDIBImageType 1
crJPEGImageType 2
crImageUnknown 0

:CRLeadingDayPosition

crLeadingDayOfWeek 0
crTrailingDayOfWeek 1

:CRLeadingDayType

crLongLeadingDay 1
crNoLeadingDay 2
crShortLeadingDay 0

:CRLegendPosition

crPlaceLeft 5
crPlaceRight 4
crPlaceBottom 6
crPlaceCustom 7

:CRLineSpacingType

crExactSpacing 1
crMultipleSpacing 0

:CRLineStyle

crLSDashLine 3
crLSDotLine 4
crLSDoubleLine 2 Not valid for LineObject.LineStyle and BoxObject.LineStyle.
crLSNoLine 0 Not valid for LineObject.LineStyle and BoxObject.LineStyle.
crLSSingleLine 1

:CRLinkJoinType

crJTAdvance 13
crJTEqual 4
crJTGreaterOrEqual 10
crJTGreaterThan 8
crJTLeftOuter 5
crJTLessOrEqual 11
crJTLessThan 9
crJTNotEqual 12
crJTRightOuter 6

:CRLinkLookUpType

crLTLookupParallel 1
crLTLookupProduct 2
crLTLookupSeries 3

:CRMarkerShape

crCircleShape 4
crDiamondShape 5
crRectangleShape 1
crTriangleShape 8

:CRMarkerSize

crLargeMarkers 4
crMediumLargeMarkers 3
crMediumMarkers 2
crMediumSmallMarkers 1
crSmallMarkers 0

:CRMinuteType

crNoMinute 2
crNumericMinute 0
crNumericMinuteNoLeadingZero 1

:CRMonthType

crLeadingZeroNumericMonth 1
crLongMonth 3
crNoMonth 4
crNumericMonth 0
crShortMonth 2

:CRNegativeType

crBracketed 3
crLeadingMinus 1
crNotNegative 0
crTrailingMinus 2

:CRNumberFormat

crCurrencyMillions 12
crCurrencyNoDecimal 3
crCurrencyThousands 11
crCurrencyTwoDecimal 4
crCustomNumberFormat 8
crMillionsNoDecimal 10
crNoDecimal 0
crOneDecimal 1
crPercentNoDecimal 5
crPercentOneDecimal 6
crPercentTwoDecimal 7
crThousandsNoDecimal 9
crTwoDecimal 2

:CRNumericFieldFormatConditionFormulaType

crAllowFieldClippingConditionFormulaType 114 (&H72)
crCurrencyPositionConditionFormulaType 111 (&H6F)
crCurrencySymbolConditionFormulaType 109 (&H6D)
crCurrencySymbolFormatConditionFormulaType 104 (&H68)
crDecimalSymbolConditionFormulaType 108 (&H6C)
crDisplayReverseSignConditionFormulaType 112 (&H70)
crEnableSuppressIfZeroConditionFormulaType 105 (&H69)
crEnableUseLeadZeroConditionFormulaType 102 (&H66)
crHasOneSymbolPerPageConditionFormulaType 110 (&H6E))
crNDecimalPlacesConditionFormulaType 100 (&H64)
crNegativeFormatConditionFormulaType 103 (&H67)
crRoundingFormatConditionFormulaType 101 (&H65)
crThousandsSeparatorFormatConditionFormulaType 106 (&H6A)
crThousandSymbolFormatConditionFormulaType 107 (&H6B)
crZeroValueStringConditionFormulaType 113 (&H71)

:CRObjectFormatConditionFormulaType

crCssClassConditionFormulaType 66 (&H42)
crEnableCanGrowConditionFormulaType 64 (&H40)
crEnableCloseAtPageBreakConditionFormulaType 62 (&H3E)
crEnableKeepTogetherConditionFormulaType 61 (&H3D)
crEnableSuppressConditinFormulaType 60 (&H3C)
crHorizontalAlignmentConditionFormulaType 63 (&H3F)
crHyperLinkConditionFormulaType 68 (&H44)
crRotationConditionFormulaType 67 (&H43)
crToolTipTextConditionFormulaType 65 (&H41)

:CRObjectKind

crBlobFieldObject 9
crBoxObject 4
crCrossTabObject 8
crFieldObject 1
crGraphObject 7
crLineObject 3
crMapObject 10
crOlapGridObject 11
crOleObject 6
crSubreportObject 5
crTextObject 2

:CROpenReportMethod

crOpenReportByDefault 0
crOpenReportByTempCopy 1

:CRPaperOrientation

crDefaultPaperOrientation 0
crLandscape 2
crPortrait 1

:CRPaperSize

crDefaultPaperSize 0
crPaper10x14 16 (&H10)
crPaper11x17 17 (&H11)
crPaperA3 8
crPaperA4 9
crPaperA4Small 10
crPaperA5 11
crPaperB4 12
crPaperB5 13
crPaperCsheet 24 (&H18)
crPaperDsheet 25 (&H19)
crPaperEnvelope10 20 (&H14)
crPaperEnvelope11 21 (&H15)
crPaperEnvelope12 22 (&H16)
crPaperEnvelope14 23 (&H17)
crPaperEnvelope9 19 (&H13)
crPaperEnvelopeB4 33 (&H21)
crPaperEnvelopeB5 34 (&H22)
crPaperEnvelopeB6 35 (&H23)
crPaperEnvelopeC3 29 (&H1D)
crPaperEnvelopeC4 30 (&H1E)
crPaperEnvelopeC5 28 (&H1C)
crPaperEnvelopeC6 31 (&H1F)
crPaperEnvelopeC65 32 (&H20)
crPaperEnvelopeDL 27 (&H1B)
crPaperEnvelopeItaly 36 (&H24)
crPaperEnvelopeMonarch 37 (&H25)
crPaperEnvelopePersonal 38 (&H26)
crPaperEsheet 26 (&H1A)
crPaperExecutive 7
crPaperFanfoldLegalGerman 41 (&H29)
crPaperFanfoldStdGerman 40 (&H28)
crPaperFanfoldUS 39 (&H27)
crPaperFolio 14
crPaperLedger 4
crPaperLegal 5
crPaperLetter 1
crPaperLetterSmall 2
crPaperNote 18 (&H12)
crPaperQuarto 15
crPaperStatement 6
crPaperTabloid 3
crPaperUser 256 (&H100)

:CRPaperSource

crPRBinAuto 7
crPRBinCassette 14
crPRBinEnvelope 5
crPRBinEnvManual 6
crPRBinFormSource 15
crPRBinLargeCapacity 11
crPRBinLargeFmt 10
crPRBinLower 2
crPRBinManual 4
crPRBinMiddle 3
crPRBinSmallFmt 9
crPRBinTractor 8
crPRBinUpper 1

:CRParameterFieldType

crQueryParameter 1
crReportParameter 0
crStoreProcedureParameter 2

:CRParameterPickListSortMethod

crNoSort 0
crAlphanumericAscending 1
crAlphanumericDescending 2
crNumericAscending 3
crNumericDescending 4

:CRPieLegendLayout

crAmountLayout 1
crBothLayout 2
crNoneLayout 3
crPercentLayout 0

:CRPieSize

crMaximumPieSize 0
crLargePieSize 16 (&H10)
crAveragePieSize 32 (&H20)
crSmallPieSize 48 (&H40)
crMinimumPieSize 64 (&H30)

:CRPlaceHolderType

crAllowPlaceHolders 2
crDelayTotalPageCountCalc 1

:CRPrinterDuplexType

crPRDPDefault 0
crPRDPHorizontal 3
crPRDPSimplex 1
crPRDPVertical 2

:CRPrintingProgress

crPrintingCancelled 5
crPrintingCompleted 3
crPrintingFailed 4
crPrintingHalted 6
crPrintingInProgress 2
crPrintingNotStarted 1

:CRRangeInfo

crRangeNotIncludeUpperLowerBound 0
crRangeIncludeUpperBound 1
crRangeIncludeLowerBound 2
crRangeNoUpperBound 4
crRangeNoLowerBound 8

:CRRenderResultType

crBSTRType 8 This constant is currently not supported.
crUISafeArrayType 8209

:CRReportFileFormat

cr70FileFormat 1792
cr80FileFormat 2048

:CRReportFormatStyle

crRFStandardStyle 0
crRFLeadingBreakStyle 1
crRFTrailingBreakStyle 2
crRFTableStyle 3
crRFDropTableStyle 4
crRFExecutiveLeadingBreakStyle 5
crRFExecutiveTrailingBreakStyle 6
crRFShadingStyle 7
crRFRedBlueBorderStyle 8
crRFMartoonTealBoxStyle 9

:CRReportKind

crColumnarReport 1
crLabelReport 2
crMulColumnReport 3

:CRReportVariableValueType

crRVBoolean 2
crRVCurrency 1
crRVDate 3
crRVDateTime 5
crRVNumber 0
crRVString 6
crRVTime 4

:CRRotationAngle

crRotate0 0
crRotate90 1
crRotate270 2

:CRRoundingType

crRoundToMillion 17
crRoundToHundredThousand 16
crRoundToTenThousand 15
crRoundToThousand 14
crRoundToHundred 13
crRoundToTen 12
crRoundToUnit 11
crRoundToTenth 10
crRoundToHundredth 9
crRoundToThousandth 8
crRoundToTenThousandth 7
crRoundToHundredThousandth 6
crRoundToMillionth 5
crRoundToTenMillionth 4
crRoundToHundredMillionth 3
crRoundToBillionth 2
crRoundToTenBillionth 1

:CRRunningTotalCondition

crRTEvalNoCondition 0
crRTEvalOnChangeOfField 1
crRTEvalOnChangeOfGroup 2
crRTEvalOnFormula 3

:CRSearchDirection

crForward 0
crBackward 1

:CRSecondType

crNumericNoSecond 2
crNumericSecond 0
crNumericSecondNoLeadingZero 1

:CRSectionAreaFormatConditionFormulaType

crSectionAreaBackgroundColorConditionFormulaType 9
crSectionAreaCssClassConditionFormulaType 8
crSectionAreaEnableHideForDrillDownConditionFormulaType 11
crSectionAreaEnableKeepTogetherConditionFormulaType 4
crSectionAreaEnableNewPageAfterConditionFormulaType 2
crSectionAreaEnableNewPageBeforeConditionFormulaType 3
crSectionAreaEnablePrintAtBottomOfPageConditionFormulaType 1
crSectionAreaEnableResetPageNumberAfterConditionFormulaType 6
crSectionAreaEnableSuppressConditionFormulaType 0
crSectionAreaEnableSuppressIfBlankConditionFormulaType 5
crSectionAreaEnableUnderlaySectionConditionFormulaType 7
crSectionAreaShowAreaConditionFormulaType 10

:CRSliceDetachment

crLargestSlice 2
crSmallestSlice 1
crNoDetachment 0

:CRSortDirection

crAscendingOrder 0
crDescendingOrder 1
crOriginalOrder 2 Not supported for any kind of groups.
crSpecifiedOrder 3 Not supported for any kind of groups.

:CRSpecialVarType

crSVTDataDate 4
crSVTDataTime 5
crSVTFileAuthor 15
crSVTFileCreationDate 16 (&H10)
crSVTFilename 14
crSVTGroupNumber 8
crSVTGroupSelection 13
crSVTModificationDate 2
crSVTModificationTime 3
crSVTPageNofM 17 (&H11)
crSVTPageNumber 7
crSVTPrintDate 0
crSVTPrintTime 1
crSVTRecordNumber 6
crSVTRecordSelection 12
crSVTReportComments 11
crSVTReportTitle 10
crSVTTotalPageCount 9

:CRStringFieldConditionFormulaType

crTextInterpretationConditionFormulaType 200 (&HC8)

:CRSubreportConditionFormulaType

crCaptionConditionFormulaType 220 (&HDC)
crDrillDownTabTextConditionFormulaType 221 (&HDD)

:CRSummaryType

crSTAverage 1
crSTCount 6
crSTDCorrelation 10
crSTDCovariance 11
crSTDistinctCount 9
crSTDMedian 13
crSTDMode 17 (&H11)
crSTDNthLargest 15
crSTDNthMostFrequent 18 (&H12)
crSTDNthSmallest 16 (&H10)
crSTDPercentage 19 (&H13)
crSTDPercentile 14
crSTDWeightedAvg 12
crSTMaximum 4
crSTMinimum 5
crSTPopStandardDeviation 8
crSTPopVariance 7
crSTSampleStandardDeviation 3
crSTSampleVariance 2
crSTSum 0

:CRTableDifferences

crTDOK 0x00000000
crTDDatabaseNotFound 0x00000001
crTDServerNotFound 0x00000002
crTDServerNotOpened 0x00000004
crTDAliasChanged 0x00000008
crTDIndexesChanged 0x00000010
crTDDriverChanged 0x00000020
crTDDictionaryChanged 0x00000040
crTDFileTypeChanged 0x00000080
crTDRecordSizeChanged 0x00000100
crTDAccessChanged 0x00000200
crTDParametersChanged 0x00000400
crTDLocationChanged 0x00000800
crTDDatabaseOtherChanges 0x00001000
crTDNumberFieldChanged 0x00010000
crTDFieldOtherChanges 0x00020000
crTDFieldNameChanged 0x00040000
crTDFieldDescChanged 0x00080000
crTDFieldTypeChanged 0x00100000
crTDFieldSizeChanged 0x00200000
crTDNativeFieldTypeChanged 0x00400000
crTDNativeFieldOffsetChanged 0x00800000
crTDNativeFieldSizeChanged 0x01000000
crTDFieldDecimalPlacesChanged 0x02000000

:CRTextFormat

crHTMLText 2
crRTFText 1
crStandardText 0

:CRTimeBase

cr12Hour 0
cr24Hour 1

:CRTimeFieldFormatConditionFormulaType

crAMPMFormatConditionFormulaType 161 (&HA1)
crAMStringConditionFormulaType 166 (&HA6)
crHourFormatConditionFormulaType 162 (&HA2)
crHourMinuteSeparatorConditionFormulaType 168 (&HA8)
crMinuteFormatConditionFormulaType 163 (&HA3)
crMinuteSecondSeparatorConditionFormulaType 167 (&HA7)
crPMStringConditionFormulaType 165 (&HA5)
crSecondFormatConditionFormulaType 164 (&HA4)
crTimeBaseConditionFormulaType 160 (&HA0)

:CRTopOrBottomNGroupSortOrder

crAllGroupsSorted 1
crAllGroupsUnsorted 0
crBottomNGroups 3
crTopNGroups 2
crUnknownGroupsSortOrder 10

:CRValueFormatType

crAllowComplexFieldFormatting 4
crIncludeFieldValues 1
crIncludeHiddenFields 2

:CRViewingAngle

crBirdsEyeView 15
crDistortedStdView 10
crDistortedView 4
crFewGroupsView 9
crFewSeriesView 8
crGroupEmphasisView 7
crGroupEyeView 6
crMaxView 16 (&H10)
crShorterView 12
crShortView 5
crStandardView 1
crTallView 2
crThickGroupsView 11
crThickSeriesView 13
crThickStdView 14
crTopView 3

:CRYearType

crLongYear 1
crNoYear 2
crShortYear 0
