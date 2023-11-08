package Topsail::CustomLogger;

use v5.030;
use strictures 2;
no warnings 'uninitialized';

use Exporter 'import';
use Carp 'croak', 'confess';
use JSON::PP;

our @EXPORT_OK = qw(get_logger lambda_say lambda_confess lambda_die);

use Log::Log4perl;
sub get_logger {
  unless( Log::Log4perl::initialized() ){
     # if TRACE_ID is defined use it
    my $trace_id = $ENV{AWS_LAMBDA_REQUEST_ID};
    if(defined $trace_id) {
        # Define a logger
        my $log_level = $ENV{APP_LOG_LEVEL};
        $log_level //= "INFO";
        my $logger = Log::Log4perl->get_logger();
        $logger->level(
            Log::Log4perl::Level::to_priority($log_level)
        );
        
            # Define a layout
        my $layout = Log::Log4perl::Layout::PatternLayout->new(
                        "$trace_id: %d (%F:%L)> %m\n");
        
            # Define an appender
        my $appender = Log::Log4perl::Appender->new(
                        "Log::Log4perl::Appender::Screen",
                        name => 'dumpy',
                        stderr => 0
                        );
        
            # Set the appender's layout
        $appender->layout($layout);
        $logger->add_appender($appender);
    } else {
        my $conf = q(
            log4perl.category                = INFO, Screen
        
            log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
            log4perl.appender.Screen.stderr  = 0
            log4perl.appender.Screen.layout  = Log::Log4perl::Layout::SimpleLayout
        );
        # ... passed as a reference to init()
        Log::Log4perl::init( \$conf );
    }
  }
  return Log::Log4perl::get_logger();
}

sub lambda_say {
  if($ENV{AWS_LAMBDA_REQUEST_ID}){
    say "Request ID: $ENV{AWS_LAMBDA_REQUEST_ID}, ", join "", @_;
  } else {
    say @_;
  }
}

sub lambda_confess {
  if($ENV{AWS_LAMBDA_REQUEST_ID}){
    confess "Request ID: $ENV{AWS_LAMBDA_REQUEST_ID}, ", join "", @_;
  } else {
    confess @_;
  }
}

sub lambda_die {
  if($ENV{AWS_LAMBDA_REQUEST_ID}){
    die "Request ID: $ENV{AWS_LAMBDA_REQUEST_ID}, ", join "", @_;
  } else {
    die @_;
  }
}
1;
