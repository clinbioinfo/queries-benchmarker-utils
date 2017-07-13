package QueriesBenchmarker::Utils::Runner;

use Moose;
use Try::Tiny;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use Term::ANSIColor;
use FindBin;
use Template;

use QueriesBenchmarker::Utils::Logger;
use QueriesBenchmarker::Utils::DBUtil::Factory;
use QueriesBenchmarker::Report::File::JSON::Writer;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

## Singleton support
my $instance;

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

has 'verbose' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setVerbose',
    reader   => 'getVerbose',
    required => FALSE,
    default  => DEFAULT_VERBOSE
    );

has 'config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigfile',
    reader   => 'getConfigfile',
    required => FALSE,
    );

has 'text_outfile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setTextOutfile',
    reader   => 'getTextOutfile',
    required => FALSE,
    );

has 'html_outfile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setHTMLOutfile',
    reader   => 'getHTMLOutfile',
    required => FALSE,
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'infile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setInfile',
    reader   => 'getInfile',
    required => FALSE
    );

has 'repository_record_list' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    writer   => 'setRepositoryRecordList',
    reader   => 'getRepositoryRecordList',
    required => FALSE
    );

has 'test_record_list' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    writer   => 'setTestRecordList',
    reader   => 'getTestRecordList',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new QueriesBenchmarker::Utils::Runner(@_);

        if (!defined($instance)){

            confess "Could not instantiate QueriesBenchmarker::Utils::Runner";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initFactory(@_);

    $self->_initDBUtils(@_);

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _initFactory {

    my $self = shift;

    my $factory = QueriesBenchmarker::Utils::DBUtil::Factory::getInstance(@_);
    if (!defined($factory)){
        $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::DBUtil::Factory");
    }

    $self->{_factory} = $factory;
}

sub _initDBUtils {

    my $self = shift;

    my $repository_list = $self->getRepositoryRecordList();

    if (!defined($repository_list)){
        $self->{_logger}->logconfess("repository_list was not defined");
    }

    foreach my $repository (@{$repository_list}){

        my $dbutil = $self->{_factory}->createByRepository($repository);
        if (!defined($dbutil)){
            $self->{_logger}->logconfess("dbutil was not defined for repository record  : " . Dumper $repository);
        }

        my $name = $repository->getName();
        if (!defined($name)){
            $self->{_logger}->logconfess("name was not defined");
        }

        $self->{_name_to_dbutil_lookup}->{$name} = $dbutil;
    }
}

sub runBenchmarkTests {

    my $self = shift;

    $self->_run_benchmark_tests(@_);

    $self->_generate_text_report(@_);

    $self->_generate_html_report(@_);

    $self->_generate_json_report(@_);
}


sub _run_benchmark_tests {

    my $self = shift;

    my $infile = $self->getInfile();
        
    if (!defined($infile)){

        $self->{_logger}->logconfess("infile was not defined");
    }

 
    my $record_list = $self->getTestRecordList();

    if (!defined($record_list)){

        $self->{_logger}->logconfess("record_list was not defined");
    }

    my $record_ctr = 0;

    foreach my $record (@{$record_list}){
    
        $record_ctr++;

        my $target_name = $record->getTargetName();
        
        if (!defined($target_name)){
            $self->{_logger}->logconfess("target name was not defined for record : ". Dumper $record);
        }

        if (! exists $self->{_name_to_dbutil_lookup}->{$target_name}){
            $self->{_logger}->logconfess("target name '$target_name' does not exist in the name to dbutil lookup");
        }       

        my $dbutil = $self->{_name_to_dbutil_lookup}->{$target_name};

        $dbutil->setOutdir($self->getOutdir());

        my $query = $record->getQuery();
        if (!defined($query)){
            $self->{_logger}->logconfess("query was not defined for record : ". Dumper $record);
        }

        my $query_name = $record->getQueryName();
        
        if (!defined($query_name)){
            $self->{_logger}->logconfess("query name was not defined for record : ". Dumper $record);
        }

        $self->{_logger}->info("Processing record '$record_ctr' with query name '$query_name'");

        $dbutil->executeQuery($query, $query_name);

        my $timeRecord = $dbutil->getTimeRecord();

        if (!defined($timeRecord)){
            $self->{_logger}->logconfess("timeRecord was not defined");
        }

        push(@{$self->{_time_lookup}->{$query_name}}, [$target_name, $timeRecord, $record->getDesc()]);

        if ($record_ctr > 4){
            last;
        }
    }

    $self->{_logger}->info("Finished processing '$record_ctr' records");
}

sub _generate_text_report {

    my $self = shift;

    my $outfile = $self->_get_text_outfile();

    open (OUTFILE, ">$outfile") || $self->{_logger}->logconfess("Could not open '$outfile' in write mode : $!");
    

    foreach my $query_name (sort keys %{$self->{_time_lookup}}){
        
        print OUTFILE "Query: $query_name\n";
        
        foreach my $list_ref (@{$self->{_time_lookup}->{$query_name}}){

            my $target_name = $list_ref->[0];
            my $time_record = $list_ref->[1];
            my $desc = $list_ref->[2];
        
            my $start_time = $time_record->{start_time};
        
            my $end_time = $time_record->{end_time};

            if (! exists $time_record->{time_diff}){
                $self->{_logger}->logconfess("time diff does not exist for time record " . Dumper $time_record);
            }

            my $time_diff = $time_record->{time_diff};

            my $record_count = $time_record->{record_count};

            # my $took = $time_record->{took};
        
            print OUTFILE "\t$target_name start time : '$start_time' end time : '$end_time' time diff '$time_diff' record count '$record_count' desc '$desc'\n"
            # print OUTFILE "\t$target time diff '$time_diff' time took: $took\n"
        }
    }

    close OUTFILE;

    $self->{_logger}->info("Wrote records to '$outfile'");

    print "Wrote report file '$outfile'\n";
    
}

sub _generate_json_report {

    my $self = shift;

    my $outfile = $self->getOutdir() . '/' . File::Basename::basename($0) . '.json';

    my $writer = new QueriesBenchmarker::Report::File::JSON::Writer(
        outfile => $outfile,
        lookup  => $self->{_time_lookup}
        );

    if (!defined($writer)){
        $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Report::File::JSON::Writer");
    }

    $writer->writeFile();    
}

sub _generate_html_report {

    my $self = shift;

    my $outfile = $self->_get_html_outfile();

    $self->{_logger}->fatal("NOT YET IMPLEMENTED");

    $self->{_logger}->info("Wrote HTML report '$outfile'");    

    print "Wrote report file '$outfile'\n";
}

sub _get_text_outfile {

    my $self = shift;

    my $outfile = $self->_get_outdir() . '/' . File::Basename::basename($0) . '.txt';

    $self->setTextOutfile($outfile);

    return $outfile;
}

sub _get_html_outfile {

    my $self = shift;


    my $outfile = $self->_get_outdir() . '/' . File::Basename::basename($0) . '.html';

    $self->setHTMLOutfile($outfile);
    
    return $outfile;
}

sub _get_outdir {

    my $self = shift;
    
    my $outdir = $self->getOutdir();
    
    if (!defined($outdir)){
    
        $self->{_logger}->logconfess("outdir was not defined");
    }
    if (!-e $outdir){
    
        mkpath($outdir) || $self->{_logger}->logconfess("Could not create output directory '$outdir' : $!");
    
        $self->{_logger}->info("Created output directory '$outdir'");
    }

    return $outdir;
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 QueriesBenchmarker::Utils::Runner
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use QueriesBenchmarker::Utils::Runner;
 my $manager = QueriesBenchmarker::Utils::Runner::getInstance();
 $manager->runBenchmarkTests($infile);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
