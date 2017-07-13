package QueriesBenchmarker::Utils::File::XML::Twig::Parser;

use Moose;
use Data::Dumper;
use XML::Twig;

extends 'QueriesBenchmarker::Utils::File::XML::Parser';

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

use constant DEFAULT_VERBOSE => TRUE;

use constant DEFAULT_USERNAME => getlogin || getpwuid($<) || $ENV{USER} || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . DEFAULT_USERNAME . '/' . File::Basename::basename($0) . '/' . time();

## Singleton support
my $instance;

my $this;

sub getInstance {

    if (!defined($instance)){

        $instance = new QueriesBenchmarker::Utils::File::XML::Twig::Parser(@_);

        if (!defined($instance)){

            confess "Could not instantiate QueriesBenchmarker::Utils::File::XML::Twig::Parser";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}

sub _parse_file {

    my $self = shift;
    my ($infile) = @_;

    if (!defined($infile)){

        $infile = $self->getInfile();

        if (!defined($infile)){
            $self->{_logger}->logconfess("infile was not defined");
        }
    }

    $self->_checkInfileStatus($infile);

    $this = $self;

    my $twig = new XML::Twig( 
       twig_handlers =>  { 
           'repository-list'   => \&_repository_list_callback,
           'test-set-list' => \&_test_set_list_callback
       });
   
    if (!defined($twig)){
        $self->{_logger}->logconfess("Could not instantiate XML::Twig for file '$infile'");
    }

    $twig->parsefile( $infile );

    $self->{_logger}->info("Finished parsing install configuration XML file '$infile'");
}

sub _repository_list_callback {

    my $self = $this;
    my ($twig, $repository_list) = @_;
      
    if (! $repository_list->has_child('repository')){
        $self->{_logger}->logconfess("repository-list does not have child repository " . Dumper $repository_list);
    }

    my $repository = $repository_list->first_child('repository');

    $self->_process_repository($repository);

    while ($repository = $repository->next_sibling()){

        $self->_process_repository($repository);
    }
}

sub _process_repository {

    my $self = shift;
    my ($repository) = @_;

    if (! $repository->has_child('name')){
        $self->{_logger}->logconfess("name was not defined for repository : " . Dumper $repository);
    }

    my $name = $repository->first_child('name')->text();

    if (! $repository->has_child('type')){
        $self->{_logger}->logconfess("type was not defined for repository : " . Dumper $repository);
    }

    my $type = $repository->first_child('type')->text();

    if (! $repository->has_child('config-file')){
        $self->{_logger}->logconfess("config-file was not defined for repository : " . Dumper $repository);
    }

    my $config_file = $repository->first_child('config-file')->text();

    my $vendor;
    
    if (! $repository->has_child('vendor')){

        if ((defined($type)) && (lc($type) eq 'sql')){
            $self->{_logger}->logconfess("vendor was not defined for repository : " . Dumper $repository);
        }
    }
    else {
        $vendor = $repository->first_child('vendor')->text();
    }

    $self->_create_repository_record($name, $type, $config_file, $vendor);
}

sub _test_set_list_callback {

    my $self = $this;
    my ($twig, $test_set_list) = @_;
  
    my $test_set = $test_set_list->first_child('test-set');

    $self->_process_test_set($test_set);

    while ($test_set = $test_set->next_sibling()){

        $self->_process_test_set($test_set);
    }
}

sub _process_test_set {

    my $self = shift;
    my ($test_set) = @_;
    
    my $name = $test_set->first_child('name')->text();
    my $desc = $test_set->first_child('desc')->text();

    my $query_group_list = $test_set->first_child('query-group-list');

    my $query_group = $query_group_list->first_child('query-group');

    $self->_process_query_group($query_group, $name, $desc);

    while ($query_group = $query_group->next_sibling()){

        $self->_process_query_group($query_group, $name, $desc);
    }
}

sub _process_query_group {

    my $self = shift;
    my ($query_group, $name, $desc) = @_;

    my $query = $query_group->first_child('query')->text();

    my $target_list = $query_group->first_child('target-list');

    my $target = $target_list->first_child('target');

    $self->_create_test_record($name, $query, $target->text(), $desc);

    while ($target = $target->next_sibling()){

        $self->_create_test_record($name, $query, $target->text(), $desc);        
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
