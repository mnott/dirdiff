#!/bin/bash

###################################################
#
# Small helper shell script that will compare two
# directories and record the differences. See the
# usage function by calling without paramters.
# 
###################################################
#
# Dependencies:
# 
#  bash
#  cd
#  mkdir
#  diff
#  grep
#  sed
#  comm
#  sort
#   
###################################################
# (c) Matthias Nott, SAP. Licensed under WFTPL.
###################################################

LANG=C

###################################################
#
# Version of this script
#
####################################################

VERSION=1.0


###################################################
#
# Default Configurations (see usage function).
#
###################################################

#
# Directory to create with the differences
# 
TARGET=diffs

#
# Pattern of directories to compare
#
DIRPATTERN=".*"

#
# Pattern of files to combine
# 
FILEPATTERN=".*"

#
# Pattern of lines to exclude from combined files
# 
EXCLUDEPATTERN="^$"

#
# Name of combined files
# 
COMBINEDFILE="combined.txt"

#
# Logfile
#
LOGFILE=log.txt


###################################################
#
# Platform specific tweaks
#
###################################################

PLATFORM=$(uname)

#
# comm wants --nocheck-order on Linux
# 
COMMPARAMETERS=""

if [[ "$PLATFORM" == "Linux" ]]; then
  COMMPARAMETERS="--nocheck-order"
fi


###################################################
#
# Command Line
#
###################################################

COMMANDLINE="$0 $*"


###################################################
#
# Main Function
#
###################################################

main(){
	# Parse Arguments
  args "$@"

  # 
  # Check for input and output dirs
  #
  if [[ $ALL != "true" ]]; then
  	if [[ ! -d "$DIRA" ]]; then
  		echo Input Directory $DIRA not found.
  		exit 1;
  	fi
  	if [[ ! -d "$DIRB" ]]; then
  		echo Input Directory $DIRB not found.
  		exit 1;
  	fi
  fi

  #
  # Make output directory if needed
  #
  if [[ ! -d "$TARGET" ]]; then
  	log Making directory $TARGET
  	mkdir "$TARGET";
  else
  	log Directory $TARGET already exists, overwriting.
  fi

  if [[ $ALL == "true" ]]; then
  	p="";
  	for f in *; do
  		if [[ -d "$f" ]] && [[ "$f" != "$TARGET" ]] && [[ "$f" =~ $DIRPATTERN ]]; then
  			if [[ "$p" != "" ]]; then
  				_diff "$p" "$f";
  			fi
  			p="$f";
  		fi
  	done
  else
    _diff "$DIRA" "$DIRB"
  fi

  #
  # Save logfile
  # 
  if [[ -f "$LOGFILE" ]]; then
    mv "$LOGFILE" "$TARGET/$LOGFILE";
  fi
}


###################################################
#
# Diff two directories (TARGET is global)
#
###################################################

_diff() {
  FIRST="$1"
  SECOND="$2"

  log Comparing $FIRST with $SECOND

  if [[ ! -d "$TARGET/$SECOND" ]]; then
  	mkdir "$TARGET/$SECOND";
  fi

  # Copy over files that were newly created
  for i in $(diff -rquw "$FIRST" "$SECOND" | grep -i -E "^Only in" | sed -e "s/^Only in.*: \(.*\)/\1/"); do cp "$SECOND/$i" "$TARGET/$SECOND"; done

  # Copy over additions to existing files
  for i in $(diff -wuq "$FIRST" "$SECOND" | grep -i -E "^Files.*differ$" | sed -e "s/^Files $FIRST\/\(.*\) and .*/\1/"); do comm $COMMPARAMETERS -13 "$FIRST/$i" "$SECOND/$i" > "$TARGET/$SECOND/$i" ; done

  # If needed, combine
  if [[ $COMBINE == "true" ]]; then
  	(
  		cd "$TARGET/$SECOND"
  		# Assumptions:
  		# 
      # Procedure: We enter each target directory and look at each file that is
      # a file and not the combined file and corresponds to the file pattern.
      # This file we assume to have a file name that has an important part at
      # the beginning, followed by an underscore. We also assume that the file
      # contains lines that start with a timestamp like 2014/12/01, followed by
      # a |. We want to put the important part from the filename right after that,
      # followed by another |, and then the rest of the line. All other lines are
      # to be ignored. Also, we want to ignore all lines that match our exclude
      # pattern.
      # 
      # We could make the "important part" pattern of the filename configurable,
      # and likewise the structure of the lines, for our purpose, this very much
      # nails it.
  		# 
			for i in * ; do 
				if [[ -f "$i" ]] && [[ "$i" =~ $FILEPATTERN ]]; then 
					export p=$(
						echo $i \
						| sed -e "s/\([^_]*\)_.*/\1/"
					);
	  			cat "$i" \
	  			| grep -P "^\d\d\d\d/\d\d/\d\d.*" \
	  			| sed -e "s/\([^|]*\)\(.*\)/\1|$p\2/";
	  		fi
	 		done \
      | grep -v -P "$EXCLUDEPATTERN" \
      | sort >"../${SECOND}_$COMBINEDFILE"
  	)
  fi
}


###################################################
#
# Usage
#
###################################################

usage(){
cat <<EOF
---------------------------------------------------------------------------
$0 - Compare Log Directories.
---------------------------------------------------------------------------
It compares two directories,  dira and dirb,  and records their differences
into a directory diffs/dirb. Differences are either new files that appeared
in directory dirb which  had not yet been in dira, or lines in files  which
have been  added to  files in directory  dira. Optionally,  the program can
create a common file sorted by timestamp.

Usage: $0 [options] dira dirb

-h | --help         : Print this help.
-a | --all          : Work on all subdirs, except target dir
-t | --target       : Target directory name (default: diffs)
-c | --combine      : Create combined files
-e | --exclude      : Pattern for lines to exclude (default: none)
-v | --verbose      : Be verbose about what is done
-l | --logfile      : Logfile to use (default: log.txt)
-dp| --dirpattern   : Pattern of directories to compare (default: ".*")
-fp| --filepattern  : Pattern of files to combine (default: ".*")

Examples:

Compare the current subdirectories except $TARGET into $TARGET

  $0 -a

Same as before, but also create each a combined file

  $0 -a -c

Same as before, but specify some output directory outdir

  $0 -a -c -t outdir

Same as before, but also be a little verbose

  $0 -a -c -t outdir -v

Same as before, but using only directories with an underscore

  $0 -a -c -t outdir -v -dp _

Same as before, but combining only files ending with log

  $0 -a -c -t outdir -v -dp _ -fp 'log$'

Same as before, but combining only files starting with CMS and crcache,
ending with log

  $0 -a -c -t outdir -v -dp _ -fp '^(CMS|crcache).*log$'

Same as before, but combining only files starting with CMS and crcache,
ending with log and excluding lines containing GetObjectInternal or
FilterElementsInSet

  $0 -a -c -t outdir -v -dp _ -fp '^(CMS|crcache).*log$' -e '(GetObjectInternal|FilterElementsInSet)'

Same as before, but combining into file workflow.txt

  $0 -a -c -t outdir -v -dp _ -fp '^(CMS|crcache).*log$' -e '(GetObjectInternal|FilterElementsInSet)' -cf workflow.txt


EOF
}


###################################################
#
# Parameter Parsing
#
###################################################

args(){
  if [[ "$1" =~ ^((-{1,2})([Hh]$|[Hh][Ee][Ll][Pp])|)$ ]]; then
    usage; exit 1
  else
  	n=2;
  	if [[ "$*" =~ "-a" ]]; then n=0; fi # Prescan for detecting -a
    while [[ $# -gt $n ]]; do
      opt="$1"
      case "$opt" in
      	"") if [[ $# -eq 2 ]]; then break; fi;;
        "-a"|"--all"           ) opt="ALL";            export ${opt}="true"; shift;;
				"-t"|"--target"        ) opt="TARGET";         export ${opt}=${2%/}; shift; shift;;
        "-c"|"--combine"       ) opt="COMBINE";        export ${opt}="true"; shift;;
        "-e"|"--exclude"       ) opt="EXCLUDEPATTERN"; export ${opt}="$2"; shift; shift;;
        "-v"|"--verbose"       ) opt="VERBOSE";        export ${opt}="true"; shift;;
        "-l"|"--logfile"       ) opt="LOGFILE";        export ${opt}="$2"; shift; shift;;
				"-dp"|"--dirpattern"   ) opt="DIRPATTERN";     export ${opt}="$2"; shift; shift;;
				"-fp"|"--filepattern"  ) opt="FILEPATTERN";    export ${opt}="$2"; shift; shift;;
				"-cf"|"--combinedfile" ) opt="COMBINEDFILE";   export ${opt}="$2"; shift; shift;;
          *                    ) echo "ERROR: Invalid option: \""$opt"\"" >&2; usage; exit 1;;
      esac
    done
  fi
  if [[ "$ALL" != "true" ]] && [[ $# -lt 2 ]] || [[ "$1" == -* ]] || [[ "$2" == -* ]]; then
    usage; exit 1
  else
  	DIRA=${1%/}
  	DIRB=${2%/}
  fi

  if [[ -f "$LOGFILE" ]]; then
    rm "LOGFILE";
  fi

  log ""
  log Running $0 on platform $PLATFORM. Command line:
  log ""
  log $COMMANDLINE
  log ""
  log Parameters:
  log ""
  log "all         : $ALL"
  if [[ "$ALL" != "true" ]]; then
    log "dira        : $DIRA"
    log "dirb        : $DIRB"
  fi
  log "dirpattern  : $DIRPATTERN"
  log "filepattern : $FILEPATTERN"
  log "exclude     : $EXCLUDEPATTERN"
  log "target      : $TARGET"
  log "combine     : $COMBINE"
  log "combinedfile: $COMBINEDFILE"
  log "verbose     : $VERBOSE"
  log "logfile     : $LOGFILE"
  log ""
}


###################################################
#
# Log
#
###################################################

log() {
	if [[ $VERBOSE == "true" ]]; then
		echo "${*}"
	fi
  echo "${*}" >>"$LOGFILE"
}


###################################################
#
# Call main
#
###################################################

main "$@"
