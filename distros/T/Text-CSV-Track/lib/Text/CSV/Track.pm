package Text::CSV::Track;

our $VERSION = '0.9';
use 5.006;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
	qw(
		file_name
		_file_fh
		_rh_value_of
		_lazy_init
		ignore_missing_file
		full_time_lock
		auto_store
		_no_lock
		ignore_badly_formated
		_csv_format
		header_lines
		footer_lines
		hash_names
		single_column
		trunc
		replace_new_lines_with
		identificator_column_number

		sep_char
		escape_char
		quote_char
		always_quote
		binary
		type
	)
);

use FindBin;

use Text::CSV_XS;
use Carp::Clan;
use English qw(-no_match_vars);
use Fcntl ':flock'; # import LOCK_* constants
use Fcntl ':seek';  # import SEEK_* constants
use List::MoreUtils qw { first_index };
use IO::Handle; #must be because file_fh->input_line_number function


sub new {
	my $class  = shift;
	my $ra_arg = shift;

	#build object from parent
	my $self = $class->SUPER::new($ra_arg);

	#create empty pointers
	$self->{_rh_value_of} = {};
	$self->{header_lines} = [] if not defined $self->{header_lines};
	$self->{footer_lines} = [] if not defined $self->{footer_lines};

	return $self;
}

sub output_row_of {
	my $self          = shift;
	my $identificator = shift;
	my $type          = shift;

	#combine values for csv file
	my @fields = $self->value_of($identificator);

	#removed entry
	return undef if (@fields == 1) and (not defined $fields[0]);

	#if in single column mode remove '1' from the start of the fields
	shift(@fields) if $self->single_column;

	#remove new lines
	if (defined $self->replace_new_lines_with) {
		my $replacement = $self->replace_new_lines_with;
		foreach my $field (@fields) {
			next if not defined $field;
			$field =~ s{[\n\r]+}{$replacement}sg;
		}
	}

	#add identificator to the values
	splice(@fields, $self->identificator_column_number, 0, $identificator);

	if ($type eq 'csv') {
		croak "invalid value to store to an csv file - ", $self->_csv_format->error_input(),"\n"
			if (not $self->_csv_format->combine(@fields));

		return $self->_csv_format->string();
	}
	elsif ($type eq 'xml') {
		my $xml_line = '<Row>'."\n";
		$xml_line .= '    <Cell><Data ss:Type="String">'.$identificator.'</Data></Cell>'."\n";
		foreach my $col_value ($self->value_of($identificator)) {
			$col_value = '' if not defined $col_value;
			$xml_line .= '    <Cell><Data ss:Type="String">'.$col_value.'</Data></Cell>'."\n";
		}
		$xml_line .= '</Row>';

		return $xml_line;
	}
	else {
		croak "unknow output format";
	}
}


sub csv_line_of {
	my $self          = shift;
	my $identificator = shift;

	return $self->output_row_of($identificator, 'csv');
}


sub value_of {
	my $self          = shift;
	my $identificator = shift;
	my $is_set        = 0;	#by default get

	#if we have one more parameter then it is set
	my $value;
	if (@_ >= 1) {
		$is_set = 1;
		$value = \@_;
	}

	#check if we have identificator
	return if not $identificator;

	#value_of hash
	my $rh_value_of = $self->_rh_value_of;

	#lazy initialization is needed for get
	$self->_init() if not $is_set;

	#switch between set and get variant
	#set
	if ($is_set) {
		$rh_value_of->{$identificator} = $value;
	}
	#get
	else {
		return undef if not defined $rh_value_of->{$identificator};

		#if we have more then one field return array
		if (@{$rh_value_of->{$identificator}} > 1) {
			return @{$rh_value_of->{$identificator}};
		}
		#otherwise return one and only value from array as scallar
		else {
			return ${$rh_value_of->{$identificator}}[0];
		}
	}
}


sub hash_of {
	my $self          = shift;
	my $identificator = shift;
	my $is_set        = 0;	#by default get

	croak "'hash_names' parameter not set" if not defined $self->hash_names;
	my @hash_names    = @{$self->hash_names};
	my @fields = $self->value_of($identificator);

	#if we have one more parameter then it is set
	my $rh;
	if (@_ >= 1) {
		$is_set = 1;
		$rh     = shift;

		croak "not a hash reference as set argument" if ref $rh ne 'HASH';
	}

	if ($is_set) {
		foreach my $key (keys %{$rh}) {
			my $index = first_index { $_ eq $key } @hash_names;

			croak "no such hash key name '$key'" if $index == -1;

			$fields[$index] = $rh->{$key};
		}

		#save back the fields
		$self->value_of($identificator, @fields);
	}
	else {
		my %hash;
		foreach my $name (@hash_names) {
			$hash{$name} = shift @fields;
		}

		return \%hash;
	}
}


sub store_as_xml {
	my $self         = shift;

	return $self->store(1);
}


sub store {
	my $self         = shift;
	my $store_as_xml = shift;

	#lazy initialization
	$self->_init();

	#get local variables from self hash
	my $rh_value_of        = $self->_rh_value_of;
	my $file_name          = $self->file_name;
	my $full_time_lock     = $self->full_time_lock;
	my $file_fh            = $self->_file_fh;

	if (not $full_time_lock) {
		open($file_fh, "+>>", $file_name) or croak "can't write to file '$file_name' - $OS_ERROR";

		#lock and truncate the access store file
		flock($file_fh, LOCK_EX) or croak "can't lock file '$file_name' - $OS_ERROR\n";
	}

	#loop through identificators and store to array only if all works fine file will be overwritten
	my @file_lines;
	foreach my $identificator (sort $self->ident_list()) {
		my $file_line;
		if (defined $store_as_xml) {
			$file_line = $self->output_row_of($identificator, 'xml');
		}
		else {
			$file_line = $self->output_row_of($identificator, 'csv');
		}

		#skip removed entries
		next if not $file_line;

		push(@file_lines, $file_line."\n");
	}

	#truncate the file so that we can store new results
	truncate($file_fh, 0) or croak "can't truncate file '$file_name' - $OS_ERROR\n";

	#write header lines
	foreach my $header_line (@{$self->header_lines}) {
		print {$file_fh} $header_line, "\n";
	}

	#write csv lines
	foreach my $line (@file_lines) {
		#print the line to csv file
		print {$file_fh} $line;
	}

	#write footer lines
	foreach my $footer_line (@{$self->footer_lines}) {
		print {$file_fh} $footer_line, "\n";
	}

	close($file_fh);
}

#lazy initialization
sub _init {
	my $self = shift;

	return if $self->_lazy_init;

	#prevent from reexecuting
	$self->_lazy_init(1);

	#default values
	$self->replace_new_lines_with('|')    if not exists $self->{'replace_new_lines_with'};
	$self->binary(1)                      if not exists $self->{'binary'};
	$self->identificator_column_number(0) if not exists $self->{'identificator_column_number'};

	#get local variables from self hash
	my $rh_value_of         = $self->_rh_value_of;
	my $file_name           = $self->file_name;
	my $ignore_missing_file = $self->ignore_missing_file;
	my $full_time_lock      = $self->full_time_lock;
	my $_no_lock            = $self->_no_lock;
	my $header_lines_count;
	my $header_lines_from_file;
	my $footer_lines_count;
	my $footer_lines_from_file;

	if (ref $self->{header_lines} eq 'ARRAY') {
		$header_lines_count = scalar @{$self->header_lines};
		$header_lines_from_file = 0;
	}
	else {
		#initialize header_lines with array of empty strings if header_lines is number
		$header_lines_count = $self->{header_lines};
		$self->header_lines([ map {""} (1 .. $header_lines_count) ]);
		$header_lines_from_file = 1;
	}

	if (ref $self->{footer_lines} eq 'ARRAY') {
		$footer_lines_count = scalar @{$self->footer_lines};
		$footer_lines_from_file = 0;
	}
	else {
		#initialize footer_lines with array of empty strings if footer_lines is number
		$footer_lines_count = $self->{footer_lines};
		$self->footer_lines([ map {""} (1 .. $footer_lines_count) ]);
		$footer_lines_from_file = 1;
	}

	#Text::CSV_XS variables
	my $sep_char            = defined $self->sep_char    ? $self->sep_char    : q{,};
	my $escape_char         = defined $self->escape_char ? $self->escape_char : q{\\};
	my $quote_char          = defined $self->quote_char  ? $self->quote_char  : q{"};
	my $always_quote        = $self->always_quote;
	my $binary              = $self->binary;

	#done with initialization if file_name empty
	return if not $file_name;

	#define csv format
	$self->_csv_format(Text::CSV_XS->new({
		sep_char     => $sep_char,
		escape_char  => $escape_char,
		quote_char   => $quote_char,
		always_quote => $always_quote,
		binary       => $binary,
	}));

	#default open mode is reading
	my $open_mode = '<';

	#if full_time_lock is set do open for writting
	if ($full_time_lock) {
		if ($ignore_missing_file) {
			$open_mode = '+>>';
		}
		else {
			$open_mode = '+<';
		}
	}

	#open file with old stored values and handle error
	my $file_fh;
	if (not open($file_fh, $open_mode, $file_name)) {
		if ($ignore_missing_file) {
			$OS_ERROR = undef;
			return;
		}
		else {
			croak "can't read file '$file_name' - $OS_ERROR";
		}
	}

	#do exclusive lock if full time lock
	if ($full_time_lock) {
		flock($file_fh, LOCK_EX) or croak "can't lock file '$file_name' - $OS_ERROR\n";
		seek($file_fh, 0, SEEK_SET);
	}
	#internal flag. used from within the same module if file is already locked
	elsif ($_no_lock) {
	}
	#otherwise shared lock is enought
	else {
		flock($file_fh, LOCK_SH) or croak "can't lock file '$file_name' - $OS_ERROR\n";
	}

	my $lines_count = 0;
	$lines_count++ while (<$file_fh>);

	#reset file position
	seek($file_fh, 0, SEEK_SET);
	$file_fh->input_line_number(0);

	#create hash of identificator => 1
	my %identificator_exist = map { $_ => 1 } $self->ident_list;

	#parse lines and store values in the hash
	LINE:
	while (my $line = <$file_fh>) {
		chomp($line);
		$lines_count--;

		#skip header lines and save them for store()
		if ($header_lines_count) {
			#save header line if not defined
			${$self->header_lines}[$file_fh->input_line_number-1] = $line if $header_lines_from_file;

			#decrease header lines code so then we will know when there is an end of headers
			$header_lines_count--;

			next;
		}

		#skip footer lines and save them for store()
		if ($lines_count < $footer_lines_count) {
			#save footer lines if not defined
			${$self->footer_lines}[$footer_lines_count - $lines_count - 1] = $line if $footer_lines_from_file;

			next;
		}

		#skip reading of values if in 'trunc' mode
		next if $self->trunc;

		#verify line. if incorrect skip with warning
		if (!$self->_csv_format->parse($line)) {
			my $msg = "badly formated '$file_name' csv line " . $file_fh->input_line_number() . " - '$line'.\n";

			#by default croak on bad line
			croak $msg if not $self->ignore_badly_formated;

			#if ignore_badly_formated_lines is on just print warning
			warn $msg;

			next;
		}

		#extract fields
		my @fields = $self->_csv_format->fields();
		my $identificator = splice(@fields, $self->identificator_column_number, 1);

		#if in single column mode insert '1' to the fields
		unshift(@fields, 1) if $self->single_column;

		#save present fields
		my @old_fields = $self->value_of($identificator);

		#set the value from file
		$self->value_of($identificator, @fields);

		#set the value from before values from file was read !needed becouse of the strategy!
		$self->value_of($identificator, @old_fields) if $identificator_exist{$identificator};
	}

	#if full time lock then store file handle
	if ($full_time_lock) {
		$self->_file_fh($file_fh);
	}
	#otherwise release shared lock and close file
	else {
		flock($file_fh, LOCK_UN) if not $_no_lock;
		close($file_fh);
	}
}


sub ident_list {
	my $self = shift;

	#lazy initialization
	$self->_init();

	#get local variables from self hash
	my $rh_value_of = $self->_rh_value_of;

	return keys %{$rh_value_of};
}


sub header_lines {
	my $self = shift;

	#set
	if (@_ >= 1) {
		$self->{header_lines} = shift;
	} else
	#get
	{
		#if _header_lines then do lazy init and get the header lines from file
		$self->_init if (ref $self->{header_lines} ne 'ARRAY');

		return $self->{header_lines};
	}

}


sub footer_lines {
	my $self = shift;

	#set
	if (@_ >= 1) {
		$self->{footer_lines} = shift;
	} else
	#get
	{
		#if footer_lines is not array then do lazy init and get the footer lines from file
		$self->_init if (ref $self->{footer_lines} ne 'ARRAY');

		return $self->{footer_lines};
	}
}


sub finish {
	my $self = shift;

	#call store if in auto_store mode
	$self->store() if $self->auto_store;

	#get local variables from self hash
	my $file_fh = $self->_file_fh;

	if (defined $file_fh) {
		close($file_fh);
	}

	$self->_file_fh(undef);
}

sub DESTROY {
	my $self = shift;

	$self->finish();
}

1;

__END__

=head1 NAME

Text::CSV::Track - module to work with .csv file that stores some value(s) per identificator

=head1 SYNOPSIS

	use Text::CSV::Track;

	#create object
	my $access_time = Text::CSV::Track->new({ file_name => $file_name, ignore_missing_file => 1 });

	#set single value
	$access_time->value_of($login, $access_time);

	#fetch single value
	print $access_time->value_of($login);

	#set multiple values
	$access_time->value_of($login, $access_time);

	#fetch multiple values
	my @fields = $access_time->value_of($login);

	#save changes
	$access_time->store();

	#print out all the identificators we have
	foreach my $login (sort $access_time->ident_list()) {
		print "$login\n";
	}

	#getting muticolumn by hash
	$track_object = Text::CSV::Track->new({
		file_name    => $file_name
		, hash_names => [ qw{ col coool } ]
	});
	my %hash = %{$track_object->hash_of('ident')};
	print "second column is: ", $hash{'coool'}, "\n";

	#setting multicolumn by hash
	$track_object->hash_of('ident2', { coool => 333 } );

	#header lines
	$track_object = Text::CSV::Track->new({
		file_name           => $file_name,
		header_lines        => \@header_lines,
		ignore_missing_file => 1,
	});

=head1 DESCRIPTION

The module manipulates csv file:

"identificator","value1"
...

It is designet to work when multiple processes access the same file at
the same time. It uses lazy initialization. That mean that the file is
read only when it is needed. There are three scenarios:

1. Only reading of values is needed. In this case first ->value_of() also
activates the reading of file. File is read while holding shared flock.
Then the lock is released.

2. Only setting of values is needed. In this case ->value_of($ident,$val)
calls just saves the values to the hash. Then when ->store() is called
it activates the reading of file. File is read while holding exclusive flock.
The identifications that were stored in the hash are replaced, the rest
is kept.

3. Both reading and setting values is needed. In this case 'full_time_lock'
flag is needed. The exclusive lock will be held from the first read until
the object is destroied. While the lock is there no other process that uses
flock can read or write to this file.

When setting and getting only single value value_of($ident) will return scalar.
If setting/getting multiple columns then an array.

=head1 METHODS

=over 4

=item new()

	new({
		file_name                   => 'filename.csv',
		ignore_missing_file         => 1,
		full_time_lock              => 1,
		auto_store                  => 1,
		ignore_badly_formated       => 1,
		header_lines                => 3, #or [ '#heading1', '#heading2', '#heading3' ]
		footer_lines                => 3, #or [ '#footer1', '#footer2', '#footer3' ]
		hash_names                  => [ qw{ column1 column2 }  ],
		single_column               => 1,
		trunc                       => 1,
		replace_new_lines_with      => '|',
		identificator_column_number => 0,

		#L<Text::CSV_XS> paramteres
		sep_char              => q{,},
		escape_char           => q{\\},
		quote_char            => q{"},
		always_quote          => 0,
		binary                => 0,
	})

All flags are optional.

'file_name' is used to read old results and then store the updated ones

If 'ignore_missing_file' is set then the lib will just warn that it can not
read the file. store() will use this name to store the results.

If 'full_time_lock' is set the exclusive lock will be held until the object is
not destroyed. use it when you need both reading the values and changing the values.
If you need just read OR change then you don't need to set this flag. See description
about lazy initialization.

If 'auto_store' is on then the store() is called when object is destroied

If 'ignore_badly_formated_lines' in on badly formated lines from input are ignored.
Otherwise the modules calls croak.

'header_lines' specifies how many lines of csv are the header lines. They will
be skipped during the reading of the file and rewritten during the storing to the
file. After first read of value the ->header_lines becomes array ref of header lines.
Optionaly you can set array ref and set the header lines.

'hash_names' specifies hash names fro hash_of() function.

'single_column' files that store just the identificator for line. In this case
during the read 1 is set as the second column. During store that one is dropped
so single column will be stored back.

'trunc' don't read previous file values. Header lines will persist.

'replace_new_lines_with' [\n\r]+ are replaced by this character if defined. By
default it is '|'. It is a good idea to replace new lines because they are not
handled by Text::CSV_XS on read.

'identificator_column_number'. If identificator is in different column than the
first one set this value. Column are numbered starting with 0 like in an
@array. ->value_of and ->hash_of are indexed as it the identificator column
was not there.

See L<Text::CSV_XS> for 'sep_char', 'escape_char', 'quote_char', 'always_quote', 'binary'

=item value_of()

Is used to both store or retrieve the value. if called with one argument
then it is a read. if called with two arguments then it will update the
value. The update will be done ONLY if the supplied value is bigger.

=item hash_of()

Returns hash of values. Names for the hash values are taken from hash_names parameter.

=item store()

when this one is called it will write the changes back to file.

=item store_as_xml()

this will write to the file but the values will be excel xml formated. Combined with
proper header and footer lines this can generate excel readable xml file.

=item ident_list()

will return the array of identificators

=item output_row_of($ident, $type)

$type is one of csv or xml.

Returns one row of data for given identificator.

=item csv_line_of($identificator)

Calls $self->output_row_of($identificator, 'csv').

=item header_lines()

Set or get header lines.

=item footer_lines()

Set or get footer lines.

=item finish()

Called by destructor to clean up thinks. Calls store() if auto_atore is on
and closes csv filehandle.

=cut

=back

=head1 TODO

	- ident_list() should return number of non undef rows in scalar context
	- strategy for Track ->new({ strategy => sub { $a > $b } })
	- then rewrite max/min to use it this way
	- constraints for columns
	- shell executable to copy, dump csv file or extract data from it
	- allow having extended csv with header names in every file key=value;key2=value2
	- atomic writes
	- allow extended csv lines, lines that look like:
	    key=value1,key5=value2,key2=value3

=head1 SEE ALSO

L<Text::CSV::Track::Max>, L<Text::CSV::Track::Min>, Module Trac - L<http://trac.cle.sk/Text-CSV-Track/>

=head1 AUTHOR

Jozef Kutej - E<lt>jozef@kutej.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jozef Kutej

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
