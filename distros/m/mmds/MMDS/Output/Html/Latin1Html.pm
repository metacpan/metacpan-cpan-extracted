package MMDS::Output::Html::Latin1Html;

# RCS Id: $Id: Latin1Html.pm,v 1.1 2002-12-30 19:22:35+01 jv Exp $

# Map iso-8859-1 to HTML encoding. Strictly speaking this is not
# necessary, since HTML uses iso-8859-1 as default character set.

%::iso2html = (
    "Æ",  "AElig",	# capital AE diphthong (ligature) */
    "Á",  "Aacute",	# capital A, acute accent */
    "Â",  "Acirc",	# capital A, circumflex accent */
    "À",  "Agrave",	# capital A, grave accent */
    "Å",  "Aring",	# capital A, ring */
    "Ã",  "Atilde",	# capital A, tilde */
    "Ä",  "Auml",	# capital A, dieresis or umlaut mark */
    "Ç",  "Ccedil",	# capital C, cedilla */
    "Ð",  "ETH",	# capital Eth, Icelandic */
    "É",  "Eacute",	# capital E, acute accent */
    "Ê",  "Ecirc",	# capital E, circumflex accent */
    "È",  "Egrave",	# capital E, grave accent */
    "Ë",  "Euml",	# capital E, dieresis or umlaut mark */
    "Í",  "Iacute",	# capital I, acute accent */
    "Î",  "Icirc",	# capital I, circumflex accent */
    "Ì",  "Igrave",	# capital I, grave accent */
    "Ï",  "Iuml",	# capital I, dieresis or umlaut mark */
    "Ñ",  "Ntilde",	# capital N, tilde */
    "Ó",  "Oacute",	# capital O, acute accent */
    "Ô",  "Ocirc",	# capital O, circumflex accent */
    "Ò",  "Ograve",	# capital O, grave accent */
    "Ø",  "Oslash",	# capital O, slash */
    "Õ",  "Otilde",	# capital O, tilde */
    "Ö",  "Ouml",	# capital O, dieresis or umlaut mark */
    "Þ",  "THORN",	# capital THORN, Icelandic */
    "Ú",  "Uacute",	# capital U, acute accent */
    "Û",  "Ucirc",	# capital U, circumflex accent */
    "Ù",  "Ugrave",	# capital U, grave accent */
    "Ü",  "Uuml",	# capital U, dieresis or umlaut mark */
    "Ý",  "Yacute",	# capital Y, acute accent */
    "á",  "aacute",	# small a, acute accent */
    "â",  "acirc",	# small a, circumflex accent */
    "æ",  "aelig",	# small ae diphthong (ligature) */
    "à",  "agrave",	# small a, grave accent */
    "&",  "amp",	# ampersand */
    "å",  "aring",	# small a, ring */
    "ã",  "atilde",	# small a, tilde */
    "ä",  "auml",	# small a, dieresis or umlaut mark */
    "ç",  "ccedil",	# small c, cedilla */
    "é",  "eacute",	# small e, acute accent */
    "ê",  "ecirc",	# small e, circumflex accent */
    "è",  "egrave",	# small e, grave accent */
#    "",  "emsp",	# em space - not collapsed
#    "",  "ensp",	# en space - not collapsed
    "ð",  "eth",	# small eth, Icelandic */
    "ë",  "euml",	# small e, dieresis or umlaut mark */
    ">",  "gt",		# greater than */
    "í",  "iacute",	# small i, acute accent */
    "î",  "icirc",	# small i, circumflex accent */
    "ì",  "igrave",	# small i, grave accent */
    "ï",  "iuml",	# small i, dieresis or umlaut mark */
    "<",  "lt",		# less than */
    " ",  "nbsp",       # non breaking space
    "ñ",  "ntilde",	# small n, tilde */
    "ó",  "oacute",	# small o, acute accent */
    "ô",  "ocirc",	# small o, circumflex accent */
    "ò",  "ograve",	# small o, grave accent */
    "ø",  "oslash",	# small o, slash */
    "õ",  "otilde",	# small o, tilde */
    "ö",  "ouml",	# small o, dieresis or umlaut mark */
#    "",  "quot",	# quot '"'
    "ß",  "szlig",	# small sharp s, German (sz ligature) */
    "þ",  "thorn",	# small thorn, Icelandic */
    "ú",  "uacute",	# small u, acute accent */
    "û",  "ucirc",	# small u, circumflex accent */
    "ù",  "ugrave",	# small u, grave accent */
    "ü",  "uuml",	# small u, dieresis or umlaut mark */
    "ý",  "yacute",	# small y, acute accent */
    "ÿ",  "yuml",	# small y, dieresis or umlaut mark */
);

1;
