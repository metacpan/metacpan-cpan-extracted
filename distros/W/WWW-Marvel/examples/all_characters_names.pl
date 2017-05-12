#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use WWW::Marvel::Client;
use WWW::Marvel::Config::File;
use WWW::Marvel::Response;

my $cfg = WWW::Marvel::Config::File->new();
my $client = WWW::Marvel::Client->new({
	public_key  => $cfg->get_public_key,
	private_key => $cfg->get_private_key,
});

my $total_records = undef;
my $founded = 0;
my $offset = 0;
my $limit = 100;
my $calls = 0;
do {
	my $res_data = $client->characters({ limit => $limit, offset => $offset });
	my $res = WWW::Marvel::Response->new($res_data);
	$total_records //= $res->get_total;
	$founded += $res->get_count;
	$offset += $limit;

	while (my $c = $res->get_next_entity) {
		printf "%s\t%s\t%s\n", $c->get_id, $c->get_name, $c->get_picture('standard_fantastic') // '';
	}
	$calls++;
	sleep 1;
} while ( defined $total_records && $founded < $total_records && $offset < $total_records );

printf "Total: %s\n", $total_records;
printf "Founded: %s\n", $founded;
printf "Offset: %s\n", $offset;
printf "Calls %s\n", $calls;
