package QueriesBenchmarker::Utils::Test::Record;

use Moose;
use Log::Log4perl;

use constant TRUE  => 1;
use constant FALSE => 0;

has 'query_name' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setQueryName',
    reader   => 'getQueryName',
    required => FALSE
    );

has 'query' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setQuery',
    reader   => 'getQuery',
    required => FALSE
    );

has 'target_name' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setTargetName',
    reader   => 'getTargetName',
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

 QueriesBenchmarker::Utils::Test::Record

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use QueriesBenchmarker::Utils::Test::Record;
 my $record = new QueriesBenchmarker::Utils::Test::Record(
  query_name  => $query_name,
  target_name => $target_name,
  query       => $query
 );

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut