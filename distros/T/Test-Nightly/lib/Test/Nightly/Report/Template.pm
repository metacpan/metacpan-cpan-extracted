package Test::Nightly::Report::Template;

use strict;

our $VERSION = '0.03';

=head1 NAME

Test::Nightly::Report::Template

=head1 DESCRIPTION

Default template for test reporting

=cut

use constant DEFAULT => 
'
<html>

<style type="text/css">
body {
	font: 0.85em verdana, arial, sans-serif;
}

td, th {
	border: 1px solid #333;
	font: 0.80em verdana, arial, sans-serif;
}

h1 {
	font: bold 1em verdana, arial, sans-serif;
	
}

.failed, .passed, .blank {
	text-align: center;
}

.failed {
	background-color: red;
}

.passed {
	background-color: green;
}

.blank {
	background-color: #eee;
}

</style>


<h1>Test::Nightly Report</h1>
<table>
	<tr>
		<th>Test</th>
		<th>Passed</th>
		<th>Failed</th>
	</tr>
[% FOREACH module = tests.keys %]
	<tr><td colspan="3">[% module %]</td></tr>
	[% FOREACH test_group = tests.$module %]
	<tr>
		<td>[% test_group.test %]</td>
		<td class="[% IF test_group.status == \'passed\' %]passed[% ELSE %]blank[% END %]">[% IF test_group.status == \'passed\' %]Passed[% ELSE %]&nbsp;[% END %] </td>
		<td class="[% IF test_group.status == \'failed\' %]failed[% ELSE %]blank[% END %]">[% IF test_group.status == \'failed\' %]Failed[% ELSE %]&nbsp;[% END %] </td>
	</tr>
	[% END %] 
[% END %]
</table>
';

=head1 AUTHOR

Kirstin Bettiol <kirstinbettiol@gmail.com>

=head1 COPYRIGHT

(c) 2005 Kirstin Bettiol
This library is free software, you can use it under the same terms as perl itself.

=head1 SEE ALSO

L<Test::Nightly::Report>
L<perl>.

=cut

1;

