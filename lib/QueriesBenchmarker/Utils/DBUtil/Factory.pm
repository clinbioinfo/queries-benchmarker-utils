package QueriesBenchmarker::Utils::DBUtil::Factory;

use Moose;

use QueriesBenchmarker::Utils::Oracle::DBUtil;
use QueriesBenchmarker::Utils::Postgresql::DBUtil;
use QueriesBenchmarker::Utils::Mysql::DBUtil;
use QueriesBenchmarker::Utils::REST::DBUtil;
use QueriesBenchmarker::Utils::MongoDB::DBUtil;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TYPE => 'oracle';

## Singleton support
my $instance;

has 'type' => (
    is      => 'rw',
    isa     => 'Str',
    writer  => 'setType',
    reader  => 'getType',
    default => DEFAULT_TYPE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new QueriesBenchmarker::Utils::DBUtil::Factory(@_);

        if (!defined($instance)){

            confess "Could not instantiate QueriesBenchmarker::Utils::DBUtil::Factory";
        }
    }

    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

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

sub _getType {

    my $self = shift;
    my (%args) = @_;

    my $type = $self->getType();

    if (!defined($type)){

        if (( exists $args{type}) && ( defined $args{type})){
            $type = $args{type};
        }
        elsif (( exists $self->{type}) && ( defined $self->{type})){
            $type = $self->{type};
        }
        else {
            $self->{_logger}->logconfess("type was not defined");
        }

        $self->setType($type);
    }

    return $type;
}

sub createByRepository {

    my $self = shift;
    my ($repository_record) = @_;

    if (!defined($repository_record)){
        $self->{_logger}->logconfess("targetRecord was not defined");
    }

    my $vendor = $repository_record->getVendor();

    my $type = $repository_record->getType();

    if (lc($type) eq 'sql'){

        if (lc($vendor) eq 'oracle'){

            my $dbutil = QueriesBenchmarker::Utils::Oracle::DBUtil::getInstance(
                username    => $repository_record->getUsername(),
                password    => $repository_record->getPassword(),
                server      => $repository_record->getServer(),
                port_number => $repository_record->getPortNumber(),
                database    => $repository_record->getDatabase()
                );

            if (!defined($dbutil)){
                $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::Oracle::DBUtil");
            }

            return $dbutil;
        }
        elsif (lc($vendor) eq 'postgresql'){

            my $dbutil = QueriesBenchmarker::Utils::Postgresql::DBUtil::getInstance(
                username    => $repository_record->getUsername(),
                password    => $repository_record->getPassword(),
                server      => $repository_record->getServer(),
                port_number => $repository_record->getPortNumber(),
                database    => $repository_record->getDatabase()
                );

            if (!defined($dbutil)){
                $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::Postgresql::DBUtil");
            }

            return $dbutil;
        }
        elsif (lc($vendor) eq 'mysql'){

            my $dbutil = QueriesBenchmarker::Utils::Mysql::DBUtil::getInstance(
                username    => $repository_record->getUsername(),
                password    => $repository_record->getPassword(),
                server      => $repository_record->getServer(),
                port_number => $repository_record->getPortNumber(),
                database    => $repository_record->getDatabase()
                );

            if (!defined($dbutil)){
                $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::Mysql::DBUtil");
            }

            return $dbutil;
        }
        else {
            $self->{_logger}->logconfess("vendor '$vendor' is not supported");
        }
    }
    elsif (lc($type) eq 'mongodb'){

        my $dbutil = QueriesBenchmarker::Utils::MongoDB::DBUtil::getInstance(
            username    => $repository_record->getUsername(),
            password    => $repository_record->getPassword(),
            server      => $repository_record->getServer(),
            port_number => $repository_record->getPortNumber(),
            database    => $repository_record->getDatabase()
            );

        if (!defined($dbutil)){
            $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::MongoDB::DBUtil");
        }

        return $dbutil;
    }
    elsif (lc($type) eq 'rest'){

        my $dbutil = QueriesBenchmarker::Utils::REST::DBUtil::getInstance(
            uri => $repository_record->getURI(),
            );

        if (!defined($dbutil)){
            $self->{_logger}->logconfess("Could not instantiate QueriesBenchmarker::Utils::REST::DBUtil");
        }

        return $dbutil;
    }
    else {
        confess "type '$type' is not currently supported";
    }
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 QueriesBenchmarker::Utils::DBUtil::Factory

 A module factory for creating DatasetAssembly::Manager instances.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use QueriesBenchmarker::Utils::DBUtil::Factory;
 my $factory = QueriesBenchmarker::Utils::DBUtil::Factory::getIntance();
 my $dbutil = $factory->create($repository_record);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
