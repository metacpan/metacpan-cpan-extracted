<%args>
$op
$id => undef ### should be extracted using utf8param()
$update => undef
</%args>
<%doc>
Since this form is used in many different situations, some care is
merited in considering the possibilities:

Situation					Op	ID	Update
----------------------------------------------------------------------
Blank form for adding a new target		new
New target rejected, changes required		new		X
New target accepted and added			new		X
---------------------------------------------------------------------
Existing target to be edited			edit	X
Edit rejected, changes required			edit	X	X
Target successfully updated			edit	X	X
----------------------------------------------------------------------
Existing target to be copied			copy	X
New target rejected, changes required		copy	X	X
New target accepted and added			copy	X	X
----------------------------------------------------------------------

Submissions, whether of new targets, edits or copies, may be rejected
due either to missing mandatory fields or host/name/port that form a
duplicate ID.
</%doc>
<%perl>
# Sanity checking
die "op = new but id defined" if $op eq "new" && defined $id;
die "op != new but id undefined" if $op ne "new" && !defined $id;

my $db = ZOOM::IRSpy::connect_to_registry();
my $conn = new ZOOM::Connection($db, 0,
				user => "admin", password => "fruitbat",
				elementSetName => "zeerex");

my $protocol = utf8paramTrim($r, "protocol");
my $host = utf8paramTrim($r, "host");
my $port = utf8paramTrim($r, "port");
my $dbname = utf8paramTrim($r, "dbname");
my $title = utf8paramTrim($r, "title");

if ((!defined $port || $port eq "") &&
    (defined $protocol && $protocol ne "")) {
    # Port-guessing based on defaults for each protocol
    $port = $protocol eq "Z39.50" ? 210 : 80;
    warn "guessed port $port";
    &utf8param($r, port => $port);
}

my $newid;
if (defined $protocol && $protocol ne "" &&
    defined $host && $host ne "" &&
    defined $port && $port ne "" &&
    defined $title && $title ne "" &&
    defined $dbname && $dbname ne "") {
    $newid = irspy_make_identifier($protocol, $host, $port, $dbname);
}

my $rec = '<explain xmlns="http://explain.z3950.org/dtd/2.0/"/>';

if (!defined $id) {
    if (!$update) {
	# About to enter data for a new record
	# Nothing to do at this stage
    } elsif (!defined $newid) {
	# Tried to create new record but data is insufficient
	print qq[<p class="error">
		Please specify title, protocol, host, port and database name.</p>\n];
	undef $update;
    } elsif ($host !~ /^\w+\.[\w.]*\w$/i) {
	print qq[<p class="error">
		This host name is not valid.</p>\n];
	undef $update;
	sleep 25;
    } elsif ($port !~ /^\d*$/i) {
	print qq[<p class="error">
		This port number is not valid.</p>\n];
	undef $update;
	sleep 25;
    } else {
	# Creating new record, all necessary data is present.  Check
	# that the new record is not a duplicate of an existing one.
	my $rs = $conn->search(new ZOOM::Query::CQL(cql_target($newid)));
	if ($rs->size() > 0) {
	    my $qnewid = xml_encode(uri_escape_utf8($newid));
	    print qq[<p class="error">
		There is already
		<a href='?op=edit&amp;id=$newid'>a record</a>
		for this protocol, host, port and database name.
		</p>\n];
	    undef $update;
	}
    }
} else {
    # assert(defined $id);
    # Copying or editing an existing record: fetch it for editing
    my $query = cql_target($id);
    my $rs = $conn->search(new ZOOM::Query::CQL($query));
    if ($rs->size() > 0) {
	$rec = $rs->record(0);
    } else {
	### Is this an error?  I don't think the UI will ever provoke it
	print qq[<p class="error">(New ID specified.)</p>\n];
	$id = undef;
    }
}

my $xc = irspy_xpath_context($rec);
my @fields =
    (
     [ title        => 0, "Name", "e:databaseInfo/e:title",
       qw() ],
     [ country      => $m->comp("country-list.mc"),
       "Country", "i:status/i:country" ],
     [ protocol     => [ qw(Z39.50 SRW SRU) ],
       "Protocol", "e:serverInfo/\@protocol" ],
     [ host         => 0, "Host", "e:serverInfo/e:host" ],
     [ port         => 0, "Port", "e:serverInfo/e:port" ],
     [ dbname       => 0, "Database Name", "e:serverInfo/e:database",
       qw(e:host e:port) ],
     [ type         => $m->comp("libtype-list.mc"),
       "Type of Library", "i:status/i:libraryType" ],
     [ username     => 0, "Username (if needed)", "e:serverInfo/e:authentication/e:user",
       qw() ],
     [ password     => 0, "Password (if needed)", "e:serverInfo/e:authentication/e:password",
       qw(e:user) ],
     [ description  => 5, "Description", "e:databaseInfo/e:description",
       qw(e:title) ],
     [ author       => 0, "Author", "e:databaseInfo/e:author",
       qw(e:title e:description) ],
     [ hosturl       => 0, "URL to Hosting Organisation", "i:status/i:hostURL" ],
     [ contact      => 0, "Contact", "e:databaseInfo/e:contact",
       qw(e:title e:description) ],
     [ extent       => 3, "Extent", "e:databaseInfo/e:extent",
       qw(e:title e:description) ],
     [ history      => 5, "History", "e:databaseInfo/e:history",
       qw(e:title e:description) ],
     [ language     => [
# This list was produced by feeding
#	http://www.loc.gov/standards/iso639-2/ISO-639-2_values_8bits.txt
# through the filter
#	awk -F'|' '$3 {print$4}'
# and shortening some of the longer names by hand
			"",
			"English",
			"Afar",
			"Abkhazian",
			"Afrikaans",
			"Akan",
			"Albanian",
			"Amharic",
			"Arabic",
			"Aragonese",
			"Armenian",
			"Assamese",
			"Avaric",
			"Avestan",
			"Aymara",
			"Azerbaijani",
			"Bashkir",
			"Bambara",
			"Basque",
			"Belarusian",
			"Bengali",
			"Bihari",
			"Bislama",
			"Bosnian",
			"Breton",
			"Bulgarian",
			"Burmese",
			"Catalan; Valencian",
			"Chamorro",
			"Chechen",
			"Chinese",
			"Church Slavic; Old Slavonic",
			"Chuvash",
			"Cornish",
			"Corsican",
			"Cree",
			"Czech",
			"Danish",
			"Divehi; Dhivehi; Maldivian",
			"Dutch; Flemish",
			"Dzongkha",
			"Esperanto",
			"Estonian",
			"Ewe",
			"Faroese",
			"Fijian",
			"Finnish",
			"French",
			"Western Frisian",
			"Fulah",
			"Georgian",
			"German",
			"Gaelic; Scottish Gaelic",
			"Irish",
			"Galician",
			"Manx",
			"Greek, Modern (1453-)",
			"Guarani",
			"Gujarati",
			"Haitian; Haitian Creole",
			"Hausa",
			"Hebrew",
			"Herero",
			"Hindi",
			"Hiri Motu",
			"Hungarian",
			"Igbo",
			"Icelandic",
			"Ido",
			"Sichuan Yi",
			"Inuktitut",
			"Interlingue",
			"Interlingua",
			"Indonesian",
			"Inupiaq",
			"Italian",
			"Javanese",
			"Japanese",
			"Kalaallisut; Greenlandic",
			"Kannada",
			"Kashmiri",
			"Kanuri",
			"Kazakh",
			"Khmer",
			"Kikuyu; Gikuyu",
			"Kinyarwanda",
			"Kirghiz",
			"Komi",
			"Kongo",
			"Korean",
			"Kuanyama; Kwanyama",
			"Kurdish",
			"Lao",
			"Latin",
			"Latvian",
			"Limburgan; Limburger; Limburgish",
			"Lingala",
			"Lithuanian",
			"Luxembourgish; Letzeburgesch",
			"Luba-Katanga",
			"Ganda",
			"Macedonian",
			"Marshallese",
			"Malayalam",
			"Maori",
			"Marathi",
			"Malay",
			"Malagasy",
			"Maltese",
			"Moldavian",
			"Mongolian",
			"Nauru",
			"Navajo; Navaho",
			"Ndebele, South; South Ndebele",
			"Ndebele, North; North Ndebele",
			"Ndonga",
			"Nepali",
			"Norwegian Nynorsk",
			"Norwegian Bokmål",
			"Norwegian",
			"Chichewa; Chewa; Nyanja",
			"Occitan (post 1500); Provençal",
			"Ojibwa",
			"Oriya",
			"Oromo",
			"Ossetian; Ossetic",
			"Panjabi; Punjabi",
			"Persian",
			"Pali",
			"Polish",
			"Portuguese",
			"Pushto",
			"Quechua",
			"Raeto-Romance",
			"Romanian",
			"Rundi",
			"Russian",
			"Sango",
			"Sanskrit",
			"Serbian",
			"Croatian",
			"Sinhala; Sinhalese",
			"Slovak",
			"Slovenian",
			"Northern Sami",
			"Samoan",
			"Shona",
			"Sindhi",
			"Somali",
			"Sotho, Southern",
			"Spanish; Castilian",
			"Sardinian",
			"Swati",
			"Sundanese",
			"Swahili",
			"Swedish",
			"Tahitian",
			"Tamil",
			"Tatar",
			"Telugu",
			"Tajik",
			"Tagalog",
			"Thai",
			"Tibetan",
			"Tigrinya",
			"Tonga (Tonga Islands)",
			"Tswana",
			"Tsonga",
			"Turkmen",
			"Turkish",
			"Twi",
			"Uighur; Uyghur",
			"Ukrainian",
			"Urdu",
			"Uzbek",
			"Venda",
			"Vietnamese",
			"Volapük",
			"Welsh",
			"Walloon",
			"Wolof",
			"Xhosa",
			"Yiddish",
			"Yoruba",
			"Zhuang; Chuang",
			"Zulu",
			],
       "Language of Records", "e:databaseInfo/e:langUsage",
       qw(e:title e:description) ],
     [ restrictions => 2, "Restrictions", "e:databaseInfo/e:restrictions",
       qw(e:title e:description) ],
     [ subjects     => 2, "Subjects", "e:databaseInfo/e:subjects",
       qw(e:title e:description) ],
     [ disabled     => [ qw(0 1) ],
       "Target Test Disabled", "i:status/i:disabled" ],
     );

# Update record with submitted data
my %fieldsByKey = map { ( $_->[0], $_) } @fields;
my %data;
foreach my $key (&utf8param($r)) {
    next if grep { $key eq $_ } qw(op id update);
    $data{$key} = trimField( utf8param($r, $key) );
}
my @changedFields = modify_xml_document($xc, \%fieldsByKey, \%data);
if ($update && @changedFields) {
    my @x = modify_xml_document($xc, { dateModified =>
					   [ dateModified => 0,
					     "Data/time modified",
					     "e:metaInfo/e:dateModified" ] },
				{ dateModified => isodate(time()) });
    die "Didn't set dateModified!" if !@x;
    ZOOM::IRSpy::_rewrite_zeerex_record($conn, $xc->getContextNode(),
					$op eq "edit" ? $id : undef);
}

</%perl>
 <h2><% xml_encode($xc->find("e:databaseInfo/e:title"), "[Untitled]") %></h2>
% if ($update && @changedFields) {
%     my $nchanges = @changedFields;
 <p style="font-weight: bold">
  The record has been <% $op ne "edit" ? "created" : "updated" %>.<br/>
  Changed <% $nchanges %> field<% $nchanges == 1 ? "" : "s" %>:
  <% join(", ", map { xml_encode($_->[2]) } @changedFields) %>.
 </p>
% return if $op eq "new";
% }
 <p>
  Although anyone is allowed to add a new target, please note that
  <b>you will not be able to edit the newly added target unless you
  have administrator privileges</b>.  So please be sure that the
  details are correct before submitting them.
 </p>
 <form method="get" action="">
  <table class="fullrecord" border="1" cellspacing="0" cellpadding="5" width="100%">
<%perl>
foreach my $ref (@fields) {
    my($name, $nlines, $caption, $xpath, @addAfter) = @$ref;
</%perl>
   <tr>
    <th><% $caption %></th>
    <td>
% my $rawval = $xc->findvalue($xpath);
% my $val = xml_encode($rawval, "");
% if (ref $nlines) {
     <select name="<% $name %>" size="1">
%     foreach my $option (@$nlines) {
      <option value="<% xml_encode($option) %>"<%
	($rawval eq $option ? ' selected="selected"' : "")
	%>><% xml_encode($option) %></option>
%     }
     </select>
% } elsif ($nlines) {
     <textarea name="<% $name %>" rows="<% $nlines %>" cols="51"><% $val %></textarea>
% } else {
     <input name="<% $name %>" type="text" size="60" value="<% $val %>"/>
% }
    </td>
    <td>
     <& /help/link.mc, help => "edit/$name" &>
    </td>
   </tr>
%   }
   <tr>
    <td align="right" colspan="2">
     <input type="submit" name="update" value="Update"/>
% $op = "edit" if $op eq "new" && defined $update;
     <input type="hidden" name="op" value="<% xml_encode($op) %>"/>
% $id = $newid if defined $newid;
% if (defined $id) {
     <input type="hidden" name="id" value="<% xml_encode($id) %>"/>
% }
    </td>
   </tr>
  </table>
 </form>
<%perl>
    if (@changedFields && 0) {
	my $x = $xc->getContextNode()->toString();
	$x = xml_encode($x);
	#$x =~ s/$/<br\/>/gm;
	print "<pre>$x</pre>\n";
    }
</%perl>
