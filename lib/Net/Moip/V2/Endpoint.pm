package Net::Moip::V2::Endpoint;

use IO::Socket::SSL;
use MIME::Base64;
use Furl;
use JSON;

use Moo;

my $JSON = JSON->new->utf8;

has 'path', is => 'ro', required => 1;

has 'api_url', is => 'ro',required => 1;

has 'ua', is => 'ro', required => 1;

has 'token', is => 'ro', required => 1;

has 'key', is => 'ro', required => 1;

has 'client_id', is => 'ro';

has 'client_secret', is => 'ro';

has '_basic_auth_token', is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    'Basic '.MIME::Base64::encode_base64( $self->token .':'. $self->key, '');
};

has 'url', is => 'ro', init_arg => undef, default => sub {
    my $self = shift;
    join '/', $self->api_url, $self->path;
};



sub get {
    my ($self, $id) = @_;

    my $url = join '/', $self->url, $id || ();
    $self->ua->get($url, [
        'Content-Type'   => 'application/json',
        'Authentication' => $self->_basic_auth_token
    ]);
}

sub post {
    my ($self, $data) = @_;

    $self->ua->post($self->url, [

        'Content-Type'   => 'application/json',
        'Authentication' => $self->_basic_auth_token

    ], $JSON->encode($data) );
}

sub request_oauth_access_token {
    my ($self, )
}





1;
