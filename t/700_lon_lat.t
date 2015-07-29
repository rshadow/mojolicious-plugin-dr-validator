#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib ../../lib);

use Test::More tests => 29;
use Encode qw(decode);

BEGIN {
    use_ok 'Test::Mojo';
    use_ok 'Mojolicious::Plugin::DR::Validator';
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

note 'lon';
{
    $t->app->routes->post("/test/lon")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('lon0')->lon,       'lon0 валидация';
        ok ! $v->has_error('lon0'),         'lon0 ошибки нет';
        is $v->param('lon0'), 0,            'lon0 значение 0';

        ok $v->required('lon1')->lon,       'lon1 валидация';
        ok ! $v->has_error('lon1'),         'lon1 ошибки нет';
        is $v->param('lon1'), 11.22,        'lon1 значение дробное';

        ok $v->required('lon2')->lon,       'lon2 валидация';
        ok $v->has_error('lon2'),           'lon2 ошибка';
        is $v->param('lon2'), undef,        'lon2 меньше -180';

        ok $v->required('lon3')->lon,       'lon3 валидация';
        ok $v->has_error('lon3'),           'lon3 ошибка';
        is $v->param('lon3'), undef,        'lon3 больше 180';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/lon", form => {

        # numeric значения не проверяем

        lon0    => 0,
        lon1    => '11.22',
        lon2    => '-200',
        lon3    => '200',
    });

    diag decode utf8 => $t->tx->res->body unless $t->tx->success;
}

note 'lat';
{
    $t->app->routes->post("/test/lat")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('lat0')->lat,       'lat0 валидация';
        ok ! $v->has_error('lat0'),         'lat0 ошибки нет';
        is $v->param('lat0'), 0,            'lat0 значение 0';

        ok $v->required('lat1')->lat,       'lat1 валидация';
        ok ! $v->has_error('lat1'),         'lat1 ошибки нет';
        is $v->param('lat1'), 11.22,        'lat1 значение дробное';

        ok $v->required('lat2')->lat,       'lat2 валидация';
        ok $v->has_error('lat2'),           'lat2 ошибка';
        is $v->param('lat2'), undef,        'lat2 меньше -90';

        ok $v->required('lat3')->lat,       'lat3 валидация';
        ok $v->has_error('lat3'),           'lat3 ошибка';
        is $v->param('lat3'), undef,        'lat3 больше 90';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/lat", form => {

        # numeric значения не проверяем

        lat0    => 0,
        lat1    => '11.22',
        lat2    => '-100',
        lat3    => '100',
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

