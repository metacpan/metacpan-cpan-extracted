#!/usr/bin/perl
#
# Non-regression tests for the pure helpers of oEdtk::EDMS.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use Test::More;
use TestOEdtk qw(quiet_require);

quiet_require('oEdtk::EDMS');

# EDMS_idldoc_seqpg($idldoc, $page) => "<idldoc>_<page on 7 digits>"
is(oEdtk::EDMS::EDMS_idldoc_seqpg('DOC', 5),  'DOC_0000005', 'seqpg pads page to 7 digits');
is(oEdtk::EDMS::EDMS_idldoc_seqpg('DOC', 0),  'DOC_0000000', 'seqpg handles page 0');
is(oEdtk::EDMS::EDMS_idldoc_seqpg('A.B', 12), 'A.B_0000012', 'seqpg keeps dots inside idldoc');
is(oEdtk::EDMS::EDMS_idldoc_seqpg('X', 12345678), 'X_12345678', 'seqpg keeps pages beyond 7 digits');

# _docubase_file_name($name): strip a trailing ".<2-4 word chars>" extension,
# turn remaining '-' and '.' into '_', then re-append the extension.
is(oEdtk::EDMS::_docubase_file_name('a.b.c.pdf'),  'a_b_c.pdf',    'dots before the extension become underscores');
is(oEdtk::EDMS::_docubase_file_name('noext'),      'noext',        'name without extension is unchanged');
is(oEdtk::EDMS::_docubase_file_name('file-name.txt'), 'file_name.txt', 'dashes become underscores');
is(oEdtk::EDMS::_docubase_file_name('a.b.c'),      'a_b_c',        'one-char tail is not an extension');
is(oEdtk::EDMS::_docubase_file_name('file.longext'), 'file_longext', 'extension longer than 4 chars is kept as a dot');
is(oEdtk::EDMS::_docubase_file_name('file.PDF'),   'file.PDF',     'uppercase extension is recognised');
is(oEdtk::EDMS::_docubase_file_name('2026-07-09.pdf'), '2026_07_09.pdf', 'date-like name is normalised');

done_testing();
