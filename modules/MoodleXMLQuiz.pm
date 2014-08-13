## @file
# This file contains the implementation of the Moodle quiz XML export loader.
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
package MoodleXMLQuiz;

use v5.12;
use XML::Simple;

# ============================================================================
#  Constructor

## @cmethod $ new(%args)
# Construct a new MoodleXMLQuiz object to handle loading of Moodle
# quiz XML exports.
#
# @param args A hash of values to initialise the object with.
# @return A new MoodleXMLQuiz object.
sub new {
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my $self     = { errstr => '',
                     @_
    };

    return bless $self, $class;
}


# ============================================================================
#  Loader code

## @method $ load_quiz($xmlfile)
# Load the moodle quiz from the specified xml file into a hash.
#
# @param xmlfile The name of the XMl file to load.
# @return A reference to a hash containing the XML data on success, undef on error.
sub load_quiz {
    my $self    = shift;
    my $xmlfile = shift;

    $self -> clear_error();

    my $quizdata = eval { XMLin($xmlfile, KeepRoot => 0); };
    return $self -> self_error("Quiz file loading failed for $xmlfile: $@")
        if($@);

    return $quizdata;
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
