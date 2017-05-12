package Tie::PagedArray;
our $VERSION = '0.02';
use 5.008;

=pod

=head1 NAME

Tie::PagedArray - A tieable module for handling large arrays by paging

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

tie my(@large_array), 'Tie::PagedArray';

tie my(@large_array), 'Tie::PagedArray', page_size => 100, paging_dir => '/tmp';

=head1 DESCRIPTION

When processing a large volumes of data a program may run out of memory. The operating system may impose a limit on the amount of memory a process can consume or the machine may simply lack the required amount of memory.

Tie::PagedArray supports large arrays by implementing paging and avoids running out of memory.
The array is broken into pages and these pages are pushed to disk barring the page that is in use. Performance depends on the device chosen for persistence of pages.

This module uses L<Storable> as its backend for serialization and deserialization. So the elements of the paged array can be any value or object. See documentation for L<Storable> module to work with code refs.

When switching pages data from the currently active page is offloaded from the memory onto the page file if the page is marked dirty. This is followed by deserializing the page file of the page to which the switch is to be made.

An active page is marked dirty by an B<assignment> of a value to any element in the page. To forcibly mark a page dirty assign an element in the page to itself!

  $large_array[2000] = $large_array[2000];

The defaults are C<page_size =E<gt> 2000>, C<paging_dir =E<gt> ".">

=head1 METHODS

=cut

use strict;
use warnings;

use Storable ();
use Tie::Array;

our @ISA = ('Tie::Array');

# Default
our $ELEMS_PER_PAGE = 2000;

# The pointers to store and retrieve
# The user can change this to Storable::nstore for sharing the page files across platforms
our $STORE_DELEGATE = \&Storable::store;
our $RETRIEVE_DELEGATE = \&Storable::retrieve;

# Object properties

use constant {
	# Array properties
	ARRAY_PAGE_BANK   => 0,
	ARRAY_ACTIVE_PAGE_NUM => 1,
	ARRAY_PAGE_SIZE   => 2,
	ARRAY_LENGTH      => 3,
	ARRAY_PAGING_DIR  => 4,
	ARRAY_PAGE_BEG_IDX=> 5,
	ARRAY_PAGE_END_IDX=> 6,
	# Page properties
	PAGE_DATA       => 0,
	PAGE_LENGTH     => 1,
	PAGE_DIRTY      => 2,
	PAGE_FILE       => 3,
	PAGE_INDEX      => 4,
};

my $PAGE_NUM = 0;

=pod

=head2 tie

The C<tie> call lets you create a new B<Tie::PagedArray> object.

  tie my(@large_array), 'Tie::PagedArray';
  tie my(@large_array), 'Tie::PagedArray', page_size => 100;
  tie my(@large_array), 'Tie::PagedArray', page_size => 100, paging_dir => '/tmp';

Ties the array C<@large_array> to C<Tie::PagedArray> class.

C<page_size> is the size of a page. If C<page_size> is omitted then it defaults to 2000 elements. The default page size can be changed by setting the package variable C<ELEMS_PER_PAGE>. The change in default only affects future ties.

  $Tie::PagedArray::ELEMS_PER_PAGE = 2000;

C<paging_dir> is a directory to store the page files. Choose a directory on a fast storage device. If omitted it defaults to the current working directory.

=cut

sub TIEARRAY {
	my ($class, %params) = @_;
	my ($page_size, $paging_dir, $use_nstore) = @params{'page_size', 'paging_dir'};
	$page_size = $page_size && int($page_size) > 0 ? int($page_size) : $ELEMS_PER_PAGE;
	$paging_dir = "." unless $paging_dir && -d $paging_dir;

	#           [PAGE_BANK, ACTIVE_PAGE_NUM, PAGE_SIZE , LENGTH, PAGING_DIR , ARRAY_PAGE_BEG_IDX, ARRAY_PAGE_END_IDX]
	my $self  = [[]       , 0              , $page_size, 0     , $paging_dir, 0                 , -1                ];
	return bless $self, $class;
}

sub FETCHSIZE {
	return $_[0]->[ARRAY_LENGTH];
}

sub STORESIZE {
	local($_);
	my ($self, $new_size, $page_num, $new_page_size) = @_;

	return $self->CLEAR() if $new_size < 1;

	($page_num, $new_page_size) = $self->_calc_page_offset($new_size) unless defined($page_num);

	my $page_bank = $self->[ARRAY_PAGE_BANK];

	# Add/remove page from the bank
	my $last_page_idx = $#$page_bank;
	my $new_pages_count  = $page_num - $last_page_idx;

	if ($new_pages_count > 0) {
		# Last page should tend towards standard page size
		$page_bank->[-1]->[PAGE_LENGTH] = $self->[ARRAY_PAGE_SIZE] if @$page_bank;
		# Add new cache to the bank if array is growing
		for (1..$new_pages_count) {
			my $page = $self->_new_page();
			$page->[PAGE_LENGTH] = $self->[ARRAY_PAGE_SIZE];
			push(@$page_bank, $page);
		}
		$page_bank->[$self->[ARRAY_ACTIVE_PAGE_NUM]]->[PAGE_DIRTY] = 1;
	} elsif ($new_pages_count < 0) {
		for (@$page_bank[$last_page_idx + $new_pages_count + 1 .. $last_page_idx]) {
			my $page_file = $_->[PAGE_FILE];
			# Free up extra pages if array is downsizing
			defined($page_file) && -f($page_file) && unlink($page_file);
		}

		$#$page_bank = $last_page_idx + $new_pages_count;
	}

	# Allocate/free up space in the page
	$page_bank->[$page_num]->[PAGE_LENGTH] = $new_page_size;

	$self->[ARRAY_LENGTH] = $self->_calc_length();

	# Do nothing if switching to currently active page_file
	$self->_switch_to_page($page_num) if $page_num != $self->[ARRAY_ACTIVE_PAGE_NUM];

	return $self->[ARRAY_LENGTH];
}

sub STORE {
	local($_);
	my ($self, $index, $value, $page_num, $offset) = @_;

	# Location in the pages to store the value
	($page_num, $offset) = $self->_calc_page_offset($index) unless defined($page_num);

	# Grow/shrink array
	my $resized = undef;

	$self->STORESIZE($index + 1, $page_num, $offset + 1) if $index >= $self->FETCHSIZE();

	# Switch to page identified by page_num
	$self->_switch_to_page($page_num) if $page_num != $self->[ARRAY_ACTIVE_PAGE_NUM];

	my $page = $self->[ARRAY_PAGE_BANK]->[$page_num];
	$page->[PAGE_DIRTY] = 1;

	return $page->[PAGE_DATA]->[$offset] = $value;
}

sub FETCH {
	local($_);
	my ($self, $index) = @_;

	# Location in the pages to store the value
	my ($page_num, $offset) = $self->_calc_page_offset($index);

	# Check for out of bounds
	$self->EXISTS($index, $page_num, $offset) or return ();

	my $page = $self->[ARRAY_PAGE_BANK]->[$page_num];

	# To make nested paged structures work. Known inefficiency!
	#$page->[PAGE_DIRTY] = 1;
	# To make updates to nested structures work just do: $arr[6] = $arr[6]; forcing a STORE operation

	# Switch to page identified by the page_num
	$self->_switch_to_page($page_num) if $page_num != $self->[ARRAY_ACTIVE_PAGE_NUM];

	return $page->[PAGE_DATA]->[$offset];
}

sub EXISTS {
	local($_);
	my ($self, $index, $page_num, $offset) = @_;

	($page_num, $offset) = $self->_calc_page_offset($index) unless defined($page_num);
	return undef if $page_num > $#{$self->[ARRAY_PAGE_BANK]} || $offset >= $self->[ARRAY_PAGE_BANK]->[$page_num]->[PAGE_LENGTH];
	return 1;
}

sub CLEAR {
	local($_);
	my ($self) = @_;

	unlink($_->[PAGE_FILE]) foreach @{$self->[ARRAY_PAGE_BANK]};
	@$self[ARRAY_PAGE_BANK, ARRAY_ACTIVE_PAGE_NUM, ARRAY_PAGE_BEG_IDX, ARRAY_PAGE_END_IDX] = ([], 0, 0, 0);
	return $self->[ARRAY_LENGTH] = 0;
}

sub DELETE {
	local($_);
	my ($self, $index) = @_;

	my $last_index = $self->FETCHSIZE - 1;
	if ($index > $last_index) {
		return undef;
	} else {
		my ($page_num, $offset) = $self->_calc_page_offset($index);
		my $value = $self->FETCH($index, $page_num, $offset);
		$self->STORE($index, undef, $page_num, $offset);
		$self->[ARRAY_PAGE_BANK]->[$page_num]->[PAGE_DIRTY] = 1;

		return $value;
	}
}

sub PUSH {
	local($_);
	my $self = shift;
	my $i = $self->FETCHSIZE();
	$self->STORE($i++, shift) while @_;
	return $i;
}

sub POP {
	local($_);
	my $self = shift;
	my $newsize = $self->FETCHSIZE() - 1;
	my $val;
	if ($newsize >= 0) {
		$val = $self->FETCH($newsize);
		$self->STORESIZE($newsize);
	}
	return $val;
}

sub SHIFT {
	local($_);
	my $self = shift;
	return undef unless $self->[ARRAY_LENGTH] > 0;

	my $page = $self->[ARRAY_ACTIVE_PAGE_NUM] != 0 ? $self->_switch_to_page(0) : $self->[ARRAY_PAGE_BANK]->[0];
	my $val = shift(@{$page->[PAGE_DATA]});

	if(--$page->[PAGE_LENGTH]) {
		$page->[PAGE_DIRTY] = 1;
		$self->[ARRAY_PAGE_END_IDX]--;
		$self->[ARRAY_LENGTH] = $self->_calc_length();
	} else {
		# If page is now empty delete it
		unlink $page->[PAGE_FILE] if -f $page->[PAGE_FILE];
		shift(@{$self->[ARRAY_PAGE_BANK]});
		$self->[ARRAY_LENGTH] = $self->_calc_length();
		$page = $self->_switch_to_page(0);
	}
	
	return $val;
}

sub UNSHIFT {
	local($_);
	my $self = shift;
	return $self->[ARRAY_LENGTH] unless @_;

	my $page = undef;
	if($self->[ARRAY_ACTIVE_PAGE_NUM] == 0) {
		$page = $self->[ARRAY_PAGE_BANK]->[0];
	} elsif ($self->[ARRAY_ACTIVE_PAGE_NUM] > 0) {
		$page = $self->_switch_to_page(0);
	}

	# Array is empty. Create new page
	unshift(@{$self->[ARRAY_PAGE_BANK]}, $page = $self->_new_page()) if !defined($page);

	my $std_page_size = $self->[ARRAY_PAGE_SIZE];
	my $room = $std_page_size - $page->[PAGE_LENGTH];
	$room = @_ if @_ < $room;
	$page->[PAGE_LENGTH] = unshift(@{$page->[PAGE_DATA]}, splice(@_, -$room)) if $room > 0;
	$page->[PAGE_DIRTY] = 1;

	my $remain_len = @_;
	while($remain_len) {
		$self->[ARRAY_ACTIVE_PAGE_NUM]++;
		unshift(@{$self->[ARRAY_PAGE_BANK]}, $page = $self->_new_page());
		$page->[PAGE_INDEX] = 0;
		$page = $self->_switch_to_page(0);
		$std_page_size = $remain_len if $std_page_size > $remain_len;
		$page->[PAGE_LENGTH] = unshift(@{$page->[PAGE_DATA]}, splice(@_, -$std_page_size));
		$page->[PAGE_DIRTY] = 1;
		$remain_len = @_;
	}

	@$self[ARRAY_PAGE_BEG_IDX, ARRAY_PAGE_END_IDX] = (0, $page->[PAGE_LENGTH] - 1);

	return $self->[ARRAY_LENGTH] = $self->_calc_length();
}

sub DESTROY {
	local($_);
	$_[0]->CLEAR;	
}

sub SPLICE {
	local($_);
	my $self = shift; 
	my $index = scalar(@_) ? shift : 0;
	my $size = $self->FETCHSIZE();
	my $len = scalar(@_) ? shift : $size - $index;

	tie my(@result), ref($self), page_size => $self->[ARRAY_PAGE_SIZE], paging_dir => $self->[ARRAY_PAGING_DIR];

	$len += $size - $index if $len < 0;
	$index = $size if $index > $size;
	$len -= $index + $len - $size if $index + $len > $size;

	my $val;
	my $page_bank = $self->[ARRAY_PAGE_BANK];
	my $new_elems_len = scalar(@_);

	###
	my ($page_num, $page_offset);
	my $copy_len = $new_elems_len <= $len ? $new_elems_len : $len;
	my $end_index = $index + $copy_len;
	
	my $j = 0;
	my $page;
	for(my $i = $index; $i < $end_index; $i++) {
		my ($page_num, $offset) = $self->_calc_page_offset($i);
		$self->_switch_to_page($page_num) if $page_num != $self->[ARRAY_ACTIVE_PAGE_NUM];
		$page = $page_bank->[$page_num];
		push(@result, $page->[PAGE_DATA]->[$offset]);
		$page->[PAGE_DATA]->[$offset] = $_[$j++];
		$page->[PAGE_DIRTY] = 1;
	}
	return @result if $new_elems_len == $len;

	if ($new_elems_len < $len) {
		# Shrink the array
		my $del_end_index = $index + $len - 1;
		my ($del_start_page_num, $del_start_offset) = $self->_calc_page_offset($end_index);
		my ($del_end_page_num, $del_end_offset) = $self->_calc_page_offset($del_end_index);
		$self->_switch_to_page($del_start_page_num) if $del_start_page_num != $self->[ARRAY_ACTIVE_PAGE_NUM];
		my $page = $page_bank->[$del_start_page_num];
		if ($del_start_page_num == $del_end_page_num) {
			# Elems to be removed are in the same page
			push(@result, splice(@{$page->[PAGE_DATA]}, $del_start_offset, $del_end_offset - $del_start_offset + 1));
			@$page[PAGE_LENGTH, PAGE_DIRTY] = (scalar(@{$page->[PAGE_DATA]}), 1);
			$self->[ARRAY_PAGE_END_IDX] = $self->[ARRAY_PAGE_BEG_IDX] + $page->[PAGE_LENGTH] - 1;
		} else {
			# Axe the elems at the end in the start page
			push(@result, splice(@{$page->[PAGE_DATA]}, $del_start_offset, $page->[PAGE_LENGTH] - $del_start_offset));
			@$page[PAGE_LENGTH, PAGE_DIRTY] = ($del_start_offset, 1);

			# Remove pages in the middle
			my ($mid_start, $mid_end) = ($del_start_page_num + 1, $del_end_page_num - 1);
			if ($mid_start <= $mid_end) {
				foreach ($mid_start .. $mid_end) {
					$self->_switch_to_page($_);
					push(@result, @{$page_bank->[$_]->[PAGE_DATA]});
					unlink $page_bank->[$_]->[PAGE_FILE];
				}
				splice(@$page_bank, $mid_start, $mid_end - $mid_start + 1);
			}

			# Axe the elems in the beginning of the page
			$self->_switch_to_page($del_end_page_num);
			$page = $page_bank->[$self->[ARRAY_ACTIVE_PAGE_NUM]];
			splice(@{$page->[PAGE_DATA]}, 0, $del_end_offset + 1);
			if ($page->[PAGE_LENGTH] = scalar(@{$page->[PAGE_DATA]})) {
				$page->[PAGE_DIRTY] = 1;
				$self->[ARRAY_PAGE_BEG_IDX] = $end_index - 1;
			} else {
				unlink $page->[PAGE_FILE];
				splice(@$page_bank, $self->[ARRAY_ACTIVE_PAGE_NUM], 1);
				$self->[ARRAY_ACTIVE_PAGE_NUM] = 0;
				$self->_switch_to_page(0);
			}
		}
	} else {
		# Expand the array
		my ($ins_start_page_num, $ins_start_offset) = $self->_calc_page_offset($end_index);
		my $remaining_len = $new_elems_len - $j;

		# If insertion is needed at the head of the identified page then
		# either add elems to the previous page or to a new page that is inserted before the identified page
		if ($ins_start_offset == 0 && $ins_start_page_num > 0) {
			--$ins_start_page_num;
			$page = $self->_switch_to_page($ins_start_page_num);
			$ins_start_offset = $page->[PAGE_LENGTH];
		}

		$self->_switch_to_page($ins_start_page_num) if $ins_start_page_num != $self->[ARRAY_ACTIVE_PAGE_NUM];
		$page = $page_bank->[$ins_start_page_num];
		my $page_data = $page->[PAGE_DATA];
		my $std_page_size = $self->[ARRAY_PAGE_SIZE];

		if ($remaining_len + $page->[PAGE_LENGTH] <= $std_page_size) {
			# All remaining new elems will fit into current page
			splice(@$page_data, $ins_start_offset, 0, @_[$j..$#_]);
			$page->[PAGE_LENGTH] += $remaining_len;
			$self->[ARRAY_PAGE_END_IDX] = $self->[ARRAY_PAGE_BEG_IDX] + $page->[PAGE_LENGTH] - 1;
		} else {
			# Split the page
			# First part of the split
			my $second_page = $self->_new_page();
			my $tail_first_page = $page->[PAGE_LENGTH] - $ins_start_offset;
			my $post_cut_space = $std_page_size - $ins_start_offset;
			$post_cut_space = $remaining_len if $remaining_len < $post_cut_space;
			my @second_page_data = splice(@{$page->[PAGE_DATA]}, $ins_start_offset, $tail_first_page, @_[$j..$j+$post_cut_space-1]);
			@$page[PAGE_LENGTH, PAGE_DIRTY] = (scalar(@{$page->[PAGE_DATA]}), 1);

			#Insert new page into the page bank
			$second_page->[PAGE_INDEX] = 0;
			splice(@$page_bank, $ins_start_page_num + 1, 0, $second_page);

			# Second part of the split
			$page = $self->_switch_to_page($ins_start_page_num + 1);
			$j += $post_cut_space;
			$remaining_len = $new_elems_len - $j;
			if ($remaining_len > 0) {
				$post_cut_space = $std_page_size - scalar(@second_page_data);
				$post_cut_space = $remaining_len if $remaining_len < $post_cut_space;
				splice(@second_page_data, 0, 0, @_[$#_-$post_cut_space+1..$#_]);
				$new_elems_len -= $post_cut_space;
				$remaining_len = $new_elems_len - $j;
			}
			@$page[PAGE_DATA, PAGE_LENGTH, PAGE_DIRTY] = (\@second_page_data, scalar(@second_page_data), 1);

			# Elems that did not make it to the pages on either side of the split
			$self->_switch_to_page($ins_start_page_num);
			while ($remaining_len > 0) {
				$page = $self->_new_page();
				$page->[PAGE_INDEX] = 0;
				splice(@$page_bank, $ins_start_page_num + 1, 0, $page);
				$self->_switch_to_page($ins_start_page_num + 1);
				my $elems_count = $std_page_size < $remaining_len ? $std_page_size : $remaining_len;
				@$page[PAGE_DATA, PAGE_LENGTH, PAGE_DIRTY] = ([@_[$j..$j+$elems_count-1]], $elems_count, 1);
				$j += $elems_count;
				$ins_start_page_num++;
				$remaining_len = $new_elems_len - $j;
			}
		}
		$page->[PAGE_DIRTY] = 1;
	}

	$self->[ARRAY_LENGTH] = $self->_calc_length();
	$page = $page_bank->[$self->[ARRAY_ACTIVE_PAGE_NUM]];
	@$self[ARRAY_PAGE_BEG_IDX, ARRAY_PAGE_END_IDX] = ($page->[PAGE_INDEX], $page->[PAGE_INDEX] + $page->[PAGE_LENGTH] - 1);
	return @result;

}

sub new {
	my $class = shift;
	return $class->TIEARRAY(@_);
}

=pod

=head2 page_files

The C<page_files> method available on the I<tied> object returns the names of the page files belonging to the array. This can be used to I<freeze> the array and archive it along with its page files!

=cut

sub page_files {
	my $self = shift;
	return map { $_->[PAGE_FILE] } @{$self->[ARRAY_PAGE_BANK]};
}

# Private methods
sub _calc_page_offset {
    local($_);
    my ($self, $index) = @_;
    # Check if index requested is within active page's index range
    return ($self->[ARRAY_ACTIVE_PAGE_NUM], $index - $self->[ARRAY_PAGE_BEG_IDX])
		if ($index >= $self->[ARRAY_PAGE_BEG_IDX] && $index <= $self->[ARRAY_PAGE_END_IDX]);

    my $bank = $self->[ARRAY_PAGE_BANK];
    my $bank_len = @$bank;
    my ($pn, $page, $page_idx, $page_end_idx);
    for ($pn = 0; $pn < $bank_len; $pn++) {
		$page = $bank->[$pn];
		$page_end_idx = ($page_idx = $page->[PAGE_INDEX]) + $page->[PAGE_LENGTH] - 1;
		return ($pn, $index - $page_idx) if ($index >= $page_idx && $index <= $page_end_idx);
    }

    my $std_page_size = $self->[ARRAY_PAGE_SIZE];

    # Empty array!
    return (int($index / $std_page_size), $index % $std_page_size) if !defined($page);

    ### If index requested is out of bounds ###

    # Last page starts out with a standard size
    $index -= $page_idx;
    return ($pn - 1, $index) if ($index < $std_page_size);

    $index -= $std_page_size;
    return ($pn + int($index / $std_page_size), $index % $std_page_size);
}

sub _switch_to_page {
	my ($self, $page_num) = @_;
	local($_);

	my $active_page_num = $self->[ARRAY_ACTIVE_PAGE_NUM];
	my $page_bank = $self->[ARRAY_PAGE_BANK];

	# Handle empty array
	if ($#$page_bank < 0) {
		@$self[ARRAY_ACTIVE_PAGE_NUM, ARRAY_PAGE_BEG_IDX, ARRAY_PAGE_END_IDX] = (-1, 0, -1);
		return undef;
	}

	# If active page num is not outside the valid range
	if ($active_page_num > -1 && $active_page_num <= $#{$self->[ARRAY_PAGE_BANK]}) {
		my $page = $page_bank->[$active_page_num];
		my $rc = 1;
		if ($page->[PAGE_DIRTY]) {
			# Write the data to the page file
			$rc = _store($page->[PAGE_DATA], $page->[PAGE_FILE]);
			die "Could not write data to page file" unless $rc;
			$page->[PAGE_DATA] = [];
			$page->[PAGE_DIRTY] = undef;
		}
	}

	# Switch to page
	my $page = $page_bank->[$page_num];
	my $page_file = $page->[PAGE_FILE];
	my $page_data = [];
	$page_data = _retrieve($page_file) if defined($page_file) && -f $page_file;

	$page->[PAGE_DATA] = $page_data;
	$page->[PAGE_DIRTY] = undef;
	$self->[ARRAY_ACTIVE_PAGE_NUM] = $page_num;
	@$self[ARRAY_PAGE_BEG_IDX, ARRAY_PAGE_END_IDX] =
		($page->[PAGE_INDEX], $page->[PAGE_INDEX] + $page->[PAGE_LENGTH] - 1);

	return($page_data ? $page : undef);
}

sub _new_page {
	my ($self) = @_;

	#      [PAGE_DATA, PAGE_LENGTH, PAGE_DIRTY, PAGE_FILE, PAGE_INDEX]
	return [[]       , 0          , 1         , sprintf("%s/arr_%i_%i_%i.pg", $self->[ARRAY_PAGING_DIR], $self, $$, $PAGE_NUM++)];
}

sub _calc_length {
	my ($self) = @_;

	# Setup array length and first index in the array for each page
	my $len = 0;
	foreach (@{$self->[ARRAY_PAGE_BANK]}) {
			$_->[PAGE_INDEX] = $len;
			$len += $_->[PAGE_LENGTH];
	}

	return $len;
}

sub _store {
	my ($data, $page_file) = @_;
	$STORE_DELEGATE->($data, $page_file);
}

sub _retrieve {
	my ($page_file) = @_;
	$RETRIEVE_DELEGATE->($page_file);
}

1;

=head1 LIMITATIONS

1) C<foreach> loop must not be used on C<Tie::PagedArray>s because the array in foreach expands into an in-memory list. Instead, use iterative loops.

  for(my $i = 0; $i < scalar(@large_array); $i++) {
    # Do something with $large_array[$i]
  }

  OR

  # In versions 5.012 and later
  while(my($i, $val) = each(@large_array)) {
    # Do something with $val
  }


2) When an update is made to an element's I<nested> datastructure then the corresponding page is not marked dirty as it is difficult to track such updates.

Suppose C<page_size =E<gt> 1> and hash refs are stored as elements in the array.

  @car_parts = ({name => "wheel", count => 4}, {name => "lamp", count => 8});

Then an update to I<count> will B<not mark> the page dirty. When the page is later switched out the modification would be lost!

  $car_parts[1]->{count} = 6;

The workaround is to assign the element to itself.

  $car_parts[1] = $car_parts[1];


3) When an object is assigned to two elements in I<different> pages they point to two independent objects.

Suppose C<page_size =E<gt> 2>, then

  my $wheel = {name => "wheel", count => 4};

  @car_parts = ($wheel, $wheel, $wheel);

  print($car_parts[0] == $car_parts[1] ? "Same object\n" : "Independent objects\n");
  Same object

  print($car_parts[0] == $car_parts[1] ? "Same object\n" : "Independent objects\n");
  Independent objects

=pod

=head1 BUGS

None known.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::PagedArray

=head1 AUTHOR

Kartik Bherin

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Kartik Bherin.

=cut
