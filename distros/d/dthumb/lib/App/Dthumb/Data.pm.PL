#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use autodie;
use MIME::Base64 qw(encode_base64);

my ($out_file) = @ARGV;

open(my $out_fh, '>', $out_file);
opendir(my $share_dh, 'share');

print {$out_fh} <DATA>;

for my $file (readdir($share_dh)) {
	if (substr($file, 0, 1) eq '.') {
		next;
	}

	open(my $fh, '<', "share/${file}");
	my $content = do { local $/ = undef; <$fh> };
	close($fh);

	if ($file =~ qr{ \. (png | gif) $ }ox) {
		$content = encode_base64($content);
	}

	printf {$out_fh} (
		"______[ %s ]______\n%s\n",
		$file,
		$content,
	);
}
closedir($share_dh);
close($out_fh);


__DATA__
package App::Dthumb::Data;


=head1 NAME

App::Dthumb::Data - Retrieve installed data (like lightbox images)

=head1 SYNOPSIS

    use App::Dthumb::Data;
    my $data = App::Dthumb::Data->new();
    
    $data->set_vars(
    	title => 'Something funky',
    );
    
    print $data->get('html_start.dthumb');
    
    open(my $fh, '>', 'close.png');
    print {$fh} $data->get('close.png');
    close($fh);

=head1 VERSION

This manual documents B<App::Dthumb::Data> version 0.2

=cut


use strict;
use warnings;
use base 'Exporter';

use Data::Section -setup;
use MIME::Base64 qw(decode_base64);

our @EXPORT_OK = ();
our $VERSION = '0.2';


=head1 METHODS

=head2 new

Returns a new B<App::Dthumb> object. Does not take any arguments.

=cut


sub new {
	my ($obj) = @_;
	my $ref = {};
	return bless($ref, $obj);
}


=head2 set_vars(%vars)

Set replacement variables.  For each hash key, when outputting data using the
B<get> function, dthumb will replace occurences of "<!-- $key -->" or "/* $key
*/" (the dollar sign is literal) with its value.

=cut


sub set_vars {
	my ($self, %vars) = @_;
	$self->{replace} = \%vars;
}


=head2 list_archived

Returns an array of all saved data.  That is, all files which do not end in
".dthumb".

=cut


sub list_archived {
	my ($self) = @_;
	return grep { ! /\.dthumb$/ } $self->section_data_names();
}


=head2 get($filename)

Returns the exact content of share/$filename.

=cut


sub get {
	my ($self, $name) = @_;
	my $data = $self->section_data($name);

	if (not $data) {
		die("No such data: ${name}\n");
	}

	$data = ${$data};

	chomp($data);

	if ($name =~ qr{ \. (png | gif) $ }ox) {
		return decode_base64($data);
	}

	while (my ($key, $value) = each %{$self->{replace}}) {
		$data =~ s{
			( \<\!-- | /\* )
				\s+ \$ $key \s+
			( --\> | \*/ )
		}{$value}gx;
	}

	return $data;
}

1;

=head1 DEPENDENCIES

=over

=item * Data::Section

=back

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel E<lt>derf@chaosdorf.deE<gt>

=head1 LICENSE

    0. You just DO WHAT THE FUCK YOU WANT TO.

=cut

__DATA__

