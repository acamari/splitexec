#!/usr/bin/env perl

# Copyright (c) 2020 Abel Camarillo <acamari@verlet.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# splitexec: reads input from stdin, it writes to temporary files
# each 1GB (see -s option); after each temporary file is fill or at the end of
# input it executes its utility argument expanding the string {} with the
# last temporary file name, further input processing is stopped until the
# utility argument exit. If the utility argument exits non-zero splitexec will
# exit with the status of utility. By default the names of
# temporary files are generated with the prefix tmp.XXXXXXXXXX. where
# XXXXXXXXXX is a random string [0-9A-Za-z] (see -p option).
# The names of temporary files are generated with a numerical suffix of
# three digits (see -a option) so the names of temporary files will be like:
# tmp.5rRM5OqZts.001, tmp.5rRM5OqZts.002, ...
# Temporary file names will be deleted after each execution of the utility
#
# example:
# 	cat 2500MB_file.tar | \
#	splitexec -p myserver_back.tar uploadapi {} dest://folder/today/{}
#
# 	will execute uploadapi 3 times:
#		uploadapi myserver_back.tar.001	dest://folder/today/myserver_back.tar.001 # 1024M
#		uploadapi myserver_back.tar.002	dest://folder/today/myserver_back.tar.002 # 1024M
#		uploadapi myserver_back.tar.003	dest://folder/today/myserver_back.tar.003 # 452M

use strict;
use Getopt::Std;
use constant BUFSIZ => 4096;

my $prog = $0;

sub
err
{
	die "$prog: ", @_, ": $!\n";
}

sub
errx
{
	die "$prog: ", @_, "\n";
}

sub
prefix2name
{
	local $_ = shift;
	# A-Z only
	errx "bad prefix: $_" unless /X{10,}$/;
	my $randchar = sub {
		my $arg = shift;
		my $i;
		my $buf = '';
		while ($i++ < length($arg)) {
			$buf .= chr(ord("A") + int(rand() * 26))
		}
		return $buf;
	};
	s/X+$/$randchar->($&)/e;
	return $_;
}

# use first argument to expand "{}" in the remaining arguments
# example:
#
# 	replacecurlybracket qw(abcd hello{}world {} {}aaaa {abcd})
#
# returns:
# 	"helloabcdworld", "abcd", "abcdaaaa", "{abcd}"
sub
replacecurly
{
	my $expandto = shift // return;
	return map {s/\{\}/$expandto/g; $_} @_;
}

# temp file size
my $sflag = 1024 ** 3; # 1GB
# prefix flag
my $pflag = prefix2name('tmp.XXXXXXXXXX');
# number of digits in suffix
my $aflag = 3;
# if true keep files instead of delete them after processing
my $kflag = 0;
my %opts;

getopts('a:kp:s:', \%opts) or errx "invalid opts";
$aflag = $opts{a} // $aflag; $aflag += 0;
$kflag = $opts{k} // $kflag;
$pflag = $opts{p} // $pflag;
$sflag = $opts{s} // $sflag;
errx "bad -a $aflag" if $aflag !~ /^\d+$/ or $aflag <= 0;
errx "bad -s $sflag" if $sflag !~ /^\d+$/ or $sflag <= 0;
errx "bad -p $pflag" if $pflag !~ /^.+$/;
errx "utility args needed" unless @ARGV;

for (my $filecount = 1;; $filecount++) {
	my $c; # count chars read
	my $buf;
	my $toread = $sflag; # how many bytes to read for this tmp file
	my $err;
	my $fname;
	my $fh;
	my $lastfile;
	my @nargv = @ARGV;

	errx "too many files" if length("$filecount") > $aflag;
	$fname = sprintf "%s.%0${aflag}d", $pflag, $filecount // errx "bad filename";
	open $fh, ">", $fname or errx "open: $fname";
	for ($c = 0;
	     $c = read STDIN, $buf, ($toread < BUFSIZ ? $toread : BUFSIZ);
	     $toread -= $c) {
		#warn "c: $c, toread: $toread, fname: $fname";
		print $fh $buf;
	}
	if (not defined $c) {
		$err = "input error: $!"; # read error
	} elsif ($c == 0 and eof(STDIN)) {
		$lastfile = 1;
	}
	close $fh or $err = "output error: $fname: $!";
	(@nargv) = replacecurly($fname, @nargv) or errx "replacecurly";
	system(@nargv) >> 8 == 0 or $err = "system: @nargv";
	unlink $fname or err "unlink: $fname" if !$kflag;
	err "$err" if $err;
	last if $lastfile;
}
exit 0;
