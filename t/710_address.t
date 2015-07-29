#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 26;
use Encode qw(decode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Encode',        qw(encode_utf8);
    use_ok 'Digest::MD5',   qw(md5_hex);
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

note 'address';
{
    my ($full, $address, $lon, $lat, $md5, $id, $type, $lang, $opt) = (
        '  United States, New York : 42.93709 ,  -75.610703  ',
        'United States, New York',
        42.93709,
        -75.610703,
        undef,
        undef,
        undef,
        undef,
        undef,
    );

    $t->app->routes->post("/test/address")->to(cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('address1')->address,   'address1 валидация';
        ok ! $v->has_error('address1'),         'address1 ошибки нет';
        is_deeply
            $v->param('address1'),
            [$address, $lon, $lat, $md5, $full, $id, $type, $lang, $opt],
            'address1 значение';

        my $a = $v->param('address1');
        is $a->address,     $address,   'address';
        is $a->lon,         $lon,       'lon';
        is $a->lat,         $lat,       'lat';
        is $a->md5,         $md5,       'md5';

        ok $v->required('address2')->address,   'address2 валидация';
        ok $v->has_error('address2'),           'address2 ошибка';
        is $v->param('address2'), undef,        'address2 пустая строка';

        ok $v->required('address3')->address,   'address3 валидация';
        ok $v->has_error('address3'),           'address3 ошибка';
        is $v->param('address3'), undef,        'address3 пропущен lat';

        ok $v->required('address4')->address,   'address4 валидация';
        ok $v->has_error('address4'),           'address4 ошибка';
        is $v->param('address4'), undef,        'address4 пропущен адрес';

        ok $v->required('address5')->address,   'address5 валидация';
        ok $v->has_error('address5'),           'address5 ошибка';
        is $v->param('address5'), undef,        'address5 пропущен адрес';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/address", form => {
        address1    => "  $address : $lon ,  $lat  ",
        address2    => '',
        address3    => "  $address : $lon , ",
        address4    => "$lon ,  $lat  ",
        address5    => "  :  $lon ,  $lat  ",
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

