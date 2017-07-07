package QueriesBenchmarker::Utils::SPARQL::Connectivity::Record;

use Moose;
use Log::Log4perl;

use constant TRUE  => 1;
use constant FALSE => 0;

has 'name' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setName',
    reader   => 'getName',
    required => FALSE
    );

has 'type' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setType',
    reader   => 'getType',
    required => FALSE
    );

has 'uri' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setURI',
    reader   => 'getURI',
    required => FALSE
    );

has 'vendor' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setVendor',
    reader   => 'getVendor',
    required => FALSE
    );

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


no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 QueriesBenchmarker::Utils::SPARQL::Connectivity::Record

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use QueriesBenchmarker::Utils::SPARQL::Connectivity::Record;
 my $record = new QueriesBenchmarker::Utils::SPARQL::Connectivity::Record(
  username => $username,
  password => $password,
  server   => $server,
  database => $database,
  port_number => $port_number
 );

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut