package QueriesBenchmarker::Utils::Oracle::DBUtil;

use Moose;

use QueriesBenchmarker::Utils::Config::Manager;

extends 'QueriesBenchmarker::Utils::DBUtil';

use DBD::Oracle qw(:ora_types);

use constant TRUE  => 1;
use constant FALSE => 0;

## Singleton support
my $instance;

sub getInstance {

    if (!defined($instance)){

        $instance = new QueriesBenchmarker::Utils::Oracle::DBUtil(@_);

        if (!defined($instance)){

            confess "Could not instantiate QueriesBenchmarker::Utils::Oracle::DBUtil";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);
    $self->_initConfigManager(@_);
    $self->_initDBI(@_);

    $self->{_logger}->info("Instantiated " . __PACKAGE__);
}

sub _get_array_ref {

    my $self = shift;
    my ($sql) = @_;

    ## pretty sql
    my $psql = $sql;
    
    ## replace all new-line characters with a single space
    $psql =~ s/\n/ /g;

    my $database = $self->getDatabase();
    my $server   = $self->getServer();
    my $username = $self->getUsername();

    $self->{_logger}->info("About to execute SQL query '$psql' (database '$database' server '$server' username '$username')");

    my $start_time = Benchmark->new;

    my $arrayRef = $self->{_dbh}->selectall_arrayref($sql);
    if (!defined($arrayRef)){
        $self->{_logger}->logconfess("arrayRef was not defined for query '$sql' (database '$database' server '$server' username '$username')");
    }
    
    my $end_time = Benchmark->new;

    my $time_diff = timediff($end_time, $start_time);

    $self->{_time_record} = {
        'start_time' => $start_time, 
        'end_time'   =>  $end_time,
        'time_diff'  => $time_diff,
        'took'       => timestr($time_diff)
    };

    return $arrayRef;    
}

sub executeQuery {

    my $self = shift;
    my ($query) = @_;

    if (!defined($query)){
        $self->{_logger}->logconfess("$query was not defined");
    }
    return $self->_get_array_ref($query);
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 QueriesBenchmarker::Utils::Oracle::DBUtil

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use QueriesBenchmarker::Utils::Oracle::DBUtil;

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut