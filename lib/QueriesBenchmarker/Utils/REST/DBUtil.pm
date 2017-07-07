package QueriesBenchmarker::Utils::REST::DBUtil;

use Moose;
use URI::Escape;
use File::Slurp;
use Benchmark;
use Time::HiRes qw( time );


use QueriesBenchmarker::Utils::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

## Singleton support
my $instance;

has 'uri' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setURI',
    reader => 'getURI'
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );


sub getInstance {

    if (!defined($instance)){

        $instance = new QueriesBenchmarker::Utils::REST::DBUtil(@_);

        if (!defined($instance)){

            confess "Could not instantiate QueriesBenchmarker::Utils::REST::DBUtil";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->{_logger}->info("Instantiated " . __PACKAGE__);
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);
    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _initConfigManager {

    my $self = shift;

    my $manager = QueriesBenchmarker::Utils::Config::Manager::getInstance(@_);

    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::Config::Manager");
    }

    $self->{_config_manager} = $manager;
}


sub executeQuery {

    my $self = shift;
    my ($query, $query_name) = @_;

    if (!defined($query)){
        $self->{_logger}->logconfess("$query was not defined");
    }

    ## Need to URL Encode and then transmit to URI
    return $self->_execute_query(@_);
}

sub _execute_query {

    my $self = shift;
    my ($query, $query_name) = @_;

    if (!defined($query)){
        $self->{_logger}->info("query was not defined");
    }
    
    if (!defined($query_name)){
        $self->{_logger}->info("query_name was not defined");
    }    

    my $url = $self->getURI();
    if (!defined($url)){
        $self->{_logger}->logconfess("url was not defined");
    }

    my $outfile = $self->getOutdir() . '/' . lc($query_name) . '.txt';

    my $encoded_query = uri_escape($query);
    if (!defined($encoded_query)){
        $self->{_logger}->logconfess("encoded_query was not defined");
    }

    # my $cmd = "curl -D- -u $username:$password -X POST --data '$data' -H 'Content-Type: application/json' $url";
    my $cmd = "curl -o $outfile -X POST -H \"Accept: application/sparql-results+json\" -d \"query=\"$encoded_query " . $url;

    print "Going to execute '$cmd'\n";

    # my $start_time = Benchmark->new;
    my $start_time = time();

    my $results = $self->_execute_cmd($cmd);

    # my $end_time = Benchmark->new;
    my $end_time = time();

    # if (! $self->isOkay($results)){
    #     $self->{_logger}->logconfess("The POST to Jira was not successful");
    # }

    # my $time_diff = timediff($end_time, $start_time);
    my $time_diff = $end_time - $start_time;

    my @lines = read_file($outfile);

    my $line_count = scalar(@lines);

    $self->{_time_record} = {
        'start_time' => $start_time, 
        'end_time'   =>  $end_time,
        'time_diff'  => $time_diff,
        'record_count' => $line_count
        # 'took'       => timestr($time_diff)
    };
}

sub _execute_cmd {

    my $self = shift;
    my ($cmd) = @_;

    $self->{_logger}->info("About to execute '$cmd'");

    eval {
        qx($cmd);
    };

    if ($?){
        $self->{_logger}->logconfess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }
}


sub isOkay {

    my $self = shift;
    my ($results) = @_;

    my $error_ctr = 0;

    foreach my $line (@{$results}){

        if ($line =~ /errorMessage/){
            $error_ctr++;
        }
    }

    if ($error_ctr > 0){
        return FALSE;
    }

    return TRUE;
}

sub getTimeRecord {

    my $self = shift;
    
    return $self->{_time_record};
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 QueriesBenchmarker::Utils::REST::DBUtil

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use QueriesBenchmarker::Utils::REST::DBUtil;

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut