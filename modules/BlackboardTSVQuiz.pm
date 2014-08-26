## @file
# This file contains the implementation of the Blackboard TSV generator.
#
# @author  Chris Page &lt;chris@starforge.co.uk&gt;
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

## @class
#
package BlackboardTSVQuiz;

use v5.12;
use XML::Simple;
use Data::Dumper;
# ============================================================================
#  Constructor

## @cmethod $ new(%args)
# Construct a new BlackboardTSVQuiz object to handle loading of Moodle
# quiz XML exports.
#
# @param args A hash of values to initialise the object with.
# @return A new BlackboardTSVQuiz object.
sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my $self     = { errstr => '',
                     @_
    };

    return bless $self, $class;
}


# ============================================================================
#  Converter code

## @method $ moodle_to_blackboard($question)
# Convert the question stored in the specified hash from Moodle format to
# a TSV line suitable to pass to Blackboard.
#
# @param question A reference to a hash containing the question information.
# @return A string containing the question in Blackboard TSV format, or
#         an empty string if the question can not be converted.
sub moodle_to_blackboard {
    my $self     = shift;
    my $question = shift;

    # Call the apprioriate handler for the question type
    # (this could be done with given/where, but v5.18/5.20 stupidity.
    if($question -> {"type"} eq "category") {
        # do nothing - silently skip categories
    } elsif($question -> {"type"} eq "multichoice") {
        return $self -> _mdl2bb_multichoice($question);
    } elsif($question -> {"type"} eq "shortanswer") {
        return $self -> _mdl2bb_shortanswer($question);
    } elsif($question -> {"type"} eq "essay") {
        return $self -> _mdl2bb_essay($question);
    } elsif($question -> {"type"} eq "truefalse") {
        return $self -> _mdl2bb_truefalse($question);
    } elsif($question -> {"type"} eq "matching") {
        return $self -> _mdl2bb_matching($question);

    } else {
        warn "Skipping question '".($question -> {"name"} -> {"text"} || "unknown")."': unsupported type '".$question -> {"type"}."'\n";
    }

    return "";
}


## @method private $ _mdl2bb_multichoice($question)
# Convert the question stored in the specified hash from Moodle format to
# a TSV line suitable to pass to Blackboard.
#
# @param question A reference to a hash containing the question information.
# @return A string containing the question in Blackboard TSV format
sub _mdl2bb_multichoice {
    my $self     = shift;
    my $question = shift;
    my $output   = "MC";

    # support multiselection
    $output = "MA"
        if($question -> {"single"} && $question -> {"single"} eq "false");

    # question text, should be html, so strip leading/trailing space and newlines
    $output .= "\t".$self -> _cleanup_newlines($question -> {"questiontext"} -> {"text"}, 0);

    my $gotcorrect = 0;
    foreach my $answer (@{$question -> {"answer"}}) {
        $output .= "\t".$self -> _cleanup_newlines($answer -> {"text"});
        if($answer -> {"fraction"} == 0) {
            $output .= "\tincorrect";
        } elsif($answer -> {"fraction"} == 100) {
            $output .= "\tcorrect";
            $gotcorrect = 1;
        } else {
            warn "Encountered unsupported fraction ".$answer -> {"fraction"}." for ".$question -> {"name"} -> {"text"}." answer ".$answer -> {"text"}.": using 'correct'\n";
            $output .= "\tincorrect";
        }
    }

    # Handle the situation where no correct answer has been set by
    # making the final 'incorrect' into a 'correct'
    $output =~ s/incorrect$/correct/
        unless($gotcorrect);

    return "$output\n";
}


## @method private $ _mdl2bb_shortanswer($question)
# Convert the question stored in the specified hash from Moodle format to
# a TSV line suitable to pass to Blackboard.
#
# @param question A reference to a hash containing the question information.
# @return A string containing the question in Blackboard TSV format
sub _mdl2bb_shortanswer {
    my $self     = shift;
    my $question = shift;
    my $output   = "SR";

    # question text, should be html, so strip leading/trailing space and newlines
    $output .= "\t".$self -> _cleanup_newlines($question -> {"questiontext"} -> {"text"}, 0);

    return "$output\n";
}


## @method private $ _mdl2bb_essay($question)
# Convert the question stored in the specified hash from Moodle format to
# a TSV line suitable to pass to Blackboard.
#
# @param question A reference to a hash containing the question information.
# @return A string containing the question in Blackboard TSV format
sub _mdl2bb_essay {
    my $self     = shift;
    my $question = shift;
    my $output   = "ESS";

    # question text, should be html, so strip leading/trailing space and newlines
    $output .= "\t".$self -> _cleanup_newlines($question -> {"questiontext"} -> {"text"}, 0);

    return "$output\n";
}


## @method private $ _mdl2bb_truefalse($question)
# Convert the question stored in the specified hash from Moodle format to
# a TSV line suitable to pass to Blackboard.
#
# @param question A reference to a hash containing the question information.
# @return A string containing the question in Blackboard TSV format
sub _mdl2bb_truefalse {
    my $self     = shift;
    my $question = shift;
    my $output   = "TF";

    # question text, should be html, so strip leading/trailing space and newlines
    $output .= "\t".$self -> _cleanup_newlines($question -> {"questiontext"} -> {"text"}, 0);

    my $truefalse = '';
    foreach my $answer (@{$question -> {"answer"}}) {
        # The correct answer should have fraction == 100 and the string "true" or "false"
        if($answer -> {"fraction"} == 100) {
            $truefalse = $answer -> {"text"};
            last;
        }
    }
    $output .= "\t".($truefalse || "false");

    return "$output\n";
}


## @method private $ _mdl2bb_matching($question)
# Convert the question stored in the specified hash from Moodle format to
# a TSV line suitable to pass to Blackboard.
#
# @param question A reference to a hash containing the question information.
# @return A string containing the question in Blackboard TSV format
sub _mdl2bb_matching {
    my $self     = shift;
    my $question = shift;
    my $output   = "ESS";

    # question text, should be html, so strip leading/trailing space and newlines
    $output .= "\t".$self -> _cleanup_newlines($question -> {"questiontext"} -> {"text"}, 0);

    foreach my $answer (@{$question -> {"subquestion"}}) {
        $output .= "\t".$self -> _cleanup_newlines($answer -> {"text"});
        $output .= "\t".$self -> _cleanup_newlines($answer -> {"answer"} -> {"text"});
    }

    return "$output\n";
}

# ============================================================================
#  Error functions

## @method private $ _cleanup_newlines($text, $addbr)
# Trim whitespace from around the specified text, and remove or replace any
# newlines with <br>
#
# @param text  The text to process.
# @param addbr If true (the default), replace newlines with <br/><br/>, otherwise
#              newlines are removed.
# @return A string containing the processed text.
sub _cleanup_newlines {
    my $self  = shift;
    my $text  = shift;
    my $addbr = shift;

    # Default to adding brs
    $addbr = 1 unless(defined($addbr));

    $text =~ s/^[\s\x{0d}\x{0a}\x{0c}]+//o;
    $text =~ s/[\s\x{0d}\x{0a}\x{0c}]+$//o;

    my $repl = $addbr ? "<br /><br />" : " ";
    $text =~ s/\r?\n/$repl/g;

    return $text;
}


# ============================================================================
#  Error functions

## @method private $ self_error($errstr)
# Set the object's errstr value to an error message, and return undef. This
# function supports error reporting in various methods throughout the class.
#
# @param errstr The error message to store in the object's errstr.
# @return Always returns undef.
sub self_error {
    my $self = shift;
    $self -> {"errstr"} = shift;

    return undef;
}


## @method private void clear_error()
# Clear the object's errstr value. This is a convenience function to help
# make the code a bit cleaner.
sub clear_error {
    my $self = shift;

    $self -> self_error(undef);
}


## @method $ errstr()
# Return the current value set in the object's errstr value. This is a
# convenience function to help make code a little cleaner.
sub errstr {
    my $self = shift;

    return $self -> {"errstr"};
}


1;
