Welcome to dirdiff!
===================



Summary
-------

This is a small helper application that I wrote to compare directories containing log files. It can extract the changes in log files between steps you take, and it can combine multiple log files per step into one, ordered by timestamp.


Procedure
---------

Here is the procedure: Assume you have a software system that generates, in a log file directory, a large amount of log files. Let's say, there are a number of processes (for example, one process could be named "CMS", another one could be named "crcache"), and they would concurrently write log files like CMS_xyz_abc.log.

Now, if you would want to search for specific errors in those logs, with dirdiff you would procede like this:

1.   Take a copy of your complete logs directory before starting. Call that
     directory, for example, 0_start

2.   Run the process that you want to analyze, then create another copy
     of the complete log directory, naming it, for example, 1_end.

3.   Keep adding as many steps as you want.

To reduce the volume, you can of course empty the logs directory first (save a copy of its content). Also, you can do any number of steps like step 2 above; a good idea would be to, for example, wait a reasonable amount of time before each step so that you will be able to better identify the time stamps in your log files.


Getting started
---------


Once done, you go into the directory containing the log file snapshot directories and get there a copy of dirdiff.sh. Call it like so:

```
# ./dirdiff.sh -a -c
```

This should create a directory diffs for you with the pair-wise differences between all (-a) your log snapshot directories, and it should also create combined log files (-c) for each of those pairs.


This will run the program on all subdirectories. It will do this:

1. Create a subdirectory diffs if it does not exist
2. Comparing, for example, a directory 1 with a directory 2, it will create a directory diffs/2.
3. Copy into diffs/2 all files from 2/ which are not in 1/
4. Copy into diffs/2 all lines from files in 2/ which are not in 1/
5. Create a file diffs/2_combined.txt which contains the content from files in diffs/2 sorted by timestamp.
6. Create a log file
7. Do these steps for all remaining directory pairs.


Assumptions
---------

Besides the technical assumption such as that you have a Unix operating system such as Linux or Mac OSX, and a number of programs that are listed at the top of dirdiff.sh, content-wise the only two assumptions are:

1. Your log file names have a pattern where at the beginning of the file, you have e.g. the process name writing that log file, followed by an underscore and then any content. We need this because when we combine the files, as we sort by timestamp, we want to identify which process wrote which line.
2. Your log files contain a timestamp in the format such as 2014/12/01 at the beginning of each line, followed by a vertical bar. All other lines are going to be ignored.


----------

Parameters
---------

Parameters can be used in any order, except for that the last two must be input- and output file, respectively. You can get a list of all options using:

```
# ./dirdiff.sh 
```
or

```
# ./dirdiff.sh -h
```

or

```
# ./dirdiff.sh --help
```


This will give you an overview of its options, and some sample calls:

```
# ./dirdiff.sh 
---------------------------------------------------------------------------
./dirdiff.sh - Compare Log Directories.
---------------------------------------------------------------------------
It compares two directories,  dira and dirb,  and records their differences
into a directory diffs/dirb. Differences are either new files that appeared
in directory dirb which  had not yet been in dira, or lines in files  which
have been  added to  files in directory  dira. Optionally,  the program can
create a common file sorted by timestamp.

Usage: ./dirdiff.sh [options] dira dirb

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

Compare the current subdirectories except diffs into diffs

  ./dirdiff.sh -a

Same as before, but also create each a combined file

  ./dirdiff.sh -a -c

Same as before, but specify some output directory outdir

  ./dirdiff.sh -a -c -t outdir

Same as before, but also be a little verbose

  ./dirdiff.sh -a -c -t outdir -v

Same as before, but using only directories with an underscore

  ./dirdiff.sh -a -c -t outdir -v -dp _

Same as before, but combining only files ending with log

  ./dirdiff.sh -a -c -t outdir -v -dp _ -fp 'log$'

Same as before, but combining only files starting with CMS and crcache,
ending with log

  ./dirdiff.sh -a -c -t outdir -v -dp _ -fp '^(CMS|crcache).*log$'

Same as before, but combining only files starting with CMS and crcache,
ending with log and excluding lines containing GetObjectInternal or
FilterElementsInSet

  ./dirdiff.sh -a -c -t outdir -v -dp _ -fp '^(CMS|crcache).*log$' -e '(GetObjectInternal|FilterElementsInSet)'

Same as before, but combining into file workflow.txt

  ./dirdiff.sh -a -c -t outdir -v -dp _ -fp '^(CMS|crcache).*log$' -e '(GetObjectInternal|FilterElementsInSet)' -cf workflow.txt
```


Most simple Usage
---------

The most simple way to use the program is to assume that in the current directory, you only have your log snapshots, and the file dirdiffs.sh:

```
# ./dirdiff.sh -a -c
```
