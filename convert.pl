#!/usr/bin/perl

## @file
# This file contains the moodle quiz export to blackboard import tool.
#
##
# @author  Chris Page &lt;chris@starforge.co.uk&gt;

use utf8;
use v5.12;
use FindBin;

# Work out where the script is, so module and resource loading can work.
my $scriptpath;
BEGIN {
    # This handles tainting, horribly permissively
    if($FindBin::Bin =~ /^(.*)$/) {
        $scriptpath = $1;
    }
}

# Add the support modules to the load path
use lib "$scriptpath/modules";

# Custom modules to support conversion
use MoodleXMLQuiz;
use BlackboardTSVQuiz;

# Standard perl modules
use Getopt::Long;
use Pod::Usage;

# ============================================================================
#  Support functions

## @fn $ save_file($name, $data)
# Save the specified string into a file. This will attempt to open the specified
# file and write the string in the second argument into it, and the file will be
# truncated before writing.  This should be used for all file saves whenever
# possible to ensure there are no internal problems with UTF-8 encoding screwups.
#
# @param name The name of the file to load into memory.
# @param data The string, or string reference, to save into the file.
# @return undef on success, otherwise this dies with an error message.
# @note This function assumes that the data passed in the second argument is a string,
#       and it does not do any binmode shenanigans on the file. Expect it to break if
#       you pass it any kind of binary data, or use this on Windows.
sub save_file {
    my $name = shift;
    my $data = shift;

    if(open(OUTFILE, ">:utf8", $name)) {
        print OUTFILE ref($data) ? ${$data} : $data;

        close(OUTFILE)
            or die "FATAL: Unable to close $name after write: $!\n";

        return undef;
    }

    die "FATAL: Unable to open $name for writing: $!\n";
}


# ============================================================================
#  The code that actually Does Stuff.

# default setup variables
my $xmlfile = ''; # Where should the quiz be read from?
my $outfile = ''; # write the output to a file?
my $help    = 0;  # Show the help documentation
my $man     = 0;  # Print the full man page

GetOptions('q|quiz:s'   => \$xmlfile,
           'o|output:s' => \$outfile,
           'h|help|?'   => \$help,
           'm|man'      => \$man)
    or pod2usage(2);
pod2usage(-verbose => 1) if($help || (!$xmlfile && !$man));
pod2usage(-exitstatus => 0, -verbose => 2) if($man);

my $moodle     = MoodleXMLQuiz -> new();
my $blackboard = BlackboardTSVQuiz -> new();

my $quiz = $moodle -> load_quiz($xmlfile)
    or die "Quiz load failed: ".$moodle -> errstr()."\n";

# Go through each question in the quiz, converting to blackboard format
my $output = "";
foreach my $question (@{$quiz -> {"question"}}) {
    $output .= $blackboard -> moodle_to_blackboard($question);
}

# If the user has specified an output file, use that rather
# than printing to stdout.
if($outfile) {
    save_file($outfile, $output);
} else {
    binmode STDOUT,":utf8";
    print $output;
}
