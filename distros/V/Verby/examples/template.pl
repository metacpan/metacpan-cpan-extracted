#!/usr/bin/perl

use strict;
use warnings;

use File::Temp qw/tempdir/;

use Verby::Dispatcher;
use Verby::Step::Closure qw/step/;
use Verby::Config::Data;
use File::Basename;

my $cfg = Verby::Config::Data->new;
%{ $cfg->data } = (
	project_root => my $out_dir = tempdir(CLEANUP => 1),
	company_name => "Beer rocks!",
	perl_module_namespace => "Acme::Møøse",
	project_url => "http://goatse.cx",
	database => {
		dsn => "dbi:moose",
		username => "",
		password => "",
	},
	demographics => [ ],
);

my $tmpl_dir = "EERS_demo/templates";

my %by_dir = (
	conf => [qw/httpd.conf startup.pl startup.xml/],
	"perl/foo" => [qw/main.pm/],
);

my $d = Verby::Dispatcher->new;
$d->config_hub($cfg);

foreach my $dir (keys %by_dir){
	foreach my $file (@{ $by_dir{$dir} }){
		my $in = "$tmpl_dir/$file";
		my $out = "$out_dir/$dir/$file";
		my $t = step "Verby::Action::Template" => sub {
			my $c = $_[1];
			$c->template($in);
			$c->output($out);
	   	};
		my $path = dirname($out);
		$t->depends(step "Verby::Action::MkPath" => sub { $_[1]->path($path) });
		$d->add_step($t);
	}
}

$d->do_all;

__END__

=pod

=head1 NAME 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Yuval Kogman, E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
