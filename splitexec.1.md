SPLITEXEC(1) - General Commands Manual

# NAME

**splitexec** - split standard input into pieces, stop after each piece and execute
a utility for it

# SYNOPSIS

**splitexec**
\[**-k**]
\[**-a**&nbsp;*suffix\_length*]
\[**-p**&nbsp;*prefix*]
\[**-s**&nbsp;*byte\_count*]
*utility*&nbsp;\[*argument&nbsp;...*]

# DESCRIPTION

The
**splitexec**
utility processes standard input, it writes it to temporary files,
after each temporary file is written it
executes
*utility*
for it, then stops processing input.
After
*utility*
exits for the piece, the piece is deleted (see
**-k**
option), and
**splitexec**
resumes processing of input.
This can be used to call utilities that expect regular files on
huge non-regular files, block devices, pipes, and such.

Optional arguments may be passed to the
*utility*.
If the string
"{}"
appears anywhere in the utility name or the arguments it is replaced
by the pathname of the current file.

The options are as follows:

**-a** *suffix\_length*

> Use
> *suffix\_length*
> letters to form the suffix of the file name. The default suffix length is 3.

**-k**

> Keep pieces after processing them.
> The default is to remove each piece after
> *utility*
> exits.

**-p** *prefix*

> If
> *prefix*
> is specified, it is used as a prefix for the names of the files
> into which the file is split. In this case, each file into which the file
> is split is named by the prefix followed by a numericaly ordered suffix
> using
> *suffix\_length*
> characters in the range
> "0-9".
> All temporary files are stored in the current directory. If this option is
> missing a random prefix is used of the form
> 'tmp.XXXXXXXXXX'
> where
> 'XXXXXXXXXX'
> is a random string of characters consisting of digits and letters
> \[A-Z].

**-s** *byte\_count*

> Create files
> *byte\_count*
> bytes in length.
> No provision is made for any kind of unit
> suffix, no
> 'k',
> 'm',
> 'g'
> is supported.
> The default value is 1073741824 (1GB).

The
*utility*
argument must be present.

Undefined behaviour may occur if utility reads from the standard input.

The
**splitexec**
utility exits immediately (without processing any further input) if a command
line
cannot be assembled,
*utility*
cannot be invoked,
an invocation of
*utility*
is terminated by a signal, or
an invocation of
*utility*
exits with a value &gt;0;

# EXIT STATUS

The **splitexec** utility exits&#160;0 on success, and&#160;&gt;0 if an error occurs.

# EXAMPLES

The
**splitexec**
utility is specially designed to integrate easily with backup routines,
for example when transferring large files to a remote host, using small
temporary storage.

Move a full disk compressed from local host to a remote host using scp:

	$ cd /tmp
	$ gzip < /dev/sdb | splitexec -p myserv-sdb.gz scp {} "user@rhost:mybackupdir/{}"

Will generate files myserv-sdb.gz.001, myserv-sdb.gz.002, ... in
*rhost*.
Using at no time more than
*bytes\_count*
bytes for temporary files in total.

To recreate the original file from the pieces:

	$ cat myserverback.* > /dev/sdb

# SEE ALSO

find(1),
split(1)

# AUTHORS

Abel Abraham Camarillo Ojeda &lt;[acamari@verlet.org](mailto:acamari@verlet.org)&gt;

# CAVEATS

No provision is made for generating a checksum of the full input.

OpenBSD 6.6 - March 22, 2020
