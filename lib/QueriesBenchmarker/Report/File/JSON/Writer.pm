package QueriesBenchmarker::Report::File::JSON::Writer;

use Moose;
use JSON;

use constant TRUE  => 1;
use constant FALSE => 0;

has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutfile',
    reader   => 'getOutfile',
    required => FALSE
);

has 'lookup' => (
    is       => 'rw',
    isa      => 'HashRef',
    writer   => 'setLookup',
    reader   => 'getLookup',
    required => FALSE
    );

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

sub writeFile {

    my $self = shift;
    my ($outfile, $lookup) = @_;

    if (!defined($outfile)){

        $outfile = $self->getOutfile();

        if (!defined($outfile)){
            $self->{_logger}->logconfess("outfile was not defined");
        }
    }

    if (!defined($lookup)){

        $lookup = $self->getLookup();

        if (!defined($lookup)){
            $self->{_logger}->logconfess("lookup was not defined");
        }
    }

    open (OUTFILE, ">$outfile") || $self->{_logger}->logconfess("Could not open '$outfile' in write mode : $!");
    
    print OUTFILE encode_json($lookup);

    close OUTFILE;

    $self->{_logger}->info("Wrote records to '$outfile'");

    print "Wrote report file '$outfile'\n";
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 QueriesBenchmarker::Report::File::JSON::Writer

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use QueriesBenchmarker::Report::File::JSON::Writer;
 my $writer = new QueriesBenchmarker::Report::File::JSON::Writer(
    outfile => $outfile,
    lookup  => $lookup
    );

 $writer->writeFile();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut