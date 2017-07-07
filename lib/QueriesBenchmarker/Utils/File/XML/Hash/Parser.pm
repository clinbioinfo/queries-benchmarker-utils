package QueriesBenchmarker::Utils::File::XML::Hash::Parser;

use Moose;
use Data::Dumper;
use File::Slurp;
use XML::Hash;

extends 'QueriesBenchmarker::Utils::File::XML::Parser';

use constant TRUE  => 1;
use constant FALSE => 0;

## Singleton support
my $instance;


sub getInstance {

    if (!defined($instance)){

        $instance = new QueriesBenchmarker::Utils::File::XML::Hash::Parser(@_);

        if (!defined($instance)){

            confess "Could not instantiate QueriesBenchmarker::Utils::File::XML::Hash::Parser";
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
    
    my $infile = $self->getInfile();
    if (!defined($infile)){
        $self->{_logger}->logconfess("infile was not defined");
    }


    my @lines = read_file($infile);

    chomp @lines;
    
    my $content = join('', @lines);

    my $xml_converter = new XML::Hash();
    if (!defined($xml_converter)){
        $self->{_logger}->logconfess("Could not instantiate XML::Hash");
    }

    my $hash = $xml_converter->fromXMLStringtoHash($content);
    if (!defined($hash)){
        $self->{_logger}->logconfess("hash was not defined");
    }

    if (exists $hash->{'queries-benchmarker'}->{'target-list'}->{'target'}){

        my $target_list = $hash->{'queries-benchmarker'}->{'target-list'}->{'target'};

        $self->_process_target_list($target_list);
    }
    else {
        $self->{_logger}->logconfess("//queries-benchmarker/target-list/target does not exist");
    }

    if (exists $hash->{'queries-benchmarker'}->{'test-set-list'}->{'test-set'}){

        my $test_set_list = $hash->{'queries-benchmarker'}->{'test-set-list'}->{'test-set'};

        $self->_process_test_set_list($test_set_list);
    }
    else {
        $self->{_logger}->logconfess("//queries-benchmarker/test-set-list/test-set does not exist");
    }

    print Dumper $hash;die;

}

sub _process_target_list {

    my $self = shift;
    my ($target_list) = @_;

     # print Dumper $target_list;die;

    foreach my $target_lookup (@{$target_list}){

        my $name;
        my $config_file;
        my $type;

        if (exists $target_lookup->{'name'}->{text}){
            $name = $target_lookup->{'name'}->{text};
        }
        else {
            $self->{_logger}->logconfess("name was not defined for target : " . Dumper $target_lookup);
        }

        if ($name eq 'bdm'){ next; }

        if (exists $target_lookup->{'config-file'}->{text}){
            $config_file = $target_lookup->{'config-file'}->{text};
        }
        else {
            $self->{_logger}->logconfess("config-file was not defined for target : " . Dumper $target_lookup);
        }

        if (exists $target_lookup->{'type'}->{text}){
            $type = $target_lookup->{'type'}->{text};
        }
        else {
            $self->{_logger}->logconfess("type was not defined for target : " . Dumper $target_lookup);
        }

        $self->_create_repository_record($name, $type, $config_file);
    }
}

sub _process_test_set_list {

    my $self = shift;
    my ($test_set_list) = @_;

    foreach my $test_set_lookup (@{$test_set_list}){

        my $query_name;

        if (exists $test_set_lookup->{'name'}){

            $query_name = $test_set_lookup->{'name'};
        }
        else {
            $self->{_logger}->logconfess("name was not defined for test set " . Dumper $test_set_lookup);
        }

        if (! exists $test_set_lookup->{'query-group-list'}->{'query-group'}){
            $self->{_logger}->logconfess("//test-set-list/test-set/query-group-list/query-group");
        }

        foreach my $query_group_lookup (@{$test_set_lookup->{'query-group-list'}->{'query-group'}}){

            if (! exists $query_group_lookup->{'query'}){

                $self->{_logger}->logconfess("//query-group-list/quuery-group/query was not defined");
            }

            my $query = $query_group_lookup->{'query'};

            if (! exists $query_group_lookup->{'target-list'}->{'target'}){

                $self->{_logger}->logconfess("//target-list/target was not defined");
            }

            my $target_list = $query_group_lookup->{'target-list'}->{'target'};

            foreach my $target_lookup (@{$target_list}){

                if (exists $target_lookup->{text}){

                    my $target_name = $target_lookup->{text};

                    $self->_create_test_record($query_name, $query, $target_name);
                }
                else {
                    $self->{_logger}->logconfess("target text was not defined");
                }
            }
        }
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
