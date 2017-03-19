use strict;
use Test2::Bundle::Extended;
use Test::Mock::Furl;
use Net::Moip::V2;
use Data::Dumper;


my $moip = Net::Moip::V2->new(
    sandbox => 1,
    token   => $ENV{MOIP_TOKEN} || 'test_token',
    key     => $ENV{MOIP_KEY} || 'test_key',
);


my $ep = $moip->endpoint('orders');

is $ep->path, 'orders', 'path';

for (qw/ token key /) {
    is $ep->$_, $moip->$_, $_;
}

like $ep->_basic_auth_token, qr/Basic \w+/, '_basic_auth_token';


subtest 'sandbox' => sub {


    is $moip->api_url, 'https://sandbox.moip.com.br/v2';
    is $moip->oauth_url, 'https://connect-sandbox.moip.com.br';

    $moip->sandbox(0);
    is $moip->api_url, 'https://api.moip.com.br/v2';
    is $moip->oauth_url, 'https://connect.moip.com.br';
    $moip->sandbox(1);
};

subtest 'get' => sub {

    $Mock_furl->mock(get => sub {
        is $_[1], 'https://sandbox.moip.com.br/v2/orders';
        is $_[2], [
            'Content-Type' => 'application/json',
            'Authorization' => $ep->_basic_auth_token,
        ];
    });

    $moip->endpoint('orders')->get;

    $Mock_furl->mock(get => sub {
        is $_[1], 'https://sandbox.moip.com.br/v2/orders/some_id';
    });

    $moip->endpoint('orders')->get('some_id');
};

subtest 'post' => sub {

    $Mock_furl->mock(post => sub {
        is $_[1], 'https://sandbox.moip.com.br/v2/orders';
        is $_[2], [
            'Content-Type' => 'application/json',
            'Authorization' => $ep->_basic_auth_token,
        ];
        is $_[3], '{"some":"json"}';
    });

    $moip->endpoint('orders')->post({
        some => 'json'
    });


};








done_testing;
