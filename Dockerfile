FROM shogo82148/p5-aws-lambda:base-5.38.al2
# or if you want to use ECR Public.
# FROM public.ecr.aws/shogo82148/p5-aws-lambda:base-5.38.al2

RUN yum clean all
# wget is broken in alpine
RUN yum -y install yq jq curl gcc make perl libc-dev perl-dev unzip \
    && curl -L https://cpanmin.us | perl - --no-wget App::cpanminus

# uninstall awscli version 1 and install awscli v2
RUN yum -y remove awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# List all dependencies here, including testing. Do not add them to Makefile.PL
RUN cpanm -v --no-wget Test::More Test::Output Digest::SHA Pod::Usage \
    File::Slurp Test::Exception Test::LectroTest Moo strictures \
    AWS::CLIWrapper~1.27 Net::DNS HTTP::Tinyish UUID::Random Clone

# We want AWS CLI calls to *not* fail and keep retrying until a timeout expires.
# 255 attempts with exponential backoff up to 20 seconds will give us over an hour
# for each single AWS CLI call in Mast, which ought to be enough for anybody.
# See https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-retries.html#cli-usage-retries-modes
ENV AWS_RETRY_MODE=standard
ENV AWS_MAX_ATTEMPTS=255

# We also don't want the AWS::CLIWrapper library that we are using to kill the `aws` CLI,
# so we set its timeout to even higher value (2 hours).
ENV AWS_CLIWRAPPER_TIMEOUT=7200

# We run our tooling on AWS EC2 instances and AWS CLI assumes credentials from the
# instance when it starts. Sometimes upon starting, AWS CLI is unable to retrieve
# credentials and fails with an error; this error is transient and the operation
# is safe to retry after a short delay. The following environment variables configure
# AWS::CLIWrapper to do that.

# This variable's value is a Perl regex (can be just a string), and as such it may
# contain multiple patterns. Do not assume that error is the only line in stdout,
# use multi-line regex or simply omit anchors such as ^ and $.
ENV AWS_CLIWRAPPER_CATCH_ERROR_PATTERN='Unable to locate credentials'

# How many retries to make before giving up
ENV AWS_CLIWRAPPER_CATCH_ERROR_RETRIES=10

# Minimum delay in seconds before retrying, >= 0
ENV AWS_CLIWRAPPER_CATCH_ERROR_MIN_DELAY=1

# Maximum delay in seconds before retrying, >= 0. Actual delay is computed as a
# random value min >= delay <= max, there is no exponential backoff.
ENV AWS_CLIWRAPPER_CATCH_ERROR_MAX_DELAY=3



RUN mkdir -p /tmp/source
ADD ./ /tmp/source/
WORKDIR /tmp/source

ARG BUILD_OPTIONS=''

RUN cpanm -v --no-wget $BUILD_OPTIONS /tmp/source \
    && rm -rf /tmp/source /root/.cpanm

# RUN cpanm -v --no-wget Fleut::Mast

WORKDIR /

COPY topsail-handler.pl /var/task/handler.pl
CMD [ "handler.handle" ]
