package QueriesBenchmarker::Utils::Manager;

use Moose;
use Try::Tiny;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use Term::ANSIColor;
use FindBin;

use QueriesBenchmarker::Utils::Logger;
use QueriesBenchmarker::Utils::Config::Manager;
use QueriesBenchmarker::Utils::File::XML::Twig::Parser;
use QueriesBenchmarker::Utils::Runner;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_CONFIG_FILE => "$FindBin::Bin/../conf/queries_benchmarder.ini";

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

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

has 'config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigFile',
    reader   => 'getConfigFile',
    required => FALSE,
    default  => DEFAULT_CONFIG_FILE
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

has 'indir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIndir',
    reader   => 'getIndir',
    required => FALSE,
    default  => DEFAULT_INDIR
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

        $instance = new QueriesBenchmarker::Utils::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate QueriesBenchmarker::Utils::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

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

sub _initConfigManager {

    my $self = shift;

    my $manager = QueriesBenchmarker::Utils::Config::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::Config::Manager");
    }

    $self->{_config_manager} = $manager;
}

sub runBenchmarkTests {

    my $self = shift;
    my ($infile) = @_;

    if (!defined($infile)){

        $infile = $self->getInfile();
        
        if (!defined($infile)){

            $self->{_logger}->logconfess("infile was not defined");
        }
    }

    my $parser = new QueriesBenchmarker::Utils::File::XML::Twig::Parser(infile => $infile);
    if (!defined($parser)){
        $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::File::XML::Twig::Parser");
    }

    my $test_record_list = $parser->getTestRecordList();
    if (!defined($test_record_list)){
        $self->{_logger}->logconfess("test_record_list was not defined");
    }

    my $repository_record_list = $parser->getRepositoryRecordList();
    if (!defined($repository_record_list)){
        $self->{_logger}->logconfess("repository_record_list was not defined");
    }

    my $runner = QueriesBenchmarker::Utils::Runner::getInstance(
        outdir => $self->getOutdir(),
        test_record_list       => $test_record_list,
        repository_record_list => $repository_record_list,
        infile => $infile
        );

    if (!defined($runner)){
        $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::Runner");
    }

    $runner->runBenchmarkTests();
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 QueriesBenchmarker::Utils::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use QueriesBenchmarker::Utils::Manager;
 my $manager = QueriesBenchmarker::Utils::Manager::getInstance();
 $manager->runBenchmarkTests($infile);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
