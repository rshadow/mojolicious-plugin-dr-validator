#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 85;
use Encode qw(decode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Encode',        qw(encode_utf8);
    use_ok 'Digest::MD5',   qw(md5_hex);
    use_ok 'Mojolicious::Plugin::DR::Validator';
    use_ok 'Mojolicious::Plugin::DR::Validator::Address';
}

note 'address не подписан';
{
    {
        package MyApp;
        use Mojo::Base 'Mojolicious';

        sub startup {
            my ($self) = @_;
            $self->plugin('DR::I18n');
            $self->plugin('DR::Validator');
        }
        1;
    }
    my $t = Test::Mojo->new('MyApp');
    ok $t, 'Test Mojo created';

    my ($full, $address, $lon, $lat, $id, $type, $lang, $opt) = (
        'United States, New York:42.93709,-75.610703 ',
        'United States, New York',
        42.93709,
        -75.610703,
        undef,
        undef,
        undef,
        undef,
    );
    my $md5 = md5_hex 'SECRET' . $full;

    $t->app->routes->post("/test/address")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('address1')->address,   'address1 валидация';
        ok ! $v->has_error('address1'),         'address1 ошибки нет';
        ok my $a1 = $v->param('address1'),      'address1 нет подписи';
        is $a1->address,    $address,   'address1 - address';
        is $a1->lon,        $lon,       'address1 - lon';
        is $a1->lat,        $lat,       'address1 - lat';
        is $a1->md5,        undef,      'address1 - md5';

        ok $v->required('address2')->address,   'address2 валидация';
        ok ! $v->has_error('address2'),         'address2 ошибки нет';
        ok my $a2 = $v->param('address2'),      'address2 подпись пустая';
        is $a2->address,    $address,   'address2 - address';
        is $a2->lon,        $lon,       'address2 - lon';
        is $a2->lat,        $lat,       'address2 - lat';
        is $a2->md5,        '',         'address2 - md5';

        ok $v->required('address3')->address,   'address3 валидация';
        ok ! $v->has_error('address3'),         'address3 ошибки нет';
        ok my $a3 = $v->param('address3'),      'address3 подпись валидна';
        is $a3->address,    $address,   'address3 - address';
        is $a3->lon,        $lon,       'address3 - lon';
        is $a3->lat,        $lat,       'address3 - lat';
        is $a3->md5,        $md5,       'address3 - md5';

        ok $v->required('address4')->address,   'address4 валидация';
        ok ! $v->has_error('address4'),         'address4 ошибки нет';
        ok my $a4 = $v->param('address4'),      'address4 подпись не валидна';
        is $a4->address,    $address,   'address4 - address';
        is $a4->lon,        $lon,       'address4 - lon';
        is $a4->lat,        $lat,       'address4 - lat';
        is $a4->md5,        'BAD',      'address4 - md5';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address", form => {
        address1    => "$address:$lon,$lat",
        address2    => "$address:$lon,$lat []",
        address3    => "$address:$lon,$lat [$md5]",
        address4    => "$address:$lon,$lat [BAD]",
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'address подписан';
{
     {
        package MyApp2;
        use Mojo::Base 'Mojolicious';

        sub startup {
            my ($self) = @_;
            $self->plugin('DR::I18n');
            $self->plugin('DR::Validator', {address_secret => 'SECRET'});
        }
        1;
    }
    my $t = Test::Mojo->new('MyApp2');
    ok $t, 'Test Mojo created with address signing';

    my ($full, $address, $lon, $lat, $id, $type, $lang, $opt) = (
        'United States, New York:42.93709,-75.610703 ',
        'United States, New York',
        42.93709,
        -75.610703,
        undef,
        undef,
        undef,
        undef,
    );
    my $md5 = md5_hex 'SECRET' . $full;

    $t->app->routes->post("/test/saddress")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('address1')->address,   'address1 валидация';
        ok $v->has_error('address1'),           'address1 ошибка';
        is $v->param('address1'), undef,        'address1 нет подписи';

        ok $v->required('address2')->address,   'address2 валидация';
        ok $v->has_error('address2'),           'address2 ошибка';
        is $v->param('address2'), undef,        'address2 подпись пустая';

        ok $v->required('address3')->address,   'address3 валидация';
        ok ! $v->has_error('address3'),         'address3 ошибки нет';
        ok my $a3 = $v->param('address3'),      'address3 подпись валидна';
        is $a3->address,    $address,   'address3 - address';
        is $a3->lon,        $lon,       'address3 - lon';
        is $a3->lat,        $lat,       'address3 - lat';
        is $a3->md5,        $md5,       'address3 - md5';

        ok $v->required('address4')->address,   'address4 валидация';
        ok $v->has_error('address4'),           'address4 ошибка';
        is $v->param('address4'), undef,        'address4 подпись не валидна';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/saddress", form => {
        address1    => "$address:$lon,$lat",
        address2    => "$address:$lon,$lat []",
        address3    => "$address:$lon,$lat [$md5]",
        address4    => "$address:$lon,$lat [BAD]",
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'address подписан utf8';
{
    {
        package MyApp4;
        use Mojo::Base 'Mojolicious';

        sub startup {
            my ($self) = @_;
            $self->plugin('DR::I18n');
            $self->plugin('DR::Validator', {address_secret => 'SECRET'});
        }
        1;
    }
    my $t = Test::Mojo->new('MyApp4');
    ok $t, 'Test Mojo created with address signing';

    my ($full, $address, $lon, $lat, $id, $type, $lang, $opt) = (
        'Российская Федерация, Москва, Радужная улица, 10:37.669342, 55.860691 ',
        'Российская Федерация, Москва, Радужная улица, 10',
        37.669342,
        55.860691,
        undef,
        undef,
        undef,
        undef,
    );
    my $md5 = md5_hex( encode_utf8( 'SECRET' . $full ) );

    $t->app->routes->post("/test/address/utf8")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('address1')->address,   'address1 валидация';
        ok ! $v->has_error('address1'),         'address1 ошибки нет';
        ok my $a1 = $v->param('address1'),      'address1 нет подписи';
        is $a1->address,    $address,   'address1 - address';
        is $a1->lon,        $lon,       'address1 - lon';
        is $a1->lat,        $lat,       'address1 - lat';
        is $a1->md5,        $md5,       'address1 - md5';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/utf8", form => {
        address1 => "$address:$lon, $lat [$md5]",
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'address реальные данные';
{
    {
        package MyApp3;
        use Mojo::Base 'Mojolicious';

        sub startup {
            my ($self) = @_;
            $self->plugin('DR::I18n');
            $self->plugin('DR::Validator', {
                address_secret => 'jinEbAupnillejotcoiletKidgoballOacGaiWyn'
            });
        }
        1;
    }
    my $t = Test::Mojo->new('MyApp3');
    ok $t, 'Test Mojo created with address signing';

    $t->app->routes->post("/test/address/real")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('address1')->address,   'address1 валидация';
        ok ! $v->has_error('address1'),         'address1 ошибки нет';
        ok my $a1 = $v->param('address1'),      'address1 нет подписи';
        is $a1->address,    'Россия, Москва, Радужная улица, 10',   'address';
        is $a1->lon,        '37.669342',                            'lon';
        is $a1->lat,        '55.860691',                            'lat';
        is $a1->md5,        'bd5511e30b99ea1275e91c1b47299c6d',     'md5';

        ok $v->required('address2')->address,   'address2 валидация';
        ok ! $v->has_error('address2'),         'address2 ошибки нет';
        ok my $a2 = $v->param('address2'),      'address2 подпись пустая';
        is $a2->address,    'Россия, Москва, Радужная улица, 10',   'address';
        is $a2->lon,        '37.669342',                            'lon';
        is $a2->lat,        '55.860691',                            'lat';
        is $a2->md5,        '14cbc10460ac83061e11ed27a3683604',     'md5';

        ok $v->required('address3')->address,   'address3 валидация';
        ok ! $v->has_error('address3'),         'address3 ошибки нет';
        ok my $a3 = $v->param('address3'),      'address3 подпись валидна';
        is $a3->address,    'Россия, Москва, Воронежская улица, 10','address';
        is $a3->lon,        '37.726834',                            'lon';
        is $a3->lat,        '55.609024',                            'lat';
        is $a3->md5,        '251de495d398119e0146bb1b1bb02810',     'md5';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/real", form => {
        address1 =>
            'Россия, Москва, Радужная улица, 10:37.669342, 55.860691'.
            '[bd5511e30b99ea1275e91c1b47299c6d]',
        address2 =>
            'Россия, Москва, Радужная улица, 10:37.669342,55.860691'.
            '[14cbc10460ac83061e11ed27a3683604]',
        address3 =>
            'Россия, Москва, Воронежская улица, 10:37.726834, 55.609024'.
            '[251de495d398119e0146bb1b1bb02810]',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}


=head1 COPYRIGHT

Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>

Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

All rights reserved. If You want to use the code You
MUST have permissions from Dmitry E. Oboukhov AND
Roman V Nikolaev.

=cut

