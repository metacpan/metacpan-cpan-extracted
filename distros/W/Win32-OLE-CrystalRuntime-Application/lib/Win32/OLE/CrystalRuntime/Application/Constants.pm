package Win32::OLE::CrystalRuntime::Application::Constants;
use strict;
use warnings;
use base qw{Exporter};

our $VERSION     = '0.12';
our %EXPORT_TAGS = ();
our @EXPORT_OK   = ();

=head1 NAME

Win32::OLE::CrystalRuntime::Application::Constants - Perl CrystalRuntime.Application Constants Object

=head1 SYNOPSIS

  use Win32::OLE::CrystalRuntime::Application::Constants qw{:all};
  use Win32::OLE::CrystalRuntime::Application::Constants qw{:CRAlignment};
  use Win32::OLE::CrystalRuntime::Application::Constants qw{crLeftAlign crHorCenterAlign};

=head1 DESCRIPTION

This package provide constants for Win32::OLE::CrystalRuntime::Application objects. 

=head1 USAGE

  use Win32::OLE::CrystalRuntime::Application::Constants qw{:CRAlignment};
  print crLeftAlign(), "\n"; #use () to pass use strict;

=head1 CONSTANTS

=head2 :CRAlignment
 
crDefaultAlign crHorCenterAlign crJustified crLeftAlign crRightAlign

=cut

$EXPORT_TAGS{"CRAlignment"}=[qw{crDefaultAlign crHorCenterAlign crJustified crLeftAlign crRightAlign}];
 
use constant crDefaultAlign => 0;
use constant crHorCenterAlign => 2;
use constant crJustified => 4;
use constant crLeftAlign => 1;
use constant crRightAlign => 3;

=head2 :CRAMPMType
 
crAmPmAfter crAmPmBefore

=cut

$EXPORT_TAGS{"CRAMPMType"}=[qw{crAmPmAfter crAmPmBefore}];
 
use constant crAmPmAfter => 1;
use constant crAmPmBefore => 0;

=head2 :CRAreaKind
 
crDetail crGroupFooter crGroupHeader crPageFooter crPageHeader crReportFooter crReportHeader

=cut

$EXPORT_TAGS{"CRAreaKind"}=[qw{crDetail crGroupFooter crGroupHeader crPageFooter crPageHeader crReportFooter crReportHeader}];
 
use constant crDetail => 4;
use constant crGroupFooter => 5;
use constant crGroupHeader => 3;
use constant crPageFooter => 7;
use constant crPageHeader => 2;
use constant crReportFooter => 8;
use constant crReportHeader => 1;

=head2 :CRBarSize
 
crMinimumBarSize crSmallBarSize crAverageBarSize crLargeBarSize crMaximumBarSize

=cut

$EXPORT_TAGS{"CRBarSize"}=[qw{crMinimumBarSize crSmallBarSize crAverageBarSize crLargeBarSize crMaximumBarSize}];
 
use constant crMinimumBarSize => 0;
use constant crSmallBarSize => 1;
use constant crAverageBarSize => 2;
use constant crLargeBarSize => 3;
use constant crMaximumBarSize => 4;

=head2 :CRBindingMatchType
 
crBMTName crBMTNameAndValue

=cut

$EXPORT_TAGS{"CRBindingMatchType"}=[qw{crBMTName crBMTNameAndValue}];
 
use constant crBMTName => 0;
use constant crBMTNameAndValue => 1;

=head2 :CRBooleanFieldFormatConditionFormulaType
 
crOutputFormatConditionFormulaType

=cut

$EXPORT_TAGS{"CRBooleanFieldFormatConditionFormulaType"}=[qw{crOutputFormatConditionFormulaType}];
 
use constant crOutputFormatConditionFormulaType => 20;  # (&H14)

=head2 :CRBooleanOutputType
 
crOneOrZero crTOrF crTrueOrFalse crYesOrNo crYOrN

=cut

$EXPORT_TAGS{"CRBooleanOutputType"}=[qw{crOneOrZero crTOrF crTrueOrFalse crYesOrNo crYOrN}];
 
use constant crOneOrZero => 4;
use constant crTOrF => 1;
use constant crTrueOrFalse => 0;
use constant crYesOrNo => 2;
use constant crYOrN => 3;

=head2 :CRBorderConditionFormulaType
 
crBackgroundColorConditionFormulaType crBorderColorConditionFormulaType crBottomLineStyleConditionFormulaType crHasDropShadowConditionFormulaType crLeftLineStyleConditionFormulaType crRightLineStyleConditionFormulaType crTightHorizontalConditionFormulaType crTightVerticalConditionFormulaType crTopLineStyleConditionFormulaType

=cut

$EXPORT_TAGS{"CRBorderConditionFormulaType"}=[qw{crBackgroundColorConditionFormulaType crBorderColorConditionFormulaType crBottomLineStyleConditionFormulaType crHasDropShadowConditionFormulaType crLeftLineStyleConditionFormulaType crRightLineStyleConditionFormulaType crTightHorizontalConditionFormulaType crTightVerticalConditionFormulaType crTopLineStyleConditionFormulaType}];
 
use constant crBackgroundColorConditionFormulaType => 45;  # (&H2D)
use constant crBorderColorConditionFormulaType => 46;  # (&H2E)
use constant crBottomLineStyleConditionFormulaType => 43;  # (&H2B)
use constant crHasDropShadowConditionFormulaType => 44;  # (&H2C)
use constant crLeftLineStyleConditionFormulaType => 40;  # (&H28)
use constant crRightLineStyleConditionFormulaType => 41;  # (&H29)
use constant crTightHorizontalConditionFormulaType => 47;  # (&H2F)
use constant crTightVerticalConditionFormulaType => 48;  # (&H30)
use constant crTopLineStyleConditionFormulaType => 42;  # (&H2A)

=head2 :CRCommonFieldFormatConditionFormulaType
 
crSuppressIfDuplicatedConditionFormulaType crUseSystemDefaultConditionFormulaType

=cut

$EXPORT_TAGS{"CRCommonFieldFormatConditionFormulaType"}=[qw{crSuppressIfDuplicatedConditionFormulaType crUseSystemDefaultConditionFormulaType}];
 
use constant crSuppressIfDuplicatedConditionFormulaType => 80;
use constant crUseSystemDefaultConditionFormulaType => 81;  # (&H51)

=head2 :CRConvertDateTimeType
 
crConvertDateTimeToDate crConvertDateTimeToString crKeepDateTimeType

=cut

$EXPORT_TAGS{"CRConvertDateTimeType"}=[qw{crConvertDateTimeToDate crConvertDateTimeToString crKeepDateTimeType}];
 
use constant crConvertDateTimeToDate => 1;
use constant crConvertDateTimeToString => 0;
use constant crKeepDateTimeType => 2;

=head2 :CRCurrencyPositionType
 
crLeadingCurrencyInsideNegative crLeadingCurrencyOutsideNegative crTrailingCurrencyInsideNegative crTrailingCurrencyOutsideNegative

=cut

$EXPORT_TAGS{"CRCurrencyPositionType"}=[qw{crLeadingCurrencyInsideNegative crLeadingCurrencyOutsideNegative crTrailingCurrencyInsideNegative crTrailingCurrencyOutsideNegative}];
 
use constant crLeadingCurrencyInsideNegative => 0;
use constant crLeadingCurrencyOutsideNegative => 1;
use constant crTrailingCurrencyInsideNegative => 2;
use constant crTrailingCurrencyOutsideNegative => 3;

=head2 :CRCurrencySymbolType
 
crCSTFixedSymbol crCSTFloatingSymbol crCSTNoSymbol

=cut

$EXPORT_TAGS{"CRCurrencySymbolType"}=[qw{crCSTFixedSymbol crCSTFloatingSymbol crCSTNoSymbol}];
 
use constant crCSTFixedSymbol => 1;
use constant crCSTFloatingSymbol => 2;
use constant crCSTNoSymbol => 0;

=head2 :CRDatabaseType
 
crSQLDatabase crStandardDatabase

=cut

$EXPORT_TAGS{"CRDatabaseType"}=[qw{crSQLDatabase crStandardDatabase}];
 
use constant crSQLDatabase => 2;
use constant crStandardDatabase => 1;

=head2 :CRDateCalendarType
 
crGregorianCalendar crGregorianUSCalendar crGregorianArabicCalendar crGregorianMEFrenchCalendar crGregorianXlitEnglishCalendar crGregorianXlitFrenchCalendar crHebrewCalendar crHijriCalendar crJapaneseCalendar crKoreanCalendar crTaiwaneseCalendar crThaiCalendar

=cut

$EXPORT_TAGS{"CRDateCalendarType"}=[qw{crGregorianCalendar crGregorianUSCalendar crGregorianArabicCalendar crGregorianMEFrenchCalendar crGregorianXlitEnglishCalendar crGregorianXlitFrenchCalendar crHebrewCalendar crHijriCalendar crJapaneseCalendar crKoreanCalendar crTaiwaneseCalendar crThaiCalendar}];
 
use constant crGregorianCalendar => 1;
use constant crGregorianUSCalendar => 2;
use constant crGregorianArabicCalendar => 10;
use constant crGregorianMEFrenchCalendar => 9;
use constant crGregorianXlitEnglishCalendar => 11;
use constant crGregorianXlitFrenchCalendar => 12;
use constant crHebrewCalendar => 8;
use constant crHijriCalendar => 6;
use constant crJapaneseCalendar => 3;
use constant crKoreanCalendar => 5;
use constant crTaiwaneseCalendar => 4;
use constant crThaiCalendar => 7;

=head2 :CRDateEraType
 
crLongEra crNoEra crShortEra

=cut

$EXPORT_TAGS{"CRDateEraType"}=[qw{crLongEra crNoEra crShortEra}];
 
use constant crLongEra => 1;
use constant crNoEra => 2;
use constant crShortEra => 0;

=head2 :CRDateFieldFormatConditionFormulaType
 
crCalendarTypeConditionFormulaType crDateFirstSeparatorCondidtionFormulaType crDateOrderConditionFormulaType crDatePrefixSeparatorConditionFormulaType crDateSecondSeparatorConditionFormulaType crDateSuffixSeparatorConditionFormulaType crDayFormatConditionFormulaType crDayOfWeekEnclosureConditionFormulaType crDayOfWeekPositionConditionFormulaType crDayOfWeekSeparatorConditionFormulaType crDayOfWeekTypeConditionFormulaType crEraTypeConditionFormulaType crMonthFormatConditionFormulaType crWindowsDefaultTypeConditionFormulaType crYearFormatConditionFormulaType

=cut

$EXPORT_TAGS{"CRDateFieldFormatConditionFormulaType"}=[qw{crCalendarTypeConditionFormulaType crDateFirstSeparatorCondidtionFormulaType crDateOrderConditionFormulaType crDatePrefixSeparatorConditionFormulaType crDateSecondSeparatorConditionFormulaType crDateSuffixSeparatorConditionFormulaType crDayFormatConditionFormulaType crDayOfWeekEnclosureConditionFormulaType crDayOfWeekPositionConditionFormulaType crDayOfWeekSeparatorConditionFormulaType crDayOfWeekTypeConditionFormulaType crEraTypeConditionFormulaType crMonthFormatConditionFormulaType crWindowsDefaultTypeConditionFormulaType crYearFormatConditionFormulaType}];
 
use constant crCalendarTypeConditionFormulaType => 131;  # (&H83)
use constant crDateFirstSeparatorCondidtionFormulaType => 128;  # (&H80)
use constant crDateOrderConditionFormulaType => 124;  # (&H7C)
use constant crDatePrefixSeparatorConditionFormulaType => 132;  # (&H84)
use constant crDateSecondSeparatorConditionFormulaType => 129;  # (&H81)
use constant crDateSuffixSeparatorConditionFormulaType => 133;  # (&H85)
use constant crDayFormatConditionFormulaType => 122;  # (&H7A)
use constant crDayOfWeekEnclosureConditionFormulaType => 134;  # (&H86)
use constant crDayOfWeekPositionConditionFormulaType => 127;  # (&H7F)
use constant crDayOfWeekSeparatorConditionFormulaType => 126;  # (&H7E)
use constant crDayOfWeekTypeConditionFormulaType => 125;  # (&H7D)
use constant crEraTypeConditionFormulaType => 130;  # (&H82)
use constant crMonthFormatConditionFormulaType => 121;  # (&H79)
use constant crWindowsDefaultTypeConditionFormulaType => 123;  # (&H7B)
use constant crYearFormatConditionFormulaType => 120;  # (&H78)

=head2 :CRDateOrder
 
crDayMonthYear crMonthDayYear crYearMonthDay

=cut

$EXPORT_TAGS{"CRDateOrder"}=[qw{crDayMonthYear crMonthDayYear crYearMonthDay}];
 
use constant crDayMonthYear => 1;
use constant crMonthDayYear => 2;
use constant crYearMonthDay => 0;

=head2 :CRDateTimeFieldFormatConditionFormulaType
 
crDateTimeOrderConditionFormulaType crDateTimeSeparatorConditionFormulaType

=cut

$EXPORT_TAGS{"CRDateTimeFieldFormatConditionFormulaType"}=[qw{crDateTimeOrderConditionFormulaType crDateTimeSeparatorConditionFormulaType}];
 
use constant crDateTimeOrderConditionFormulaType => 140;  # (&H8C)
use constant crDateTimeSeparatorConditionFormulaType => 141;  # (&H8D)

=head2 :CRDateWindowsDefaultType
 
crNotUsingWindowsDefaults crUseWindowsLongDate crUseWindowsShortDate

=cut

$EXPORT_TAGS{"CRDateWindowsDefaultType"}=[qw{crNotUsingWindowsDefaults crUseWindowsLongDate crUseWindowsShortDate}];
 
use constant crNotUsingWindowsDefaults => 2;
use constant crUseWindowsLongDate => 0;
use constant crUseWindowsShortDate => 1;

=head2 :CRDayType
 
crLeadingZeroNumericDay crNoDay crNumericDay

=cut

$EXPORT_TAGS{"CRDayType"}=[qw{crLeadingZeroNumericDay crNoDay crNumericDay}];
 
use constant crLeadingZeroNumericDay => 1;
use constant crNoDay => 2;
use constant crNumericDay => 0;

=head2 :CRDiscreteOrRangeKind
 
crDiscreteValue crRangeValue crDiscreteAndRangeValue

=cut

$EXPORT_TAGS{"CRDiscreteOrRangeKind"}=[qw{crDiscreteValue crRangeValue crDiscreteAndRangeValue}];
 
use constant crDiscreteValue => 0;
use constant crRangeValue => 1;
use constant crDiscreteAndRangeValue => 2;

=head2 :CRDivisionMethod
 
crAutomaticDivision crManualDivision

=cut

$EXPORT_TAGS{"CRDivisionMethod"}=[qw{crAutomaticDivision crManualDivision}];
 
use constant crAutomaticDivision => 0;
use constant crManualDivision => 1;

=head2 :CRExchangeDestinationType
 
crExchangeFolderType crExchangePostDocMessage

=cut

$EXPORT_TAGS{"CRExchangeDestinationType"}=[qw{crExchangeFolderType crExchangePostDocMessage}];
 
use constant crExchangeFolderType => 0;
use constant crExchangePostDocMessage => 1011;  # (&H3F3)

=head2 :CRExportDestinationType
 
crEDTApplication crEDTDiskFile crEDTEMailMAPI crEDTEMailVIM crEDTLotusDomino crEDTMicrosoftExchange crEDTNoDestination

=cut

$EXPORT_TAGS{"CRExportDestinationType"}=[qw{crEDTApplication crEDTDiskFile crEDTEMailMAPI crEDTEMailVIM crEDTLotusDomino crEDTMicrosoftExchange crEDTNoDestination}];
 
use constant crEDTApplication => 5;
use constant crEDTDiskFile => 1;
use constant crEDTEMailMAPI => 2;
use constant crEDTEMailVIM => 3;
use constant crEDTLotusDomino => 6;
use constant crEDTMicrosoftExchange => 4;
use constant crEDTNoDestination => 0;

=head2 :CRExportFormatType
 
crEFTCharSeparatedValues crEFTCommaSeparatedValues crEFTCrystalReport crEFTCrystalReport70 crEFTDataInterchange crEFTExactRichText crEFTExcel50 crEFTExcel50Tabular crEFTExcel70 crEFTExcel70Tabular crEFTExcel80 crEFTExcel80Tabular crEFTExcel97 crEFTExplorer32Extend crEFTHTML32Standard crEFTHTML40 crEFTLotus123WK1 crEFTLotus123WK3 crEFTLotus123WKS crEFTNoFormat crEFTODBC crEFTPaginatedText crEFTPortableDocFormat crEFTRecordStyle crEFTReportDefinition crEFTTabSeparatedText crEFTTabSeparatedValues crEFTText crEFTWordForWindows crEFTXML

=cut

$EXPORT_TAGS{"CRExportFormatType"}=[qw{crEFTCharSeparatedValues crEFTCommaSeparatedValues crEFTCrystalReport crEFTCrystalReport70 crEFTDataInterchange crEFTExactRichText crEFTExcel50 crEFTExcel50Tabular crEFTExcel70 crEFTExcel70Tabular crEFTExcel80 crEFTExcel80Tabular crEFTExcel97 crEFTExplorer32Extend crEFTHTML32Standard crEFTHTML40 crEFTLotus123WK1 crEFTLotus123WK3 crEFTLotus123WKS crEFTNoFormat crEFTODBC crEFTPaginatedText crEFTPortableDocFormat crEFTRecordStyle crEFTReportDefinition crEFTTabSeparatedText crEFTTabSeparatedValues crEFTText crEFTWordForWindows crEFTXML}];
 
use constant crEFTCharSeparatedValues => 7;
use constant crEFTCommaSeparatedValues => 5;
use constant crEFTCrystalReport => 1;
use constant crEFTCrystalReport70 => 33;
use constant crEFTDataInterchange => 2;
use constant crEFTExactRichText => 35;  # (&H23)
use constant crEFTExcel50 => 21;  # (&H15)
use constant crEFTExcel50Tabular => 22;  # (&H16)
use constant crEFTExcel70 => 27;  # (&H1B)
use constant crEFTExcel70Tabular => 28;  # (&H1C)
use constant crEFTExcel80 => 29;  # (&H1D)
use constant crEFTExcel80Tabular => 30;  # (&H1E)
use constant crEFTExcel97 => 36;  # (&H24)
use constant crEFTExplorer32Extend => 25;  # (&H19)
use constant crEFTHTML32Standard => 24;  # (&H18)
use constant crEFTHTML40 => 32;  # (&H20)
use constant crEFTLotus123WK1 => 12;
use constant crEFTLotus123WK3 => 13;
use constant crEFTLotus123WKS => 11;
use constant crEFTNoFormat => 0;
use constant crEFTODBC => 23;  # (&H17)
use constant crEFTPaginatedText => 10;
use constant crEFTPortableDocFormat => 31;  # (&H1F)
use constant crEFTRecordStyle => 3;
use constant crEFTReportDefinition => 34;  # (&H22)
use constant crEFTTabSeparatedText => 9;
use constant crEFTTabSeparatedValues => 6;
use constant crEFTText => 8;
use constant crEFTWordForWindows => 14;
use constant crEFTXML => 37;  # (&H25)

=head2 :CRFieldKind
 
crDatabaseField crFormulaField crGroupNameField crRunningTotalField crParameterField crSpecialVarField crSQLExpressionField crSummaryField

=cut

$EXPORT_TAGS{"CRFieldKind"}=[qw{crDatabaseField crFormulaField crGroupNameField crRunningTotalField crParameterField crSpecialVarField crSQLExpressionField crSummaryField}];
 
use constant crDatabaseField => 1;
use constant crFormulaField => 2;
use constant crGroupNameField => 5;
use constant crRunningTotalField => 7;
use constant crParameterField => 6;
use constant crSpecialVarField => 4;
use constant crSQLExpressionField => 8;
use constant crSummaryField => 3;

=head2 :CRFieldMappingType
 
crAutoFieldMapping crEventFieldMapping crPromptFieldMapping

=cut

$EXPORT_TAGS{"CRFieldMappingType"}=[qw{crAutoFieldMapping crEventFieldMapping crPromptFieldMapping}];
 
use constant crAutoFieldMapping => 0;
use constant crEventFieldMapping => 2;
use constant crPromptFieldMapping => 1;

=head2 :CRFieldValueType
 
crBitmapField crBlobField crBooleanField crChartField crCurrencyField crDateField crDateTimeField crIconField crInt16sField crInt16uField crInt32sField crInt32uField crInt8sField crInt8uField crNumberField crOleField crPersistentMemoField crPictureField crStringField crTimeField crTransientMemoField crUnknownField

=cut

$EXPORT_TAGS{"CRFieldValueType"}=[qw{crBitmapField crBlobField crBooleanField crChartField crCurrencyField crDateField crDateTimeField crIconField crInt16sField crInt16uField crInt32sField crInt32uField crInt8sField crInt8uField crNumberField crOleField crPersistentMemoField crPictureField crStringField crTimeField crTransientMemoField crUnknownField}];
 
use constant crBitmapField => 17;  # (&H11)
use constant crBlobField => 15;
use constant crBooleanField => 9;
use constant crChartField => 21;  # (&H15)
use constant crCurrencyField => 8;
use constant crDateField => 10;
use constant crDateTimeField => 16;  # (&H10)
use constant crIconField => 18;  # (&H12)
use constant crInt16sField => 3;
use constant crInt16uField => 4;
use constant crInt32sField => 5;
use constant crInt32uField => 6;
use constant crInt8sField => 1;
use constant crInt8uField => 2;
use constant crNumberField => 7;
use constant crOleField => 20;  # (&H14)
use constant crPersistentMemoField => 14;
use constant crPictureField => 19;  # (&H13)
use constant crStringField => 12;
use constant crTimeField => 11;
use constant crTransientMemoField => 13;
use constant crUnknownField => 22;  # (&H16)

=head2 :CRFontColorConditionFormulaType
 
crColorConditionFormulaType crFontConditionFormulaType crFontSizeConditionFormulaType crFontStrikeOutConditionFormulaType crFontStyleConditionFormulaType crFontUnderLineConditioneFormulaType

=cut

$EXPORT_TAGS{"CRFontColorConditionFormulaType"}=[qw{crColorConditionFormulaType crFontConditionFormulaType crFontSizeConditionFormulaType crFontStrikeOutConditionFormulaType crFontStyleConditionFormulaType crFontUnderLineConditioneFormulaType}];
 
use constant crColorConditionFormulaType => 180;  # (&HB4)
use constant crFontConditionFormulaType => 181;  # (&HB5)
use constant crFontSizeConditionFormulaType => 183;  # (&HB7)
use constant crFontStrikeOutConditionFormulaType => 184;  # (&HB8)
use constant crFontStyleConditionFormulaType => 182;  # (&HB6)
use constant crFontUnderLineConditioneFormulaType => 185;  # (&HB9)

=head2 :CRFormulaSyntax
 
crBasicSyntaxFormula crCrystalSyntaxFormula

=cut

$EXPORT_TAGS{"CRFormulaSyntax"}=[qw{crBasicSyntaxFormula crCrystalSyntaxFormula}];
 
use constant crBasicSyntaxFormula => 1;
use constant crCrystalSyntaxFormula => 0;  # Default value

=head2 :CRGraphColor
 
crBlackAndWhiteGraph crColorGraph

=cut

$EXPORT_TAGS{"CRGraphColor"}=[qw{crBlackAndWhiteGraph crColorGraph}];
 
use constant crBlackAndWhiteGraph => 1;
use constant crColorGraph => 0;

=head2 :CRGraphDataPoint
 
crNone crShowLabel crShowValue

=cut

$EXPORT_TAGS{"CRGraphDataPoint"}=[qw{crNone crShowLabel crShowValue}];
 
use constant crNone => 0;
use constant crShowLabel => 1;
use constant crShowValue => 2;

=head2 :CRGraphDataType
 
crCrossTabGraph crDetailGraph crGroupGraph

=cut

$EXPORT_TAGS{"CRGraphDataType"}=[qw{crCrossTabGraph crDetailGraph crGroupGraph}];
 
use constant crCrossTabGraph => 2;
use constant crDetailGraph => 1;
use constant crGroupGraph => 0;

=head2 :CRGraphDirection
 
crHorizontalGraph crVerticalGraph

=cut

$EXPORT_TAGS{"CRGraphDirection"}=[qw{crHorizontalGraph crVerticalGraph}];
 
use constant crHorizontalGraph => 0;
use constant crVerticalGraph => 1;

=head2 :CRGraphType
 
crAbsoluteAreaGraph crDualAxisBubbleGraph crFaked3DAbsoluteAreaGraph crFaked3DPercentAreaGraph crFaked3DPercentBarGraph crFaked3DRegularPieGraph crFaked3DSideBySideBarGraph crFaked3DStackedAreaGraph crFaked3DStackedBarGraph crHighLowDualAxisGraph crHighLowGraph crHighLowOpenCloseDualAxisGraph crHighLowOpenCloseGraph crHighLowOpenDualAxisGraph crHighLowOpenGraph crLineGraphWithMarkers crMultipleDoughnutGraph crMultiplePieGraph crMultipleProportionalDoughnutGraph crMultipleProportionalPieGraph crPercentageLineGraph crPercentageLineGraphWithMarkers crPercentAreaGraph crPercentBarGraph crRadarDualAxisGraph crRegularBubbleGraph crRegularDoughnutGraph crRegularLineGraph crRegularPieGraph crRegularRadarGraph crSideBySideBarGraph crStackedAreaGraph crStackedBarGraph crStackedLineGraph crStackedLineGraphWithMarkers crStackedRadarGraph crThreeDCutCornersGraph crThreeDOctagonGraph crThreeDPyramidGraph crThreeDRegularGraph crThreeDSurfaceHoneycombGraph crThreeDSurfaceRegularGraph crThreeDSurfaceWithSidesGraph crUnknownGraph crXyScatterGraph

=cut

$EXPORT_TAGS{"CRGraphType"}=[qw{crAbsoluteAreaGraph crDualAxisBubbleGraph crFaked3DAbsoluteAreaGraph crFaked3DPercentAreaGraph crFaked3DPercentBarGraph crFaked3DRegularPieGraph crFaked3DSideBySideBarGraph crFaked3DStackedAreaGraph crFaked3DStackedBarGraph crHighLowDualAxisGraph crHighLowGraph crHighLowOpenCloseDualAxisGraph crHighLowOpenCloseGraph crHighLowOpenDualAxisGraph crHighLowOpenGraph crLineGraphWithMarkers crMultipleDoughnutGraph crMultiplePieGraph crMultipleProportionalDoughnutGraph crMultipleProportionalPieGraph crPercentageLineGraph crPercentageLineGraphWithMarkers crPercentAreaGraph crPercentBarGraph crRadarDualAxisGraph crRegularBubbleGraph crRegularDoughnutGraph crRegularLineGraph crRegularPieGraph crRegularRadarGraph crSideBySideBarGraph crStackedAreaGraph crStackedBarGraph crStackedLineGraph crStackedLineGraphWithMarkers crStackedRadarGraph crThreeDCutCornersGraph crThreeDOctagonGraph crThreeDPyramidGraph crThreeDRegularGraph crThreeDSurfaceHoneycombGraph crThreeDSurfaceRegularGraph crThreeDSurfaceWithSidesGraph crUnknownGraph crXyScatterGraph}];
 
use constant crAbsoluteAreaGraph => 20;  # Obsolete
use constant crDualAxisBubbleGraph => 91;  # Obsolete
use constant crFaked3DAbsoluteAreaGraph => 23;  # Obsolete
use constant crFaked3DPercentAreaGraph => 25;  # (&H19)
use constant crFaked3DPercentBarGraph => 5;
use constant crFaked3DRegularPieGraph => 31;  # (&H1F)
use constant crFaked3DSideBySideBarGraph => 3;
use constant crFaked3DStackedAreaGraph => 24;  # (&H18)
use constant crFaked3DStackedBarGraph => 4;
use constant crHighLowDualAxisGraph => 101;  # Obsolete.
use constant crHighLowGraph => 100;  # (&H64)
use constant crHighLowOpenCloseDualAxisGraph => 105;  # Obsolete.
use constant crHighLowOpenCloseGraph => 104;  # (&H68)
use constant crHighLowOpenDualAxisGraph => 103;  # Obsolete.
use constant crHighLowOpenGraph => 102;  # Obsolete.
use constant crLineGraphWithMarkers => 13;
use constant crMultipleDoughnutGraph => 41;  # (&H29)
use constant crMultiplePieGraph => 32;  # (&H20)
use constant crMultipleProportionalDoughnutGraph => 42;  # (&H2A)
use constant crMultipleProportionalPieGraph => 33;  # (&H21)
use constant crPercentageLineGraph => 12;
use constant crPercentageLineGraphWithMarkers => 15;
use constant crPercentAreaGraph => 22;  # (&H16)
use constant crPercentBarGraph => 2;
use constant crRadarDualAxisGraph => 82;  # Obsolete
use constant crRegularBubbleGraph => 90;  # (&H5A)
use constant crRegularDoughnutGraph => 40;  # (&H28)
use constant crRegularLineGraph => 10;
use constant crRegularPieGraph => 30;  # (&H1E)
use constant crRegularRadarGraph => 80;  # (&H50)
use constant crSideBySideBarGraph => 0;
use constant crStackedAreaGraph => 21;  # (&H15)
use constant crStackedBarGraph => 1;
use constant crStackedLineGraph => 11;
use constant crStackedLineGraphWithMarkers => 14;
use constant crStackedRadarGraph => 81;  # (&H51)
use constant crThreeDCutCornersGraph => 53;  # (&H35)
use constant crThreeDOctagonGraph => 52;  # (&H34)
use constant crThreeDPyramidGraph => 51;  # (&H33)
use constant crThreeDRegularGraph => 50;  # (&H32)
use constant crThreeDSurfaceHoneycombGraph => 62;  # (&H3E)
use constant crThreeDSurfaceRegularGraph => 60;  # (&H3C)
use constant crThreeDSurfaceWithSidesGraph => 61;  # (&H3D)
use constant crUnknownGraph => 1000;  # (&H3E8)
use constant crXyScatterGraph => 70;  # (&H46)

=head2 :CRGridlineType
 
crMajorAndMinorGridlines crMajorGridlines crMinorGridlines crNoGridlines

=cut

$EXPORT_TAGS{"CRGridlineType"}=[qw{crMajorAndMinorGridlines crMajorGridlines crMinorGridlines crNoGridlines}];
 
use constant crMajorAndMinorGridlines => 3;
use constant crMajorGridlines => 2;
use constant crMinorGridlines => 1;
use constant crNoGridlines => 0;

=head2 :CRGroupCondition
 
crGCAnnually crGCAnyValue crGCBiweekly crGCByAMPM crGCByHour crGCByMinute crGCBySecond crGCDaily crGCEveryNo crGCEveryYes crGCMonthly crGCNextIsNo crGCNextIsYes crGCQuarterly crGCSemiAnnually crGCSemimonthly crGCToNo crGCToNo crGCWeekly

=cut

$EXPORT_TAGS{"CRGroupCondition"}=[qw{crGCAnnually crGCAnyValue crGCBiweekly crGCByAMPM crGCByHour crGCByMinute crGCBySecond crGCDaily crGCEveryNo crGCEveryYes crGCMonthly crGCNextIsNo crGCNextIsYes crGCQuarterly crGCSemiAnnually crGCSemimonthly crGCToNo crGCToNo crGCWeekly}];
 
use constant crGCAnnually => 7;
use constant crGCAnyValue => 14;
use constant crGCBiweekly => 2;
use constant crGCByAMPM => 18;  # (&H12)
use constant crGCByHour => 17;  # (&H11)
use constant crGCByMinute => 16;  # (&H10)
use constant crGCBySecond => 15;
use constant crGCDaily => 0;
use constant crGCEveryNo => 11;
use constant crGCEveryYes => 10;
use constant crGCMonthly => 4;
use constant crGCNextIsNo => 13;
use constant crGCNextIsYes => 12;
use constant crGCQuarterly => 5;
use constant crGCSemiAnnually => 6;
use constant crGCSemimonthly => 3;
use constant crGCToNo => 9;
use constant crGCToNoXXX => 8;  # One of crGCToNo (8 or 9) has got to be an error in the documentation.
use constant crGCWeekly => 1;

=head2 :CRHierarchicalSummaryType
 
crHierarchicalSummaryNone crSummaryAcrossHierarchy

=cut

$EXPORT_TAGS{"CRHierarchicalSummaryType"}=[qw{crHierarchicalSummaryNone crSummaryAcrossHierarchy}];
 
use constant crHierarchicalSummaryNone => 0;
use constant crSummaryAcrossHierarchy => 1;

=head2 :CRHourType
 
crNoHour crNumericHour crNumericHourNoLeadingZero

=cut

$EXPORT_TAGS{"CRHourType"}=[qw{crNoHour crNumericHour crNumericHourNoLeadingZero}];
 
use constant crNoHour => 2;
use constant crNumericHour => 0;
use constant crNumericHourNoLeadingZero => 1;

=head2 :CRHTMLPageStyle
 
crFramePageStyle crPlainPageStyle crToolbarAtBottomPageStyle crToolbarAtTopPageStyle crToolbarPageStyle

=cut

$EXPORT_TAGS{"CRHTMLPageStyle"}=[qw{crFramePageStyle crPlainPageStyle crToolbarAtBottomPageStyle crToolbarAtTopPageStyle crToolbarPageStyle}];
 
use constant crFramePageStyle => 2;
use constant crPlainPageStyle => 0;
use constant crToolbarAtBottomPageStyle => 4;
use constant crToolbarAtTopPageStyle => 3;
use constant crToolbarPageStyle => 1;

=head2 :CRHTMLToolbarStyle
 
crToolbarRefreshButton crToolbarSearchBox

=cut

$EXPORT_TAGS{"CRHTMLToolbarStyle"}=[qw{crToolbarRefreshButton crToolbarSearchBox}];
 
use constant crToolbarRefreshButton => 1;
use constant crToolbarSearchBox => 2;

=head2 :CRImageType
 
crDIBImageType crJPEGImageType crImageUnknown

=cut

$EXPORT_TAGS{"CRImageType"}=[qw{crDIBImageType crJPEGImageType crImageUnknown}];
 
use constant crDIBImageType => 1;
use constant crJPEGImageType => 2;
use constant crImageUnknown => 0;

=head2 :CRLeadingDayPosition
 
crLeadingDayOfWeek crTrailingDayOfWeek

=cut

$EXPORT_TAGS{"CRLeadingDayPosition"}=[qw{crLeadingDayOfWeek crTrailingDayOfWeek}];
 
use constant crLeadingDayOfWeek => 0;
use constant crTrailingDayOfWeek => 1;

=head2 :CRLeadingDayType
 
crLongLeadingDay crNoLeadingDay crShortLeadingDay

=cut

$EXPORT_TAGS{"CRLeadingDayType"}=[qw{crLongLeadingDay crNoLeadingDay crShortLeadingDay}];
 
use constant crLongLeadingDay => 1;
use constant crNoLeadingDay => 2;
use constant crShortLeadingDay => 0;

=head2 :CRLegendPosition
 
crPlaceLeft crPlaceRight crPlaceBottom crPlaceCustom

=cut

$EXPORT_TAGS{"CRLegendPosition"}=[qw{crPlaceLeft crPlaceRight crPlaceBottom crPlaceCustom}];
 
use constant crPlaceLeft => 5;
use constant crPlaceRight => 4;
use constant crPlaceBottom => 6;
use constant crPlaceCustom => 7;

=head2 :CRLineSpacingType
 
crExactSpacing crMultipleSpacing

=cut

$EXPORT_TAGS{"CRLineSpacingType"}=[qw{crExactSpacing crMultipleSpacing}];
 
use constant crExactSpacing => 1;
use constant crMultipleSpacing => 0;

=head2 :CRLineStyle
 
crLSDashLine crLSDotLine crLSDoubleLine crLSNoLine crLSSingleLine

=cut

$EXPORT_TAGS{"CRLineStyle"}=[qw{crLSDashLine crLSDotLine crLSDoubleLine crLSNoLine crLSSingleLine}];
 
use constant crLSDashLine => 3;
use constant crLSDotLine => 4;
use constant crLSDoubleLine => 2;  # Not valid for LineObject.LineStyle and BoxObject.LineStyle.
use constant crLSNoLine => 0;  # Not valid for LineObject.LineStyle and BoxObject.LineStyle.
use constant crLSSingleLine => 1;

=head2 :CRLinkJoinType
 
crJTAdvance crJTEqual crJTGreaterOrEqual crJTGreaterThan crJTLeftOuter crJTLessOrEqual crJTLessThan crJTNotEqual crJTRightOuter

=cut

$EXPORT_TAGS{"CRLinkJoinType"}=[qw{crJTAdvance crJTEqual crJTGreaterOrEqual crJTGreaterThan crJTLeftOuter crJTLessOrEqual crJTLessThan crJTNotEqual crJTRightOuter}];
 
use constant crJTAdvance => 13;
use constant crJTEqual => 4;
use constant crJTGreaterOrEqual => 10;
use constant crJTGreaterThan => 8;
use constant crJTLeftOuter => 5;
use constant crJTLessOrEqual => 11;
use constant crJTLessThan => 9;
use constant crJTNotEqual => 12;
use constant crJTRightOuter => 6;

=head2 :CRLinkLookUpType
 
crLTLookupParallel crLTLookupProduct crLTLookupSeries

=cut

$EXPORT_TAGS{"CRLinkLookUpType"}=[qw{crLTLookupParallel crLTLookupProduct crLTLookupSeries}];
 
use constant crLTLookupParallel => 1;
use constant crLTLookupProduct => 2;
use constant crLTLookupSeries => 3;

=head2 :CRMarkerShape
 
crCircleShape crDiamondShape crRectangleShape crTriangleShape

=cut

$EXPORT_TAGS{"CRMarkerShape"}=[qw{crCircleShape crDiamondShape crRectangleShape crTriangleShape}];
 
use constant crCircleShape => 4;
use constant crDiamondShape => 5;
use constant crRectangleShape => 1;
use constant crTriangleShape => 8;

=head2 :CRMarkerSize
 
crLargeMarkers crMediumLargeMarkers crMediumMarkers crMediumSmallMarkers crSmallMarkers

=cut

$EXPORT_TAGS{"CRMarkerSize"}=[qw{crLargeMarkers crMediumLargeMarkers crMediumMarkers crMediumSmallMarkers crSmallMarkers}];
 
use constant crLargeMarkers => 4;
use constant crMediumLargeMarkers => 3;
use constant crMediumMarkers => 2;
use constant crMediumSmallMarkers => 1;
use constant crSmallMarkers => 0;

=head2 :CRMinuteType
 
crNoMinute crNumericMinute crNumericMinuteNoLeadingZero

=cut

$EXPORT_TAGS{"CRMinuteType"}=[qw{crNoMinute crNumericMinute crNumericMinuteNoLeadingZero}];
 
use constant crNoMinute => 2;
use constant crNumericMinute => 0;
use constant crNumericMinuteNoLeadingZero => 1;

=head2 :CRMonthType
 
crLeadingZeroNumericMonth crLongMonth crNoMonth crNumericMonth crShortMonth

=cut

$EXPORT_TAGS{"CRMonthType"}=[qw{crLeadingZeroNumericMonth crLongMonth crNoMonth crNumericMonth crShortMonth}];
 
use constant crLeadingZeroNumericMonth => 1;
use constant crLongMonth => 3;
use constant crNoMonth => 4;
use constant crNumericMonth => 0;
use constant crShortMonth => 2;

=head2 :CRNegativeType
 
crBracketed crLeadingMinus crNotNegative crTrailingMinus

=cut

$EXPORT_TAGS{"CRNegativeType"}=[qw{crBracketed crLeadingMinus crNotNegative crTrailingMinus}];
 
use constant crBracketed => 3;
use constant crLeadingMinus => 1;
use constant crNotNegative => 0;
use constant crTrailingMinus => 2;

=head2 :CRNumberFormat
 
crCurrencyMillions crCurrencyNoDecimal crCurrencyThousands crCurrencyTwoDecimal crCustomNumberFormat crMillionsNoDecimal crNoDecimal crOneDecimal crPercentNoDecimal crPercentOneDecimal crPercentTwoDecimal crThousandsNoDecimal crTwoDecimal

=cut

$EXPORT_TAGS{"CRNumberFormat"}=[qw{crCurrencyMillions crCurrencyNoDecimal crCurrencyThousands crCurrencyTwoDecimal crCustomNumberFormat crMillionsNoDecimal crNoDecimal crOneDecimal crPercentNoDecimal crPercentOneDecimal crPercentTwoDecimal crThousandsNoDecimal crTwoDecimal}];
 
use constant crCurrencyMillions => 12;
use constant crCurrencyNoDecimal => 3;
use constant crCurrencyThousands => 11;
use constant crCurrencyTwoDecimal => 4;
use constant crCustomNumberFormat => 8;
use constant crMillionsNoDecimal => 10;
use constant crNoDecimal => 0;
use constant crOneDecimal => 1;
use constant crPercentNoDecimal => 5;
use constant crPercentOneDecimal => 6;
use constant crPercentTwoDecimal => 7;
use constant crThousandsNoDecimal => 9;
use constant crTwoDecimal => 2;

=head2 :CRNumericFieldFormatConditionFormulaType
 
crAllowFieldClippingConditionFormulaType crCurrencyPositionConditionFormulaType crCurrencySymbolConditionFormulaType crCurrencySymbolFormatConditionFormulaType crDecimalSymbolConditionFormulaType crDisplayReverseSignConditionFormulaType crEnableSuppressIfZeroConditionFormulaType crEnableUseLeadZeroConditionFormulaType crHasOneSymbolPerPageConditionFormulaType crNDecimalPlacesConditionFormulaType crNegativeFormatConditionFormulaType crRoundingFormatConditionFormulaType crThousandsSeparatorFormatConditionFormulaType crThousandSymbolFormatConditionFormulaType crZeroValueStringConditionFormulaType

=cut

$EXPORT_TAGS{"CRNumericFieldFormatConditionFormulaType"}=[qw{crAllowFieldClippingConditionFormulaType crCurrencyPositionConditionFormulaType crCurrencySymbolConditionFormulaType crCurrencySymbolFormatConditionFormulaType crDecimalSymbolConditionFormulaType crDisplayReverseSignConditionFormulaType crEnableSuppressIfZeroConditionFormulaType crEnableUseLeadZeroConditionFormulaType crHasOneSymbolPerPageConditionFormulaType crNDecimalPlacesConditionFormulaType crNegativeFormatConditionFormulaType crRoundingFormatConditionFormulaType crThousandsSeparatorFormatConditionFormulaType crThousandSymbolFormatConditionFormulaType crZeroValueStringConditionFormulaType}];
 
use constant crAllowFieldClippingConditionFormulaType => 114;  # (&H72)
use constant crCurrencyPositionConditionFormulaType => 111;  # (&H6F)
use constant crCurrencySymbolConditionFormulaType => 109;  # (&H6D)
use constant crCurrencySymbolFormatConditionFormulaType => 104;  # (&H68)
use constant crDecimalSymbolConditionFormulaType => 108;  # (&H6C)
use constant crDisplayReverseSignConditionFormulaType => 112;  # (&H70)
use constant crEnableSuppressIfZeroConditionFormulaType => 105;  # (&H69)
use constant crEnableUseLeadZeroConditionFormulaType => 102;  # (&H66)
use constant crHasOneSymbolPerPageConditionFormulaType => 110;  # (&H6E))
use constant crNDecimalPlacesConditionFormulaType => 100;  # (&H64)
use constant crNegativeFormatConditionFormulaType => 103;  # (&H67)
use constant crRoundingFormatConditionFormulaType => 101;  # (&H65)
use constant crThousandsSeparatorFormatConditionFormulaType => 106;  # (&H6A)
use constant crThousandSymbolFormatConditionFormulaType => 107;  # (&H6B)
use constant crZeroValueStringConditionFormulaType => 113;  # (&H71)

=head2 :CRObjectFormatConditionFormulaType
 
crCssClassConditionFormulaType crEnableCanGrowConditionFormulaType crEnableCloseAtPageBreakConditionFormulaType crEnableKeepTogetherConditionFormulaType crEnableSuppressConditinFormulaType crHorizontalAlignmentConditionFormulaType crHyperLinkConditionFormulaType crRotationConditionFormulaType crToolTipTextConditionFormulaType

=cut

$EXPORT_TAGS{"CRObjectFormatConditionFormulaType"}=[qw{crCssClassConditionFormulaType crEnableCanGrowConditionFormulaType crEnableCloseAtPageBreakConditionFormulaType crEnableKeepTogetherConditionFormulaType crEnableSuppressConditinFormulaType crHorizontalAlignmentConditionFormulaType crHyperLinkConditionFormulaType crRotationConditionFormulaType crToolTipTextConditionFormulaType}];
 
use constant crCssClassConditionFormulaType => 66;  # (&H42)
use constant crEnableCanGrowConditionFormulaType => 64;  # (&H40)
use constant crEnableCloseAtPageBreakConditionFormulaType => 62;  # (&H3E)
use constant crEnableKeepTogetherConditionFormulaType => 61;  # (&H3D)
use constant crEnableSuppressConditinFormulaType => 60;  # (&H3C)
use constant crHorizontalAlignmentConditionFormulaType => 63;  # (&H3F)
use constant crHyperLinkConditionFormulaType => 68;  # (&H44)
use constant crRotationConditionFormulaType => 67;  # (&H43)
use constant crToolTipTextConditionFormulaType => 65;  # (&H41)

=head2 :CRObjectKind
 
crBlobFieldObject crBoxObject crCrossTabObject crFieldObject crGraphObject crLineObject crMapObject crOlapGridObject crOleObject crSubreportObject crTextObject

=cut

$EXPORT_TAGS{"CRObjectKind"}=[qw{crBlobFieldObject crBoxObject crCrossTabObject crFieldObject crGraphObject crLineObject crMapObject crOlapGridObject crOleObject crSubreportObject crTextObject}];
 
use constant crBlobFieldObject => 9;
use constant crBoxObject => 4;
use constant crCrossTabObject => 8;
use constant crFieldObject => 1;
use constant crGraphObject => 7;
use constant crLineObject => 3;
use constant crMapObject => 10;
use constant crOlapGridObject => 11;
use constant crOleObject => 6;
use constant crSubreportObject => 5;
use constant crTextObject => 2;

=head2 :CROpenReportMethod
 
crOpenReportByDefault crOpenReportByTempCopy

=cut

$EXPORT_TAGS{"CROpenReportMethod"}=[qw{crOpenReportByDefault crOpenReportByTempCopy}];
 
use constant crOpenReportByDefault => 0;
use constant crOpenReportByTempCopy => 1;

=head2 :CRPaperOrientation
 
crDefaultPaperOrientation crLandscape crPortrait

=cut

$EXPORT_TAGS{"CRPaperOrientation"}=[qw{crDefaultPaperOrientation crLandscape crPortrait}];
 
use constant crDefaultPaperOrientation => 0;
use constant crLandscape => 2;
use constant crPortrait => 1;

=head2 :CRPaperSize
 
crDefaultPaperSize crPaper10x14 crPaper11x17 crPaperA3 crPaperA4 crPaperA4Small crPaperA5 crPaperB4 crPaperB5 crPaperCsheet crPaperDsheet crPaperEnvelope10 crPaperEnvelope11 crPaperEnvelope12 crPaperEnvelope14 crPaperEnvelope9 crPaperEnvelopeB4 crPaperEnvelopeB5 crPaperEnvelopeB6 crPaperEnvelopeC3 crPaperEnvelopeC4 crPaperEnvelopeC5 crPaperEnvelopeC6 crPaperEnvelopeC65 crPaperEnvelopeDL crPaperEnvelopeItaly crPaperEnvelopeMonarch crPaperEnvelopePersonal crPaperEsheet crPaperExecutive crPaperFanfoldLegalGerman crPaperFanfoldStdGerman crPaperFanfoldUS crPaperFolio crPaperLedger crPaperLegal crPaperLetter crPaperLetterSmall crPaperNote crPaperQuarto crPaperStatement crPaperTabloid crPaperUser

=cut

$EXPORT_TAGS{"CRPaperSize"}=[qw{crDefaultPaperSize crPaper10x14 crPaper11x17 crPaperA3 crPaperA4 crPaperA4Small crPaperA5 crPaperB4 crPaperB5 crPaperCsheet crPaperDsheet crPaperEnvelope10 crPaperEnvelope11 crPaperEnvelope12 crPaperEnvelope14 crPaperEnvelope9 crPaperEnvelopeB4 crPaperEnvelopeB5 crPaperEnvelopeB6 crPaperEnvelopeC3 crPaperEnvelopeC4 crPaperEnvelopeC5 crPaperEnvelopeC6 crPaperEnvelopeC65 crPaperEnvelopeDL crPaperEnvelopeItaly crPaperEnvelopeMonarch crPaperEnvelopePersonal crPaperEsheet crPaperExecutive crPaperFanfoldLegalGerman crPaperFanfoldStdGerman crPaperFanfoldUS crPaperFolio crPaperLedger crPaperLegal crPaperLetter crPaperLetterSmall crPaperNote crPaperQuarto crPaperStatement crPaperTabloid crPaperUser}];
 
use constant crDefaultPaperSize => 0;
use constant crPaper10x14 => 16;  # (&H10)
use constant crPaper11x17 => 17;  # (&H11)
use constant crPaperA3 => 8;
use constant crPaperA4 => 9;
use constant crPaperA4Small => 10;
use constant crPaperA5 => 11;
use constant crPaperB4 => 12;
use constant crPaperB5 => 13;
use constant crPaperCsheet => 24;  # (&H18)
use constant crPaperDsheet => 25;  # (&H19)
use constant crPaperEnvelope10 => 20;  # (&H14)
use constant crPaperEnvelope11 => 21;  # (&H15)
use constant crPaperEnvelope12 => 22;  # (&H16)
use constant crPaperEnvelope14 => 23;  # (&H17)
use constant crPaperEnvelope9 => 19;  # (&H13)
use constant crPaperEnvelopeB4 => 33;  # (&H21)
use constant crPaperEnvelopeB5 => 34;  # (&H22)
use constant crPaperEnvelopeB6 => 35;  # (&H23)
use constant crPaperEnvelopeC3 => 29;  # (&H1D)
use constant crPaperEnvelopeC4 => 30;  # (&H1E)
use constant crPaperEnvelopeC5 => 28;  # (&H1C)
use constant crPaperEnvelopeC6 => 31;  # (&H1F)
use constant crPaperEnvelopeC65 => 32;  # (&H20)
use constant crPaperEnvelopeDL => 27;  # (&H1B)
use constant crPaperEnvelopeItaly => 36;  # (&H24)
use constant crPaperEnvelopeMonarch => 37;  # (&H25)
use constant crPaperEnvelopePersonal => 38;  # (&H26)
use constant crPaperEsheet => 26;  # (&H1A)
use constant crPaperExecutive => 7;
use constant crPaperFanfoldLegalGerman => 41;  # (&H29)
use constant crPaperFanfoldStdGerman => 40;  # (&H28)
use constant crPaperFanfoldUS => 39;  # (&H27)
use constant crPaperFolio => 14;
use constant crPaperLedger => 4;
use constant crPaperLegal => 5;
use constant crPaperLetter => 1;
use constant crPaperLetterSmall => 2;
use constant crPaperNote => 18;  # (&H12)
use constant crPaperQuarto => 15;
use constant crPaperStatement => 6;
use constant crPaperTabloid => 3;
use constant crPaperUser => 256;  # (&H100)

=head2 :CRPaperSource
 
crPRBinAuto crPRBinCassette crPRBinEnvelope crPRBinEnvManual crPRBinFormSource crPRBinLargeCapacity crPRBinLargeFmt crPRBinLower crPRBinManual crPRBinMiddle crPRBinSmallFmt crPRBinTractor crPRBinUpper

=cut

$EXPORT_TAGS{"CRPaperSource"}=[qw{crPRBinAuto crPRBinCassette crPRBinEnvelope crPRBinEnvManual crPRBinFormSource crPRBinLargeCapacity crPRBinLargeFmt crPRBinLower crPRBinManual crPRBinMiddle crPRBinSmallFmt crPRBinTractor crPRBinUpper}];
 
use constant crPRBinAuto => 7;
use constant crPRBinCassette => 14;
use constant crPRBinEnvelope => 5;
use constant crPRBinEnvManual => 6;
use constant crPRBinFormSource => 15;
use constant crPRBinLargeCapacity => 11;
use constant crPRBinLargeFmt => 10;
use constant crPRBinLower => 2;
use constant crPRBinManual => 4;
use constant crPRBinMiddle => 3;
use constant crPRBinSmallFmt => 9;
use constant crPRBinTractor => 8;
use constant crPRBinUpper => 1;

=head2 :CRParameterFieldType
 
crQueryParameter crReportParameter crStoreProcedureParameter

=cut

$EXPORT_TAGS{"CRParameterFieldType"}=[qw{crQueryParameter crReportParameter crStoreProcedureParameter}];
 
use constant crQueryParameter => 1;
use constant crReportParameter => 0;
use constant crStoreProcedureParameter => 2;

=head2 :CRParameterPickListSortMethod
 
crNoSort crAlphanumericAscending crAlphanumericDescending crNumericAscending crNumericDescending

=cut

$EXPORT_TAGS{"CRParameterPickListSortMethod"}=[qw{crNoSort crAlphanumericAscending crAlphanumericDescending crNumericAscending crNumericDescending}];
 
use constant crNoSort => 0;
use constant crAlphanumericAscending => 1;
use constant crAlphanumericDescending => 2;
use constant crNumericAscending => 3;
use constant crNumericDescending => 4;

=head2 :CRPieLegendLayout
 
crAmountLayout crBothLayout crNoneLayout crPercentLayout

=cut

$EXPORT_TAGS{"CRPieLegendLayout"}=[qw{crAmountLayout crBothLayout crNoneLayout crPercentLayout}];
 
use constant crAmountLayout => 1;
use constant crBothLayout => 2;
use constant crNoneLayout => 3;
use constant crPercentLayout => 0;

=head2 :CRPieSize
 
crMaximumPieSize crLargePieSize crAveragePieSize crSmallPieSize crMinimumPieSize

=cut

$EXPORT_TAGS{"CRPieSize"}=[qw{crMaximumPieSize crLargePieSize crAveragePieSize crSmallPieSize crMinimumPieSize}];
 
use constant crMaximumPieSize => 0;
use constant crLargePieSize => 16;  # (&H10)
use constant crAveragePieSize => 32;  # (&H20)
use constant crSmallPieSize => 48;  # (&H40)
use constant crMinimumPieSize => 64;  # (&H30)

=head2 :CRPlaceHolderType
 
crAllowPlaceHolders crDelayTotalPageCountCalc

=cut

$EXPORT_TAGS{"CRPlaceHolderType"}=[qw{crAllowPlaceHolders crDelayTotalPageCountCalc}];
 
use constant crAllowPlaceHolders => 2;
use constant crDelayTotalPageCountCalc => 1;

=head2 :CRPrinterDuplexType
 
crPRDPDefault crPRDPHorizontal crPRDPSimplex crPRDPVertical

=cut

$EXPORT_TAGS{"CRPrinterDuplexType"}=[qw{crPRDPDefault crPRDPHorizontal crPRDPSimplex crPRDPVertical}];
 
use constant crPRDPDefault => 0;
use constant crPRDPHorizontal => 3;
use constant crPRDPSimplex => 1;
use constant crPRDPVertical => 2;

=head2 :CRPrintingProgress
 
crPrintingCancelled crPrintingCompleted crPrintingFailed crPrintingHalted crPrintingInProgress crPrintingNotStarted

=cut

$EXPORT_TAGS{"CRPrintingProgress"}=[qw{crPrintingCancelled crPrintingCompleted crPrintingFailed crPrintingHalted crPrintingInProgress crPrintingNotStarted}];
 
use constant crPrintingCancelled => 5;
use constant crPrintingCompleted => 3;
use constant crPrintingFailed => 4;
use constant crPrintingHalted => 6;
use constant crPrintingInProgress => 2;
use constant crPrintingNotStarted => 1;

=head2 :CRRangeInfo
 
crRangeNotIncludeUpperLowerBound crRangeIncludeUpperBound crRangeIncludeLowerBound crRangeNoUpperBound crRangeNoLowerBound

=cut

$EXPORT_TAGS{"CRRangeInfo"}=[qw{crRangeNotIncludeUpperLowerBound crRangeIncludeUpperBound crRangeIncludeLowerBound crRangeNoUpperBound crRangeNoLowerBound}];
 
use constant crRangeNotIncludeUpperLowerBound => 0;
use constant crRangeIncludeUpperBound => 1;
use constant crRangeIncludeLowerBound => 2;
use constant crRangeNoUpperBound => 4;
use constant crRangeNoLowerBound => 8;

=head2 :CRRenderResultType
 
crBSTRType crUISafeArrayType

=cut

$EXPORT_TAGS{"CRRenderResultType"}=[qw{crBSTRType crUISafeArrayType}];
 
use constant crBSTRType => 8;  # This constant is currently not supported.
use constant crUISafeArrayType => 8209;

=head2 :CRReportFileFormat
 
cr70FileFormat cr80FileFormat

=cut

$EXPORT_TAGS{"CRReportFileFormat"}=[qw{cr70FileFormat cr80FileFormat}];
 
use constant cr70FileFormat => 1792;
use constant cr80FileFormat => 2048;

=head2 :CRReportFormatStyle
 
crRFStandardStyle crRFLeadingBreakStyle crRFTrailingBreakStyle crRFTableStyle crRFDropTableStyle crRFExecutiveLeadingBreakStyle crRFExecutiveTrailingBreakStyle crRFShadingStyle crRFRedBlueBorderStyle crRFMartoonTealBoxStyle

=cut

$EXPORT_TAGS{"CRReportFormatStyle"}=[qw{crRFStandardStyle crRFLeadingBreakStyle crRFTrailingBreakStyle crRFTableStyle crRFDropTableStyle crRFExecutiveLeadingBreakStyle crRFExecutiveTrailingBreakStyle crRFShadingStyle crRFRedBlueBorderStyle crRFMartoonTealBoxStyle}];
 
use constant crRFStandardStyle => 0;
use constant crRFLeadingBreakStyle => 1;
use constant crRFTrailingBreakStyle => 2;
use constant crRFTableStyle => 3;
use constant crRFDropTableStyle => 4;
use constant crRFExecutiveLeadingBreakStyle => 5;
use constant crRFExecutiveTrailingBreakStyle => 6;
use constant crRFShadingStyle => 7;
use constant crRFRedBlueBorderStyle => 8;
use constant crRFMartoonTealBoxStyle => 9;

=head2 :CRReportKind
 
crColumnarReport crLabelReport crMulColumnReport

=cut

$EXPORT_TAGS{"CRReportKind"}=[qw{crColumnarReport crLabelReport crMulColumnReport}];
 
use constant crColumnarReport => 1;
use constant crLabelReport => 2;
use constant crMulColumnReport => 3;

=head2 :CRReportVariableValueType
 
crRVBoolean crRVCurrency crRVDate crRVDateTime crRVNumber crRVString crRVTime

=cut

$EXPORT_TAGS{"CRReportVariableValueType"}=[qw{crRVBoolean crRVCurrency crRVDate crRVDateTime crRVNumber crRVString crRVTime}];
 
use constant crRVBoolean => 2;
use constant crRVCurrency => 1;
use constant crRVDate => 3;
use constant crRVDateTime => 5;
use constant crRVNumber => 0;
use constant crRVString => 6;
use constant crRVTime => 4;

=head2 :CRRotationAngle
 
crRotate0 crRotate90 crRotate270

=cut

$EXPORT_TAGS{"CRRotationAngle"}=[qw{crRotate0 crRotate90 crRotate270}];
 
use constant crRotate0 => 0;
use constant crRotate90 => 1;
use constant crRotate270 => 2;

=head2 :CRRoundingType
 
crRoundToMillion crRoundToHundredThousand crRoundToTenThousand crRoundToThousand crRoundToHundred crRoundToTen crRoundToUnit crRoundToTenth crRoundToHundredth crRoundToThousandth crRoundToTenThousandth crRoundToHundredThousandth crRoundToMillionth crRoundToTenMillionth crRoundToHundredMillionth crRoundToBillionth crRoundToTenBillionth

=cut

$EXPORT_TAGS{"CRRoundingType"}=[qw{crRoundToMillion crRoundToHundredThousand crRoundToTenThousand crRoundToThousand crRoundToHundred crRoundToTen crRoundToUnit crRoundToTenth crRoundToHundredth crRoundToThousandth crRoundToTenThousandth crRoundToHundredThousandth crRoundToMillionth crRoundToTenMillionth crRoundToHundredMillionth crRoundToBillionth crRoundToTenBillionth}];
 
use constant crRoundToMillion => 17;
use constant crRoundToHundredThousand => 16;
use constant crRoundToTenThousand => 15;
use constant crRoundToThousand => 14;
use constant crRoundToHundred => 13;
use constant crRoundToTen => 12;
use constant crRoundToUnit => 11;
use constant crRoundToTenth => 10;
use constant crRoundToHundredth => 9;
use constant crRoundToThousandth => 8;
use constant crRoundToTenThousandth => 7;
use constant crRoundToHundredThousandth => 6;
use constant crRoundToMillionth => 5;
use constant crRoundToTenMillionth => 4;
use constant crRoundToHundredMillionth => 3;
use constant crRoundToBillionth => 2;
use constant crRoundToTenBillionth => 1;

=head2 :CRRunningTotalCondition
 
crRTEvalNoCondition crRTEvalOnChangeOfField crRTEvalOnChangeOfGroup crRTEvalOnFormula

=cut

$EXPORT_TAGS{"CRRunningTotalCondition"}=[qw{crRTEvalNoCondition crRTEvalOnChangeOfField crRTEvalOnChangeOfGroup crRTEvalOnFormula}];
 
use constant crRTEvalNoCondition => 0;
use constant crRTEvalOnChangeOfField => 1;
use constant crRTEvalOnChangeOfGroup => 2;
use constant crRTEvalOnFormula => 3;

=head2 :CRSearchDirection
 
crForward crBackward

=cut

$EXPORT_TAGS{"CRSearchDirection"}=[qw{crForward crBackward}];
 
use constant crForward => 0;
use constant crBackward => 1;

=head2 :CRSecondType
 
crNumericNoSecond crNumericSecond crNumericSecondNoLeadingZero

=cut

$EXPORT_TAGS{"CRSecondType"}=[qw{crNumericNoSecond crNumericSecond crNumericSecondNoLeadingZero}];
 
use constant crNumericNoSecond => 2;
use constant crNumericSecond => 0;
use constant crNumericSecondNoLeadingZero => 1;

=head2 :CRSectionAreaFormatConditionFormulaType
 
crSectionAreaBackgroundColorConditionFormulaType crSectionAreaCssClassConditionFormulaType crSectionAreaEnableHideForDrillDownConditionFormulaType crSectionAreaEnableKeepTogetherConditionFormulaType crSectionAreaEnableNewPageAfterConditionFormulaType crSectionAreaEnableNewPageBeforeConditionFormulaType crSectionAreaEnablePrintAtBottomOfPageConditionFormulaType crSectionAreaEnableResetPageNumberAfterConditionFormulaType crSectionAreaEnableSuppressConditionFormulaType crSectionAreaEnableSuppressIfBlankConditionFormulaType crSectionAreaEnableUnderlaySectionConditionFormulaType crSectionAreaShowAreaConditionFormulaType

=cut

$EXPORT_TAGS{"CRSectionAreaFormatConditionFormulaType"}=[qw{crSectionAreaBackgroundColorConditionFormulaType crSectionAreaCssClassConditionFormulaType crSectionAreaEnableHideForDrillDownConditionFormulaType crSectionAreaEnableKeepTogetherConditionFormulaType crSectionAreaEnableNewPageAfterConditionFormulaType crSectionAreaEnableNewPageBeforeConditionFormulaType crSectionAreaEnablePrintAtBottomOfPageConditionFormulaType crSectionAreaEnableResetPageNumberAfterConditionFormulaType crSectionAreaEnableSuppressConditionFormulaType crSectionAreaEnableSuppressIfBlankConditionFormulaType crSectionAreaEnableUnderlaySectionConditionFormulaType crSectionAreaShowAreaConditionFormulaType}];
 
use constant crSectionAreaBackgroundColorConditionFormulaType => 9;
use constant crSectionAreaCssClassConditionFormulaType => 8;
use constant crSectionAreaEnableHideForDrillDownConditionFormulaType => 11;
use constant crSectionAreaEnableKeepTogetherConditionFormulaType => 4;
use constant crSectionAreaEnableNewPageAfterConditionFormulaType => 2;
use constant crSectionAreaEnableNewPageBeforeConditionFormulaType => 3;
use constant crSectionAreaEnablePrintAtBottomOfPageConditionFormulaType => 1;
use constant crSectionAreaEnableResetPageNumberAfterConditionFormulaType => 6;
use constant crSectionAreaEnableSuppressConditionFormulaType => 0;
use constant crSectionAreaEnableSuppressIfBlankConditionFormulaType => 5;
use constant crSectionAreaEnableUnderlaySectionConditionFormulaType => 7;
use constant crSectionAreaShowAreaConditionFormulaType => 10;

=head2 :CRSliceDetachment
 
crLargestSlice crSmallestSlice crNoDetachment

=cut

$EXPORT_TAGS{"CRSliceDetachment"}=[qw{crLargestSlice crSmallestSlice crNoDetachment}];
 
use constant crLargestSlice => 2;
use constant crSmallestSlice => 1;
use constant crNoDetachment => 0;

=head2 :CRSortDirection
 
crAscendingOrder crDescendingOrder crOriginalOrder crSpecifiedOrder

=cut

$EXPORT_TAGS{"CRSortDirection"}=[qw{crAscendingOrder crDescendingOrder crOriginalOrder crSpecifiedOrder}];
 
use constant crAscendingOrder => 0;
use constant crDescendingOrder => 1;
use constant crOriginalOrder => 2;  # Not supported for any kind of groups.
use constant crSpecifiedOrder => 3;  # Not supported for any kind of groups.

=head2 :CRSpecialVarType
 
crSVTDataDate crSVTDataTime crSVTFileAuthor crSVTFileCreationDate crSVTFilename crSVTGroupNumber crSVTGroupSelection crSVTModificationDate crSVTModificationTime crSVTPageNofM crSVTPageNumber crSVTPrintDate crSVTPrintTime crSVTRecordNumber crSVTRecordSelection crSVTReportComments crSVTReportTitle crSVTTotalPageCount

=cut

$EXPORT_TAGS{"CRSpecialVarType"}=[qw{crSVTDataDate crSVTDataTime crSVTFileAuthor crSVTFileCreationDate crSVTFilename crSVTGroupNumber crSVTGroupSelection crSVTModificationDate crSVTModificationTime crSVTPageNofM crSVTPageNumber crSVTPrintDate crSVTPrintTime crSVTRecordNumber crSVTRecordSelection crSVTReportComments crSVTReportTitle crSVTTotalPageCount}];
 
use constant crSVTDataDate => 4;
use constant crSVTDataTime => 5;
use constant crSVTFileAuthor => 15;
use constant crSVTFileCreationDate => 16;  # (&H10)
use constant crSVTFilename => 14;
use constant crSVTGroupNumber => 8;
use constant crSVTGroupSelection => 13;
use constant crSVTModificationDate => 2;
use constant crSVTModificationTime => 3;
use constant crSVTPageNofM => 17;  # (&H11)
use constant crSVTPageNumber => 7;
use constant crSVTPrintDate => 0;
use constant crSVTPrintTime => 1;
use constant crSVTRecordNumber => 6;
use constant crSVTRecordSelection => 12;
use constant crSVTReportComments => 11;
use constant crSVTReportTitle => 10;
use constant crSVTTotalPageCount => 9;

=head2 :CRStringFieldConditionFormulaType
 
crTextInterpretationConditionFormulaType

=cut

$EXPORT_TAGS{"CRStringFieldConditionFormulaType"}=[qw{crTextInterpretationConditionFormulaType}];
 
use constant crTextInterpretationConditionFormulaType => 200;  # (&HC8)

=head2 :CRSubreportConditionFormulaType
 
crCaptionConditionFormulaType crDrillDownTabTextConditionFormulaType

=cut

$EXPORT_TAGS{"CRSubreportConditionFormulaType"}=[qw{crCaptionConditionFormulaType crDrillDownTabTextConditionFormulaType}];
 
use constant crCaptionConditionFormulaType => 220;  # (&HDC)
use constant crDrillDownTabTextConditionFormulaType => 221;  # (&HDD)

=head2 :CRSummaryType
 
crSTAverage crSTCount crSTDCorrelation crSTDCovariance crSTDistinctCount crSTDMedian crSTDMode crSTDNthLargest crSTDNthMostFrequent crSTDNthSmallest crSTDPercentage crSTDPercentile crSTDWeightedAvg crSTMaximum crSTMinimum crSTPopStandardDeviation crSTPopVariance crSTSampleStandardDeviation crSTSampleVariance crSTSum

=cut

$EXPORT_TAGS{"CRSummaryType"}=[qw{crSTAverage crSTCount crSTDCorrelation crSTDCovariance crSTDistinctCount crSTDMedian crSTDMode crSTDNthLargest crSTDNthMostFrequent crSTDNthSmallest crSTDPercentage crSTDPercentile crSTDWeightedAvg crSTMaximum crSTMinimum crSTPopStandardDeviation crSTPopVariance crSTSampleStandardDeviation crSTSampleVariance crSTSum}];
 
use constant crSTAverage => 1;
use constant crSTCount => 6;
use constant crSTDCorrelation => 10;
use constant crSTDCovariance => 11;
use constant crSTDistinctCount => 9;
use constant crSTDMedian => 13;
use constant crSTDMode => 17;  # (&H11)
use constant crSTDNthLargest => 15;
use constant crSTDNthMostFrequent => 18;  # (&H12)
use constant crSTDNthSmallest => 16;  # (&H10)
use constant crSTDPercentage => 19;  # (&H13)
use constant crSTDPercentile => 14;
use constant crSTDWeightedAvg => 12;
use constant crSTMaximum => 4;
use constant crSTMinimum => 5;
use constant crSTPopStandardDeviation => 8;
use constant crSTPopVariance => 7;
use constant crSTSampleStandardDeviation => 3;
use constant crSTSampleVariance => 2;
use constant crSTSum => 0;

=head2 :CRTableDifferences
 
crTDOK crTDDatabaseNotFound crTDServerNotFound crTDServerNotOpened crTDAliasChanged crTDIndexesChanged crTDDriverChanged crTDDictionaryChanged crTDFileTypeChanged crTDRecordSizeChanged crTDAccessChanged crTDParametersChanged crTDLocationChanged crTDDatabaseOtherChanges crTDNumberFieldChanged crTDFieldOtherChanges crTDFieldNameChanged crTDFieldDescChanged crTDFieldTypeChanged crTDFieldSizeChanged crTDNativeFieldTypeChanged crTDNativeFieldOffsetChanged crTDNativeFieldSizeChanged crTDFieldDecimalPlacesChanged

=cut

$EXPORT_TAGS{"CRTableDifferences"}=[qw{crTDOK crTDDatabaseNotFound crTDServerNotFound crTDServerNotOpened crTDAliasChanged crTDIndexesChanged crTDDriverChanged crTDDictionaryChanged crTDFileTypeChanged crTDRecordSizeChanged crTDAccessChanged crTDParametersChanged crTDLocationChanged crTDDatabaseOtherChanges crTDNumberFieldChanged crTDFieldOtherChanges crTDFieldNameChanged crTDFieldDescChanged crTDFieldTypeChanged crTDFieldSizeChanged crTDNativeFieldTypeChanged crTDNativeFieldOffsetChanged crTDNativeFieldSizeChanged crTDFieldDecimalPlacesChanged}];
 
use constant crTDOK => 0x00000000;
use constant crTDDatabaseNotFound => 0x00000001;
use constant crTDServerNotFound => 0x00000002;
use constant crTDServerNotOpened => 0x00000004;
use constant crTDAliasChanged => 0x00000008;
use constant crTDIndexesChanged => 0x00000010;
use constant crTDDriverChanged => 0x00000020;
use constant crTDDictionaryChanged => 0x00000040;
use constant crTDFileTypeChanged => 0x00000080;
use constant crTDRecordSizeChanged => 0x00000100;
use constant crTDAccessChanged => 0x00000200;
use constant crTDParametersChanged => 0x00000400;
use constant crTDLocationChanged => 0x00000800;
use constant crTDDatabaseOtherChanges => 0x00001000;
use constant crTDNumberFieldChanged => 0x00010000;
use constant crTDFieldOtherChanges => 0x00020000;
use constant crTDFieldNameChanged => 0x00040000;
use constant crTDFieldDescChanged => 0x00080000;
use constant crTDFieldTypeChanged => 0x00100000;
use constant crTDFieldSizeChanged => 0x00200000;
use constant crTDNativeFieldTypeChanged => 0x00400000;
use constant crTDNativeFieldOffsetChanged => 0x00800000;
use constant crTDNativeFieldSizeChanged => 0x01000000;
use constant crTDFieldDecimalPlacesChanged => 0x02000000;

=head2 :CRTextFormat
 
crHTMLText crRTFText crStandardText

=cut

$EXPORT_TAGS{"CRTextFormat"}=[qw{crHTMLText crRTFText crStandardText}];
 
use constant crHTMLText => 2;
use constant crRTFText => 1;
use constant crStandardText => 0;

=head2 :CRTimeBase
 
cr12Hour cr24Hour

=cut

$EXPORT_TAGS{"CRTimeBase"}=[qw{cr12Hour cr24Hour}];
 
use constant cr12Hour => 0;
use constant cr24Hour => 1;

=head2 :CRTimeFieldFormatConditionFormulaType
 
crAMPMFormatConditionFormulaType crAMStringConditionFormulaType crHourFormatConditionFormulaType crHourMinuteSeparatorConditionFormulaType crMinuteFormatConditionFormulaType crMinuteSecondSeparatorConditionFormulaType crPMStringConditionFormulaType crSecondFormatConditionFormulaType crTimeBaseConditionFormulaType

=cut

$EXPORT_TAGS{"CRTimeFieldFormatConditionFormulaType"}=[qw{crAMPMFormatConditionFormulaType crAMStringConditionFormulaType crHourFormatConditionFormulaType crHourMinuteSeparatorConditionFormulaType crMinuteFormatConditionFormulaType crMinuteSecondSeparatorConditionFormulaType crPMStringConditionFormulaType crSecondFormatConditionFormulaType crTimeBaseConditionFormulaType}];
 
use constant crAMPMFormatConditionFormulaType => 161;  # (&HA1)
use constant crAMStringConditionFormulaType => 166;  # (&HA6)
use constant crHourFormatConditionFormulaType => 162;  # (&HA2)
use constant crHourMinuteSeparatorConditionFormulaType => 168;  # (&HA8)
use constant crMinuteFormatConditionFormulaType => 163;  # (&HA3)
use constant crMinuteSecondSeparatorConditionFormulaType => 167;  # (&HA7)
use constant crPMStringConditionFormulaType => 165;  # (&HA5)
use constant crSecondFormatConditionFormulaType => 164;  # (&HA4)
use constant crTimeBaseConditionFormulaType => 160;  # (&HA0)

=head2 :CRTopOrBottomNGroupSortOrder
 
crAllGroupsSorted crAllGroupsUnsorted crBottomNGroups crTopNGroups crUnknownGroupsSortOrder

=cut

$EXPORT_TAGS{"CRTopOrBottomNGroupSortOrder"}=[qw{crAllGroupsSorted crAllGroupsUnsorted crBottomNGroups crTopNGroups crUnknownGroupsSortOrder}];
 
use constant crAllGroupsSorted => 1;
use constant crAllGroupsUnsorted => 0;
use constant crBottomNGroups => 3;
use constant crTopNGroups => 2;
use constant crUnknownGroupsSortOrder => 10;

=head2 :CRValueFormatType
 
crAllowComplexFieldFormatting crIncludeFieldValues crIncludeHiddenFields

=cut

$EXPORT_TAGS{"CRValueFormatType"}=[qw{crAllowComplexFieldFormatting crIncludeFieldValues crIncludeHiddenFields}];
 
use constant crAllowComplexFieldFormatting => 4;
use constant crIncludeFieldValues => 1;
use constant crIncludeHiddenFields => 2;

=head2 :CRViewingAngle
 
crBirdsEyeView crDistortedStdView crDistortedView crFewGroupsView crFewSeriesView crGroupEmphasisView crGroupEyeView crMaxView crShorterView crShortView crStandardView crTallView crThickGroupsView crThickSeriesView crThickStdView crTopView

=cut

$EXPORT_TAGS{"CRViewingAngle"}=[qw{crBirdsEyeView crDistortedStdView crDistortedView crFewGroupsView crFewSeriesView crGroupEmphasisView crGroupEyeView crMaxView crShorterView crShortView crStandardView crTallView crThickGroupsView crThickSeriesView crThickStdView crTopView}];
 
use constant crBirdsEyeView => 15;
use constant crDistortedStdView => 10;
use constant crDistortedView => 4;
use constant crFewGroupsView => 9;
use constant crFewSeriesView => 8;
use constant crGroupEmphasisView => 7;
use constant crGroupEyeView => 6;
use constant crMaxView => 16;  # (&H10)
use constant crShorterView => 12;
use constant crShortView => 5;
use constant crStandardView => 1;
use constant crTallView => 2;
use constant crThickGroupsView => 11;
use constant crThickSeriesView => 13;
use constant crThickStdView => 14;
use constant crTopView => 3;

=head2 :CRYearType
 
crLongYear crNoYear crShortYear

=cut

$EXPORT_TAGS{"CRYearType"}=[qw{crLongYear crNoYear crShortYear}];
 
use constant crLongYear => 1;
use constant crNoYear => 2;
use constant crShortYear => 0;

push @EXPORT_OK, @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;

$EXPORT_TAGS{"all"}=[@EXPORT_OK];

=head1 BUGS

=head1 SUPPORT

Please try Business Objects.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>stopllc,tld=>com,account=>mdavis
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

Crystal Reports XI Technical Reference Guide - http://support.businessobjects.com/documentation/product_guides/boexi/en/crxi_Techref_en.pdf

L<Win32::OLE>, L<Win32::OLE::CrystalRuntime::Application>, L<Win32::OLE::CrystalRuntime::Application::Report>

=cut

1;
