package QueriesBenchmarker::Utils::DBUtil;

use Moose;
use Benchmark;

use QueriesBenchmarker::Utils::Config::Manager;

use DBI;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_USE_PROXY_ACCOUNT => FALSE;

## Singleton support
my $instance;

has 'use_proxy_database_account' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setUseProxyDatabaseAccount',
    reader   => 'getUseProxyDatabaseAccount',
    required => FALSE,
    default  => DEFAULT_USE_PROXY_ACCOUNT
);

has 'username' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setUsername',
    reader => 'getUsername'
    );

has 'password' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setPassword',
    reader => 'getPassword'
    );

has 'database' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setDatabase',
    reader => 'getDatabase'
    );

has 'server' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setServer',
    reader => 'getServer'
    );

has 'port_number' => (
    is     => 'rw',
    isa    => 'Str',
    writer => 'setPortNumber',
    reader => 'getPortNumber'
    );


sub getInstance {

    if (!defined($instance)){

        $instance = new QueriesBenchmarker::Utils::DBUtil(@_);

        if (!defined($instance)){

            confess "Could not instantiate QueriesBenchmarker::Utils::DBUtil";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);
    $self->_initConfigManager(@_);
    $self->_initDBI(@_);
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

sub _initDBI {

    my $self = shift;

    my $username = $self->getUsername();
    my $password = $self->getPassword();
    my $server   = $self->getServer();
    my $database = $self->getDatabase();
    my $port_number = $self->getPortNumber();

    if ($self->getUseProxyDatabaseAccount()){

        $username = 'BDM_PROXY[' . uc($username) . ']';
    }

    my $dbh = DBI->connect("dbi:Oracle://$server:$port_number/$database", $username, $password);
    if (!defined($dbh)){
	$self->{_logger}->logconfess("Could not connect to '$database' on server '$server' port '$port_number' with username '$username'' " . $DBI::errstr);
    }


    $self->{_dbh} = $dbh;
}

sub _getUsername {

    my $self = shift;
    my (%args) = @_;

    my $username = $self->getUsername();

    if (!defined($username)){
        if (( exists $args{username}) && ( defined $args{username})){
            $username = $args{username};
        }
        elsif (( exists $self->{_username}) && ( defined $self->{_username})){
            $username = $self->{_username};
        }
        else {

            $username = $self->_getUsernameFromConfig();

            if (!defined($username)){
                $self->{_logger}->logconfess("Could not retrieve database admin username from the configuration file");
            }
        }

        $self->setUsername($username);
    }

    return $username;
}

sub _getUsernameFromConfig {

    my $self = shift;
    return $self->{_config_manager}->getDatabaseAdminUsername();
}


sub _getPassword {

    my $self = shift;
    my (%args) = @_;

    my $password = $self->getPassword();

    if (!defined($password)){
        if (( exists $args{password}) && ( defined $args{password})){
            $password = $args{password};
        }
        elsif (( exists $self->{_password}) && ( defined $self->{_password})){
            $password = $self->{_password};
        }
        else {

            $password = $self->_getPasswordFromConfig();

            if (!defined($password)){
                $self->{_logger}->logconfess("Could not retrieve database admin password from the configuration file");
            }
        }

        $self->setPassword($password);
    }

    return $password;
}

sub _getPasswordFromConfig {

    my $self = shift;
    return $self->{_config_manager}->getDatabaseAdminPassword();
}

sub _getDatabase {

    my $self = shift;
    my (%args) = @_;

    my $database = $self->getDatabase();

    if (!defined($database)){
        if (( exists $args{database}) && ( defined $args{database})){
            $database = $args{database};
        }
        elsif (( exists $self->{_database}) && ( defined $self->{_database})){
            $database = $self->{_database};
        }
        else {

            $database = $self->_getDatabaseFromConfig();

            if (!defined($database)){
                $self->{_logger}->logconfess("Could not retrieve database admin database from the configuration file");
            }
        }

        $self->setDatabase($database);
    }

    return $database;
}

sub _getDatabaseFromConfig {

    my $self = shift;
    return $self->{_config_manager}->getDatabaseAdminDatabase();
}

sub _getServer {

    my $self = shift;
    my (%args) = @_;

    my $server = $self->getServer();

    if (!defined($server)){
        if (( exists $args{server}) && ( defined $args{server})){
            $server = $args{server};
        }
        elsif (( exists $self->{_server}) && ( defined $self->{_server})){
            $server = $self->{_server};
        }
        else {

            $server = $self->_getServerFromConfig();

            if (!defined($server)){
                $self->{_logger}->logconfess("Could not retrieve database admin server from the configuration file");
            }
        }

        $self->setServer($server);
    }

    return $server;
}

sub _getServerFromConfig {

    my $self = shift;
    return $self->{_config_manager}->getServer();
}

sub _getPortNumber {

    my $self = shift;
    my (%args) = @_;

    my $port_number = $self->getPortNumber();

    if (!defined($port_number)){

        if (( exists $args{port_number}) && ( defined $args{port_number})){
            $port_number = $args{port_number};
        }
        elsif (( exists $self->{_port_number}) && ( defined $self->{_port_number})){
            $port_number = $self->{_port_number};
        }
        else {

            $port_number = $self->getDefaultPortNumber();                

            $self->{_logger}->warn("Could not retrieve port number from the configuration file so set defaul value '$port_number'");             
        }

        $self->setPortNumber($port_number);
    }

    return $port_number;
}

sub _getPortNumberFromConfig {

    my $self = shift;
    return $self->{_config_manager}->getPortNumber();
}

sub getTimeRecord {

    my $self = shift;
    
    return $self->{_time_record};
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 QueriesBenchmarker::Utils::DBUtil
 A module for generate database connectivity support.

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use QueriesBenchmarker::Utils::DBUtil;
 my $dbutil = QueriesBenchmarker::Utils::DBUtil::getInstance(
    username => $username, 
    password => $password,
    server   => $server,
    database => $database
    );

 my $records = $dbutil->executeQuery($query);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
