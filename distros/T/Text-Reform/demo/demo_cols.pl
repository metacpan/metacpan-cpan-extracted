#! /usr/bin/perl -w

use Text::Reform;

# Easy when data already in columns...

@name  = qw(Tom Dick Harry);
@score = qw( 88   54    99);
@time  = qw( 15   13    18);

print form
'-----------------------------',   
'Name             Score   Time',   
'-----------------------------',   
'[[[[[[[[[[[[[[   |||||   ||||',
\@name,          \@score,\@time;

print "\n"x2;

# Not so easy when data in rows...

@data = (
	{ name=>'Tom',   score=>88, time=>15 },
	{ name=>'Dick',  score=>54, time=>13 },
	{ name=>'Harry', score=>99, time=>18 },
);


# The ugly way...

print form
'-----------------------------',   
'Name             Score   Time',   
'-----------------------------',   
'[[[[[[[[[[[[[[   |||||   ||||',
[map $$_{name},  @data],
[map $$_{score}, @data],
[map $$_{time} , @data];

print "\n"x2;

# The nice way...

print form
'-----------------------------',   
'Name             Score   Time',   
'-----------------------------',   
'[[[[[[[[[[[[[[   |||||   ||||',
{ cols => [qw(name score time)],
  from => \@data
};


@data = (
	[ 15, 'Tom',   88 ],
	[ 13, 'Dick',  54 ],
	[ 18, 'Harry', 99 ],
);

print "\n"x2;


# Works for arrays too...

print form
'-----------------------------',
'Name             Score   Time',   
'-----------------------------',   
'[[[[[[[[[[[[[[   |||||   ||||',
{ cols=>[1,2,0], from=>\@data };
