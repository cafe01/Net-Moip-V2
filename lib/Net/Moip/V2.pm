package Net::Moip::V2;

use IO::Socket::SSL;
use MIME::Base64;
use Furl;
use JSON;
use Moo;
use URI;

use Net::Moip::V2::Endpoint;

our $VERSION = "0.01";

my $JSON = JSON->new->utf8;

has 'ua', is => 'ro', default => sub {
    Furl->new(
        agent         => "Net-Moip-V2/$VERSION",
        timeout       => 15,
        max_redirects => 3,
        # <perigrin> "SSL Wants a read first" I think is suggesting you
        # haven't read OpenSSL a bedtime story in too long and perhaps
        # it's feeling neglected and lonely?
        # see also: https://metacpan.org/pod/IO::Socket::SSL#SNI-Support
        # https://metacpan.org/pod/Furl#FAQ
        # https://rt.cpan.org/Public/Bug/Display.html?id=86684
        ssl_opts => {
            SSL_verify_mode => SSL_VERIFY_PEER(),
            # forcing version yields better error message:
            SSL_version     => 'TLSv1_2',
        },
    );
};

has 'token', is => 'ro', required => 1;

has 'key', is => 'ro', required => 1;

has 'client_id', is => 'ro';

has 'client_secret', is => 'ro';



has 'api_url', (
    is      => 'ro',
    writer  => '_set_api_url',
    default => 'https://api.moip.com.br/v2'
);

has 'oauth_url', (
    is      => 'ro',
    writer  => '_set_oauth_url',
    default => 'https://connect.moip.com.br'
);


has 'sandbox', (
    is      => 'rw',
    default => 0,
    trigger => sub {
        my ($self, $sandbox) = @_;
        $self->_set_api_url( $sandbox
            ? 'https://sandbox.moip.com.br/v2'
            : 'https://api.moip.com.br/v2'
        );
        $self->_set_oauth_url( $sandbox
            ? 'https://connect-sandbox.moip.com.br'
            : 'https://connect.moip.com.br'
        );
    }
);

has '_basic_auth_token', is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    'Basic '.MIME::Base64::encode_base64( $self->token .':'. $self->key, '');
};

sub build_authorization_url {
    my ($self, $redirect_uri, $scope) = @_;
    die 'Method signature is: build_authorization_url($redirect_uri, $scope)'
        unless $redirect_uri && $scope;

    my $url = URI->new($self->oauth_url.'/oauth/authorize');
    $url->query_form(
        response_type => 'code',
        client_id => $self->client_id,
        redirect_uri => $redirect_uri,
        scope => join(',', map { uc } @$scope)
    );
    $url;
}

sub request_access_token {
    my ($self, $redirect_uri, $code) = @_;
    die 'Method signature is: request_access_token($redirect_uri, $code)'
        unless $redirect_uri && $code;

    my $uri = URI->new($self->oauth_url.'/oauth/token');
    $uri->query_form(
        client_id => $self->client_id,
        client_secret => $self->client_secret,
        grant_type => 'authorization_code',
        redirect_uri => $redirect_uri,
        code => $code
    );

    my ($url, $body) = $uri->as_string =~ /(.*?)\?(.*)/;
    my $res = $self->ua->post($url, [
        'Content-Type'   => 'application/x-www-form-urlencoded',
        'Authentication' => $self->_basic_auth_token,
        'Cache-Control:' => 'no-cache'
    ], $body);

    return { error => $res->status_line } unless $res->is_success;
    my $data = $JSON->decode($res->content);
}




sub endpoint {
    my ($self, $path) = @_;
    die "Syntax: moip->endpoint(<name>)" unless $path;
    Net::Moip::V2::Endpoint->new(
        path => $path,
        map { $_ => $self->$_ } qw/ ua api_url token key client_id client_secret /
    );
}

sub get {
    my $self = shift;
    my $endpoint = shift;
    $self->endpoint($endpoint)->get(@_);
}

sub post {
    my $self = shift;
    my $endpoint = shift;
    $self->endpoint($endpoint)->post(@_);
}




1;
__END__

=encoding utf-8

=head1 NAME

Net::Moip::V2 - It's new $module

=head1 SYNOPSIS

    use Net::Moip::V2;

    my $moip = Net::Moip::V2->new(
        timeout => 10,
    );

    # Working with the 'orders' collection
    my $orders = $moip->collection('orders');

    # List orders: GET /orders
    my @orders = $orders->get;

    # Create new order: POST /orders
    my $new_order = $orders->post(\%params);

    # Fetch order
    my $order = $orders->get($new_order->{id});

    # Related collection
    my $order_payments = $order->collection('payments');

    # List payments for a specific order
    # GET /orders/<order id>/payments
    my @order_payments = $order_payments->get;



=head1 DESCRIPTION

Net::Moip::V2 is a thin wrapper over the Moip V2 API. Which means it's not an
abstraction of actual REST API, so you won't find methods like C<create_order()> or
C<get_orders()>. This module will help you build the endpoint path, and send
http requests, with authentication handled for you.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
