package Finance::Shares::Log;
use strict;
use warnings;
use File::Spec;
use Date::Pcalc qw(:all);
require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    today_as_days today_as_string
    string_from_days days_from_string
    ymd_from_days days_from_ymd
    ymd_from_string string_from_ymd
    increment_date
    expand_tilde check_file fetch_line);

our %EXPORT_TAGS =( 
    date    => [ qw(today_as_days today_as_string
		    string_from_days days_from_string
		    ymd_from_days days_from_ymd
		    ymd_from_string string_from_ymd
		    increment_date) ],
    file    => [ qw(expand_tilde check_file
		    fetch_line) ] );

 sub today_as_days ();
 sub today_as_string ();
 sub string_from_days ($);
 sub days_from_string ($);
 sub ymd_from_days ($);
 sub days_from_ymd (@);
 sub ymd_from_string ($);
 sub string_from_ymd (@);
 sub increment_date ($$);
 
 sub expand_tilde ($); 
 sub check_file ($;$);
 sub fetch_line ($);

our $VERSION = '0.03';

=head1 NAME

Finance::Shares::Log - Keep track of activity in Finance::Share modules

=head1 SYNOPSIS

This module houses three groups of functions.  The main object handles Log files.  Exported functions are provided
that assist with date and file handling.

    use Finance::Shares::Log qw(:date :file);

    use Finance::Shares::Log qw(
	    today_as_days
	    today_as_string
	    days_from_time
	    time_from_days
	    string_from_days
	    days_from_string
	    ymd_from_days
	    days_from_ymd
	    ymd_from_string
	    string_from_ymd
	    expand_tilde
	    check_file
	    fetch_line
	);

=head2 Log methods

The simplest usage sends messages to a specified file.  Sending a message with level 0 is equivalent to the
builtin C<die>.

    my $lf = Finance::Shares::Log->new("logfile.txt");
    $lf->log(1, $message);
    $lf->log(0, $fatal_message);

This can be expanded by adding C<level()> and C<file()>.

    my $lf = Finance::Shares::Log->new();
    $lf->file("myprog.log", "~/logs");
    $lf->level(5);
    $lf->log(5, "This message gets through");
    $lf->log(6, "While this is ignored");

Although the main uses are given above, lower level access is available.

    my $lf = Finance::Shares::Log->new();
    $lf->open("~/myprog.log");
    $lf->print("Own level monitoring") unless ($lf->level() > 2);
    my using_file = $lf->is_file();
    my open_file = $lf->is_open();
    $lf->close();

Frills include the ability to duplicate log entries allowing multiple destinations, as well as logging in
simulated time.

    my $l1 = new Finance::Shares::Log('main.log');
    my $l2 = new Finance::Shares::Log('second.log');
    $l1->copy_to( $l2 );
    $l1->copy_remove( $l2 );

    $l1->tick( $my_date );
    
=head2 Date functions

    $days = today_as_days();
    $date = today_as_string();

    $days = days_from_time( $time );
    $time = time_from_days( $days );

    $date = string_from_days( $days );
    $days = days_from_string( $date );

    ($year, $month, $day) = ymd_from_days( $days );
    $days = days_from_ymd( $year, $month, $day );
    ($year, $month, $day) = ymd_from_string( $date );
    $date = string_from_ymd( $year, $month, $day );

=head2 File functions
    
    $abs_file = check_file( $rel_file );
    $abs_file = check_file( $abs_file );
    $abs_file = check_file( $file, $rel_dir );
    $abs_file = check_file( $file, $abs_dir );
    $abs_file = check_file( $rel_file, $abs_dir );

    $abs_file = expand_tilde( $shell_name );

    $line = fetch_line( FILE_HANDLE );

=head1 DESCRIPTION

A centralized logging system is used to keep track of which stock prices are fetched from the internet and what
processing has been done on them.  It is possible to route messages to any number of destinations.

Example

    my $l1 = new Finance::Shares::Log();
    my $l2 = new Finance::Shares::Log('debug.log');
    my $l3 = new Finance::Shares::Log('shares.log');
    $l1->copy_to( $l2 );
    $l1->copy_to( $l3 );
    
    $l1->level(99);
    $l2->level(5);
    $l3->level(1);
    
    $l1->log(1, "hello");
    $l1->log(4, "something wrong?");

'Hello' would appear on the console from $1 as well as being written to the other two files.  The second message
will go to all except 'shares.log'.
    
=cut

=head1 CONSTRUCTOR

=cut

sub new {
    my ($class, $file, $dir, $level) = @_;
    $level = 2 unless (defined $level);
    my $o = {};
    bless( $o, $class );
    
    $o->{logfile} = check_file($file, $dir);
    if (defined($file)) {
	$o->{fh} = 0;
	$o->{isfile} = 1;
    } else {
	$o->{fh} = *STDERR;
	$o->{isfile} = 0;
    }
    $o->{level} = $level;
    
    return $o;
}

=head2 new( [file, [dir, [level]]] )

=over 8

=item file

An optional fully qualified path-and-file, a simple file name, or "" for null device.

=item dir

An optional directory.  If present (and C<file> is not already an absolute path), it is prepended to
C<file>.

=item level

The logging threshold.  Messages with numbers greater than this will be ignored. (Default: 2)

=back

Create a new log object.  If C<filename> already exists, logging will just be appended.  Any leading '~' is
expanded, otherwise any arguments are handled using L<File::Spec|File::Spec> so should be portable.

Logged data will be sent to STDOUT if no file is given.  If C<file> is given the value "", all logged data is
suppressed.

=cut

=head1 OBJECT METHODS

=cut

sub log {
    my ($o, $priority, @params) = @_;
    if ($priority <= $o->{level}) {
	$o->open( $o->{file} );
	$o->print( @params );
	$o->print("Stopped") if ($priority == 0);
	$o->close();
    }
    
    if (defined $o->{copy}) {
	for (my $i = 0; $i <= $#{$o->{copy}}; $i++) {
	    my $other = $o->{copy}[$i];
	    $other->log($priority, @params) if defined $other;
	}
    }
    
    die (join(' ', @params), "\nStopped") if ($priority == 0);
}

=head2 log( priority, string_or_array )

=over 8

=item priority

This is compared with the value passed to C<level()> to determine whether the data gets logged or ignored.  Higher
numbers should be used for greater detail; lower numbers for messages that are more important.  A value of '0'
signifies a fatal error message - the method calls C<die>.

=item string_or_array

The data to be sent to the log.  A timestamp and a trailing "\n" will be added.

=back

The main logging function.  This opens the file, send the data to it and closes it again (if necessary).  Use the
lower level C<print()> method if this proves inappropriate.

=cut

=head1 ACCESS METHODS

=cut

sub file {
    my ($o, $file, $dir) = @_;
    if (defined $file) {
	$o->open($file, $dir);
	$o->close();
    }
    return $o->{isfile} ? $o->{logfile} : ();
}

=head2 file( [file [, dir]] )

=over 8

=item file

An optional fully qualified path-and-file, a simple file name, or "" for null device.

=item dir

An optional directory.  If present (and C<file> is not already an absolute path), it is prepended to
C<file>.

=back

Specify the file to use.  If it doesn't already exist, it is created.  With no arguments, this redirects output to
STDERR, while "" is interpreted as the NULL device.

Returns the name of the log file.

=cut

sub level {
    my ($o, $level) = @_;
    $o->{level} = $level if (defined($level) and $level >= 0);
    return $o->{level};
}

=head2 level( [level] )

C<level> should be a number 0 or greater.  Data sent to C<log()> with a number less than or equal to this will be
output.  Messages with levels greater than this will be suppressed.

A level of 0 supresses all except fatal messages.

Returns the priority threshold.

=cut

sub copy_to {
    my ($o, $other) = @_;
    if (ref($other) eq 'Finance::Shares::Log') {
	$o->{copy} = [] unless defined $o->{copy};
	push @{$o->{copy}}, $other;
    }
}

=head2 copy_to( other_log )

Register another log which will receive copies of all B<log> calls made to this object.  C<other_log> must be
another Finance::Shares::Log object.

=cut

sub copy_remove {
    my ($o, $other) = @_;
    if (defined $o->{copy}) {
	for (my $i = 0; $i <= $#{$o->{copy}}; $i++) {
	    delete $o->{copy}[$i] if ($o->{copy}[$i] == $other);
	}
    }
}

=head2 copy_remove( other_log )

Stop B<log> calls being copied to the Finance::Shares::Log object previously registered with B<copy_to>.

=cut

sub tick {
    my ($o, $prompt) = @_;
    $o->{prompt} = $prompt;
}

=head2 tick( prompt )

Messages are prefixed by a timestamp by default.  This method allows logging of simulated time.  Calling B<tick>
with a suitable string such as a date, registers that as the prefix to use.  All B<log> messages will use that
until another B<tick> is called.

Setting C<prompt> to false ('' or 0) restores the automatic timestamp.

=cut

=head1 SUPPORT METHODS

=cut

sub open {
    my ($o, $file, $dir) = @_;
    return if ($o->{isfile} and $o->{fh});

    $o->{logfile} = check_file($file, $dir) if (defined($file));
    if (defined($o->{logfile})) {
	$o->{isfile} = 1;
	CORE::open (FILE, ">>", $o->{logfile}) 
	    or die "Unable to open \'$o->{logfile}\' for writing : $!\nStopped";
	$o->{fh} = *FILE;
    } else {
	$o->{isfile} = 0;
	$o->{fh} = *STDERR;
    }
}

=head2 open( [file, [dir]] )

=over 8

=item file

An optional fully qualified path-and-file, a simple file name, or "" for null device.

=item dir

An optional directory C<dir>.  If present (and C<file> is not already an absolute path), it is prepended to
C<file>.

=back

If a file has been given, an attempt is made to open it for appending data.  The special name "" sends all logged
data to /dev/null.  Alternatively, if the file is a handle such as C<STDOOUT>, the data will be sent there.
The method either dies (if no file has been specified or it cannot be opened) or data may be written.

=cut

sub is_open {
    my $o = shift;
    return ($o->{fh} ? 1 : 0);
}

=head2 is_open()

Return C<true> if the log file is open.

=cut

sub is_file {
    my $o = shift;
    return $o->{isfile};
}

=head2 is_file()

Return C<true> if the log file is an actual file.

=cut

sub close {
    my $o = shift;
    if ($o->{isfile} && $o->{fh}) {
	CORE::close $o->{fh};
	$o->{fh} = 0;
    }
}

=head2 close()

Closes the log file.

=cut

sub print {
    my ($o, @params) = @_;
    my $timestamp = $o->{prompt} || CORE::localtime();
    print {$o->{fh}} "${timestamp}: ", @params, "\n" if $o->{fh};
}

=head2 print( string_or_array )

Unlike the builtin C<print>, a timestamp is output before the parameter(s) and a "\n" is added on the end.

C<open()> must have been called beforehand, and C<close()> should be called after the printing is done.

=cut

### EXPORTED FUNCTIONS

=head1 DATE FUNCTIONS

There are three types of dates here.  A 'days' value is the number of days from some arbitrary day zero.  A 'date'
is a string in YYYY-MM-DD format while 'ymd' refers to an array holding a year, month and day such as (2002, 12,
31).  See L<SYNOPSIS> for all the functions.

All the work is done by David Eisenberg's Date::Pcalc module.  These function just provide an interface convenient
for the Finance::Shares modules.

=cut

sub today_as_days () {
    return Date_to_Days( Today() );
}

=head2 today_as_days

Return the number of days in the date, as used by Date::Pcalc.

=cut

sub today_as_string () {
    return string_from_days( today_as_days() );
}

=head2 today_as_string

Return today's date in YYYY-MM-DD format.

=cut

sub string_from_days ($) {
    my $days = shift;
    my ($year, $month, $day) = Add_Delta_Days(1,1,1, $days - 1);
    return sprintf("%04d-%02d-%02d", $year, $month, $day);
}

=head2 string_from_days( days )

Convert the number of Date::Pcalc days into YYYY-MM-DD format.

=cut

sub days_from_string ($) {
    my $string = shift;
    my @date = ($string =~ /(\d{4})-(\d{2})-(\d{2})/);
    return Date_to_Days(@date) if (@date == 3);
}

=head2 days_from_string ( date )

Convert a YYYY-MM-DD date into a number of days, as used by Date::Pcalc.

=cut

sub days_from_ymd (@) {
    return Date_to_Days(@_) if (@_ == 3);
}

=head2 days_from_ymd( year, month, day )

Convert the numeric year, month and day date into Date::Pcalc days.

=cut

sub ymd_from_days ($) {
    my $days = shift;
    return Add_Delta_Days(1,1,1, $days - 1);
}

=head2 ymd_from_days( days )

Convert the number of Date::Pcalc days into an array of numeric values in the form:

    (year, month, day)

=cut

sub string_from_ymd (@) {
    return sprintf("%04d-%02d-%02d", @_);
}

=head2 string_from_ymd( year, month, day )

Convert the numeric representation of year, month and day into a YYYY-MM-DD date.

=cut

sub ymd_from_string ($) {
    my $string = shift;
    return ($string =~ /(\d{4})-(\d{2})-(\d{2})/);
}

=head2 ymd_from_string( date )

Convert a YYYY-MM-DD date into an array of numeric values in the form:

    (year, month, day)

=cut

sub increment_date ($$) {
    my ($string, $days) = @_;
    my @date = ymd_from_string( $string );
    my @newdate = Add_Delta_Days( @date, $days );
    return string_from_ymd( @newdate );
}

=head2 increment_date( date, days )

Add the number of days given to the YYYY-MM-DD date and return the new date in YYYY-MM-DD format.

=cut

=head1 FILE FUNCTIONS

=cut

sub check_file ($;$) {
    my ($filename, $dir) = @_;
   
    if (defined($filename)) {
	if ($filename eq "") {
	    $filename = File::Spec->devnull();
	} else {
	    $filename = expand_tilde($filename);
	    $filename = File::Spec->canonpath($filename);
	    unless (File::Spec->file_name_is_absolute($filename)) {
		if (defined($dir)) {
		    $dir = expand_tilde($dir);
		    $dir = File::Spec->canonpath($dir);
		    $dir = File::Spec->rel2abs($dir) unless (File::Spec->file_name_is_absolute($dir));
		    $filename = File::Spec->catfile($dir, $filename);
		} else {
		    $filename = File::Spec->rel2abs($filename);
		}
	    }

	    my @subdirs = ();
	    my ($volume, $directories, $file) = File::Spec->splitpath($filename);
	    @subdirs = File::Spec->splitdir( $directories );

	    my $path = $volume;
	    foreach my $dir (@subdirs) {
		$path = File::Spec->catdir( $path, $dir );
		mkdir $path unless (-d $path);
	    }
	    
	    $filename = File::Spec->catfile($path, $file);
	    unless (-e $filename) {
		CORE::open(FILE, ">", $filename) or die "Unable to open \'$filename\' for writing : $!\nStopped";
		CORE::close FILE;
	    }
	}
    }

    return $filename;
}

=head2 check_file( file, [dir] )

=over 8

=item file

An optional fully qualified path-and-file, a simple file name, or "".

=item dir

An optional directory C<dir>.  If present (and C<file> is not already an absolute path), it is prepended to
C<file>.

=back

If no directory is given either way, the current directory is assumed.  Any leading '~' is expanded
to the users home directory, and the file is created (with any intervening directories) if it doesn't exist. 

If C<file> is given "" the special file File::Spec->devnull() is returned.

L<File::Spec|File::Spec> is used throughout so file access should be portable.  

=cut

sub expand_tilde ($) {
    my ($dir) = @_;
    $dir = "" unless $dir;
    $dir =~ s{^~([^/]*)}{$1 ? (getpwnam($1))[7] : ($ENV{HOME} || $ENV{LOGDIR} || (getpwuid($>))[7]) }ex;
    return $dir;
}

=head2 expand_tilde( dir )

Expands any leading '~' to the home directory.

=cut

sub fetch_line ($) {
    my ($fh) = @_;
    my $line;
    while ( <$fh> ) {
	next if /^\s*#/;
	next if /^\s*$/;
	chomp;
	s/^\s*//;
	s/\s*$//;
	return $_;
    }
    return "";
}

=head2 fetch_line( FILE_HANDLE )

Return the next line of data from an open file.  Blank lines and '#' comments are skipped and leading and trailing
space is removed.

=cut

=head1 BUGS

Please report those you find to the author.

=head1 AUTHOR

Chris Willmot, chris@willmot.co.uk

=head1 SEE ALSO

L<Finance::Shares::MySQL> and
L<Finance::Shares::Sample>.

=cut

1;
