#!/bin/perl
#
#  Direct html/html_sr API coverage
#
use strict qw(vars);
use warnings;

use Test::More tests => 8;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use File::Temp qw(tempdir tempfile);
use File::Spec;

use WebDyne qw(html html_sr);

my $tmp_dn=tempdir(CLEANUP => 1);
my $template_fn=File::Spec->catfile($tmp_dn, 'api.psp');

open(my $template_fh, '>', $template_fn) || die "unable to open '$template_fn' for write, $!";
print {$template_fh} <<'END_TEMPLATE';
<start_html>
<perl handler="handler">
Value: ${value}
</perl>
__PERL__
sub handler {
    my ($self, $param_hr)=@_;
    return $self->render($param_hr);
}
END_TEMPLATE
close($template_fh) || die "unable to close '$template_fn', $!";

my $html_one=html($template_fn, { param => { value => 'alpha' } });
like($html_one, qr/Value:\s*alpha/, 'html() supports filename plus hashref options');

my $html_two=html($template_fn, param => { value => 'beta' });
like($html_two, qr/Value:\s*beta/, 'html() supports filename plus key/value options');

my $html_three=html({ filename => $template_fn, param => { value => 'gamma' } });
like($html_three, qr/Value:\s*gamma/, 'html() supports hashref-only calling form');

my $html_sr=html_sr($template_fn, { param => { value => 'delta' } });
is(ref($html_sr), 'SCALAR', 'html_sr() returns a scalar reference when capturing output');
like($$html_sr, qr/Value:\s*delta/, 'html_sr() captured output contains rendered param value');

my ($outfile_fh, $outfile_fn)=tempfile();
my $outfile_html=html($template_fn, { param => { value => 'epsilon' }, outfile => $outfile_fh });
close($outfile_fh) || die "unable to close '$outfile_fn', $!";
ok(!defined($outfile_html), 'html() returns undef when outfile is supplied');

open(my $verify_fh, '<', $outfile_fn) || die "unable to open '$outfile_fn' for read, $!";
local $/;
my $written_html=<$verify_fh>;
close($verify_fh) || die "unable to close '$outfile_fn', $!";
like($written_html, qr/Value:\s*epsilon/, 'outfile receives rendered HTML content');

my $outfile_sr=html_sr($template_fn, { param => { value => 'zeta' }, outfile => IO::File->new_tmpfile() });
ok(ref($outfile_sr) eq 'SCALAR' && !defined($$outfile_sr), 'html_sr() returns undefined scalar ref when outfile is supplied');
