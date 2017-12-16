# A simple program that can upload to S3 from a named pipe.

## Problem:

It's not trivial to provide scratch space for AWS Batch jobs.

However, sometimes the need for scratch space can be eliminated.

Imagine a batch job that downloads a file from S3,
and runs a program that produces
two output files and then uploads them to S3. If each of these
3 files is 10GB, you'll need 30GB to do this, which is not
available by default in AWS batch.

If instead you could stream from S3, through your program,
into two streams uploading back to S3, you could run the job
without needing extra scratch space.

That's where this tool, working in conjunction with
[named pipes](https://en.wikipedia.org/wiki/Named_pipe), comes in.


## Usage:

```
s3uploader -h
Usage of s3uploader:
 -b string
       Bucket name.
 -k string
       Object key name.
 -s string
       Server-side encryption (AES256 or aws:kms)
```

**NOTE**: The environment variable `AWS_REGION` must be
set in order to use this program. Users at Fred Hutch
should set it to `us-west-2` as follows:

```bash
export AWS_REGION=us-west-2
```

## Example usage with regular file:

```
s3uploader -b mybucket -k myKey < myfile.txt
```

## Example usage with named pipe:

```bash
mkfifo pipe1
s3uploader -b mybucket -k myKey < pipe1 & # hook up one end of the pipe
cat some_file > pipe1 # hook up the other end
```

## Usage in AWS Batch

The point of this program is to be able to operate without scratch space in AWS batch.

Users at Fred Hutch must always supply the
option `-s AES256` because buckets at Fred Hutch
require server-side encryption with this algorithm.

If your analysis is simple and uses a program that takes one input
and writes one output, and can read from STDIN and write to STDOUT,
you do not need this tool and you can stop reading.

But if you are using a tool that reads from one or more files and
writes to one or more files, you may be able to use it.

`s3uploader` only works with programs that read and write in a
streaming fashion, from beginning to end. If the program seeks
to random locations within the file, you cannot use this tool.
How will you know? You'll probably get strange errors if you try it.

### Simple example

Imagine a program called `mytool` which takes a single input
file and produces two output files. A typical invocation would
look like this:

```bash
mytool --input inputfile --output1 outputfile1 --output2 outputfile2
```

What we want is for the input to be streamed from S3 and
the output (both files) to be streamed back to S3.

The first thing we have to do (as mentioned above) is
set `AWS_REGION`:

```bash
export AWS_REGION=us-west-2
```

The standard AWS command-line interface (`aws`) can handle the
downloading part, but `s3uploader` is needed for the upload.

So let's create three named pipes:

```bash
mkfifo inputfile
mkfifo outputfile1
mkfifo outputfile2
```

Now let's hook up one end of the pipes.

```bash
aws s3 cp --sse AES256 --cli-read-timeout 0 \
  s3://mybucket/myfile - > inputfile &
```

We've just set up the `aws` command to download to the named
pipe called `inputfile`, and to not time out. Nothing will actually
happen until another process (`mytool` in this case) comes along
and reads from the other end of the pipe. That's why we put
the `&` at the end of the command, so it just waits until
it's time to do something.

Let's set up the other two pipes:

```bash
s3uploader -b mybucket -k outputfile1 -s AES256 < outputfile1 &

s3uploader -b mybucket -k outputfile2 -s AES256 < outputfile2 &
```

We've set up two instances of `s3uploader` to upload to
`s3://mybucket/outputfile1` and `s3://mybucket/outputfile2`
from `outputfile1` and `outputfile2` respectively.
Again, nothing will happen until `mytool` is run. So let's run it:

```bash
mytool --input inputfile --output1 outputfile1 --output2 outputfile2
```

Notice that this command line is identical to our first
example invocation of `mytool`. But the files that it's operating
on are named pipes, and data is actually being read from
(and written to) S3.

Finally, a short `sleep` is necessary so that the
named pipes can finish their work. Then we indicate
that we are done:

```bash
echo waiting 5 seconds
sleep 5
echo Done.
```


### Real-world example

See [example-script.sh](example-script.sh).



## Download the binary

The linux build is available
[here](https://s3-us-west-2.amazonaws.com/fredhutch-aws-batch-tools/linux-build-of-s3uploader/s3uploader).

You can download it like this:

```bash
curl -LO https://s3-us-west-2.amazonaws.com/fredhutch-aws-batch-tools/linux-build-of-s3uploader/s3uploader
chmod +x s3uploader
```
