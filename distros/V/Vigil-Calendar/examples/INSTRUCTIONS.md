
INSTRUCTIONS.md

# MANIFEST /examples

    examples/
        │   :... -calendar.lib
        │
        ├─ agenda_html/
        │             :... -cal_agenda_html.pl
        │             :... -calendar.lib
        │             :... -calendar_css.pl
        │             :... -demo_calendar.css
        │
        ├─ agenda_pdf/
        │            :... -cal_agenda_pdf.pl
        │            :... -calendar.lib
        │
        ├─ agenda_text/
        │             :... -cal_agenda_text.pl
        │             :... -calendar.lib
        │
        ├─ css/
	    │     :... -calendar.css
        │     :... -calendar.css.backup
        │
        ├─ grid_html/
        │           :... -cal_grid_html.pl
        │           :... -calendar.lib
        │           :... -calendar_css.pl
        │           :... -demo_calendar.css
        │           :... -demo_small_calendar.css
        │
        └─ grid_pdf/
                   :... -cal_grid_pdf.pl
                   :... -calendar.lib

# DESCRIPTION
These files are provided so that you can rapidly develop and delploy
content using Vigil::Calendar. There IS a bit of a learning curve,
but with an hour's work you can be a master of generating calendars.

I have provided two HTML examples, two PDF examples using PDF::API2,
and one text only version.

## AGENDA

An agenda view is a list of dates with content. Only days with content
are listed. The scripts are written to always display X number of days
worth of content. The demo scripts all have three months worth of display
data. If you go beyond those months, no data will show. However, if
you go to previous months, no matter how far back you go, the data will
still show. This is because the script is written to always display X days
of data, so it keeps iterating until if finds data (up to 365 days).

## GRID
The grid view is a traditional calendar of 7 columns and 4, 5, or 6 rows.

The demo script for the HTML grid has two calendars on the page. This is
to demonstrate the flexibility of the dynamic CSS solution that I implemented
for this project/demonstration.

## PDF DEMOS
For the PDF demonstrations, you must run these scripts from the command line (CLI).

To do this, you will need to have Perl installed on your computer. After you
have perl installed, you will also need PDF::API2 which can be installed on
your CLI with:

	>cpan PDF::API2

When you run the script, the PDF will be opened by the system automatically. To do
so, you will need a way to view PDFs installed on your system. This could be as
simple as Chrome or Edge which open PDFs, or, e.g. Adobe Acrobat Reader, Foxit,
Preview (MacOS), etc.

## DYNAMIC CSS Files
In the CSS files are verbose instructions for you, but here is the overview of how
the dynamic CSS file system works.

The calendars have a hierarchical structure of class names to apply styling. These
are designed so that there is a logical progression within each item that has 
classes.

### HTML AGENDA
Here is an example of this hierarchical nature for the agenda calendars:

	<PREFIX>-agenda-day-all {}                       This styling applies to all day fields in the agenda.
	--<prefix>-agenda-day-even {}                    This will modify styling on all even days
	----<prefix>-agenda-day-thu {}                   This will modify styling on all thursdays
    ------<prefix>-agenda-day-today {}               This will modify styling if that item is the same day as TODAY for the viewer
    --------<prefix>-agenda-day-date-2025-09-18 {}   This will modify styling for a specific date, and must be added manually to the file.

Here is the actual HTML that the library uses to deliver the agenda days:

	  <div class="<prefix>-agenda-wrapper">
	:Repeating Starts
		<!-- Left column: Date info -->
		<div class="<prefix>-agenda-dateinfo-all <prefix>-agenda-dateinfo-even <prefix>-agenda-dateinfo-fri <prefix>-agenda-dateinfo-today <prefix>-agenda-dateinfo-date-2025-09-12">
		  <div class="<prefix>-agenda-dateinfo-name-all <prefix>-agenda-dateinfo-name-even <prefix>-agenda-dateinfo-name-fri <prefix>-agenda-dateinfo-name-today <prefix>-agenda-dateinfo-name-date-2025-09-12">Friday</div>
		  <div class="<prefix>-agenda-dateinfo-number-all <prefix>-agenda-dateinfo-number-even <prefix>-agenda-dateinfo-number-fri <prefix>-agenda-dateinfo-number-today <prefix>-agenda-dateinfo-number-date-2025-09-12">12<span class="superscript">th</span></div>
		  <div class="<prefix>-agenda-dateinfo-monthyear-all <prefix>-agenda-dateinfo-monthyear-even <prefix>-agenda-dateinfo-monthyear-fri <prefix>-agenda-dateinfo-monthyear-today <prefix>-agenda-dateinfo-monthyear-date-2025-09-12">September, 2025</div>
		</div>
		<!-- Right column: User content -->
		<div class="<prefix>-agenda-content-all <prefix>-agenda-content-even <prefix>-agenda-content-fri <prefix>-agenda-content-today <prefix>-agenda-content-date-2025-11-15">
		  <!-- Start User Content// -->
		    Foo
		  <!-- //End User Content -->
		</div>
	:Repeating ends
	  </div>
	  
The output will resemble this:


    (Agenda wrapper will hold all the divs: <PREFIX>-agenda-wrapper {} )
	
         ╔═══════════╤══════════════════════════════════════════════╗
         ║ Thursday  │ (1) Item                                     ║
         ║    18     │ (2) Item                                     ║
         ║ Sept,2025 │                                              ║
         ╚═══════════╧══════════════════════════════════════════════╝
    
	-The whole output is:      <PREFIX>-agenda-day
    -The box with the date is: <PREFIX>-agenda-dateinfo
    -The name of the day is:   <PREFIX>-agenda-dateinfo-name
	-The date number is:       <PREFIX>-agenda-dateinfo-number
	-The date month & year is: <prefix>-agenda-dateinfo-monthyear
	-The right side box is:    <PREFIX>-agenda-content
	
	Each one of these sections of the display are expanded to offer styling for:

		-all {}
		-odd {}
		-even {}
		-mon {}
		-tue {}
		-wed {}
		-thu {}
		-fri {}
		-sat {]
		-today {}
		-date-YYYY-MM-DD {}

### HTML Grid

This works exactly the same as the agenda CSS. The difference is the hierarchy of
class names. With a grid display, columns and rows are at the top of the list. In
developing this, one of them had to become the alpha, so I arbitrarily chose the
columns for this.

This means that if you style rows, columns will override them. If you style columns,
then the individual day parts will override them.

The order of stylings for HTML grids is as follows (Those on the bottom of the list
will override those above them):

<PREFIX>-table

<PREFIX>-dayname-*
This only affects the row at the top of the calendar with the names of the days. It
will modify anything in the class above it.

<PREFIX>-row-*
Row is used to affect all rows, all odd rows, and all even rows. It will modify
anything in the classes above it.

<PREFIX>-week-*
Week is used to affect the individual physical rows of the calendar. The 1st of the
month is always row 1. It will modify anything in the classes above it.

<PREFIX>-col-*
The columns styling does not include the row with the names of the days. It will
modify anything in the classes above it.

<PREFIX>-curr-day-*
<PREFIX>-prev-day-*
<PREFIX>-next-day-*
These columns separate out days of the previous month and the current month. These
three will never overlap. They will modify anything in the classes above them.

<PREFIX>-curr-daynum-*
<PREFIX>-prev-daynum-*
<PREFIX>-next-daynum-*
These apply the the date number that shows up in each day's cell. It separates out
days of the previous month and the current month. These three will never overlap.
They will modify anything in the classes above them.

#### Current Day Styling

Previous and next days (from the previous and next month) can each take up from none to six
days of the week. Therefore, they can overlap the column stylings.
	<PREFIX>-prev-day-*
	<PREFIX>-next-day-*
These two include -all, -odd, -even, -mon, -tue, -wed, -thu, -fri, -sat, -today, -date-YYYY-MM-DD

The current day of the week is, inherently, the same as the columns. It only has one styling class:

	<PREFIX>-curr-day-today

### Targeted Date Styling

You can target specific days in the agenda or grid view by creating a class for it's date. To do this
you append '-date-YYYY-MM-DD' to the classname root, e.g.

	<PREFIX>-curr-day {} becomes <PREFIX>-curr-day-date-2025-09-18 {}

In the grid view CSS, day and daynum support this date targeting.

In the agenda view CSS, all of the class groups support the date targeting.

To create a date targeted styling, take the root of the class name and append '-date-YYYY-MM-DD'

e.g.:

    GRID view

        Root: <PREFIX>-curr-day
    Targeted: <PREFIX>-curr-day-date-YYYY-MM-DD

        Root: <PREFIX>-prev-day
    Targeted: <PREFIX>-prev-day-date-YYYY-MM-DD

        Root: <PREFIX>-next-day
    Targeted: <PREFIX>-next-day-date-YYYY-MM-DD

        Root: <PREFIX>-curr-daynum
    Targeted: <PREFIX>-curr-daynum-date-YYYY-MM-DD

        Root: <PREFIX>-prev-daynum
    Targeted: <PREFIX>-prev-daynum-date-YYYY-MM-DD

        Root: <PREFIX>-next-daynum
    Targeted: <PREFIX>-next-daynum-date-YYYY-MM-DD

    AGENDA view:

        Root: <prefix>-agenda-day
    Targeted: <prefix>-agenda-day-date-2025-09-18 {}

        Root: <prefix>-agenda-date-info
    Targeted: <prefix>-agenda-date-info-date-2025-09-18 {}

        Root: <prefix>-agenda-dateinfo-name
    Targeted: <prefix>-agenda-dateinfo-name-date-2025-09-18 {}

        Root: <prefix>-agenda-dateinfo-number
    Targeted: <prefix>-agenda-dateinfo-number-date-2025-09-18 }

        Root: <prefix>-agenda-dateinfo-monthyear
    Targeted: <prefix>-agenda-dateinfo-monthyear-date-2025-09-18 {}

        Root: <prefix>-agenda-content
    Targeted: <prefix>-agenda-content-date-2025-09-09 {}


