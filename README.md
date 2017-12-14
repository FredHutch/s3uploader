# A simple program that can upload to S3 from a named pipe.

## Usage:

```
s3uploader -h
Usage of s3uploader:
  -b string
    	Bucket name.
  -k string
    	Object key name.
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

Because it is designed to be used at Fred Hutch, where all
buckets require that uploads have Server Side Encryption enabled
(with the AES256 algorithm), `s3uploader` automatically turns
this on.

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

TBA

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
