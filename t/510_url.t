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
    use_ok 'Mojo::URL';
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

note 'url';
{
    $t->app->routes->post("/test/url")->to( cb => sub {
        my ($self) = @_;

        my $v = $self->validation;

        ok $v->required('unknown')->url,            'unknown валидация';
        ok $v->has_error('unknown'),                'unknown ошибка';
        is $v->param('unknown'), undef,             'unknown не передано';

        ok $v->required('url0')->url,               'url0 валидация';
        ok $v->has_error('url0'),                   'url0 ошибка';
        is $v->param('url0'), undef,                'url0 только хост';

        ok $v->required('url1')->url,               'url1 валидация';
        ok $v->has_error('url1'),                   'url1 ошибка';
        is $v->param('url1'), undef,                'url1 пустая строка';

        ok $v->required('url2')->url,               'url2 валидация';
        ok $v->has_error('url2'),                   'url2 ошибка';
        is $v->param('url2'), undef,                'url2 только схема';

        ok $v->required('url3')->url,               'url3 валидация';
        ok ! $v->has_error('url3'),                 'url3 ошибки нет';
        is $v->param('url3'), 'http://a.ru',        'url3 http';

        ok $v->required('url4')->url,               'url4 валидация';
        ok ! $v->has_error('url4'),                 'url4 ошибки нет';
        is $v->param('url4'), 'https://a.ru',       'url4 https';

        ok $v->required('url5')->url,                   'url5 валидация';
        ok ! $v->has_error('url5'),                     'url5 ошибки нет';
        is $v->param('url5'), 'http://aa-bb.cc.ru?b=1', 'url5 регистр';

        ok $v->required('url6')->url,                   'url6 валидация';
        ok ! $v->has_error('url6'),                     'url6 ошибки нет';
        is $v->param('url6'), 'http://a.ru?b=1',        'url6 с пробелами';

        $self->render(text => 'OK.');
    });

    $t->post_ok("/test/url", form => {
        url0        => 'a.ru',
        url1        => '',
        url2        => 'http://',
        url3        => 'http://a.ru',
        url4        => 'https://a.ru',
        url5        => 'http://aA-bB.Cc.ru?b=1',
        url6        => '  http://a.ru?b=1  ',
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

