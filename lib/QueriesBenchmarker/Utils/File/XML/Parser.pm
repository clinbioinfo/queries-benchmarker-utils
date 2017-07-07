package QueriesBenchmarker::Utils::File::XML::Parser;

use Moose;
use Data::Dumper;
use File::Slurp;

use QueriesBenchmarker::Utils::SQL::Connectivity::Record;
use QueriesBenchmarker::Utils::SPARQL::Connectivity::Record;
use QueriesBenchmarker::Utils::Test::Record;

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

sub getInstance {

    if (!defined($instance)){

        $instance = new QueriesBenchmarker::Utils::File::XML::Parser(@_);

        if (!defined($instance)){

            confess "Could not instantiate QueriesBenchmarker::Utils::File::XML::Parser";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

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

sub getRepositoryRecordList {

    my $self = shift;
    
    if (! exists $self->{_repository_record_list}){
        $self->_parse_file(@_);
    }

    return $self->{_repository_record_list};
}

sub getTestRecordList {

    my $self = shift;
    
    if (! exists $self->{_test_record_list}){
        $self->_parse_file(@_);
    }

    return $self->{_test_record_list};
}

sub _create_repository_record {

    my $self = shift;
    my ($name, $type, $config_file, $vendor) = @_;

    if (lc($type) eq 'sql'){

        $self->_create_sql_repository_record(@_);
    }
    elsif (lc($type) eq 'rest'){

        $self->_create_sparql_repository_record(@_);
    }
    else {
        $self->{_logger}->logconfess("type '$type' is not supported");
    }
}

sub _create_sql_repository_record {

    my $self = shift;
    my ($name, $type, $config_file, $vendor) = @_;


    my $record = new QueriesBenchmarker::Utils::SQL::Connectivity::Record(
        name => $name,
        type => $type,
        vendor => $vendor
        );
    if (!defined($record)){
        $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::SQL::Connectivity::Record");
    }

    my @lines = read_file($config_file);

    foreach my $line (@lines){

        if ($line =~ m|^\#|){
            next;
        }
        elsif ($line =~ m|^username=(\S+)|){

            $record->setUsername($1);

            next;
        }
        elsif ($line =~ m|^password=(\S+)|){

            $record->setPassword($1);

            next;
        }
        elsif ($line =~ m|^database=(\S+)|){

            $record->setDatabase($1);

            next;
        }
        elsif ($line =~ m|^server=(\S+)|){

            $record->setServer($1);

            next;
        }
        elsif ($line =~ m|^port_number=(\S+)|){

            $record->setPortNumber($1);

            next;
        }
    }

    push(@{$self->{_repository_record_list}}, $record);
}

sub _create_sparql_repository_record {

    my $self = shift;
    my ($name, $type, $config_file) = @_;

    my $record = new QueriesBenchmarker::Utils::SPARQL::Connectivity::Record(
        name => $name,
        type => $type
        );

    if (!defined($record)){
        $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::SPARLQ::Connectivity::Record");
    }

    $config_file = File::Spec->rel2abs($config_file);

    if (!-e $config_file){
        $self->{_logger}->logconfess("config_file '$config_file' does not exist");
    }

    my @lines = read_file($config_file);

    foreach my $line (@lines){

        if ($line =~ m|^\#|){
            next;
        }
        elsif ($line =~ m|^uri=(\S+)|){

            $record->setURI($1);

            next;
        }
    }

    push(@{$self->{_repository_record_list}}, $record);
}

sub _create_test_record {

    my $self = shift;
    my ($query_name, $query, $target_name) = @_;

    my $test_record = new QueriesBenchmarker::Utils::Test::Record(
        target_name => $target_name,
        query       => $query,
        query_name  => $query_name
        );

    if (!defined($test_record)){
        $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::Test::Record");
    }

    push(@{$self->{_test_record_list}}, $test_record);
}

sub _checkInfileStatus {

    my $self = shift;
    my ($infile) = @_;

    if (!defined($infile)){
        $self->{_logger}->logconfess("infile was not defined");
    }

    my $errorCtr = 0 ;

    if (!-e $infile){
        $self->{_logger}->fatal("input file '$infile' does not exist");
        $errorCtr++;
    }
    else {
        if (!-f $infile){
            $self->{_logger}->fatal("'$infile' is not a regular file");
            $errorCtr++;
        }
        
        if (!-r $infile){
            $self->{_logger}->fatal("input file '$infile' does not have read permissions");
            $errorCtr++;
        }
        
        if (!-s $infile){
            $self->{_logger}->fatal("input file '$infile' does not have any content");
            $errorCtr++;
        }
    }

    if ($errorCtr > 0){
        $self->{_logger}->logconfess("Encountered issues with input file '$infile'");
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 QueriesBenchmarker::Utils::File::XML::Parser
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use QueriesBenchmarker::Utils::File::XML::Parser;
 my $manager = QueriesBenchmarker::Utils::File::XML::Parser::getInstance();
 $manager->runBenchmarkTests($infile);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
