#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 70;
use Encode qw(decode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Encode',        qw(encode_utf8);
    use_ok 'JSON::XS',      qw(encode_json);
    use_ok 'Mojolicious::Plugin::DR::Validator';
    use_ok 'Mojolicious::Plugin::DR::Validator::Address';
}

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

note 'address json';
{
    my ($full, $address, $lon, $lat, $md5, $id, $type, $lang, $opt) = (
        'United States, New York : 42.93709 , -75.610703',
        'United States, New York',
        42.93709,
        -75.610703,
        undef,
        123,
        'p',
        'en',
        'extra',
    );
    my $json = encode_json [ $id, $type, $address, $lon, $lat, $lang, $opt ];

    my $json7 = encode_json [
        $id, $type, $address, $lon, $lat, $lang, 'unknown'
    ];
    my $json8 = encode_json [
        $id, $type, $address, $lon, $lat, $lang, undef
    ];

    my ($address2, $lon2, $lat2) = (
        'United States, Elizabeth',
        40.6622967,
        -74.1965427,
    );
    my $json9 = encode_json [
        $id, $type, $address, $lon, $lat, $lang, [$address2, $lon2, $lat2]
    ];

    $t->app->routes->post("/test/address/json")->to(cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('address1')->address,   'address1 валидация';
        ok ! $v->has_error('address1'),         'address1 ошибки нет';
        is_deeply
            my $a = $v->param('address1'),
            [$address, $lon, $lat, $md5, $full, $id, $type, $lang, $opt],
            'address1 значение';
        is $a->address,     $address,   'address';
        is $a->lon,         $lon,       'lon';
        is $a->lat,         $lat,       'lat';
        is $a->md5,         $md5,       'md5';
        is $a->fullname,    $full,      'fullname';
        is $a->id,          $id,        'id';
        is $a->type,        $type,      'type';
        is $a->lang,        $lang,      'lang';
        is $a->opt,         $opt,       'opt';

        is $a->is_extra,    1,          'is_extra';

        ok $v->required('address2')->address,   'address2 валидация';
        ok $v->has_error('address2'),           'address2 ошибка';
        is $v->param('address2'), undef,        'address2 пустой массив';

        ok $v->required('address3')->address,   'address3 валидация';
        ok $v->has_error('address3'),           'address3 ошибка';
        is $v->param('address3'), undef,        'address3 массив null';

        ok $v->required('address4')->address,   'address4 валидация';
        ok $v->has_error('address4'),           'address4 ошибка';
        is $v->param('address4'), undef,        'address4 неверный формат';

        ok $v->required('address5')->address,   'address5 валидация';
        ok $v->has_error('address5'),           'address5 ошибка';
        is $v->param('address5'), undef,        'address5 null';

        ok $v->required('address6')->address,   'address6 валидация';
        ok $v->has_error('address6'),           'address6 ошибка';
        is $v->param('address6'), undef,        'address6 пустая строка';


        ok $v->required('address7')->address,   'address7 валидация';
        ok ! $v->has_error('address7'),         'address7 ошибки нет';
        ok my $a7 = $v->param('address7'),      'address7 значение';
        is $a7->is_extra, 0,                    'address7 is_extra неизвестно';

        ok $v->required('address8')->address,   'address8 валидация';
        ok ! $v->has_error('address8'),         'address8 ошибки нет';
        ok my $a8 = $v->param('address8'),      'address8 значение';
        is $a8->is_extra, 0,                    'address8 is_extra undef';

        ok $v->required('address9')->address,   'address9 валидация';
        ok ! $v->has_error('address9'),         'address9 ошибки нет';
        ok my $a9 = $v->param('address9'),      'address9 значение';
        is $a9->is_near, 1,                     'is_near';
        isa_ok $a9->near, 'ARRAY',              'адрес рядом';
        is $a9->near->address,  $address2,      'рядом с address';
        is $a9->near->lon,      $lon2,          'рядом с lon';
        is $a9->near->lat,      $lat2,          'рядом с lat';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/json", form => {
        address1    => $json,
        address2    => "[]",
        address3    => "[null]",
        address4    => encode_json([$address, $lon, $lat]),
        address5    => "null",
        address6    => "",
        address7    => $json7,
        address8    => $json8,
        address9    => $json9,
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'address json реальные запросы';
{
    $t->app->routes->post("/test/address/json/real")->to(cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('address1')->address,   'address1 валидация';
        ok ! $v->has_error('address1'),         'address1 ошибки нет';
        ok my $a = $v->param('address1'),       'address1 значение';
        is $a->address,     'Россия, Москва, Воронежская, 38/43',   'address';
        is $a->lon,         '37.742669',                            'lon';
        is $a->lat,         '55.609859',                            'lat';
        is $a->md5,         undef,                                  'md5';
        is $a->fullname,    'Россия, Москва, Воронежская, 38/43'.
                            ' : 37.742669 , 55.609859',
                            'fullname';
        is $a->id,          '2034755',                              'id';
        is $a->type,        'p',                                    'type';
        is $a->lang,        'ru',                                   'lang';
        is $a->opt,         undef,                                  'opt';

        ok $v->required('address2')->address,   'address2 валидация';
        ok ! $v->has_error('address2'),         'address2 ошибки нет';
        ok my $a2 = $v->param('address2'),      'address2 значение';
        is $a2->address, 'Россия, Москва, Новороссийская, 8', 'address2';
        is $a2->lon, 37.759475, 'lon';
        is $a2->lat, 55.679201, 'lat';


        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address/json/real", form => {
        address1    => '["'.
            '2034755","p","Россия, Москва, Воронежская, 38/43","37.742669",'.
            '"55.609859","ru"'.
        ']',
        address2   => '['.
            'null,"p","Россия, Москва, Новороссийская, 8",'.
            '"37.759475","55.679201","ru"'.
        ']',
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

