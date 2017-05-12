#!/opt/editique/perl/bin/perl
# this line should be modified to point to your perl install

# THIS CGI IS AN INTERFACE FOR THE END USER SO THAT THEY CAN MODIFY INLINE PARTS OF DOCUMENTS
use strict;
use warnings;

use CGI;
use CGI::FormBuilder;
use File::Basename;
use oEdtk::Config qw(config_read);
use oEdtk::DBAdmin qw(db_connect);

my $check_cgi = uc(basename($0));
if (!defined ($cfg->{$check_cgi}) || ($cfg->{$check_cgi}) !~/yes/i ) { die "ERROR: config said 'application not authorized on this server'\n" }


sub para_load($$$) {
	my ($dbh, $app, $corp) = @_;

	my $sql = 'SELECT * FROM EDTK_TEST_PARA ' .
	    'WHERE ED_PARA_REFIDDOC = ? AND ED_PARA_CORP = ?';
	my $row = $dbh->selectrow_hashref($sql, undef, $app, $corp);
	return $row;
}

sub para_insert($$$$) {
	my ($dbh, $app, $corp, $text) = @_;

	my $sql = 'INSERT INTO EDTK_TEST_PARA ' .
	    '(ED_PARA_REFIDDOC, ED_PARA_CORP, ED_TEXTBLOC) VALUES (?, ?, ?)';
	my $rv = $dbh->do($sql, undef, $app, $corp, $text);
	if (!$rv) {
		return $dbh->errstr;
	}
	return undef;
}

sub para_update($$$$) {
	my ($dbh, $app, $corp, $text) = @_;

	my $sql = 'UPDATE EDTK_TEST_PARA SET ED_TEXTBLOC = ? ' .
	    'WHERE ED_PARA_REFIDDOC = ? AND ED_PARA_CORP = ?';
	my $rv = $dbh->do($sql, undef, $text, $app, $corp);
	if (!defined($rv)) {
		return $dbh->errstr;
	}
	if ($rv != 1) {
		return '0 rows matched';
	}
	return undef;
}

sub div($$) {
	my ($class, $txt) = @_;
	return "<div class=\"$class\">$txt</div>";
}

my $form = CGI::FormBuilder->new(
	fields		=> ['app', 'corp', 'para'],
	submit		=> ['Load', 'Insert'],
	method		=> 'post',
	title		=> 'Paragraph Test'
);
$form->field(
	name		=> 'app',
	type		=> 'text',
	label		=> 'Application:',
	size		=> 20,
	required	=> 1,
);
$form->field(
	name		=> 'corp',
	type		=> 'text',
	label		=> 'Entity:',
	required	=> 1,
	size		=> 8,
	value		=> 'MNT'
);
$form->field(
	name		=> 'para',
	type		=> 'textarea',
	label		=> 'Text:',
	cols		=> 80,
	rows		=> 10
);

if ($form->submitted eq 'Load' && $form->validate) {
	# Load the text paragraph from the database.
	my $cfg = config_read('EDTK_DB');
	my $dbh = db_connect($cfg, 'EDTK_DBI_DSN');
	my $data = para_load($dbh, $form->field('app'), $form->field('corp'));
	if (!defined($data)) {
		$form->text(div('err', 'Could not find data.'));
	} else {
		# Change the 'Insert' button to 'Update' when we are updating
		# an entry and not inserting a new one.
		$form->text(div('msg', 'Successfully loaded data.'));
		$form->field(name => 'para', value => $data->{'ED_TEXTBLOC'},
		    force => 1);
		$form->submit(['Load', 'Update']);
	}
} elsif ($form->submitted eq 'Update' && $form->validate) {
	my $cfg = config_read('EDTK_DB');
	my $dbh = db_connect($cfg, 'EDTK_DBI_DSN');
	my $ret = para_update($dbh, $form->field('app'), $form->field('corp'),
	    $form->field('para'));
	if (defined($ret)) {
		$form->text(div('err', "Error updating value: $ret"));
	} else {
		$form->text(div('msg', 'Value successfully updated.'));
	}
} elsif ($form->submitted eq 'Insert' && $form->validate) {
	my $cfg = config_read('EDTK_DB');
	my $dbh = db_connect($cfg, 'EDTK_DBI_DSN');
	my $ret = para_insert($dbh, $form->field('app'), $form->field('corp'),
	    $form->field('para'));
	if (defined($ret)) {
		$form->text(div('err', "Error inserting new value: $ret"));
	} else {
		$form->text(div('msg', 'Value successfully inserted.'));
		$form->submit(['Load', 'Update']);
	}
}

my $css = <<EOF;
div.err {
	padding: 1em 0em 1em 0em;
	border-color: red;
	border-style: solid;
	border-width: 1px;
	background-color: #FF9999;
	font-weight: bold;
	text-align: center;
	color: red;
}
div.msg {
	padding: 1em 0em 1em 0em;
	border-color: green;
	border-style: solid;
	border-width: 1px;
	background-color: #B3E6B3;
	font-weight: bold;
	text-align: center;
	color: green;
}
EOF

my $q = CGI->new;
print $q->header('text/html'),
      $q->start_html(-title => 'Paragraph Test',
                     -style => { -code => $css }),
      $q->h2('Web frontend for managing database data'),
      $form->render,
      $q->end_html;
